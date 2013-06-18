#include "java.h"
#include "javaisa.h"
#include "reloc.h"

static	int	pcdis;
static	int	callunrescue;
static	Jinst	*J;
static	Method	*M;
	Code	*code;		/* method under translation */

static	int	trylevel(int);
static	void	unrescue(int);

/*
 * Allocate a Dis instruction.
 */

static Inst*
newi(uchar op)
{
	Inst *i;

	i = Mallocz(sizeof(Inst));
	i->op = (uchar)op;
	i->pc = pcdis;
	pcdis += 1;
	i->j = J;
	i->next = nil;
	if(J && J->dis == nil)
		J->dis = i;
	if(ihead == nil)
		ihead = i;
	if(itail)
		itail->next = i;
	itail = i;
	return i;
}

/*
 * Allocate a Dis instruction and record for branch-address patching.
 */

static Inst*
newibap(uchar op)
{
	Inst *i;

	i = newi(op);
	patchop(i);
	return i;
}

/*
 * Turn single indirection off fp into double indirection.
 */

static void
sind2dind(Addr *a, int s)
{
	if(a->mode == Afp) {
		a->mode = Afpind;
		/* check for overflow ??? */
		a->u.b.fi = a->u.offset;
		a->u.b.si = s;
	} else if(a->mode == Amp && a->u.offset == 0)
		;	/* verifyerror(J); *//* can't reject prior to runtime */
	else
		fatal("sind2dind: %d not Afp\n", a->mode);
}

/*
 * Middle operands that match destination operands are redundant.
 */

static void
middstcmp(Inst *i)
{
	Addr *m, *d;

	m = &i->m;
	d = &i->d;
	if(m->mode == Afp && m->mode == d->mode && m->u.offset == d->u.offset) {
		m->mode = Anone;
		m->u.offset = 0;
	}
}

/*
 * For instructions that may reference Module Data.
 */

static void
datareloc(Inst *i)
{
	if(i->op == IMOVP && i->s.mode == Amp && i->s.u.offset == 0)
		return;		/* don't relocate reference to nil */
	if(i->s.mode == Amp)
		addDreloc(i, PSRC, PSIND);
	if(i->m.mode == Amp)
		addDreloc(i, PMID, PSIND);
}

static uchar
movinst(uchar jtype)
{
	uchar movi;

	switch(jtype) {
	case 'Z':
	case 'B':
		if(J->op == Jgetfield || J->op == Jgetstatic)
			movi = ICVTBW;
		else if(J->op == Jputfield || J->op == Jputstatic)
			movi = ICVTWB;
		else
			movi = IMOVW;
		break;
	case 'C':
	case 'S':
	case 'I':
		movi = IMOVW;
		break;
	case 'J':
		movi = IMOVL;
		break;
	case 'F':
	case 'D':
		movi = IMOVF;
		break;
	case 'L':
	case '[':
		movi = IMOVP;
		break;
	default:
		SET(movi);	/* not reached */
	}
	return movi;
}

typedef struct	FieldInfo	FieldInfo;

struct FieldInfo {
	char	*classname;
	char	*fieldname;
	char	*sig;
	int	flags;
};

static void
getfldinfo(FieldInfo *fi)
{
	Const *c, *n;
	int i, ix;
	Method *m;

	if(J->op == Jinvokeinterface)
		ix = J->u.x2c0.ix;
	else
		ix = J->u.i;
	c = &class->cps[ix];
	fi->classname = CLASSNAME(c->fmiref.class_index);
	n = &class->cps[c->fmiref.name_type_index];
	fi->fieldname = STRING(n->nat.name_index);
	fi->sig = STRING(n->nat.sig_index);
	fi->flags = 0;
	if(strcmp(fi->classname, THISCLASS) != 0)
		return;
	for(i = 0, m = class->methods; i < class->methods_count; i++, m++) {
		if(strcmp(fi->fieldname, STRING(m->name_index)) == 0
		&& strcmp(fi->sig, STRING(m->sig_index)) == 0) {
			fi->flags = m->access_flags;
			break;
		}
	}
}

/*
 * mframe instruction for a call to a Loader entry point.
 */

static Inst*
loadermframe(Freloc *frm, Freloc *frf)
{
	Inst *imframe;

	imframe = newi(IMFRAME);
	addrsind(&imframe->s, Amp, 0);
	addrimm(&imframe->m, 0);
	addrsind(&imframe->d, Afp, getreg(DIS_W));
	LTIpatch(frm, imframe, PSRC, PSIND);
	LTIpatch(frf, imframe, PMID, PIMM);

	return imframe;
}

/*
 * mcall instruction for a call to a Loader entry point.
 */

static Inst*
loadermcall(Inst *imframe, Freloc *frf, Freloc *frm)
{
	Inst *imcall;

	imcall = newi(IMCALL);
	imcall->s = imframe->d;
	imcall->m = imframe->m;
	imcall->d = imframe->s;
	LTIpatch(frf, imcall, PMID, PIMM);
	LTIpatch(frm, imcall, PDST, PSIND);

	return imcall;
}

/*
 * Call "rtload" for run-time resolution.
 */

static void
callrtload(RTClass *rtc, char *classname)
{
	Inst *imframe, *i;
	Creloc *cr;
	Freloc *frm, *frf;
	RTReloc *rtr;

	USED(classname);
	rtr = getRTReloc(rtc, RMP, nil, 0);
	cr = getCreloc(RLOADER);
	frm = getFreloc(cr, RMP, nil, 0);
	frf = getFreloc(cr, "rtload", nil, 0);

	i = newi(IBNEW);
	addrsind(&i->s, Amp, 0);
	addrsind(&i->m, Amp, 0);
	addrimm(&i->d, i->pc+4);
	RTIpatch(rtr, i, PSRC, PSIND);

	imframe = loadermframe(frm, frf);

	i = newi(ILEA);
	addrsind(&i->s, Amp, 0);
	addrdind(&i->d, Afpind, imframe->d.u.offset, REGSIZE);
	RTIpatch(rtr, i, PSRC, PSIND);

	loadermcall(imframe, frf, frm);
	relreg(&imframe->d);
}

/*
 * Sign-extend an 8-bit unsigned char (Dis byte) to a 32-bit int.
 */

static void
signextend(Addr *dst)
{
	Inst *i;

	i = newi(ISHLW);
	addrimm(&i->s, 24);
	/*i->m = *dst;*/ /* redundant */
	i->d = *dst;

	i = newi(ISHRW);
	addrimm(&i->s, 24);
	/*i->m = *dst;*/ /* redundant */
	i->d = *dst;
}

/*
 * addw instruction for run-time relocated getstatic & putstatic.
 */

static Addr*
rtstaticadd(FieldInfo *fi, RTClass *rtc)
{
	Inst *i;

	i = newi(IADDW);
	addrdind(&i->s, Ampind, 0, 0);
	addrsind(&i->m, Amp, 0);
	addrsind(&i->d, Afp, getreg(DIS_W));

	RTIpatch(getRTReloc(rtc, RMP, nil, 0), i, PSRC, PDIND1);
	RTIpatch(getRTReloc(rtc, fi->fieldname, fi->sig, Rgetputstatic),
		i, PMID, PSIND);

	return &i->d;
}

/*
 * addw instruction for load-time relocated getstatic & putstatic.
 */

static Addr*
ltstaticadd(FieldInfo *fi)
{
	Inst *i;
	Creloc *cr;

	i = newi(IADDW);
	addrdind(&i->s, Ampind, 0, 0);
	addrimm(&i->m, 0);
	addrsind(&i->d, Afp, getreg(DIS_W));

	cr = getCreloc(fi->classname);
	LTIpatch(getFreloc(cr, RMP, nil, 0), i, PSRC, PDIND1);
	LTIpatch(getFreloc(cr, fi->fieldname, fi->sig, Rgetputstatic),
		i, PMID, PIMM);

	return &i->d;
}

/*
 * Java getstatic.
 */

static void
getstatic(void)
{
	int state;
	Inst *i;
	Addr *a;
	FieldInfo fi;
	RTClass *rtc;

	getfldinfo(&fi);
	state = crefstate(fi.classname, J->bb, 0);
	if(state & LTCODE) {
		a = ltstaticadd(&fi);
	} else {
		rtc = getRTClass(fi.classname);
		if(state & RTCALL)
			callrtload(rtc, fi.classname);
		a = rtstaticadd(&fi, rtc);
	}

	i = newi(movinst(fi.sig[0]));
	i->s = *a;
	sind2dind(&i->s, 0);
	relreg(a);
	dstreg(&J->dst, j2dtype(J->jtype));
	i->d = J->dst;

	if(fi.sig[0] == 'B')
		signextend(&i->d);
}

/*
 * Java putstatic.
 */

static void
putstatic(void)
{
	int state;
	Inst *i;
	Addr *a;
	FieldInfo fi;
	RTClass *rtc;

	getfldinfo(&fi);
	state = crefstate(fi.classname, J->bb, 0);
	if(state & LTCODE) {
		a = ltstaticadd(&fi);
	} else {
		rtc = getRTClass(fi.classname);
		if(state & RTCALL)
			callrtload(rtc, fi.classname);
		a = rtstaticadd(&fi, rtc);
	}

	i = newi(movinst(fi.sig[0]));
	i->s = code->j[J->src[0]].dst;
	relreg(&code->j[J->src[0]].dst);
	i->d = *a;
	sind2dind(&i->d, 0);
	relreg(a);
	datareloc(i);
}

/*
 * addw instruction for run-time relocated getfield & putfield.
 */

static Addr*
rtfieldadd(FieldInfo *fi, RTClass *rtc, Addr *a)
{
	Inst *i;

	i = newi(IADDW);
	i->s = *a;
	addrsind(&i->m, Amp, 0);
	addrsind(&i->d, Afp, getreg(DIS_W));

	RTIpatch(getRTReloc(rtc, fi->fieldname, fi->sig, Rgetputfield),
		i, PMID, PSIND);

	return &i->d;
}

/*
 * Java getfield.
 */

static void
getfield(void)
{
	int state;
	Addr *a;
	Inst *i;
	FieldInfo fi;
	Creloc *cr;
	RTClass *rtc;

	getfldinfo(&fi);
	state = crefstate(fi.classname, J->bb, 0);
	if(state & LTCODE) {
		i = newi(movinst(fi.sig[0]));
		i->s = code->j[J->src[0]].dst;
		sind2dind(&i->s, 0);
		relreg(&code->j[J->src[0]].dst);
		cr = getCreloc(fi.classname);
		LTIpatch(getFreloc(cr, fi.fieldname, fi.sig, Rgetputfield),
			i, PSRC, PDIND2);
	} else {
		rtc = getRTClass(fi.classname);
		if(state & RTCALL)
			callrtload(rtc, fi.classname);
		a = rtfieldadd(&fi, rtc, &code->j[J->src[0]].dst);
		relreg(&code->j[J->src[0]].dst);
		i = newi(movinst(fi.sig[0]));
		i->s = *a;
		sind2dind(&i->s, 0);
		relreg(a);
	}
	dstreg(&J->dst, j2dtype(J->jtype));
	i->d = J->dst;

	if(fi.sig[0] == 'B')
		signextend(&i->d);

}

/*
 * Java putfield.
 */

static void
putfield(void)
{
	int state;
	Addr *a;
	Inst *i;
	FieldInfo fi;
	Creloc *cr;
	RTClass *rtc;

	getfldinfo(&fi);
	state = crefstate(fi.classname, J->bb, 0);
	if(state & LTCODE) {
		i = newi(movinst(fi.sig[0]));
		i->s = code->j[J->src[1]].dst;
		relreg(&code->j[J->src[1]].dst);
		i->d = code->j[J->src[0]].dst;
		relreg(&code->j[J->src[0]].dst);

		cr = getCreloc(fi.classname);
		LTIpatch(getFreloc(cr, fi.fieldname, fi.sig, Rgetputfield),
			i, PDST, PDIND2);
	} else {
		rtc = getRTClass(fi.classname);
		if(state & RTCALL)
			callrtload(rtc, fi.classname);
		a = rtfieldadd(&fi, rtc, &code->j[J->src[0]].dst);
		relreg(&code->j[J->src[0]].dst);

		i = newi(movinst(fi.sig[0]));
		i->s = code->j[J->src[1]].dst;
		relreg(&code->j[J->src[1]].dst);
		i->d = *a;
		relreg(a);
	}
	sind2dind(&i->d, 0);
	datareloc(i);
}

/*
 * Push function arguments.
 */

static void
pushargs(int calltype, int calleeframe, char *sig)
{
	Inst *i;
	int frameoff;
	int arg, size;

	frameoff = REGSIZE;
	arg = 0;
	if(calltype != Rinvokestatic) {
		i = newi(IMOVP);		/* this pointer */
		i->s = code->j[J->src[arg]].dst;
		addrdind(&i->d, Afpind, calleeframe, frameoff);
		frameoff += IBY2WD;
		arg++;
	}

	sig++;	/* skip '(' */
	while(sig[0] != ')') {
		i = newi(movinst(sig[0]));
		i->s = code->j[J->src[arg]].dst;
		size = cellsize[j2dtype(sig[0])];
		frameoff = align(frameoff, size);
		addrdind(&i->d, Afpind, calleeframe, frameoff);
		datareloc(i);
		frameoff += size;
		sig = nextjavatype(sig);
		arg++;
	}

	/* return value */
	if(sig[1] != 'V') {	/* skip ')' */
		i = newi(ILEA);
		dstreg(&J->dst, j2dtype(J->jtype));
		i->s = J->dst;
		addrdind(&i->d, Afpind, calleeframe, REGRET*IBY2WD);
	}
}

/*
 * Run-time relocated invokespecial and invokestatic.
 */

static void
rtinvokess(FieldInfo *fi, int calltype, int mpflag, int state)
{
	int n;
	Inst *imframe, *imcall;
	RTClass *rtc;
	RTReloc *rtr1, *rtr2;

	rtc = getRTClass(fi->classname);
	if(state & RTCALL)
		callrtload(rtc, fi->classname);

	imframe = newi(IMFRAME);
	addrsind(&imframe->s, Amp, 0);
	addrsind(&imframe->m, Amp, 0);
	addrsind(&imframe->d, Afp, getreg(DIS_W));

	rtr1 = getRTReloc(rtc, fi->fieldname, fi->sig, calltype|mpflag);
	rtr2 = getRTReloc(rtc, fi->fieldname, fi->sig, calltype);
	RTIpatch(rtr1, imframe, PSRC, PSIND);
	RTIpatch(rtr2, imframe, PMID, PSIND);

	/* push arguments into callee's frame, handle return type */
	pushargs(calltype, imframe->d.u.offset, fi->sig);

	imcall = newi(IMCALL);
	imcall->s = imframe->d;
	imcall->m = imframe->m;
	imcall->d = imframe->s;

	RTIpatch(rtr1, imcall, PDST, PSIND);
	RTIpatch(rtr2, imcall, PMID, PSIND);

	for(n = 0; n < J->nsrc; n++)
		relreg(&code->j[J->src[n]].dst);
	relreg(&imframe->d);
}

/*
 * Load-time relocated invokespecial and invokestatic.
 */

static void
invokess(int calltype, int mpflag)
{
	int n, state;
	Inst *imframe, *imcall;
	Creloc *cr;
	Freloc *frf, *frm;
	FieldInfo fi;

	frf = nil;
	getfldinfo(&fi);
	state = crefstate(fi.classname, J->bb, 0);
	if(state & RTCODE) {
		rtinvokess(&fi, calltype, mpflag, state);
		return;
	}
	cr = getCreloc(fi.classname);
	/* fi.flags set only if fi.classname == this_class */
	if(fi.flags & (ACC_PRIVATE | ACC_STATIC)) {
		if(fi.flags & ACC_NATIVE)
			frm = getFreloc(cr, RNP, nil, 0);
		else
			frm = nil;	/* frame/call */
	} else {
		/* force @mp, @np into the list for cr */
		getFreloc(cr, RMP, nil, 0);
		getFreloc(cr, RNP, nil, 0);
		frm = getFreloc(cr, fi.fieldname, fi.sig, calltype|mpflag);
	}

	if(frm == nil) {
		imframe = newi(IFRAME);
		addrimm(&imframe->s, 0);
	} else {
		imframe = newi(IMFRAME);
		addrsind(&imframe->s, Amp, 0);
		addrimm(&imframe->m, 0);
		LTIpatch(frm, imframe, PSRC, PSIND);
		frf = getFreloc(cr, fi.fieldname, fi.sig, calltype);
		LTIpatch(frf, imframe, PMID, PIMM);
	}
	addrsind(&imframe->d, Afp, getreg(DIS_W));

	/* push arguments into callee's frame, handle return type */
	pushargs(calltype, imframe->d.u.offset, fi.sig);

	if(frm == nil) {
		imcall = newi(ICALL);
		addfcpatch(imframe, imcall, fi.fieldname, fi.sig);
	} else {
		imcall = newi(IMCALL);
		imcall->m = imframe->m;
		LTIpatch(frf, imcall, PMID, PIMM);
		LTIpatch(frm, imcall, PDST, PSIND);
	}
	imcall->s = imframe->d;
	imcall->d = imframe->s;

	for(n = 0; n < J->nsrc; n++)
		relreg(&code->j[J->src[n]].dst);
	relreg(&imframe->d);
}

/*
 * Load-time relocated invokeinterface.
 * Resolve all interfaces at load-time.
 */

static void
invokei(void)
{
	int n;
	Creloc *cr;
	Freloc *frm, *frf, *frfi;
	FieldInfo fi;
	/*
	 * call Loader->getinterface() with these
	 */
	Inst *imframe1, *imovw1, *imovp, *imovw2, *ilea, *imcall1;
	/*
	 * call interface method with these
	 */
	Inst *iaddw, *imovw3, *imframe2, *imcall2;

	cr = getCreloc(RLOADER);
	frm = getFreloc(cr, RMP, nil, 0);
	frf = getFreloc(cr, "getinterface", nil, 0);

	/* call Loader->getinterface */

	imframe1 = loadermframe(frm, frf);

	imovw1 = newi(IMOVW);
	imovw1->s = code->j[J->src[0]].dst;	/* this pointer */
	sind2dind(&imovw1->s, 0);
	addrsind(&imovw1->d, Afp, getreg(DIS_W));

	imovp = newi(IMOVP);
	imovp->s = imovw1->d;
	sind2dind(&imovp->s, 4);
	addrdind(&imovp->d, Afpind, imframe1->d.u.offset, REGSIZE);

	imovw2 = newi(IMOVW);
	addrimm(&imovw2->s, 0);
	addrdind(&imovw2->d, Afpind, imframe1->d.u.offset, REGSIZE+IBY2WD);

	getfldinfo(&fi);
	frfi = getFreloc(getCreloc(fi.classname), fi.fieldname,
		fi.sig, Rinvokeinterface);
	LTIpatch(frfi, imovw2, PSRC, PIMM);

	ilea = newi(ILEA);
	addrsind(&ilea->s, Afp, getreg(DIS_W));
	addrdind(&ilea->d, Afpind, imframe1->d.u.offset, REGRET*IBY2WD);

	imcall1 = loadermcall(imframe1, frf, frm);
	USED(imcall1);

	/* call interface method */

	iaddw = newi(IADDW);
	iaddw->s = imovw1->d;
	iaddw->m = ilea->s;
	iaddw->d = imovw1->d;

	imovw3 = newi(IMOVW);
	imovw3->s = iaddw->d;
	sind2dind(&imovw3->s, 4);
	imovw3->d = ilea->s;

	imframe2 = newi(IMFRAME);
	imframe2->s = iaddw->d;
	sind2dind(&imframe2->s, 0);
	imframe2->m = imovw3->d;
	imframe2->d = imframe1->d;

	/* push arguments into callee's frame, handle return type */
	pushargs(Rinvokeinterface, imframe2->d.u.offset, fi.sig);

	imcall2 = newi(IMCALL);
	imcall2->s = imframe2->d;
	imcall2->m = imframe2->m;
	imcall2->d = imframe2->s;

	for(n = 0; n < J->nsrc; n++)
		relreg(&code->j[J->src[n]].dst);
	relreg(&imframe1->d);
	relreg(&imovw1->d);
	relreg(&ilea->s);
}

/*
 * Run-time relocated invokevirtual.
 */

static void
rtinvokev(FieldInfo *fi, int state)
{
	int n;
	Inst *iaddw, *imovw1, *imovw2, *imframe, *imcall;
	RTClass *rtc;

	rtc = getRTClass(fi->classname);
	if(state & RTCALL)
		callrtload(rtc, fi->classname);

	imovw1 = newi(IMOVW);
	imovw1->s = code->j[J->src[0]].dst;	/* this pointer */
	sind2dind(&imovw1->s, 0);
	addrsind(&imovw1->d, Afp, getreg(DIS_W));

	iaddw = newi(IADDW);
	iaddw->s = imovw1->d;
	addrsind(&iaddw->m, Amp, 0);
	iaddw->d = imovw1->d;

	RTIpatch(getRTReloc(rtc, fi->fieldname, fi->sig, Rinvokevirtual),
		iaddw, PMID, PSIND);

	imovw2 = newi(IMOVW);
	imovw2->s = iaddw->d;
	sind2dind(&imovw2->s, 4);
	addrsind(&imovw2->d, Afp, getreg(DIS_W));

	imframe = newi(IMFRAME);
	imframe->s = imovw1->d;
	sind2dind(&imframe->s, 0);
	imframe->m = imovw2->d;
	addrsind(&imframe->d, Afp, getreg(DIS_W));

	/* push arguments into callee's frame, handle return type */
	pushargs(Rinvokevirtual, imframe->d.u.offset, fi->sig);

	imcall = newi(IMCALL);
	imcall->s = imframe->d;
	imcall->m = imframe->m;
	imcall->d = imframe->s;

	for(n = 0; n < J->nsrc; n++)
		relreg(&code->j[J->src[n]].dst);
	relreg(&imovw1->d);
	relreg(&imovw2->d);
	relreg(&imframe->d);
}

/*
 * Load-time relocated invokevirtual.
 */

static void
invokev(void)
{
	int n, state;
	Inst *imovw1, *imovw2, *imframe, *imcall;
	Creloc *cr;
	Freloc *fr;
	FieldInfo fi;

	getfldinfo(&fi);
	state = crefstate(fi.classname, J->bb, 0);
	if(state & RTCODE) {
		rtinvokev(&fi, state);
		return;
	}
	cr = getCreloc(fi.classname);
	fr = getFreloc(cr, fi.fieldname, fi.sig, Rinvokevirtual);

	imovw1 = newi(IMOVW);
	imovw1->s = code->j[J->src[0]].dst;	/* this pointer */
	sind2dind(&imovw1->s, 0);
	addrsind(&imovw1->d, Afp, getreg(DIS_W));

	imovw2 = newi(IMOVW);
	imovw2->s = imovw1->d;
	sind2dind(&imovw2->s, 4);
	addrsind(&imovw2->d, Afp, getreg(DIS_W));
	LTIpatch(fr, imovw2, PSRC, PDIND2);

	imframe = newi(IMFRAME);
	imframe->s = imovw1->d;
	sind2dind(&imframe->s, 0);
	imframe->m = imovw2->d;
	addrsind(&imframe->d, Afp, getreg(DIS_W));
	LTIpatch(fr, imframe, PSRC, PDIND2);

	/* push arguments into callee's frame, handle return type */
	pushargs(Rinvokevirtual, imframe->d.u.offset, fi.sig);

	imcall = newi(IMCALL);
	imcall->s = imframe->d;
	imcall->m = imframe->m;
	imcall->d = imframe->s;
	LTIpatch(fr, imcall, PDST, PDIND2);

	for(n = 0; n < J->nsrc; n++)
		relreg(&code->j[J->src[n]].dst);
	relreg(&imovw1->d);
	relreg(&imovw2->d);
	relreg(&imframe->d);
}

/*
 * Run-time relocated new.
 */

static void
rtnew(FieldInfo *fi, int state)
{
	Inst *i1, *i2;
	RTClass *rtc;
	RTReloc *rtr;

	rtc = getRTClass(fi->classname);
	if(state & RTCALL)
		callrtload(rtc, fi->classname);

	i1 = newi(IMNEWZ);
	addrsind(&i1->s, Amp, 0);
	addrsind(&i1->m, Amp, 0);
	dstreg(&J->dst, DIS_P);
	i1->d = J->dst;

	rtr = getRTReloc(rtc, RCLASS, nil, 0);
	RTIpatch(rtr, i1, PMID, PSIND);
	rtr = getRTReloc(rtc, RMP, nil, 0);
	RTIpatch(rtr, i1, PSRC, PSIND);

	i2 = newi(IMOVP);
	addrdind(&i2->s, Ampind, 0, 0);
	i2->d = i1->d;
	sind2dind(&i2->d, 0);

	RTIpatch(rtr, i2, PSRC, PDIND1);
}

/*
 * Load-time relocated new.
 */

static void
xjavanew(char *name, Addr *a)
{
	int state;
	Inst *i1, *i2;
	Creloc *cr;
	Freloc *frc, *frm;
	FieldInfo fi;

	if(J) {	/* kludge: J == nil when called from clinitinits() */
		state = crefstate(name, J->bb, 0);
		if(state & RTCODE) {
			fi.classname = name;
			rtnew(&fi, state);
			return;
		}
	}

	cr = getCreloc(name);
	frc = getFreloc(cr, RCLASS, nil, 0);
	frm = getFreloc(cr, RMP, nil, 0);

	if(strcmp(name, THISCLASS) == 0) {
		i1 = newi(INEWZ);
		addrimm(&i1->s, 0);
		LTIpatch(frc, i1, PSRC, PIMM);
	} else {
		i1 = newi(IMNEWZ);
		addrsind(&i1->s, Amp, 0);
		LTIpatch(frm, i1, PSRC, PSIND);
		addrimm(&i1->m, 0);
		LTIpatch(frc, i1, PMID, PIMM);
	}
	dstreg(a, DIS_P);
	i1->d = *a;

	i2 = newi(IMOVP);
	addrdind(&i2->s, Ampind, 0, 0);
	LTIpatch(frm, i2, PSRC, PDIND1);
	i2->d = i1->d;
	sind2dind(&i2->d, 0);
}

/*
 * Java newarray
 */

static void
newarray(void)
{
	Inst *i;
	int n, tid;

	switch(J->u.i) {
	case T_BOOLEAN:
	case T_BYTE:
		n = 1;
		break;
	case T_CHAR:
	case T_SHORT:
	case T_INT:
		n = IBY2WD;
		break;
	case T_LONG:
	case T_FLOAT:
	case T_DOUBLE:
		n = IBY2LG;
		break;
	default:
		verifyerrormess("newarray data type");
		return;
	}
	if(n == 1)
		tid = descid(n, 0, (uchar*)"");
	else
		tid = descid(n, 1, (uchar*)"\0");

	xjavanew("inferno/vm/Array", &J->dst);
	i = newi(INEWAZ);
	i->s = code->j[J->src[0]].dst;
	relreg(&code->j[J->src[0]].dst);
	addrimm(&i->m, tid);
	i->d = J->dst;
	sind2dind(&i->d, ARY_DATA);
	datareloc(i);

	i = newi(IMOVW);
	addrimm(&i->s, 1);
	i->d = J->dst;
	sind2dind(&i->d, ARY_NDIM);

	i = newi(IMOVW);
	addrimm(&i->s, J->u.i);
	i->d = J->dst;
	sind2dind(&i->d, ARY_ETYPE);
}

typedef	struct	ArrayInfo	ArrayInfo;

struct ArrayInfo {
	int	ndim;		/* number of dimensions */
	int	etype;		/* element type code (if primitive) */
	char	*ename;		/* element type name (if non-primitive) */
};

/*
 * Glean array information.  s may name a Class, Interface, or Array type.
 * Used by xanewarray, xmultianewarray, checkcast, instanceof.
 */

static void
getaryinfo(ArrayInfo *ai, char *s)
{
	int n;

	ai->ndim = 0;
	ai->etype = 0;
	ai->ename = nil;

	while(s[0] == '[') {
		ai->ndim++;
		s++;
	}

	if(ai->ndim > 0) {
		switch(s[0]) {
		case 'Z':
			ai->etype = T_BOOLEAN;
			break;
		case 'B':
			ai->etype = T_BYTE;
			break;
		case 'C':
			ai->etype = T_CHAR;
			break;
		case 'S':
			ai->etype = T_SHORT;
			break;
		case 'I':
			ai->etype = T_INT;
			break;
		case 'F':
			ai->etype = T_FLOAT;
			break;
		case 'J':
			ai->etype = T_LONG;
			break;
		case 'D':
			ai->etype = T_DOUBLE;
			break;
		case 'L':
			/* ai->etype = 0; */	/* above */
			break;
		}
	}
	if(ai->etype == 0) {
		n = strlen(s) + 1;
		if(ai->ndim > 0) {	/* e.g., s == "LX.Y.Z;" */
			s++;
			n -= 2;
		}
		ai->ename = Malloc(n);
		strncpy(ai->ename, s, n-1);
		ai->ename[n-1] = '\0';
	}
}

/*
 * Java anewarray
 */

static void
xanewarray(void)
{
	Inst *i;
	int state;
	RTClass *rtc;
	ArrayInfo ai;

	SET(state);
	SET(rtc);
	getaryinfo(&ai, CLASSNAME(J->u.i));
	if(ai.etype == 0) {
		state = crefstate(ai.ename, J->bb, 0);
		if(state & RTCODE) {
			rtc = getRTClass(ai.ename);
			if(state & RTCALL)
				callrtload(rtc, ai.ename);
		}
	}

	xjavanew("inferno/vm/Array", &J->dst);
	i = newi(INEWA);
	i->s = code->j[J->src[0]].dst;
	relreg(&code->j[J->src[0]].dst);
	addrimm(&i->m, descid(IBY2WD, 1, (uchar*)"\x80"));
	i->d = J->dst;
	sind2dind(&i->d, ARY_DATA);
	datareloc(i);

	i = newi(IMOVW);
	addrimm(&i->s, ai.ndim+1);
	i->d = J->dst;
	sind2dind(&i->d, ARY_NDIM);

	if(ai.etype == 0) {
		i = newi(IMOVP);
		addrsind(&i->s, Amp, 0);
		if(state & RTCODE) {
			RTIpatch(getRTReloc(rtc, RADT, nil, 0), i, PSRC, PSIND);
		} else {
			LTIpatch(getFreloc(getCreloc(ai.ename), RADT, nil, 0),
				i, PSRC, PSIND);
		}
		i->d = J->dst;
		sind2dind(&i->d, ARY_ADT);
	} else {
		i = newi(IMOVW);
		addrimm(&i->s, ai.etype);
		i->d = J->dst;
		sind2dind(&i->d, ARY_ETYPE);
	}
}

/*
 * Java multianewarray
 */

static void
xmultianewarray(void)
{
	Inst *imframe, *iindw, *i;
	int n, state;
	RTClass *rtc;
	Creloc *cr;
	Freloc *frm, *frf;
	ArrayInfo ai;

	SET(state);
	SET(rtc);
	getaryinfo(&ai, CLASSNAME(J->u.x2d.ix));
	if(ai.etype == 0) {
		state = crefstate(ai.ename, J->bb, 0);
		if(state & RTCODE) {
			rtc = getRTClass(ai.ename);
			if(state & RTCALL)
				callrtload(rtc, ai.ename);
		}
	}

	cr = getCreloc(RLOADER);
	frm = getFreloc(cr, RMP, nil, 0);
	frf = getFreloc(cr, "multianewarray", nil, 0);

	imframe = loadermframe(frm, frf);

	/* 1st arg: number of dimensions */

	i = newi(IMOVW);
	addrimm(&i->s, ai.ndim);
	addrdind(&i->d, Afpind, imframe->d.u.offset, REGSIZE);

	/* 2nd arg: @adt reloc if ref element type, nil otherwise */

	i = newi(IMOVP);
	addrsind(&i->s, Amp, 0);
	if(ai.etype == 0) {
		if(state & RTCODE) {
			RTIpatch(getRTReloc(rtc, RADT, nil, 0), i, PSRC, PSIND);
		} else {
			LTIpatch(getFreloc(getCreloc(ai.ename), RADT, nil, 0),
				i, PSRC, PSIND);
		}
	}
	addrdind(&i->d, Afpind, imframe->d.u.offset, REGSIZE+IBY2WD);

	/* 3rd arg: element type */

	i = newi(IMOVW);
	addrimm(&i->s, ai.etype);
	addrdind(&i->d, Afpind, imframe->d.u.offset, REGSIZE+2*IBY2WD);

	/* 4th arg: array of dimensionality information */

	i = newi(INEWA);
	addrimm(&i->s, J->u.x2d.dim);
	addrimm(&i->m, descid(IBY2WD, 1, (uchar*)"\0"));
	addrdind(&i->d, Afpind, imframe->d.u.offset, REGSIZE+3*IBY2WD);

	iindw = newi(IINDW);
	addrdind(&iindw->s, Afpind, imframe->d.u.offset, REGSIZE+3*IBY2WD);
	addrsind(&iindw->m, Afp, getreg(DIS_W));
	addrimm(&iindw->d, 0);

	for(n = 0; n < J->u.x2d.dim; n++) {
		i = newi(IMOVW);
		i->s = code->j[J->src[n]].dst;
		relreg(&code->j[J->src[n]].dst);
		i->d = iindw->m;
		sind2dind(&i->d, n*IBY2WD);
	}
	relreg(&iindw->m);

	i = newi(ILEA);
	dstreg(&J->dst, DIS_P);
	i->s = J->dst;
	addrdind(&i->d, Afpind, imframe->d.u.offset, REGRET*IBY2WD);

	loadermcall(imframe, frf, frm);
	relreg(&imframe->d);
}

static void
arraylength(void)
{
	Inst *i;

	i = newi(ILENA);
	i->s = code->j[J->src[0]].dst;
	relreg(&code->j[J->src[0]].dst);
	sind2dind(&i->s, ARY_DATA);
	dstreg(&J->dst, DIS_W);
	i->d = J->dst;
}

static Addr*
arrayindex(uchar index)
{
	Inst *i;

	i = newi(index);
	i->s = code->j[J->src[0]].dst;
	relreg(&code->j[J->src[0]].dst);
	sind2dind(&i->s, ARY_DATA);
	i->d = code->j[J->src[1]].dst;
	relreg(&code->j[J->src[1]].dst);
	addrsind(&i->m, Afp, getreg(DIS_W));

	return &i->m;
}

/*
 * Load an array element.
 */

static void
xarrayload(uchar inst1, uchar inst2, uchar dtype)
{
	Addr *a;
	Inst *i;

	a = arrayindex(inst1);
	i = newi(inst2);
	i->s = *a;
	sind2dind(&i->s, 0);
	relreg(a);
	dstreg(&J->dst, dtype);
	i->d = J->dst;
	if(inst2 == ICVTBW)	/* loading from a byte array */
		signextend(&i->d);
}

/*
 * Call Loader->aastorecheck() to do runtime checks for aastore.
 */

static void
aastore(void)
{
	Inst *imframe, *imovp, *imcall;
	Creloc *cr;
	Freloc *frm, *frf;

	cr = getCreloc(RLOADER);
	frm = getFreloc(cr, RMP, nil, 0);
	frf = getFreloc(cr, "aastorecheck", nil, 0);

	imframe = loadermframe(frm, frf);

	imovp = newi(IMOVP);
	imovp->s = code->j[J->src[2]].dst;
	addrdind(&imovp->d, Afpind, imframe->d.u.offset, REGSIZE);

	imovp = newi(IMOVP);
	imovp->s = code->j[J->src[0]].dst;
	addrdind(&imovp->d, Afpind, imframe->d.u.offset, REGSIZE+IBY2WD);

	imcall = loadermcall(imframe, frf, frm);
	USED(imcall);
	relreg(&imframe->d);
}

/*
 * Store an array element.
 */

static void
xarraystore(uchar inst1, uchar inst2)
{
	Addr *a;
	Inst *i;

	a = arrayindex(inst1);
	i = newi(inst2);
	i->s = code->j[J->src[2]].dst;
	relreg(&code->j[J->src[2]].dst);
	i->d = *a;
	sind2dind(&i->d, 0);
	relreg(a);
	datareloc(i);
}

/*
 * monitorenter, monitorexit, athrow.  Also used for synchronized methods.
 */

static void
mon_or_throw(uchar op, int flags, int syncblock)
{
	char *loaderfn;
	Inst *imframe, *i;
	Creloc *cr;
	Freloc *frm, *frf, *fro;

	switch(op) {
	case Jathrow:
		loaderfn = "throw";
		break;
	case Jmonitorenter:
		loaderfn = "monitorenter";
		break;
	case Jmonitorexit:
		loaderfn = "monitorexit";
		break;
	default:
		verifyerrormess("bad monitor/throw op");
		return;
	}

	cr = getCreloc(RLOADER);
	frm = getFreloc(cr, RMP, nil, 0);
	frf = getFreloc(cr, loaderfn, nil, 0);

	imframe = loadermframe(frm, frf);

	i = newi(IMOVP);
	if(op == Jathrow || syncblock) {	/* throw or synchronized block */
		i->s = code->j[J->src[0]].dst;
		relreg(&code->j[J->src[0]].dst);
	} else if(flags & ACC_STATIC) {		/* synchronized class method */
		addrsind(&i->s, Amp, 0);
		fro = getFreloc(getCreloc(THISCLASS), ROBJ, nil, 0);
		LTIpatch(fro, i, PSRC, PSIND);
	} else					/* synchronized instance method */
		addrsind(&i->s, Afp, THISOFF);
	addrdind(&i->d, Afpind, imframe->d.u.offset, REGSIZE);

	loadermcall(imframe, frf, frm);
	relreg(&imframe->d);

	/* for jit: so mcall has an instruction for its return address */
	if(op == Jathrow && J->pc+1 == code->code_length) {
		i = newi(IJMP);
		addrimm(&i->d, 0);
	}
}

static void
xjavaload(uchar op)
{
	Inst *i;

	if(J->movsrc.mode != Anone) {	/* marked for explicit mov */
		i = newi(op);
		i->s = J->movsrc;
		dstreg(&J->dst, j2dtype(J->jtype));
		i->d = J->dst;
		datareloc(i);
	}
}

static void
xjavastore(uchar op)
{
	Inst *i;

	if(op == IMOVP && J->bb->js == J && (J->bb->flags & BB_FINALLY))
		; /* astore instruction at the start of a finally block */
	else if(J->dst.mode != Anone) {	/* marked for explicit mov */
		i = newi(op);
		i->s = code->j[J->src[0]].dst;
		relreg(&code->j[J->src[0]].dst);
		i->d = J->dst;
		datareloc(i);
	}
}

/*
 * Check immediate middle operands that are too big.
 */

static void
midcheck(Addr *a)
{
	if(a->mode == Aimm && (a->u.ival > 0x7fff || a->u.ival < -0x8000)) {
		a->mode = Amp;
		a->u.offset = mpint(a->u.ival);
	}
}

/*
 * Coerce a 64-bit real to a 32-bit real (and back).
 */

static void
real64to32(Addr *a)
{
	Inst *i1, *i2;

	i1 = newi(ICVTFR);
	i1->s = *a;
	addrsind(&i1->d, Afp, getreg(DIS_W));

	i2 = newi(ICVTRF);
	i2->s = i1->d;
	i2->d = i1->s;

	relreg(&i1->d);
}

static void
xbinop(uchar op, uchar dtype, int cvtreal)
{
	Inst *i;

	i = newi(op);
	i->s = code->j[J->src[1]].dst;
	relreg(&code->j[J->src[1]].dst);
	i->m = code->j[J->src[0]].dst;
	relreg(&code->j[J->src[0]].dst);
	midcheck(&i->m);
	dstreg(&J->dst, dtype);
	i->d = J->dst;
	middstcmp(i);
	datareloc(i);

	if(cvtreal)
		real64to32(&i->d);
}

static void
shift(uchar op, uchar dtype)
{
	Inst *iaddw, *i;

	iaddw = newi(IANDW);
	iaddw->s = code->j[J->src[1]].dst;
	relreg(&code->j[J->src[1]].dst);
	if(dtype == DIS_W)	/* ishl, ishr, iushr */
		addrimm(&iaddw->m, 31);
	else			/* lshl, lshr, lushr */
		addrimm(&iaddw->m, 63);
	addrsind(&iaddw->d, Afp, getreg(DIS_W));
	datareloc(iaddw);

	i = newi(op);
	i->s = iaddw->d;
	relreg(&iaddw->d);
	i->m = code->j[J->src[0]].dst;
	relreg(&code->j[J->src[0]].dst);
	midcheck(&i->m);
	dstreg(&J->dst, dtype);
	i->d = J->dst;
	middstcmp(i);
	datareloc(i);
}

static void
cvt(uchar op, uchar dtype, int cvtreal)
{
	Inst *i;

	i = newi(op);
	i->s = code->j[J->src[0]].dst;
	relreg(&code->j[J->src[0]].dst);
	dstreg(&J->dst, dtype);
	i->d = J->dst;
	datareloc(i);

	if(cvtreal)
		real64to32(&i->d);
}

static void
i2c(void)
{
	Inst *i;

	i = newi(IANDW);
	i->s = code->j[J->src[0]].dst;
	relreg(&code->j[J->src[0]].dst);
	addrsind(&i->m, Amp, mpint(0xffff));
	dstreg(&J->dst, DIS_W);
	i->d = J->dst;
	datareloc(i);
}

/*
 * i2b, i2s.
 */

static void
i2bs(int shift)
{
	Inst *i1, *i2;

	i1 = newi(ISHLW);
	addrimm(&i1->s, shift);
	i1->m = code->j[J->src[0]].dst;
	relreg(&code->j[J->src[0]].dst);
	midcheck(&i1->m);
	dstreg(&J->dst, DIS_W);
	i1->d = J->dst;
	middstcmp(i1);
	datareloc(i1);

	i2 = newi(ISHRW);
	addrimm(&i2->s, shift);
	/* i2->m = i1->d; */ /* redundant */
	i2->d = i1->d;
}

/*
 * ineg, lneg, fneg, dneg
 */

static void
neg(uchar op, uchar dtype)
{
	Inst *i;

	i = newi(op);
	i->s = code->j[J->src[0]].dst;
	relreg(&code->j[J->src[0]].dst);
	if(op == ISUBW)		/* ineg */
		addrimm(&i->m, 0);
	else if(op == ISUBL)	/* lneg */
		addrsind(&i->m, Amp, mplong(0));
	dstreg(&J->dst, dtype);
	i->d = J->dst;
	datareloc(i);
}

static void
iinc(int val, int ix)
{
	Inst *i;

	i = newi(IADDW);
	addrimm(&i->s, val);
	addrsind(&i->d, Afp, localix(DIS_W, ix));
}

/*
 * For javaif and javagoto, compute difference of try nesting
 * level between source PC and destination PC.
 *   J->pc is source PC
 *   J->u.i is destination PC (relative from J->pc)
 */

static int
tldiff(void)
{
	int tls, tld;

	tld = 0;
	tls = trylevel(J->pc);
	if(tls > 0)
		tld = trylevel(J->pc+J->u.i);
	return tls-tld;
}

/*
 * Java if_acmp<cond>, if_icmp<cond>, if<cond>, ifnonnull, ifnull.
 */

enum {
	CMPNULL = 0,	/* compare against null: ifnonnull, ifnull */
	CMPZERO,	/* compare against 0: if<cond> */
	CMP2OP		/* general compare: if_acmp<cond>, if_icmp<cond> */
};

static void
javaif(uchar op, uchar cmpkind)
{
	Inst *i;
	int n;

	n = tldiff();
	if(n > 0) {
		/* complement the test when calling Sys->unrescue() */
		switch(op) {
		case IBEQW:
			op = IBNEW;
			break;
		case IBNEW:
			op = IBEQW;
			break;
		case IBLTW:
			op = IBGEW;
			break;
		case IBLEW:
			op = IBGTW;
			break;
		case IBGTW:
			op = IBLEW;
			break;
		case IBGEW:
			op = IBLTW;
			break;
		}
		i = newi(op);
		addrimm(&i->d, pcdis + 2*n + 1);
	} else {
		i = newibap(op);
		addrimm(&i->d, J->u.i);
	}

	i->s = code->j[J->src[0]].dst;
	relreg(&code->j[J->src[0]].dst);

	switch(cmpkind) {
	case CMPNULL:
		addrsind(&i->m, Amp, 0);
		break;
	case CMPZERO:
		addrimm(&i->m, 0);
		datareloc(i);
		break;
	case CMP2OP:
		i->m = code->j[J->src[1]].dst;
		relreg(&code->j[J->src[1]].dst);
		midcheck(&i->m);
		datareloc(i);
		break;
	}

	if(n > 0) {
		unrescue(n);
		callunrescue = 0;
		i = newibap(IJMP);
		addrimm(&i->d, J->u.i);
	}
}

/*
 * Java goto and goto_w.
 */

static void
javagoto(void)
{
	Inst *i;
	int n;

	n = tldiff();
	if(n > 0) {
		unrescue(n);
		callunrescue = 0;
	}
	i = newibap(IJMP);
	addrimm(&i->d, J->u.i);
}

/*
 * Java return instructions.
 */

static void
xjavareturn(uchar op)
{
	Inst *i;

	if(op != 0) {		/* if op == 0, then return void */
		i = newi(op);
		i->s = code->j[J->src[0]].dst;
		relreg(&code->j[J->src[0]].dst);
		addrdind(&i->d, Afpind, REGRET*IBY2WD, 0);
		datareloc(i);
	}

	if(M->access_flags & ACC_SYNCHRONIZED)
		mon_or_throw(Jmonitorexit, M->access_flags, 0);

	newi(IRET);
}

/*
 * pop & pop2
 */

static void
xjavapop(void)
{
	relreg(&code->j[J->src[0]].dst);
	if(J->nsrc == 2)	/* pop2 */
		relreg(&code->j[J->src[1]].dst);
}

/*
 * dup, dup2, etc.
 */

static void
xjavadup(void)
{
	acqreg(&code->j[J->src[0]].dst);
	if(J->nsrc == 2)
		acqreg(&code->j[J->src[1]].dst);
}

static void
xldc(void)
{
	Inst *i;

	switch(class->cts[J->u.i]) {
	case CON_Integer:
		xjavaload(IMOVW);
		break;
	case CON_Float:
	case CON_Double:
		xjavaload(IMOVF);
		break;
	case CON_Long:
		xjavaload(IMOVL);
		break;
	case CON_String:
		xjavanew("java/lang/String", &J->dst);
		i = newi(IMOVP);
		i->s = J->movsrc;
		i->d = J->dst;
		sind2dind(&i->d, STR_DISSTR);
		addDreloc(i, PSRC, PSIND);
		break;
	}
}

/*
 * Java jsr and jsr_w.
 * ix is relative Java pc offset of finally block entry point.
 */

static void
jsr(int ix)
{
	Inst *i;

	i = newi(IMOVW);
	addrimm(&i->s, 0);
	addrsind(&i->d, Amp, 0);
	jsrfixup(&i->s, &i->d, i->pc+2, J->pc+ix);
	addDreloc(i, PDST, PSIND);

	i = newibap(IJMP);
	addrimm(&i->d, ix);
}

/*
 * Java ret and wide ret.
 */

static void
ret(void)
{
	Inst *i;

	i = newi(IGOTO);
	addrsind(&i->s, Amp, 0);
	addrsind(&i->d, Amp, 0);
	retfixup(&i->s, &i->d, J->pc);
	addDreloc(i, PSRC, PSIND);
	addDreloc(i, PDST, PSIND);
}

static void
tableswitch(void)
{
	Inst *i;
	int j, k, n, lb;
	int *jt;

	n = J->u.t1.hb - J->u.t1.lb + 1;
	jt = Malloc((n*3+1)*sizeof(int));
	for(j = 0, k = 0, lb = J->u.t1.lb; j < n; j++) {
		jt[k++] = lb;
		jt[k++] = ++lb;
		jt[k++] = J->u.t1.tbl[j];
	}
	jt[k] = J->u.t1.dflt;
	i = newi(ICASE);
	i->s = code->j[J->src[0]].dst;
	relreg(&code->j[J->src[0]].dst);
	addrsind(&i->d, Amp, mpcase(n, jt));
	patchcase(i, n, jt);
	addDreloc(i, PDST, PSIND);
}

static void
lookupswitch(void)
{
	Inst *i;
	int j, k;
	int *jt;

	jt = Malloc((J->u.t2.np*3+1)*sizeof(int));
	for(j = 0, k = 0; j < J->u.t2.np*2; j += 2) {
		jt[k++] = J->u.t2.tbl[j];
		jt[k++] = J->u.t2.tbl[j]+1;
		jt[k++] = J->u.t2.tbl[j+1];
	}
	jt[k] = J->u.t2.dflt;
	i = newi(ICASE);
	i->s = code->j[J->src[0]].dst;
	relreg(&code->j[J->src[0]].dst);
	addrsind(&i->d, Amp, mpcase(J->u.t2.np, jt));
	patchcase(i, J->u.t2.np, jt);
	addDreloc(i, PDST, PSIND);
}

/*
 * Call a library routine.  Supports lcmp, [df]cmp[gl], [df]rem.
 */

static void
jmath(char *jname, uchar movinst, uchar dtype)
{
	Inst *imframe, *i;
	Creloc *cr;
	Freloc *frm, *frf;

	cr = getCreloc(RLOADER);
	frm = getFreloc(cr, RMP, nil, 0);
	frf = getFreloc(cr, jname, nil, 0);

	imframe = loadermframe(frm, frf);

	i = newi(movinst);
	i->s = code->j[J->src[0]].dst;
	relreg(&code->j[J->src[0]].dst);
	addrdind(&i->d, Afpind, imframe->d.u.offset, REGSIZE);
	datareloc(i);

	if(jname[1] != '2') {	/* d2i or d2l ? */
		i = newi(movinst);
		i->s = code->j[J->src[1]].dst;
		relreg(&code->j[J->src[1]].dst);
		addrdind(&i->d, Afpind, imframe->d.u.offset, REGSIZE+IBY2LG);
		datareloc(i);
	}

	i = newi(ILEA);
	dstreg(&J->dst, dtype);
	i->s = J->dst;
	addrdind(&i->d, Afpind, imframe->d.u.offset, REGRET*IBY2WD);

	loadermcall(imframe, frf, frm);
	relreg(&imframe->d);
}

/*
 * checkcast & instanceof
 */

static void
rtti(void)
{
	char *loaderfn;
	Inst *imframe, *i;
	int state;
	RTClass *rtc;
	Creloc *cr;
	Freloc *frm, *frf;
	ArrayInfo ai;

	SET(state);
	SET(rtc);
	getaryinfo(&ai, CLASSNAME(J->u.i));
	if(ai.etype == 0) {
		state = crefstate(ai.ename, J->bb, 0);
		if(state & RTCODE) {
			rtc = getRTClass(ai.ename);
			if(state & RTCALL)
				callrtload(rtc, ai.ename);
		}
	}

	if(J->op == Jcheckcast) {
		if(ai.ndim > 0) {
			if(ai.etype > 0)
				loaderfn = "pcheckcast";
			else
				loaderfn = "acheckcast";
		} else
				loaderfn = "checkcast";
	} else {
		if(ai.ndim > 0) {
			if(ai.etype > 0)
				loaderfn = "pinstanceof";
			else
				loaderfn = "ainstanceof";
		} else
				loaderfn = "instanceof";
	}

	cr = getCreloc(RLOADER);
	frm = getFreloc(cr, RMP, nil, 0);
	frf = getFreloc(cr, loaderfn, nil, 0);

	imframe = loadermframe(frm, frf);

	/* pass object as first argument */

	i = newi(IMOVP);
	i->s = code->j[J->src[0]].dst;
	addrdind(&i->d, Afpind, imframe->d.u.offset, REGSIZE);

	/* second argument */

	if(ai.etype == 0) {
		i = newi(IMOVP);
		addrsind(&i->s, Amp, 0);
		if(state & RTCODE) {
			RTIpatch(getRTReloc(rtc, RADT, nil, 0), i, PSRC, PSIND);
		} else {
			LTIpatch(getFreloc(getCreloc(ai.ename), RADT, nil, 0),
				i, PSRC, PSIND);
		}
	} else {
		i = newi(IMOVW);
		addrimm(&i->s, ai.etype);
	}
	addrdind(&i->d, Afpind, imframe->d.u.offset, REGSIZE+IBY2WD);

	/* third argument, if present */

	if(ai.ndim > 0) {
		i = newi(IMOVW);
		addrimm(&i->s, ai.ndim);
		addrdind(&i->d, Afpind, imframe->d.u.offset, REGSIZE+2*IBY2WD);
	}

	if(J->op == Jinstanceof) {
		i = newi(ILEA);
		dstreg(&J->dst, DIS_W);
		i->s = J->dst;
		addrdind(&i->d, Afpind, imframe->d.u.offset, REGRET*IBY2WD);
	}

	loadermcall(imframe, frf, frm);
	relreg(&imframe->d);

	if(J->op == Jcheckcast) {
		i = newi(IMOVP);
		i->s = code->j[J->src[0]].dst;
		relreg(&code->j[J->src[0]].dst);
		dstreg(&J->dst, DIS_P);
		i->d = J->dst;
		datareloc(i);
	} else
		relreg(&code->j[J->src[0]].dst);
}

/*
 * Exception handling.
 */

typedef	struct	Catch	Catch;
typedef	struct	Try	Try;
typedef	struct	EHInst	EHInst;

struct Catch {
	char	*exname;
	int	handler_pc;
	Catch	*next;
};

struct Try {
	int	start_pc;
	int	end_pc;
	int	any_pc;
	Catch	*catch;
	Try	*next;
};

struct EHInst {
	Inst	*i;
	EHInst	*next;
};

static	EHInst	*ehinst;
static	Try	*trylist;

/*
 * Save an EH branch instruction for later patching.
 */

static void
saveehinst(Inst *i)
{
	EHInst *ehi;

	ehi = Malloc(sizeof(EHInst));
	ehi->i = i;
	ehi->next = ehinst;
	ehinst = ehi;
}

/*
 * Patch an EH branch instruction.
 * Java PCs in exception tables are absolute, not relative.
 */

static void
patchehinst(void)
{
	EHInst *ehi, *ehi2;
	Inst *i;
	Jinst *j;

	for(ehi = ehinst; ehi; ehi = ehi2) {
		i = ehi->i;
		j = &code->j[i->d.u.ival];
		while(j->dis == nil)
			j += j->size;
		i->d.u.ival = j->dis->pc;
		ehi2 = ehi->next;
		free(ehi);
	}
	ehinst = nil;
}

/*
 * Convert handler information into a more convenient form.
 */

static void
cvtehinfo(void)
{
	int i;
	Try *t;
	Catch *c;
	Handler *h;

	if(code->nex == 0)
		return;

	/* process in reverse to maintain order of try & catch blocks */
	for(i = code->nex-1; i >= 0; i--) {
		h = code->ex[i];
		if((t = trylist) == nil
		|| (t->start_pc != h->start_pc || t->end_pc != h->end_pc)) {
			t = Mallocz(sizeof(Try));
			t->start_pc = h->start_pc;
			t->end_pc = h->end_pc;
			t->next = trylist;
			trylist = t;
		}
		if(h->catch_type == 0) {
			t->any_pc = h->handler_pc;
		} else {
			c = Malloc(sizeof(Catch));
			c->handler_pc = h->handler_pc;
			c->exname = CLASSNAME(h->catch_type);
			c->next = t->catch;
			t->catch = c;
		}
	}
}

/*
 * At what try nesting level is the given Java pc at.
 * 0 means not within a try block.
 */

static int
trylevel(int pc)
{
	int level;
	Try *t;

	level = 0;
	for(t = trylist; t; t = t->next) {
		if(pc >= t->start_pc && pc < t->end_pc)
			level += 1;
	}
	return level;
}

/*
 * Free the handler information.
 */

static void
ehinfofree(void)
{
	Try *t, *t2;
	Catch *c, *c2;

	for(t = trylist; t; t = t2) {
		for(c = t->catch; c; c = c2) {
			c2 = c->next;
			free(c);
		}
		t2 = t->next;
		free(t);
	}
	trylist = nil;
}

/*
 * Install an exception handler: call sys->rescue("*", nil).
 */

static Addr*
rescue(void)
{
	Inst *imframe, *i;
	Creloc *cr;
	Freloc *frm, *frf;

	cr = getCreloc(RLOADER);
	frm = getFreloc(cr, RSYS, nil, 0);
	frf = getFreloc(cr, "rescue", nil, 0);

	imframe = loadermframe(frm, frf);

	i = newi(IMOVP);
	addrsind(&i->s, Amp, mpstring("*"));
	addrdind(&i->d, Afpind, imframe->d.u.offset, REGSIZE);
	addDreloc(i, PSRC, PSIND);

	i = newi(IMOVP);
	addrsind(&i->s, Afp, REFSYSEX);
	addrdind(&i->d, Afpind, imframe->d.u.offset, REGSIZE+IBY2WD);

	i = newi(ILEA);
	addrsind(&i->s, Afp, getreg(DIS_W));
	addrdind(&i->d, Afpind, imframe->d.u.offset, REGRET*IBY2WD);

	loadermcall(imframe, frf, frm);
	relreg(&imframe->d);

	return &i->s;
}

/*
 * Uninstall one or more exception handlers: call sys->unrescue() n times.
 */

static void
unrescue(int n)
{
	Inst *imframe;
	Creloc *cr;
	Freloc *frm, *frf;

	cr = getCreloc(RLOADER);
	frm = getFreloc(cr, RSYS, nil, 0);
	frf = getFreloc(cr, "unrescue", nil, 0);

	while(n > 0) {
		imframe = loadermframe(frm, frf);
		loadermcall(imframe, frf, frm);
		relreg(&imframe->d);
		n--;
	}
}

/*
 * Current handler doesn't catch current exception.
 * Call sys->raise(@jex) to propagate (rethrow) the exception.
 */

static Inst*
rethrow(void)
{
	Inst *imframe, *i;
	Creloc *cr;
	Freloc *frm, *frf;

	cr = getCreloc(RLOADER);
	frm = getFreloc(cr, RSYS, nil, 0);
	frf = getFreloc(cr, "raise", nil, 0);

	if(M->access_flags & ACC_SYNCHRONIZED && trylevel(J->pc) == 1)
		mon_or_throw(Jmonitorexit, M->access_flags, 0);

	imframe = loadermframe(frm, frf);

	i = newi(IMOVP);
	addrsind(&i->s, Amp, 0);
	addrdind(&i->d, Afpind, imframe->d.u.offset, REGSIZE);
	LTIpatch(getFreloc(cr, RJEX, nil, 0), i, PSRC, PSIND);

	i = loadermcall(imframe, frf, frm);
	relreg(&imframe->d);

	return i;
}

/*
 * Retrieve thrown object prior to jumping to exception handler.
 */

static void
catch(void)
{
	Inst *imframe, *i;
	Creloc *cr;
	Freloc *frm, *frf;

	cr = getCreloc(RLOADER);
	frm = getFreloc(cr, RMP, nil, 0);
	frf = getFreloc(cr, "culprit", nil, 0);

	imframe = loadermframe(frm, frf);

	i = newi(IMOVP);
	addrsind(&i->s, Afp, REFSYSEX);
	addrdind(&i->d, Afpind, imframe->d.u.offset, REGSIZE);

	i = newi(ILEA);
	addrsind(&i->s, Afp, EXOBJ);	/* put in known location */
	addrdind(&i->d, Afpind, imframe->d.u.offset, REGRET*IBY2WD);

	loadermcall(imframe, frf, frm);
	relreg(&imframe->d);
}

/*
 * Does thrown object match handler for exception class exname ?
 */

static Addr*
chkhandler(char *exname)
{
	int state;
	Inst *imframe, *i;
	RTClass *rtc;
	Creloc *cr;
	Freloc *frm, *frf;

	SET(rtc);
	state = crefstate(exname, J->bb, 1);
	if(state & RTCODE) {
		rtc = getRTClass(exname);
		if(state & RTCALL)
			callrtload(rtc, exname);

	}

	cr = getCreloc(RLOADER);
	frm = getFreloc(cr, RMP, nil, 0);
	frf = getFreloc(cr, "instanceof", nil, 0);

	imframe = loadermframe(frm, frf);

	i = newi(IMOVP);
	addrsind(&i->s, Afp, EXOBJ);
	addrdind(&i->d, Afpind, imframe->d.u.offset, REGSIZE);

	i = newi(IMOVP);
	addrsind(&i->s, Amp, 0);
	if(state & RTCODE)
		RTIpatch(getRTReloc(rtc, RADT, nil, 0), i, PSRC, PSIND);
	else
		LTIpatch(getFreloc(getCreloc(exname), RADT, nil, 0), i, PSRC, PSIND);
	addrdind(&i->d, Afpind, imframe->d.u.offset, REGSIZE+IBY2WD);

	i = newi(ILEA);
	addrsind(&i->s, Afp, getreg(DIS_W));
	addrdind(&i->d, Afpind, imframe->d.u.offset, REGRET*IBY2WD);

	loadermcall(imframe, frf, frm);
	relreg(&imframe->d);

	return &i->s;
}

/*
 * Start of a try block.  Install exception handler for try block t.
 */

static void
trystart(Try *t)
{
	Inst *ibeqw, *i;
	Addr *a;
	Catch *c;

	a = rescue();

	ibeqw = newi(IBEQW);
	ibeqw->s = *a;
	relreg(a);
	addrimm(&ibeqw->m, 0);		/* Sys->HANDLER == 0 */
	addrimm(&ibeqw->d, 0);

	/* code executed when sys->rescue() "returns" Sys->EXCEPTION */

	unrescue(1);

	catch();

	for(c = t->catch; c; c = c->next) {
		a = chkhandler(c->exname);
		i = newi(IBEQW);
		i->s = *a;
		relreg(a);
		addrimm(&i->m, 1);
		addrimm(&i->d, c->handler_pc);
		saveehinst(i);
	}

	if(t->any_pc > 0) {
		i = newi(IJMP);
		addrimm(&i->d, t->any_pc);
		saveehinst(i);
	} else
		i = rethrow();

	ibeqw->d.u.ival = i->pc+1;
}

/*
 * At the start or end of a try block ?
 */

static void
tryhandling(void)
{
	Try *t;

	for(t = trylist; t; t = t->next) {
		/* > 1 try block can have the same start_pc */
		if(t->start_pc == J->pc)
			trystart(t);
		/* try block may consist of just 1 bytecode */
		if(t->end_pc == J->pc+J->size)
			callunrescue = 1;
	}
}

/*
 * Generate Dis assembly code for one method.
 */

static void
java2dis(void)
{
	Jinst *jnext, *je;

	je = J + code->code_length;
	while(J < je) {
		if(J->bb->js == J) {	/* start of a basic block ? */
			/* ignore unreachable code */
			if((J->bb->flags & BB_REACHABLE) == 0) {
				J = J->bb->je + J->bb->je->size;
				continue;
			}
			/* initialize fp temporary pool */
			clearreg();
			reservereg(J->bb->entrystk, J->bb->entrysz);
			reservereg(J->bb->exitstk, J->bb->exitsz);
		}

		/* start of a synchronized method ? */
		if(J->pc == 0 && M->access_flags & ACC_SYNCHRONIZED)
			mon_or_throw(Jmonitorenter, M->access_flags, 0);

		tryhandling();

		jnext = J+J->size;
		if(jnext >= je)
			jnext = nil;
		/* "optimize" loads and stores */
		if(jnext && isstore(jnext) && jnext->bb->js != jnext) {
			if(J->dst.mode == Afp && J->dst.u.offset == -1) {
				J->dst = jnext->dst;
				/* mark jnext so mov not generated for it */
				jnext->dst.mode = Anone;
			} else if(isload(J) && J->movsrc.mode == Anone) {
				J->movsrc = J->dst;
				J->dst = jnext->dst;
				/* mark jnext so mov not generated for it */
				jnext->dst.mode = Anone;
			}
		}

		switch(J->op) {
		case Jnop:
			break;
		case Jaconst_null:
			xjavaload(IMOVP);
			break;
		case Jiconst_m1:
		case Jiconst_0:
		case Jiconst_1:
		case Jiconst_2:
		case Jiconst_3:
		case Jiconst_4:
		case Jiconst_5:
		case Jbipush:
		case Jsipush:
			xjavaload(IMOVW);
			break;
		case Jlconst_0:
		case Jlconst_1:
			xjavaload(IMOVL);
			break;
		case Jfconst_0:
		case Jdconst_0:
		case Jfconst_1:
		case Jdconst_1:
		case Jfconst_2:
			xjavaload(IMOVF);
			break;
		case Jldc:
		case Jldc_w:
		case Jldc2_w:
			xldc();
			break;
		case Jiload:
		case Jiload_0:
		case Jiload_1:
		case Jiload_2:
		case Jiload_3:
			xjavaload(IMOVW);
			break;
		case Jlload:
		case Jlload_0:
		case Jlload_1:
		case Jlload_2:
		case Jlload_3:
			xjavaload(IMOVL);
			break;
		case Jfload:
		case Jdload:
		case Jfload_0:
		case Jdload_0:
		case Jfload_1:
		case Jdload_1:
		case Jfload_2:
		case Jdload_2:
		case Jfload_3:
		case Jdload_3:
			xjavaload(IMOVF);
			break;
		case Jaload:
		case Jaload_0:
		case Jaload_1:
		case Jaload_2:
		case Jaload_3:
			xjavaload(IMOVP);
			break;
		case Jbaload:
			xarrayload(IINDB, ICVTBW, DIS_W);
			break;
		case Jcaload:
		case Jsaload:
		case Jiaload:
			xarrayload(IINDW, IMOVW, DIS_W);
			break;
		case Jlaload:
			xarrayload(IINDL, IMOVL, DIS_L);
			break;
		case Jfaload:
		case Jdaload:
			xarrayload(IINDF, IMOVF, DIS_L);
			break;
		case Jaaload:
			xarrayload(IINDX, IMOVP, DIS_P);
			break;
		case Jistore:
		case Jistore_0:
		case Jistore_1:
		case Jistore_2:
		case Jistore_3:
			xjavastore(IMOVW);
			break;
		case Jlstore:
		case Jlstore_0:
		case Jlstore_1:
		case Jlstore_2:
		case Jlstore_3:
			xjavastore(IMOVL);
			break;
		case Jfstore:
		case Jdstore:
		case Jfstore_0:
		case Jdstore_0:
		case Jfstore_1:
		case Jdstore_1:
		case Jfstore_2:
		case Jdstore_2:
		case Jfstore_3:
		case Jdstore_3:
			xjavastore(IMOVF);
			break;
		case Jastore:
		case Jastore_0:
		case Jastore_1:
		case Jastore_2:
		case Jastore_3:
			xjavastore(IMOVP);
			break;
		case Jbastore:
			xarraystore(IINDB, ICVTWB);
			break;
		case Jcastore:
		case Jsastore:
		case Jiastore:
			xarraystore(IINDW, IMOVW);
			break;
		case Jlastore:
			xarraystore(IINDL, IMOVL);
			break;
		case Jfastore:
		case Jdastore:
			xarraystore(IINDF, IMOVF);
			break;
		case Jaastore:
			aastore();
			xarraystore(IINDX, IMOVP);
			break;
		case Jpop:
		case Jpop2:
			xjavapop();
			break;
		case Jdup:
		case Jdup_x1:
		case Jdup_x2:
		case Jdup2:
		case Jdup2_x1:
		case Jdup2_x2:
			xjavadup();
			break;
		case Jswap:
			break;
		case Jiadd:
			xbinop(IADDW, DIS_W, 0);
			break;
		case Jisub:
			xbinop(ISUBW, DIS_W, 0);
			break;
		case Jimul:
			xbinop(IMULW, DIS_W, 0);
			break;
		case Jidiv:
			xbinop(IDIVW, DIS_W, 0);
			break;
		case Jishl:
			shift(ISHLW, DIS_W);
			break;
		case Jishr:
			shift(ISHRW, DIS_W);
			break;
		case Jiushr:
			shift(ILSRW, DIS_W);
			break;
		case Jirem:
			xbinop(IMODW, DIS_W, 0);
			break;
		case Jiand:
			xbinop(IANDW, DIS_W, 0);
			break;
		case Jior:
			xbinop(IORW, DIS_W, 0);
			break;
		case Jixor:
			xbinop(IXORW, DIS_W, 0);
			break;
		case Jladd:
			xbinop(IADDL, DIS_L, 0);
			break;
		case Jlsub:
			xbinop(ISUBL, DIS_L, 0);
			break;
		case Jlmul:
			xbinop(IMULL, DIS_L, 0);
			break;
		case Jldiv:
			xbinop(IDIVL, DIS_L, 0);
			break;
		case Jlrem:
			xbinop(IMODL, DIS_L, 0);
			break;
		case Jland:
			xbinop(IANDL, DIS_L, 0);
			break;
		case Jlor:
			xbinop(IORL, DIS_L, 0);
			break;
		case Jlxor:
			xbinop(IXORL, DIS_L, 0);
			break;
		case Jfadd:
			xbinop(IADDF, DIS_L, 1);
			break;
		case Jdadd:
			xbinop(IADDF, DIS_L, 0);
			break;
		case Jfsub:
			xbinop(ISUBF, DIS_L, 1);
			break;
		case Jdsub:
			xbinop(ISUBF, DIS_L, 0);
			break;
		case Jfmul:
			xbinop(IMULF, DIS_L, 1);
			break;
		case Jdmul:
			xbinop(IMULF, DIS_L, 0);
			break;
		case Jfdiv:
			xbinop(IDIVF, DIS_L, 1);
			break;
		case Jddiv:
			xbinop(IDIVF, DIS_L, 0);
			break;
		case Jfrem:
		case Jdrem:
			jmath("drem", IMOVF, DIS_L);
			break;
		case Jineg:
			neg(ISUBW, DIS_W);
			break;
		case Jlneg:
			neg(ISUBL, DIS_L);
			break;
		case Jfneg:
		case Jdneg:
			neg(INEGF, DIS_L);
			break;
		case Jlshl:
			shift(ISHLL, DIS_L);
			break;
		case Jlshr:
			shift(ISHRL, DIS_L);
			break;
		case Jlushr:
			shift(ILSRL, DIS_L);
			break;
		case Jiinc:
			iinc(J->u.x1c.icon, J->u.x1c.ix);
			break;
		case Ji2l:
			cvt(ICVTWL, DIS_L, 0);
			break;
		case Ji2f:
			cvt(ICVTWF, DIS_L, 1);
			break;
		case Ji2d:
			cvt(ICVTWF, DIS_L, 0);
			break;
		case Jl2i:
			cvt(ICVTLW, DIS_W, 0);
			break;
		case Jl2f:
			cvt(ICVTLF, DIS_L, 1);
			break;
		case Jl2d:
			cvt(ICVTLF, DIS_L, 0);
			break;
		case Jf2i:
		case Jd2i:
			jmath("d2i", IMOVF, DIS_W);
			break;
		case Jf2l:
		case Jd2l:
			jmath("d2l", IMOVF, DIS_L);
			break;
		case Jf2d:
			cvt(IMOVF, DIS_L, 0);
			break;
		case Jd2f:
			cvt(IMOVF, DIS_L, 1);
			break;
		case Ji2b:
			i2bs(24);
			break;
		case Ji2c:
			i2c();
			break;
		case Ji2s:
			i2bs(16);
			break;
		case Jlcmp:
			jmath("lcmp", IMOVL, DIS_W);
			break;
		case Jfcmpl:
		case Jdcmpl:
			jmath("dcmpl", IMOVF, DIS_W);
			break;
		case Jfcmpg:
		case Jdcmpg:
			jmath("dcmpg", IMOVF, DIS_W);
			break;
		case Jifeq:
			javaif(IBEQW, CMPZERO);
			break;
		case Jifne:
			javaif(IBNEW, CMPZERO);
			break;
		case Jiflt:
			javaif(IBLTW, CMPZERO);
			break;
		case Jifge:
			javaif(IBGEW, CMPZERO);
			break;
		case Jifgt:
			javaif(IBGTW, CMPZERO);
			break;
		case Jifle:
			javaif(IBLEW, CMPZERO);
			break;
		case Jif_acmpeq:
		case Jif_icmpeq:
			javaif(IBEQW, CMP2OP);
			break;
		case Jif_acmpne:
		case Jif_icmpne:
			javaif(IBNEW, CMP2OP);
			break;
		case Jif_icmplt:
			javaif(IBLTW, CMP2OP);
			break;
		case Jif_icmpge:
			javaif(IBGEW, CMP2OP);
			break;
		case Jif_icmpgt:
			javaif(IBGTW, CMP2OP);
			break;
		case Jif_icmple:
			javaif(IBLEW, CMP2OP);
			break;
		case Jgoto:
		case Jgoto_w:
			javagoto();
			break;
		case Jjsr:
		case Jjsr_w:
			jsr(J->u.i);
			break;
		case Jret:
			ret();
			break;
		case Jtableswitch:
			tableswitch();
			break;
		case Jlookupswitch:
			lookupswitch();
			break;
		case Jireturn:
			xjavareturn(IMOVW);
			break;
		case Jlreturn:
			xjavareturn(IMOVL);
			break;
		case Jfreturn:
		case Jdreturn:
			xjavareturn(IMOVF);
			break;
		case Jareturn:
			xjavareturn(IMOVP);
			break;
		case Jreturn:
			xjavareturn(0);
			break;
		case Jgetfield:
			getfield();
			break;
		case Jgetstatic:
			getstatic();
			break;
		case Jputfield:
			putfield();
			break;
		case Jputstatic:
			putstatic();
			break;
		case Jinvokevirtual:
			invokev();
			break;
		case Jinvokespecial:
			invokess(Rinvokespecial, Rspecialmp);
			break;
		case Jinvokestatic:
			invokess(Rinvokestatic, Rstaticmp);
			break;
		case Jinvokeinterface:
			invokei();
			break;
		case Jxxxunusedxxx:
			break;
		case Jnew:
			xjavanew(CLASSNAME(J->u.i), &J->dst);
			break;
		case Jnewarray:
			newarray();
			break;
		case Janewarray:
			xanewarray();
			break;
		case Jarraylength:
			arraylength();
			break;
		case Jcheckcast:
		case Jinstanceof:
			rtti();
			break;
		case Jathrow:
		case Jmonitorenter:
		case Jmonitorexit:
			if(J->op == Jathrow
			&& M->access_flags & ACC_SYNCHRONIZED
			&& trylevel(J->pc) == 0) {
				mon_or_throw(Jmonitorexit, M->access_flags, 0);
			}
			mon_or_throw(J->op, 0, 1);
			break;
		case Jwide:
			switch(J->u.w.op) {
			case Jiload:
				xjavaload(IMOVW);
				break;
			case Jlload:
				xjavaload(IMOVL);
				break;
			case Jfload:
			case Jdload:
				xjavaload(IMOVF);
				break;
			case Jaload:
				xjavaload(IMOVP);
				break;
			case Jistore:
				xjavastore(IMOVW);
				break;
			case Jlstore:
				xjavastore(IMOVL);
				break;
			case Jfstore:
			case Jdstore:
				xjavastore(IMOVF);
				break;
			case Jastore:
				xjavastore(IMOVP);
				break;
			case Jret:
				ret();
				break;
			case Jiinc:
				iinc(J->u.w.icon, J->u.w.ix);
				break;
			}
			break;
		case Jmultianewarray:
			xmultianewarray();
			break;
		case Jifnull:
			javaif(IBEQW, CMPNULL);
			break;
		case Jifnonnull:
			javaif(IBNEW, CMPNULL);
			break;
		}
		if(callunrescue == 1) {
			unrescue(1);
			callunrescue = 0;
		}
		J += J->size;
	}
	J = nil;
}

/*
 * If there are exception handlers, then allocate a 'ref Sys->Exception'
 * to pass to Sys->rescue() and Loader->culprit().
 */

static void
ref_sys_except(void)
{
	Inst *i;

	if(code->nex == 0)
		return;

	i = newi(INEW);
	addrimm(&i->s, descid(3*IBY2WD, 1, (uchar*)"\xc0"));
	addrsind(&i->d, Afp, REFSYSEX);
}

/*
 * Generate initialization code for 'static final' fields that have
 * ConstantValue attributes.
 */

static Inst*
clinitinits(void)
{
	uchar movi;
	int j, ix, offset, value;
	char *sig;
	Addr *a;
	Addr as;
	Const *c;
	Field *fp;
	FieldInfo fi;
	Inst *i, *reti;

	SET(value);
	as.mode = Afp;
	fi.classname = THISCLASS;
	reti = nil;

	for(j = 0, fp = class->fields; j < class->fields_count; j++, fp++) {
		if((fp->access_flags & ACC_STATIC) && (ix = CVattrindex(fp))) {
			sig = STRING(fp->sig_index);
			c = &class->cps[ix];
			switch(class->cts[ix]) {
			case CON_Integer:
				if(c->tint == 0)
					continue;
				if(sig[0] == 'Z' || sig[0] == 'B')
					movi = ICVTWB;
				else
					movi = IMOVW;
				if(notimmable(c->tint))
					offset = mpint(c->tint);
				else {
					offset = -1;
					value = c->tint;
				}
				break;
			case CON_Long:
				if(c->tvlong == 0)
					continue;
				movi = IMOVL;
				offset = mplong(c->tvlong);
				break;
			case CON_Float:
			case CON_Double:
				if(c->tdouble == 0.0)
					continue;
				movi = IMOVF;
				offset = mpreal(c->tdouble);
				break;
			case CON_String:
				movi = IMOVP;
				offset = mpstring(STRING(c->ci.name_index));
				break;
			default:
				verifyerrormess("clinitinits: constant type");
				return nil;
			}
			fi.fieldname = STRING(fp->name_index);
			fi.sig = sig;
			a = ltstaticadd(&fi);
			if(reti == nil)
				reti = itail;
			if(movi == IMOVP) {
				as.u.offset = -1;
				xjavanew("java/lang/String", &as);
				i = newi(IMOVP);
				addrsind(&i->s, Amp, offset);
				i->d = as;
				sind2dind(&i->d, STR_DISSTR);
				addDreloc(i, PSRC, PSIND);
			}
			i = newi(movi);
			if(movi == IMOVP) {
				i->s = as;
				relreg(&as);
			} else if(offset >= 0) {
				addrsind(&i->s, Amp, offset);
				addDreloc(i, PSRC, PSIND);
			} else
				addrimm(&i->s, value);
			i->d = *a;
			sind2dind(&i->d, 0);
			relreg(a);
		}
	}
	return reti;
}

/*
 * Cook up a <clinit> static method.
 */

static void
genclinit(void)
{
	int savepc;

	savepc = pcdis;
	openframe("()V", ACC_STATIC);
	clinitclone = clinitinits();		/* save for -v option */
	newi(IRET);
	xtrnlink(closeframe(), savepc, "<clinit>", "()V");
}

/*
 * Cook up link entry and body for <clone> static method.
 */

static Inst*
genclone(void)
{
	Inst *i, *clone;
	Freloc *fr;

	xtrnlink(descid(40, 2, (uchar*)"\x0\xc0"), pcdis, "<clone>", "()V");

	/*
	 * new    @Class, 36(fp)
	 * movmp  0(32(fp)), @Class, 0(36(fp))
	 * movp   36(fp), 0(16(fp))
	 * ret
	 */

	fr = getFreloc(getCreloc(THISCLASS), RCLASS, nil, 0);

	i = newi(INEW);
	addrimm(&i->s, 0);
	LTIpatch(fr, i, PSRC, PIMM);
	addrsind(&i->d, Afp, 36);
	clone = i;	/* save for -v option */

	i = newi(IMOVMP);
	addrdind(&i->s, Afpind, 32, 0);
	addrimm(&i->m, 0);
	LTIpatch(fr, i, PMID, PIMM);
	addrdind(&i->d, Afpind, 36, 0);

	i = newi(IMOVP);
	addrsind(&i->s, Afp, 36);
	addrdind(&i->d, Afpind, 16, 0);

	newi(IRET);

	return clone;
}

/*
 * Translate the methods in class cl.
 */

void
xlate(void)
{
	int i, j, n;
	int savepcdis;
	Attr *a;
	Inst *clone;
	Method *m;
	char *name, *sig;

	n = 0;
	for(i = 0, m = class->methods; i < class->methods_count; i++, m++) {
		name = STRING(m->name_index);
		pcode[n].name = name;
		sig = STRING(m->sig_index);
		pcode[n].sig = sig;
		for(j = 0, a = m->attr_info; j < m->attr_count; j++, a++) {
			if(strcmp(STRING(a->name), "Code") == 0) {
				M = m;
				code = javadas(a);
				pcode[n].code = code;
				cvtehinfo();
				/* exception object */
				addrsind(&code->j[code->code_length].dst, Afp, EXOBJ);
				openframe(sig, m->access_flags&ACC_STATIC);
				savepcdis = pcdis;
				flowgraph();
				simjvm(sig);
				unify();
				J = &code->j[0];
				ref_sys_except();
				if(doclinitinits && strcmp(name, "<clinit>") == 0) {
					clinitinits();
					doclinitinits = 0;
				}
				java2dis();
				bbfree();
				xtrnlink(closeframe(), savepcdis, name, sig);
				patchmethod(savepcdis);
				patchehinst();
				patchfree();
				finallyfree();
				ehinfofree();
				creffree();
			}
		}
		n += 1;
	}

	if(doclinitinits)
		genclinit();

	if((class->access_flags & (ACC_INTERFACE | ACC_ABSTRACT)) == 0) {
		clone = genclone();
		if(clinitclone == nil)
			clinitclone = clone;
	}
}

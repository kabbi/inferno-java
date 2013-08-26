pcdis:		int;
callunrescue:	int;
J:		ref Jinst;
M:		ref Method;
code:		ref Code;		# method under translation

trylevel:	fn(pc: int): int;
unrescue:	fn(n: int);

#
# Allocate a Dis instruction.
#

newi(op: int): ref Inst
{
	i: ref Inst;

	i = ref Inst(byte op, nil, nil, nil, pcdis, J, nil);
	i.s = ref Addr(byte 0, 0, 0);
	i.m = ref Addr(byte 0, 0, 0);
	i.d = ref Addr(byte 0, 0, 0);
	pcdis += 1;
	if(J != nil && J.dis == nil)
		J.dis = i;
	if(ihead == nil)
		ihead = i;
	if(itail != nil)
		itail.next = i;
	itail = i;
	return i;
}

#
# Allocate a Dis instruction and record for branch-address patching.
#

newibap(op: int): ref Inst
{
	i: ref Inst;

	i = newi(op);
	patchop(i);
	return i;
}

#
# Turn single indirection off fp into double indirection.
#

sind2dind(a: ref Addr, s: int)
{
	if(a.mode == byte Afp) {
		a.mode = byte Afpind;
		a.ival = a.offset;
		a.offset = s;
	} else if(a.mode == byte Amp && a.offset == 0)
		;	# verifyerror(J); # can't reject prior to runtime
	else
		fatal("sind2dind: " + string a.mode + " not Afp");
}

#
# Middle operands that match destination operands are redundant.
#

middstcmp(i: ref Inst)
{
	m, d: ref Addr;

	m = i.m;
	d = i.d;
	if(m.mode == Afp && m.mode == d.mode && m.offset == d.offset) {
		m.mode = Anone;
		m.offset = 0;
	}
}

#
# For instructions that may reference Module Data.
#

datareloc(i: ref Inst)
{
	if(i.op == byte IMOVP && i.s.mode == byte Amp && i.s.offset == 0)
		return;		# don't relocate reference to nil
	if(i.s.mode == byte Amp)
		addDreloc(i, PSRC, PSIND);
	if(i.m.mode == byte Amp)
		addDreloc(i, PMID, PSIND);
}

movinst(jtype: int): int
{
	movi: int;

	case jtype {
	'Z' or
	'B' =>
		if(J.op == byte Jgetfield || J.op == byte Jgetstatic)
			movi = ICVTBW;
		else if(J.op == byte Jputfield || J.op == byte Jputstatic)
			movi = ICVTWB;
		else
			movi = IMOVW;
	'C' or
	'S' or
	'I' =>
		movi = IMOVW;
	'J' =>
		movi = IMOVL;
	'F' or
	'D' =>
		movi = IMOVF;
	'L' or
	'[' =>
		movi = IMOVP;
	}
	return movi;
}

FieldInfo: adt {
	classname:	string;
	fieldname:	string;
	sig:		string;
	flags:		int;
};

getfldinfo(): ref FieldInfo
{
	i: int;
	m: ref Method;
	fi: ref FieldInfo = ref FieldInfo(nil, nil, nil, 0);
	ix: int;

	pick jp := J {
	Pi =>
		ix = jp.i;
	Px2c0 =>
		ix = jp.x2c0.ix;
	* =>
		badpick("getfldinfo[Pi|Px2c0]");
	}

	pick c := class.cps[ix] {
	Pfmiref =>
		fi.classname = CLASSNAME(c.fmiref.class_index);
		pick n := class.cps[c.fmiref.name_type_index] {
		Pnat =>
			fi.fieldname = STRING(n.nat.name_index);
			fi.sig = STRING(n.nat.sig_index);
		* =>
			badpick("getfldinfo[Pnat]");
		}
	* =>
		badpick("getfldinfo[Pfmiref]");
	}
	fi.flags = 0;
	if(fi.classname != THISCLASS)
		return fi;
	for(i = 0; i < class.methods_count; i++) {
		m = class.methods[i];
		if(fi.fieldname == STRING(m.name_index)
		&& fi.sig == STRING(m.sig_index)) {
			fi.flags = m.access_flags;
			break;
		}
	}
	return fi;
}

#
# mframe instruction for a call to a Loader entry point.
#

loadermframe(frm: ref Freloc, frf: ref Freloc): ref Inst
{
	imframe: ref Inst;

	imframe = newi(IMFRAME);
	addrsind(imframe.s, Amp, 0);
	addrimm(imframe.m, 0);
	addrsind(imframe.d, Afp, getreg(DIS_W));
	LTIpatch(frm, imframe, PSRC, PSIND);
	LTIpatch(frf, imframe, PMID, PIMM);

	return imframe;
}

#
# mcall instruction for a call to a Loader entry point.
#

loadermcall(imframe: ref Inst, frf: ref Freloc, frm: ref Freloc): ref Inst
{
	imcall: ref Inst;

	imcall = newi(IMCALL);
	*imcall.s = *imframe.d;
	*imcall.m = *imframe.m;
	*imcall.d = *imframe.s;
	LTIpatch(frf, imcall, PMID, PIMM);
	LTIpatch(frm, imcall, PDST, PSIND);

	return imcall;
}

#
# Call "rtload" for run-time resolution.
#

rtcache:	array of string;
rtncache:	int;
rtnmax:		int;

callrtload(rtc: ref RTClass, classname: string)
{
	j: int;
	imframe, i: ref Inst;
	cr: ref Creloc;
	frm, frf: ref Freloc;
	rtr: ref RTReloc;

	# rtload() already called for classname in this basic block ?
	for(j = 0; j < rtncache; j++) {
		if(rtcache[j] == classname)
			return;
	}
	if(rtncache >= rtnmax) {
		oldrtnmax := rtnmax;
		rtnmax += ALLOCINCR;
		newrtcache := array [rtnmax] of string;
		for(k := 0; k < oldrtnmax; k++)
			newrtcache[k] = rtcache[k];
		rtcache = newrtcache;
	}
	rtcache[rtncache++] = classname;

	rtr = getRTReloc(rtc, RMP, nil, 0);
	cr = getCreloc(RLOADER);
	frm = getFreloc(cr, RMP, nil, 0);
	frf = getFreloc(cr, "rtload", nil, 0);

	i = newi(IBNEW);
	addrsind(i.s, Amp, 0);
	addrsind(i.m, Amp, 0);
	addrimm(i.d, i.pc+4);
	RTIpatch(rtr, i, PSRC, PSIND);

	imframe = loadermframe(frm, frf);

	i = newi(ILEA);
	addrsind(i.s, Amp, 0);
	addrdind(i.d, Afpind, imframe.d.offset, REGSIZE);
	RTIpatch(rtr, i, PSRC, PSIND);

	loadermcall(imframe, frf, frm);
	relreg(imframe.d);
}

#
# Sign-extend an 8-bit unsigned char (Dis byte) to a 32-bit int.
#

signextend(dst: ref Addr)
{
	i: ref Inst;

	i = newi(ISHLW);
	addrimm(i.s, 24);
	# *i.m = *dst; # redundant
	*i.d = *dst;

	i = newi(ISHRW);
	addrimm(i.s, 24);
	# *i.m = *dst; # redundant
	*i.d = *dst;
}

#
# addw instruction for run-time relocated getstatic & putstatic.
#

rtstaticadd(fi: ref FieldInfo, rtc: ref RTClass): ref Addr
{
	i: ref Inst;

	i = newi(IADDW);
	addrdind(i.s, Ampind, 0, 0);
	addrsind(i.m, Amp, 0);
	addrsind(i.d, Afp, getreg(DIS_W));

	RTIpatch(getRTReloc(rtc, RMP, nil, 0), i, PSRC, PDIND1);
	RTIpatch(getRTReloc(rtc, fi.fieldname, fi.sig, Rgetputstatic),
		i, PMID, PSIND);

	return i.d;
}

#
# Run-time relocated getstatic.
#

rtgetstatic(fi: ref FieldInfo)
{
	a: ref Addr;
	i: ref Inst;
	rtc: ref RTClass;

	rtc = getRTClass(fi.classname);
	callrtload(rtc, fi.classname);
	a = rtstaticadd(fi, rtc);

	i = newi(movinst(fi.sig[0]));
	*i.s = *a;
	sind2dind(i.s, 0);
	relreg(a);
	dstreg(J.dst, j2dtype(J.jtype));
	*i.d = *J.dst;

	if(fi.sig[0] == 'B')
		signextend(i.d);
}

#
# Run-time relocated putstatic.
#

rtputstatic(fi: ref FieldInfo)
{
	a: ref Addr;
	i: ref Inst;
	rtc: ref RTClass;

	rtc = getRTClass(fi.classname);
	callrtload(rtc, fi.classname);
	a = rtstaticadd(fi, rtc);

	i = newi(movinst(fi.sig[0]));
	*i.s = *code.j[J.src[0]].dst;
	relreg(code.j[J.src[0]].dst);
	*i.d = *a;
	sind2dind(i.d, 0);
	relreg(a);
	datareloc(i);
}

#
# addw instruction for load-time relocated getstatic & putstatic.
#

ltstaticadd(fi: ref FieldInfo): ref Addr
{
	i: ref Inst;
	cr: ref Creloc;

	i = newi(IADDW);
	addrdind(i.s, Ampind, 0, 0);
	addrimm(i.m, 0);
	addrsind(i.d, Afp, getreg(DIS_W));

	cr = getCreloc(fi.classname);
	LTIpatch(getFreloc(cr, RMP, nil, 0), i, PSRC, PDIND1);
	LTIpatch(getFreloc(cr, fi.fieldname, fi.sig, Rgetputstatic),
		i, PMID, PIMM);

	return i.d;
}

#
# Load-time relocated getstatic.
#

getstatic()
{
	i: ref Inst;
	a: ref Addr;
	fi: ref FieldInfo;

	fi = getfldinfo();
	if(dortload(fi.classname)) {
		rtgetstatic(fi);
		return;
	}

	a = ltstaticadd(fi);

	i = newi(movinst(fi.sig[0]));
	*i.s = *a;
	sind2dind(i.s, 0);
	relreg(a);
	dstreg(J.dst, j2dtype(J.jtype));
	*i.d = *J.dst;

	if(fi.sig[0] == 'B')
		signextend(i.d);
}

#
# Load-time relocated putstatic.
#

putstatic()
{
	i: ref Inst;
	a: ref Addr;
	fi: ref FieldInfo;

	fi = getfldinfo();
	if(dortload(fi.classname)) {
		rtputstatic(fi);
		return;
	}

	a = ltstaticadd(fi);

	i = newi(movinst(fi.sig[0]));
	*i.s = *code.j[J.src[0]].dst;
	relreg(code.j[J.src[0]].dst);
	*i.d = *a;
	sind2dind(i.d, 0);
	relreg(a);
	datareloc(i);
}

#
# addw instruction for run-time relocated getfield & putfield.
#

rtfieldadd(fi: ref FieldInfo, rtc: ref RTClass, a: ref Addr): ref Addr
{
	i: ref Inst;

	i = newi(IADDW);
	*i.s = *a;
	addrsind(i.m, Amp, 0);
	addrsind(i.d, Afp, getreg(DIS_W));

	RTIpatch(getRTReloc(rtc, fi.fieldname, fi.sig, Rgetputfield),
		i, PMID, PSIND);

	return i.d;
}

#
# Run-time relocated getfield.
#

rtgetfield(fi: ref FieldInfo)
{
	a: ref Addr;
	i: ref Inst;
	rtc: ref RTClass;

	rtc = getRTClass(fi.classname);
	callrtload(rtc, fi.classname);
	a = rtfieldadd(fi, rtc, code.j[J.src[0]].dst);
	relreg(code.j[J.src[0]].dst);

	i = newi(movinst(fi.sig[0]));
	*i.s = *a;
	sind2dind(i.s, 0);
	relreg(a);
	dstreg(J.dst, j2dtype(J.jtype));
	*i.d = *J.dst;

	if(fi.sig[0] == 'B')
		signextend(i.d);
}

#
# Run-time relocated putfield.
#

rtputfield(fi: ref FieldInfo)
{
	a: ref Addr;
	i: ref Inst;
	rtc: ref RTClass;

	rtc = getRTClass(fi.classname);
	callrtload(rtc, fi.classname);
	a = rtfieldadd(fi, rtc, code.j[J.src[0]].dst);
	relreg(code.j[J.src[0]].dst);

	i = newi(movinst(fi.sig[0]));
	*i.s = *code.j[J.src[1]].dst;
	relreg(code.j[J.src[1]].dst);
	*i.d = *a;
	relreg(a);
	sind2dind(i.d, 0);
	datareloc(i);
}

#
# Load-time relocated getfield.
#

getfield()
{
	i: ref Inst;
	cr: ref Creloc;
	fi: ref FieldInfo;

	fi = getfldinfo();
	if(dortload(fi.classname)) {
		rtgetfield(fi);
		return;
	}

	i = newi(movinst(fi.sig[0]));
	*i.s = *code.j[J.src[0]].dst;
	sind2dind(i.s, 0);
	relreg(code.j[J.src[0]].dst);
	dstreg(J.dst, j2dtype(J.jtype));
	*i.d = *J.dst;

	cr = getCreloc(fi.classname);
	LTIpatch(getFreloc(cr, fi.fieldname, fi.sig, Rgetputfield),
		i, PSRC, PDIND2);

	if(fi.sig[0] == 'B')
		signextend(i.d);
}

#
# Load-time relocated putfield.
#

putfield()
{
	i: ref Inst;
	cr: ref Creloc;
	fi: ref FieldInfo;

	fi = getfldinfo();
	if(dortload(fi.classname)) {
		rtputfield(fi);
		return;
	}

	i = newi(movinst(fi.sig[0]));
	*i.s = *code.j[J.src[1]].dst;
	relreg(code.j[J.src[1]].dst);
	*i.d = *code.j[J.src[0]].dst;
	relreg(code.j[J.src[0]].dst);
	sind2dind(i.d, 0);
	datareloc(i);

	cr = getCreloc(fi.classname);
	LTIpatch(getFreloc(cr, fi.fieldname, fi.sig, Rgetputfield),
		i, PDST, PDIND2);
}

#
# Push function arguments.
#

pushargs(calltype: int, calleeframe: int, sig: string)
{
	i: ref Inst;
	frameoff: int;
	arg, size: int;

	frameoff = REGSIZE;
	arg = 0;
	if(calltype != Rinvokestatic) {
		i = newi(IMOVP);		# this pointer
		*i.s = *code.j[J.src[arg]].dst;
		addrdind(i.d, Afpind, calleeframe, frameoff);
		frameoff += IBY2WD;
		arg++;
	}

	sig = sig[1:];	# skip '('
	while(sig[0] != ')') {
		i = newi(movinst(sig[0]));
		*i.s = *code.j[J.src[arg]].dst;
		size = cellsize[int j2dtype(byte sig[0])];
		frameoff = align(frameoff, size);
		addrdind(i.d, Afpind, calleeframe, frameoff);
		datareloc(i);
		frameoff += size;
		sig = nextjavatype(sig);
		arg++;
	}

	# return value
	if(sig[1] != 'V') {	# skip ')'
		i = newi(ILEA);
		dstreg(J.dst, j2dtype(J.jtype));
		*i.s = *J.dst;
		addrdind(i.d, Afpind, calleeframe, REGRET*IBY2WD);
	}
}

#
# Run-time relocated invokespecial and invokestatic.
#

rtinvokess(fi: ref FieldInfo, calltype: int, mpflag: int)
{
	n: int;
	imframe, imcall: ref Inst;
	rtc: ref RTClass;
	rtr1, rtr2: ref RTReloc;

	rtc = getRTClass(fi.classname);
	callrtload(rtc, fi.classname);

	imframe = newi(IMFRAME);
	addrsind(imframe.s, Amp, 0);
	addrsind(imframe.m, Amp, 0);
	addrsind(imframe.d, Afp, getreg(DIS_W));

	rtr1 = getRTReloc(rtc, fi.fieldname, fi.sig, calltype|mpflag);
	rtr2 = getRTReloc(rtc, fi.fieldname, fi.sig, calltype);
	RTIpatch(rtr1, imframe, PSRC, PSIND);
	RTIpatch(rtr2, imframe, PMID, PSIND);

	# push arguments into callee's frame, handle return type
	pushargs(calltype, imframe.d.offset, fi.sig);

	imcall = newi(IMCALL);
	*imcall.s = *imframe.d;
	*imcall.m = *imframe.m;
	*imcall.d = *imframe.s;

	RTIpatch(rtr1, imcall, PDST, PSIND);
	RTIpatch(rtr2, imcall, PMID, PSIND);

	for(n = 0; n < J.nsrc; n++)
		relreg(code.j[J.src[n]].dst);
	relreg(imframe.d);
}

#
# Load-time relocated invokespecial and invokestatic.
#

invokess(calltype: int, mpflag: int)
{
	n: int;
	imframe, imcall: ref Inst;
	cr: ref Creloc;
	frf, frm: ref Freloc;
	fi: ref FieldInfo;

	fi = getfldinfo();
	if(dortload(fi.classname)) {
		rtinvokess(fi, calltype, mpflag);
		return;
	}
	cr = getCreloc(fi.classname);
	# fi.flags set only if fi.classname == this_class
	if(fi.flags & (ACC_PRIVATE | ACC_STATIC)) {
		if(fi.flags & ACC_NATIVE)
			frm = getFreloc(cr, RNP, nil, 0);
		else
			frm = nil;	# frame/call
	} else {
		# force @mp, @np into the list for cr
		getFreloc(cr, RMP, nil, 0);
		getFreloc(cr, RNP, nil, 0);
		frm = getFreloc(cr, fi.fieldname, fi.sig, calltype|mpflag);
	}

	if(frm == nil) {
		imframe = newi(IFRAME);
		addrimm(imframe.s, 0);
	} else {
		imframe = newi(IMFRAME);
		addrsind(imframe.s, Amp, 0);
		addrimm(imframe.m, 0);
		LTIpatch(frm, imframe, PSRC, PSIND);
		frf = getFreloc(cr, fi.fieldname, fi.sig, calltype);
		LTIpatch(frf, imframe, PMID, PIMM);
	}
	addrsind(imframe.d, Afp, getreg(DIS_W));

	# push arguments into callee's frame, handle return type
	pushargs(calltype, imframe.d.offset, fi.sig);

	if(frm == nil) {
		imcall = newi(ICALL);
		addfcpatch(imframe, imcall, fi.fieldname, fi.sig);
	} else {
		imcall = newi(IMCALL);
		*imcall.m = *imframe.m;
		LTIpatch(frf, imcall, PMID, PIMM);
		LTIpatch(frm, imcall, PDST, PSIND);
	}
	*imcall.s = *imframe.d;
	*imcall.d = *imframe.s;

	for(n = 0; n < J.nsrc; n++)
		relreg(code.j[J.src[n]].dst);
	relreg(imframe.d);
}

#
# Load-time relocated invokeinterface.
# Resolve all interfaces at load-time.
#

invokei()
{
	n: int;
	cr: ref Creloc;
	frm, frf, frfi: ref Freloc;
	fi: ref FieldInfo;
	#
	# call Loader.getinterface() with these
	#
	imframe1, imovw1, imovp, imovw2, ilea, imcall1: ref Inst;
	#
	# call interface method with these
	#
	iaddw, imovw3, imframe2, imcall2: ref Inst;

	cr = getCreloc(RLOADER);
	frm = getFreloc(cr, RMP, nil, 0);
	frf = getFreloc(cr, "getinterface", nil, 0);

	# call Loader.getinterface

	imframe1 = loadermframe(frm, frf);

	imovw1 = newi(IMOVW);
	*imovw1.s = *code.j[J.src[0]].dst;	# this pointer
	sind2dind(imovw1.s, 0);
	addrsind(imovw1.d, Afp, getreg(DIS_W));

	imovp = newi(IMOVP);
	*imovp.s = *imovw1.d;
	sind2dind(imovp.s, 4);
	addrdind(imovp.d, Afpind, imframe1.d.offset, REGSIZE);

	imovw2 = newi(IMOVW);
	addrimm(imovw2.s, 0);
	addrdind(imovw2.d, Afpind, imframe1.d.offset, REGSIZE+IBY2WD);

	fi = getfldinfo();
	frfi = getFreloc(getCreloc(fi.classname), fi.fieldname,
		fi.sig, Rinvokeinterface);
	LTIpatch(frfi, imovw2, PSRC, PIMM);

	ilea = newi(ILEA);
	addrsind(ilea.s, Afp, getreg(DIS_W));
	addrdind(ilea.d, Afpind, imframe1.d.offset, REGRET*IBY2WD);

	imcall1 = loadermcall(imframe1, frf, frm);

	# call interface method

	iaddw = newi(IADDW);
	*iaddw.s = *imovw1.d;
	*iaddw.m = *ilea.s;
	*iaddw.d = *imovw1.d;

	imovw3 = newi(IMOVW);
	*imovw3.s = *iaddw.d;
	sind2dind(imovw3.s, 4);
	*imovw3.d = *ilea.s;

	imframe2 = newi(IMFRAME);
	*imframe2.s = *iaddw.d;
	sind2dind(imframe2.s, 0);
	*imframe2.m = *imovw3.d;
	*imframe2.d = *imframe1.d;

	# push arguments into callee's frame, handle return type
	pushargs(Rinvokeinterface, imframe2.d.offset, fi.sig);

	imcall2 = newi(IMCALL);
	*imcall2.s = *imframe2.d;
	*imcall2.m = *imframe2.m;
	*imcall2.d = *imframe2.s;

	for(n = 0; n < J.nsrc; n++)
		relreg(code.j[J.src[n]].dst);
	relreg(imframe1.d);
	relreg(imovw1.d);
	relreg(ilea.s);
}

#
# Run-time relocated invokevirtual.
#

rtinvokev(fi: ref FieldInfo)
{
	n: int;
	iaddw, imovw1, imovw2, imframe, imcall: ref Inst;
	rtc: ref RTClass;

	rtc = getRTClass(fi.classname);
	callrtload(rtc, fi.classname);

	imovw1 = newi(IMOVW);
	*imovw1.s = *code.j[J.src[0]].dst;	# this pointer
	sind2dind(imovw1.s, 0);
	addrsind(imovw1.d, Afp, getreg(DIS_W));

	iaddw = newi(IADDW);
	*iaddw.s = *imovw1.d;
	addrsind(iaddw.m, Amp, 0);
	*iaddw.d = *imovw1.d;

	RTIpatch(getRTReloc(rtc, fi.fieldname, fi.sig, Rinvokevirtual),
		iaddw, PMID, PSIND);

	imovw2 = newi(IMOVW);
	*imovw2.s = *iaddw.d;
	sind2dind(imovw2.s, 4);
	addrsind(imovw2.d, Afp, getreg(DIS_W));

	imframe = newi(IMFRAME);
	*imframe.s = *imovw1.d;
	sind2dind(imframe.s, 0);
	*imframe.m = *imovw2.d;
	addrsind(imframe.d, Afp, getreg(DIS_W));

	# push arguments into callee's frame, handle return type
	pushargs(Rinvokevirtual, imframe.d.offset, fi.sig);

	imcall = newi(IMCALL);
	*imcall.s = *imframe.d;
	*imcall.m = *imframe.m;
	*imcall.d = *imframe.s;

	for(n = 0; n < J.nsrc; n++)
		relreg(code.j[J.src[n]].dst);
	relreg(imovw1.d);
	relreg(imovw2.d);
	relreg(imframe.d);
}

#
# Load-time relocated invokevirtual.
#

invokev()
{
	n: int;
	imovw1, imovw2, imframe, imcall: ref Inst;
	cr: ref Creloc;
	fr: ref Freloc;
	fi: ref FieldInfo;

	fi = getfldinfo();
	if(dortload(fi.classname)) {
		rtinvokev(fi);
		return;
	}
	cr = getCreloc(fi.classname);
	fr = getFreloc(cr, fi.fieldname, fi.sig, Rinvokevirtual);

	imovw1 = newi(IMOVW);
	*imovw1.s = *code.j[J.src[0]].dst;	# this pointer
	sind2dind(imovw1.s, 0);
	addrsind(imovw1.d, Afp, getreg(DIS_W));

	imovw2 = newi(IMOVW);
	*imovw2.s = *imovw1.d;
	sind2dind(imovw2.s, 4);
	addrsind(imovw2.d, Afp, getreg(DIS_W));
	LTIpatch(fr, imovw2, PSRC, PDIND2);

	imframe = newi(IMFRAME);
	*imframe.s = *imovw1.d;
	sind2dind(imframe.s, 0);
	*imframe.m = *imovw2.d;
	addrsind(imframe.d, Afp, getreg(DIS_W));
	LTIpatch(fr, imframe, PSRC, PDIND2);

	# push arguments into callee's frame, handle return type
	pushargs(Rinvokevirtual, imframe.d.offset, fi.sig);

	imcall = newi(IMCALL);
	*imcall.s = *imframe.d;
	*imcall.m = *imframe.m;
	*imcall.d = *imframe.s;
	LTIpatch(fr, imcall, PDST, PDIND2);

	for(n = 0; n < J.nsrc; n++)
		relreg(code.j[J.src[n]].dst);
	relreg(imovw1.d);
	relreg(imovw2.d);
	relreg(imframe.d);
}

#
# Run-time relocated new.
#

rtnew(fi: ref FieldInfo)
{
	i1, i2: ref Inst;
	rtc: ref RTClass;
	rtr: ref RTReloc;

	rtc = getRTClass(fi.classname);
	callrtload(rtc, fi.classname);

	i1 = newi(IMNEWZ);
	addrsind(i1.s, Amp, 0);
	addrsind(i1.m, Amp, 0);
	dstreg(J.dst, DIS_P);
	*i1.d = *J.dst;

	rtr = getRTReloc(rtc, RCLASS, nil, 0);
	RTIpatch(rtr, i1, PMID, PSIND);
	rtr = getRTReloc(rtc, RMP, nil, 0);
	RTIpatch(rtr, i1, PSRC, PSIND);

	i2 = newi(IMOVP);
	addrdind(i2.s, Ampind, 0, 0);
	*i2.d = *i1.d;
	sind2dind(i2.d, 0);

	RTIpatch(rtr, i2, PSRC, PDIND1);
}

#
# Load-time relocated new.
#

xjavanew(name: string, a: ref Addr)
{
	i1, i2: ref Inst;
	cr: ref Creloc;
	frc, frm: ref Freloc;
	fi: ref FieldInfo;

	if(dortload(name)) {
		fi = ref FieldInfo(name, nil, nil, 0);
		rtnew(fi);
		return;
	}
	cr = getCreloc(name);
	frc = getFreloc(cr, RCLASS, nil, 0);
	frm = getFreloc(cr, RMP, nil, 0);

	if(name == THISCLASS) {
		i1 = newi(INEWZ);
		addrimm(i1.s, 0);
		LTIpatch(frc, i1, PSRC, PIMM);
	} else {
		i1 = newi(IMNEWZ);
		addrsind(i1.s, Amp, 0);
		LTIpatch(frm, i1, PSRC, PSIND);
		addrimm(i1.m, 0);
		LTIpatch(frc, i1, PMID, PIMM);
	}
	dstreg(a, DIS_P);
	*i1.d = *a;

	i2 = newi(IMOVP);
	addrdind(i2.s, Ampind, 0, 0);
	LTIpatch(frm, i2, PSRC, PDIND1);
	*i2.d = *i1.d;
	sind2dind(i2.d, 0);
}

#
# Java newarray
#

newarray()
{
	i: ref Inst;
	n, tid: int;
	ix: int;

	pick jp := J {
	Pi =>
		ix = jp.i;
	* =>
		badpick("newarray");
	}

	case ix {
	T_BOOLEAN or
	T_BYTE =>
		n = 1;
	T_CHAR or
	T_SHORT or
	T_INT =>
		n = IBY2WD;
	T_LONG or
	T_FLOAT or
	T_DOUBLE =>
		n = IBY2LG;
	}
	if(n == 1)
		tid = descid(n, 0, array [1] of { byte 0 });
	else
		tid = descid(n, 1, array [1] of { byte 0 });

	xjavanew("inferno/vm/Array", J.dst);
	i = newi(INEWAZ);
	*i.s = *code.j[J.src[0]].dst;
	relreg(code.j[J.src[0]].dst);
	addrimm(i.m, tid);
	*i.d = *J.dst;
	sind2dind(i.d, ARY_DATA);
	datareloc(i);

	i = newi(IMOVW);
	addrimm(i.s, 1);
	*i.d = *J.dst;
	sind2dind(i.d, ARY_NDIM);

	i = newi(IMOVW);
	addrimm(i.s, ix);
	*i.d = *J.dst;
	sind2dind(i.d, ARY_ETYPE);
}

ArrayInfo: adt {
	ndim:	int;		# number of dimensions
	etype:	int;		# element type code (if primitive)
	ename:	string;		# element type name (if non-primitive)
};

#
# Glean array information.  s may name a Class, Interface, or Array type.
# Used by xanewarray, xmultianewarray, checkcast, instanceof.
#

getaryinfo(s: string): ref ArrayInfo
{
	n: int;
	ai: ref ArrayInfo = ref ArrayInfo(0, 0, nil);

	while(s[0] == '[') {
		ai.ndim++;
		s = s[1:];
	}

	if(ai.ndim > 0) {
		case s[0] {
		'Z' =>
			ai.etype = T_BOOLEAN;
		'B' =>
			ai.etype = T_BYTE;
		'C' =>
			ai.etype = T_CHAR;
		'S' =>
			ai.etype = T_SHORT;
		'I' =>
			ai.etype = T_INT;
		'F' =>
			ai.etype = T_FLOAT;
		'J' =>
			ai.etype = T_LONG;
		'D' =>
			ai.etype = T_DOUBLE;
		'L' =>
			;	# ai.etype = 0;	# above
		}
	}
	if(ai.etype == 0) {
		n = len s + 1;
		if(ai.ndim > 0) {	# e.g., s == "LX.Y.Z;"
			s = s[1:];
			n -= 2;
		}
		ai.ename = s[0:n-1];
	}
	return ai;
}

#
# Java anewarray
#

xanewarray()
{
	i: ref Inst;
	rtflag: int;
	rtc: ref RTClass;
	ai: ref ArrayInfo;
	ix: int;

	pick jp := J {
	Pi =>
		ix = jp.i;
	* =>
		badpick("xanewarray");
	}

	ai = getaryinfo(CLASSNAME(ix));
	rtflag = 0;
	if(dortload(ai.ename)) {
		rtflag = 1;
		rtc = getRTClass(ai.ename);
		callrtload(rtc, ai.ename);
	}

	xjavanew("inferno/vm/Array", J.dst);
	i = newi(INEWA);
	*i.s = *code.j[J.src[0]].dst;
	relreg(code.j[J.src[0]].dst);
	addrimm(i.m, descid(IBY2WD, 1, array [1] of { byte 16r80 }));
	*i.d = *J.dst;
	sind2dind(i.d, ARY_DATA);
	datareloc(i);

	i = newi(IMOVW);
	addrimm(i.s, ai.ndim+1);
	*i.d = *J.dst;
	sind2dind(i.d, ARY_NDIM);

	if(ai.etype == 0) {
		i = newi(IMOVP);
		addrsind(i.s, Amp, 0);
		if(rtflag == 1) {
			RTIpatch(getRTReloc(rtc, RADT, nil, 0), i, PSRC, PSIND);
		} else {
			LTIpatch(getFreloc(getCreloc(ai.ename), RADT, nil, 0),
				i, PSRC, PSIND);
		}
		*i.d = *J.dst;
		sind2dind(i.d, ARY_ADT);
	} else {
		i = newi(IMOVW);
		addrimm(i.s, ai.etype);
		*i.d = *J.dst;
		sind2dind(i.d, ARY_ETYPE);
	}
}

#
# Java multianewarray
#

xmultianewarray()
{
	imframe, iindw, i: ref Inst;
	n, rtflag: int;
	rtc: ref RTClass;
	cr: ref Creloc;
	frm, frf: ref Freloc;
	ai: ref ArrayInfo;
	jpx2d: ref Jinst.Px2d;

	pick jp := J {
	Px2d =>
		jpx2d = jp;
	* =>
		badpick("xmultianewarray");
	}

	ai = getaryinfo(CLASSNAME(jpx2d.x2d.ix));
	rtflag = 0;
	if(dortload(ai.ename)) {
		rtflag = 1;
		rtc = getRTClass(ai.ename);
		callrtload(rtc, ai.ename);
	}

	cr = getCreloc(RLOADER);
	frm = getFreloc(cr, RMP, nil, 0);
	frf = getFreloc(cr, "multianewarray", nil, 0);

	imframe = loadermframe(frm, frf);

	# 1st arg: number of dimensions

	i = newi(IMOVW);
	addrimm(i.s, ai.ndim);
	addrdind(i.d, Afpind, imframe.d.offset, REGSIZE);

	# 2nd arg: @adt reloc if ref element type, nil otherwise

	i = newi(IMOVP);
	addrsind(i.s, Amp, 0);
	if(ai.etype == 0) {
		if(rtflag == 1) {
			RTIpatch(getRTReloc(rtc, RADT, nil, 0), i, PSRC, PSIND);
		} else {
			LTIpatch(getFreloc(getCreloc(ai.ename), RADT, nil, 0),
				i, PSRC, PSIND);
		}
	}
	addrdind(i.d, Afpind, imframe.d.offset, REGSIZE+IBY2WD);

	# 3rd arg: element type

	i = newi(IMOVW);
	addrimm(i.s, ai.etype);
	addrdind(i.d, Afpind, imframe.d.offset, REGSIZE+2*IBY2WD);

	# 4th arg: array of dimensionality information

	i = newi(INEWA);
	addrimm(i.s, jpx2d.x2d.dim);
	addrimm(i.m, descid(IBY2WD, 1, array [1] of { byte 0 }));
	addrdind(i.d, Afpind, imframe.d.offset, REGSIZE+3*IBY2WD);

	iindw = newi(IINDW);
	addrdind(iindw.s, Afpind, imframe.d.offset, REGSIZE+3*IBY2WD);
	addrsind(iindw.m, Afp, getreg(DIS_W));
	addrimm(iindw.d, 0);

	for(n = 0; n < jpx2d.x2d.dim; n++) {
		i = newi(IMOVW);
		*i.s = *code.j[J.src[n]].dst;
		relreg(code.j[J.src[n]].dst);
		*i.d = *iindw.m;
		sind2dind(i.d, n*IBY2WD);
	}
	relreg(iindw.m);

	i = newi(ILEA);
	dstreg(J.dst, DIS_P);
	*i.s = *J.dst;
	addrdind(i.d, Afpind, imframe.d.offset, REGRET*IBY2WD);

	loadermcall(imframe, frf, frm);
	relreg(imframe.d);
}

arraylength()
{
	i: ref Inst;

	i = newi(ILENA);
	*i.s = *code.j[J.src[0]].dst;
	relreg(code.j[J.src[0]].dst);
	sind2dind(i.s, ARY_DATA);
	dstreg(J.dst, DIS_W);
	*i.d = *J.dst;
}

arrayindex(index: int): ref Addr
{
	i: ref Inst;

	i = newi(index);
	*i.s = *code.j[J.src[0]].dst;
	relreg(code.j[J.src[0]].dst);
	sind2dind(i.s, ARY_DATA);
	*i.d = *code.j[J.src[1]].dst;
	relreg(code.j[J.src[1]].dst);
	addrsind(i.m, Afp, getreg(DIS_W));

	return i.m;
}

#
# Load an array element.
#

xarrayload(inst1: int, inst2: int, dtype: byte)
{
	a: ref Addr;
	i: ref Inst;

	a = arrayindex(inst1);
	i = newi(inst2);
	*i.s = *a;
	sind2dind(i.s, 0);
	relreg(a);
	dstreg(J.dst, dtype);
	*i.d = *J.dst;
	if(inst2 == ICVTBW)	# loading from a byte array
		signextend(i.d);
}

#
# Call Loader.aastorecheck() to do runtime checks for aastore.
#

aastore()
{
	imframe, imovp, imcall: ref Inst;
	cr: ref Creloc;
	frm, frf: ref Freloc;

	cr = getCreloc(RLOADER);
	frm = getFreloc(cr, RMP, nil, 0);
	frf = getFreloc(cr, "aastorecheck", nil, 0);

	imframe = loadermframe(frm, frf);

	imovp = newi(IMOVP);
	*imovp.s = *code.j[J.src[2]].dst;
	addrdind(imovp.d, Afpind, imframe.d.offset, REGSIZE);

	imovp = newi(IMOVP);
	*imovp.s = *code.j[J.src[0]].dst;
	addrdind(imovp.d, Afpind, imframe.d.offset, REGSIZE+IBY2WD);

	imcall = loadermcall(imframe, frf, frm);
	relreg(imframe.d);
}

#
# Store an array element.
#

xarraystore(inst1: int, inst2: int)
{
	a: ref Addr;
	i: ref Inst;

	a = arrayindex(inst1);
	i = newi(inst2);
	*i.s = *code.j[J.src[2]].dst;
	relreg(code.j[J.src[2]].dst);
	*i.d = *a;
	sind2dind(i.d, 0);
	relreg(a);
	datareloc(i);
}

#
# monitorenter, monitorexit, athrow.  Also used for synchronized methods.
#

mon_or_throw(op: int, flags: int, syncblock: int)
{
	loaderfn: string;
	imframe, i: ref Inst;
	cr: ref Creloc;
	frm, frf, fro: ref Freloc;

	case op {
	Jathrow =>
		loaderfn = "throw";
	Jmonitorenter =>
		loaderfn = "monitorenter";
	Jmonitorexit =>
		loaderfn = "monitorexit";
	}

	cr = getCreloc(RLOADER);
	frm = getFreloc(cr, RMP, nil, 0);
	frf = getFreloc(cr, loaderfn, nil, 0);

	imframe = loadermframe(frm, frf);

	i = newi(IMOVP);
	if(op == Jathrow || syncblock) {	# throw or synchronized block
		*i.s = *code.j[J.src[0]].dst;
		relreg(code.j[J.src[0]].dst);
	} else if(flags & ACC_STATIC) { 	# synchronized class method
		addrsind(i.s, Amp, 0);
		fro = getFreloc(getCreloc(THISCLASS), ROBJ, nil, 0);
		LTIpatch(fro, i, PSRC, PSIND);
	} else					# synchronized instance method
		addrsind(i.s, Afp, THISOFF);
	addrdind(i.d, Afpind, imframe.d.offset, REGSIZE);

	loadermcall(imframe, frf, frm);
	relreg(imframe.d);

	# for jit: so mcall has an instruction for its return address
	if(op == Jathrow && J.pc+1 == code.code_length) {
		i = newi(IJMP);
		addrimm(i.d, 0);
	}
}

xjavaload(op: int)
{
	i: ref Inst;

	if(J.movsrc.mode != Anone) {	# marked for explicit mov
		i = newi(op);
		*i.s = *J.movsrc;
		dstreg(J.dst, j2dtype(J.jtype));
		*i.d = *J.dst;
		datareloc(i);
	}
}

xjavastore(op: int)
{
	i: ref Inst;

	if(op == IMOVP && J.bb.js == J && int (J.bb.flags & BB_FINALLY))
		print("[The voice of Translator] removed some MOV at %d\n", op); # astore instruction at the start of a finally block
	else if(J.dst.mode != Anone) {	# marked for explicit mov
		i = newi(op);
		*i.s = *code.j[J.src[0]].dst;
		relreg(code.j[J.src[0]].dst);
		*i.d = *J.dst;
		datareloc(i);
	}
}

#
# Check immediate middle operands that are too big.
#

midcheck(a: ref Addr)
{
	if(a.mode == Aimm && (a.ival > 16r7fff || a.ival < -16r8000)) {
		a.mode = Amp;
		a.offset = mpint(a.ival);
	}
}

#
# Coerce a 64-bit real to a 32-bit real (and back).
#

real64to32(a: ref Addr)
{
	i1, i2: ref Inst;

	i1 = newi(ICVTFR);
	*i1.s = *a;
	addrsind(i1.d, Afp, getreg(DIS_W));

	i2 = newi(ICVTRF);
	*i2.s = *i1.d;
	*i2.d = *i1.s;

	relreg(i1.d);
}

xbinop(op: int, dtype: byte, cvtreal: int)
{
	i: ref Inst;

	i = newi(op);
	*i.s = *code.j[J.src[1]].dst;
	relreg(code.j[J.src[1]].dst);
	*i.m = *code.j[J.src[0]].dst;
	relreg(code.j[J.src[0]].dst);
	midcheck(i.m);
	dstreg(J.dst, dtype);
	*i.d = *J.dst;
	middstcmp(i);
	datareloc(i);

	if(cvtreal)
		real64to32(i.d);
}

shift(op: int, dtype: byte)
{
	iaddw, i: ref Inst;

	iaddw = newi(IANDW);
	*iaddw.s = *code.j[J.src[1]].dst;
	relreg(code.j[J.src[1]].dst);
	if(dtype == DIS_W)	# ishl, ishr, iushr
		addrimm(iaddw.m, 31);
	else			# lshl, lshr, lushr
		addrimm(iaddw.m, 63);
	addrsind(iaddw.d, Afp, getreg(DIS_W));
	datareloc(iaddw);

	i = newi(op);
	*i.s = *iaddw.d;
	relreg(iaddw.d);
	*i.m = *code.j[J.src[0]].dst;
	relreg(code.j[J.src[0]].dst);
	midcheck(i.m);
	dstreg(J.dst, dtype);
	*i.d = *J.dst;
	middstcmp(i);
	datareloc(i);
}

cvt(op: int, dtype: byte, cvtreal: int)
{
	i: ref Inst;

	i = newi(op);
	*i.s = *code.j[J.src[0]].dst;
	relreg(code.j[J.src[0]].dst);
	dstreg(J.dst, dtype);
	*i.d = *J.dst;
	datareloc(i);

	if(cvtreal)
		real64to32(i.d);
}

i2c()
{
	i: ref Inst;

	i = newi(IANDW);
	*i.s = *code.j[J.src[0]].dst;
	relreg(code.j[J.src[0]].dst);
	addrsind(i.m, Amp, mpint(16rffff));
	dstreg(J.dst, DIS_W);
	*i.d = *J.dst;
	datareloc(i);
}

#
# i2b, i2s.
#

i2bs(shift: int)
{
	i1, i2: ref Inst;

	i1 = newi(ISHLW);
	addrimm(i1.s, shift);
	*i1.m = *code.j[J.src[0]].dst;
	relreg(code.j[J.src[0]].dst);
	midcheck(i1.m);
	dstreg(J.dst, DIS_W);
	*i1.d = *J.dst;
	middstcmp(i1);
	datareloc(i1);

	i2 = newi(ISHRW);
	addrimm(i2.s, shift);
	# *i2.m = *i1.d; # redundant
	*i2.d = *i1.d;
}

#
# ineg, lneg, fneg, dneg
#

neg(op: int, dtype: byte)
{
	i: ref Inst;

	i = newi(op);
	*i.s = *code.j[J.src[0]].dst;
	relreg(code.j[J.src[0]].dst);
	if(op == ISUBW)		# ineg
		addrimm(i.m, 0);
	else if(op == ISUBL)	# lneg
		addrsind(i.m, Amp, mplong(big 0));
	dstreg(J.dst, dtype);
	*i.d = *J.dst;
	datareloc(i);
}

iinc(val: int, ix: int)
{
	i: ref Inst;

	i = newi(IADDW);
	addrimm(i.s, val);
	addrsind(i.d, Afp, localix(DIS_W, ix));
}

#
# For javaif and javagoto, compute difference of try nesting
# level between source PC and destination PC.
#   J.pc is source PC
#   J.u.i is destination PC (relative from J.pc)
#

#tldiff(): int
#{
#	tls, tld: int;
#	ix: int;
#
#	pick jp := J {
#	Pi =>
#		ix = jp.i;
#	* =>
#		badpick("tldiff");
#	}
#
#	tld = 0;
#	tls = trylevel(J.pc);
#	if(tls > 0)
#		tld = trylevel(J.pc+ix);
#	return tls-tld;
#}

#
# Java if_acmp<cond>, if_icmp<cond>, if<cond>, ifnonnull, ifnull.
#

CMPNULL,		# compare against null: ifnonnull, ifnull
CMPZERO,		# compare against 0: if<cond>
CMP2OP:	con iota;	# general compare: if_acmp<cond>, if_icmp<cond>

javaif(op: int, cmpkind: int)
{
	i: ref Inst;
	n: int;
	ix: int;

	pick jp := J {
	Pi =>
		ix = jp.i;
	* =>
		badpick("javaif");
	}

	#n = tldiff();
	#if(n > 0) {
	#	# complement the test when calling Sys.unrescue()
	#	case op {
	#	IBEQW =>
	#		op = IBNEW;
	#	IBNEW =>
	#		op = IBEQW;
	#	IBLTW =>
	#		op = IBGEW;
	#	IBLEW =>
	#		op = IBGTW;
	#	IBGTW =>
	#		op = IBLEW;
	#	IBGEW =>
	#		op = IBLTW;
	#	}
	#	i = newi(op);
	#	addrimm(i.d, pcdis + 2*n + 1);
	#} else {
		i = newibap(op);
		addrimm(i.d, ix);
	#}

	*i.s = *code.j[J.src[0]].dst;
	relreg(code.j[J.src[0]].dst);

	case cmpkind {
	CMPNULL =>
		addrsind(i.m, Amp, 0);
	CMPZERO =>
		addrimm(i.m, 0);
		datareloc(i);
	CMP2OP =>
		*i.m = *code.j[J.src[1]].dst;
		relreg(code.j[J.src[1]].dst);
		midcheck(i.m);
		datareloc(i);
	}

	#if(n > 0) {
	#	unrescue(n);
	#	callunrescue = 0;
	#	i = newibap(IJMP);
	#	addrimm(i.d, ix);
	#}
}

#
# Java goto and goto_w.
#

javagoto()
{
	i: ref Inst;
	n: int;
	ix: int;

	pick jp := J {
	Pi =>
		ix = jp.i;
	* =>
		badpick("javagoto");
	}

	#n = tldiff();
	#if(n > 0) {
	#	unrescue(n);
	#	callunrescue = 0;
	#}
	i = newibap(IJMP);
	addrimm(i.d, ix);
}

#
# Java return instructions.
#

xjavareturn(op: int)
{
	i: ref Inst;

	if(op != 0) {		# if op == 0, then return void
		i = newi(op);
		*i.s = *code.j[J.src[0]].dst;
		relreg(code.j[J.src[0]].dst);
		addrdind(i.d, Afpind, REGRET*IBY2WD, 0);
		datareloc(i);
	}

	if(M.access_flags & ACC_SYNCHRONIZED)
		mon_or_throw(Jmonitorexit, M.access_flags, 0);

	newi(IRET);
}

#
# pop & pop2
#

xjavapop()
{
	relreg(code.j[J.src[0]].dst);
	if(J.nsrc == 2)	# pop2
		relreg(code.j[J.src[1]].dst);
}

#
# dup, dup2, etc.
#

xjavadup()
{
	acqreg(code.j[J.src[0]].dst);
	if(J.nsrc == 2)
		acqreg(code.j[J.src[1]].dst);
}

xgetclass(a: ref Addr, class: int)
{
	imframe, iindw, i: ref Inst;
	n, rtflag: int;
	rtc: ref RTClass;
	cr: ref Creloc;
	frm, frf: ref Freloc;
	ai: ref ArrayInfo;

	# Ensure that Class is loaded
	rtc = getRTClass(RCLASSCLASS);
	callrtload(rtc, RCLASSCLASS);

	cr = getCreloc(RLOADER);
	frm = getFreloc(cr, RMP, nil, 0);
	frf = getFreloc(cr, "getclassclass", nil, 0);

	imframe = loadermframe(frm, frf);

	# 1st arg: our name

	i = newi(IMOVP);
	addrsind(i.s, Amp, mpstring(THISCLASS));
	addrdind(i.d, Afpind, imframe.d.offset, REGSIZE);
	datareloc(i);

	# 2nd arg: the name of Class to load

	i = newi(IMOVP);
	addrsind(i.s, Amp, mpstring(CLASSNAME(class)));
	addrdind(i.d, Afpind, imframe.d.offset, REGSIZE+IBY2WD);
	datareloc(i);

	# Result: Class object pointer

	i = newi(ILEA);
	dstreg(J.dst, DIS_P);
	*i.s = *J.dst;
	addrdind(i.d, Afpind, imframe.d.offset, REGRET*IBY2WD);

	loadermcall(imframe, frf, frm);
	relreg(imframe.d);
}

xldc()
{
	i: ref Inst;
	ix: int;

	pick jp := J {
	Pi =>
		ix = jp.i;
	* =>
		badpick("xldc[1]");
	}

	case int class.cts[ix] {
	CON_Integer =>
		xjavaload(IMOVW);
	CON_Float or
	CON_Double =>
		xjavaload(IMOVF);
	CON_Long =>
		xjavaload(IMOVL);
	CON_String =>
		xjavanew("java/lang/String", J.dst);
		i = newi(IMOVP);
		*i.s = *J.movsrc;
		*i.d = *J.dst;
		sind2dind(i.d, STR_DISSTR);
		addDreloc(i, PSRC, PSIND);
	CON_Class =>
		# TODO: stub!
		#xjavanew("java/lang/String", J.dst);
		#i = newi(IMOVP);
		#*i.s = *J.movsrc;
		#*i.d = *J.dst;
		#sind2dind(i.d, STR_DISSTR);
		#addDreloc(i, PSRC, PSIND);
		xgetclass(J.dst, ix);
	* =>
		badpick("xldc[2]");
	}
}

#
# Java jsr and jsr_w.
# ix is relative Java pc offset of finally block entry point.
#

jsr(ix: int)
{
	i: ref Inst;

	i = newi(IMOVW);
	addrimm(i.s, 0);
	addrsind(i.d, Amp, 0);
	jsrfixup(i.s, i.d, i.pc+2, J.pc+ix);
	addDreloc(i, PDST, PSIND);

	i = newibap(IJMP);
	addrimm(i.d, ix);
}

#
# Java ret and wide ret.
#

ret()
{
	i: ref Inst;

	i = newi(IGOTO);
	addrsind(i.s, Amp, 0);
	addrsind(i.d, Amp, 0);
	retfixup(i.s, i.d, J.pc);
	addDreloc(i, PSRC, PSIND);
	addDreloc(i, PDST, PSIND);
}

tableswitch()
{
	i: ref Inst;
	j, k, n, lb: int;
	jt: array of int;
	jpt1: ref Jinst.Pt1;

	pick jp := J {
	Pt1 =>
		jpt1 = jp;
	* =>
		badpick("tableswitch");
	}

	n = jpt1.t1.hb - jpt1.t1.lb + 1;
	jt = array [n*3+1] of int;
	j = 0;
	k = 0;
	lb = jpt1.t1.lb;
	while(j < n) {
		jt[k++] = lb;
		jt[k++] = ++lb;
		jt[k++] = jpt1.t1.tbl[j];
		j++;
	}
	jt[k] = jpt1.t1.dflt;
	i = newi(ICASE);
	*i.s = *code.j[J.src[0]].dst;
	relreg(code.j[J.src[0]].dst);
	addrsind(i.d, Amp, mpcase(n, jt));
	patchcase(i, n, jt);
	addDreloc(i, PDST, PSIND);
}

lookupswitch()
{
	i: ref Inst;
	j, k: int;
	jt: array of int;
	jpt2: ref Jinst.Pt2;

	pick jp := J {
	Pt2 =>
		jpt2 = jp;
	* =>
		badpick("lookupswitch");
	}

	jt = array [jpt2.t2.np*3+1] of int;
	j = 0;
	k = 0;
	while(j < jpt2.t2.np*2) {
		jt[k++] = jpt2.t2.tbl[j];
		jt[k++] = jpt2.t2.tbl[j]+1;
		jt[k++] = jpt2.t2.tbl[j+1];
		j += 2;
	}
	jt[k] = jpt2.t2.dflt;
	i = newi(ICASE);
	*i.s = *code.j[J.src[0]].dst;
	relreg(code.j[J.src[0]].dst);
	addrsind(i.d, Amp, mpcase(jpt2.t2.np, jt));
	patchcase(i, jpt2.t2.np, jt);
	addDreloc(i, PDST, PSIND);
}

#
# Call a library routine.  Supports lcmp, [df]cmp[gl], [df]rem.
#

jmath(jname: string, movinst: int, dtype: byte)
{
	imframe, i: ref Inst;
	cr: ref Creloc;
	frm, frf: ref Freloc;

	cr = getCreloc(RLOADER);
	frm = getFreloc(cr, RMP, nil, 0);
	frf = getFreloc(cr, jname, nil, 0);

	imframe = loadermframe(frm, frf);

	i = newi(movinst);
	*i.s = *code.j[J.src[0]].dst;
	relreg(code.j[J.src[0]].dst);
	addrdind(i.d, Afpind, imframe.d.offset, REGSIZE);
	datareloc(i);

	if(jname[1] != '2') {	# d2i or d2l ?
		i = newi(movinst);
		*i.s = *code.j[J.src[1]].dst;
		relreg(code.j[J.src[1]].dst);
		addrdind(i.d, Afpind, imframe.d.offset, REGSIZE+IBY2LG);
		datareloc(i);
	}

	i = newi(ILEA);
	dstreg(J.dst, dtype);
	*i.s = *J.dst;
	addrdind(i.d, Afpind, imframe.d.offset, REGRET*IBY2WD);

	loadermcall(imframe, frf, frm);
	relreg(imframe.d);
}

#
# checkcast & instanceof
#

rtti()
{
	loaderfn: string;
	imframe, i: ref Inst;
	rtflag: int;
	rtc: ref RTClass;
	cr: ref Creloc;
	frm, frf: ref Freloc;
	ai: ref ArrayInfo;
	ix: int;

	pick jp := J {
	Pi =>
		ix = jp.i;
	* =>
		badpick("rtti");
	}

	ai = getaryinfo(CLASSNAME(ix));
	rtflag = 0;
	if(dortload(ai.ename)) {
		rtflag = 1;
		rtc = getRTClass(ai.ename);
		callrtload(rtc, ai.ename);
	}

	if(J.op == byte Jcheckcast) {
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

	# pass object as first argument

	i = newi(IMOVP);
	*i.s = *code.j[J.src[0]].dst;
	addrdind(i.d, Afpind, imframe.d.offset, REGSIZE);

	# second argument

	if(ai.etype == 0) {
		i = newi(IMOVP);
		addrsind(i.s, Amp, 0);
		if(rtflag == 1) {
			RTIpatch(getRTReloc(rtc, RADT, nil, 0), i, PSRC, PSIND);
		} else {
			LTIpatch(getFreloc(getCreloc(ai.ename), RADT, nil, 0),
				i, PSRC, PSIND);
		}
	} else {
		i = newi(IMOVW);
		addrimm(i.s, ai.etype);
	}
	addrdind(i.d, Afpind, imframe.d.offset, REGSIZE+IBY2WD);

	# third argument, if present

	if(ai.ndim > 0) {
		i = newi(IMOVW);
		addrimm(i.s, ai.ndim);
		addrdind(i.d, Afpind, imframe.d.offset, REGSIZE+2*IBY2WD);
	}

	if(J.op == byte Jinstanceof) {
		i = newi(ILEA);
		dstreg(J.dst, DIS_W);
		*i.s = *J.dst;
		addrdind(i.d, Afpind, imframe.d.offset, REGRET*IBY2WD);
	}

	loadermcall(imframe, frf, frm);
	relreg(imframe.d);

	if(J.op == byte Jcheckcast) {
		i = newi(IMOVP);
		*i.s = *code.j[J.src[0]].dst;
		relreg(code.j[J.src[0]].dst);
		dstreg(J.dst, DIS_P);
		*i.d = *J.dst;
		datareloc(i);
	} else
		relreg(code.j[J.src[0]].dst);
}

#
# Exception handling.
#

Catch: adt {
	exname:		string;
	handler_pc:	int;
	next:		cyclic ref Catch;
};

Try: adt {
	start_pc:	int;
	end_pc:		int;
	any_pc:		int;
	catch:		ref Catch;
	next:		cyclic ref Try;
};

EHInst: adt {
	i:		ref Inst;
	next:		cyclic ref EHInst;
};

ehinst:		ref EHInst;
trylist:	ref Try;
distrylist:	ref Try;

#
# Dis pc by jinst index
#

instpc(jix: int): int
{
	j := code.j[jix];
	while(j.dis == nil) {
		jix += j.size;
		j = code.j[jix];
	}
	return j.dis.pc;
}

#
# Save an EH branch instruction for later patching.
#

saveehinst(i: ref Inst)
{
	ehi: ref EHInst;

	ehi = ref EHInst(i, ehinst);
	ehinst = ehi;
}

#
# Patch an EH branch instruction.
# Java PCs in exception tables are absolute, not relative.
#

patchehinst()
{
	for(ehi := ehinst; ehi != nil; ehi = ehi.next)
		ehi.i.d.ival = instpc(ehi.i.d.ival);
	ehinst = nil;
}

#
# Convert handler information into a more convenient form.
#

cvtehinfo()
{
	i: int;
	t: ref Try;
	c: ref Catch;
	h: ref Handler;

	if(code.nex == 0)
		return;

	# process in reverse to maintain order of try & catch blocks
	for(i = code.nex-1; i >= 0; i--) {
		h = code.ex[i];
		if(trylist == nil
		|| (t.start_pc != h.start_pc || t.end_pc != h.end_pc)) {
			t = ref Try(h.start_pc, h.end_pc, 0, nil, trylist);
			trylist = t;
		}
		if(h.catch_type == 0) {
			t.any_pc = h.handler_pc;
		} else {
			c = ref Catch(CLASSNAME(h.catch_type), h.handler_pc, t.catch);
			t.catch = c;
		}
	}
}

#
# At what try nesting level is the given Java pc at.
# 0 means not within a try block.
#

trylevel(pc: int): int
{
	level: int;
	t: ref Try;

	level = 0;
	for(t = trylist; t != nil; t = t.next) {
		if(pc >= t.start_pc && pc < t.end_pc)
			level += 1;
	}
	return level;
}

#
# Current handler doesn't catch current exception.
# Call raise to propagate (rethrow) the exception.
#

rethrow(): ref Inst
{
	print("rethrow()\n");
	i: ref Inst;

	# FIXME: is that needed?
	#if(M.access_flags & ACC_SYNCHRONIZED && trylevel(J.pc) == 1)
	#	mon_or_throw(Jmonitorexit, M.access_flags, 0);

	i = newi(IRAISE);
	addrsind(i.s, Afp, EXSTR);

	return i;
}

#
# Retrieve thrown object prior to jumping to exception handler.
#

catch()
{
	print("catch()\n");
	imframe, i: ref Inst;
	cr: ref Creloc;
	frm, frf: ref Freloc;

	cr = getCreloc(RLOADER);
	frm = getFreloc(cr, RMP, nil, 0);
	frf = getFreloc(cr, "culprit", nil, 0);

	imframe = loadermframe(frm, frf);

	i = newi(IMOVP);
	addrsind(i.s, Afp, EXSTR);
	addrdind(i.d, Afpind, imframe.d.offset, REGSIZE);

	i = newi(ILEA);
	addrsind(i.s, Afp, EXOBJ);	# put in known location
	addrdind(i.d, Afpind, imframe.d.offset, REGRET*IBY2WD);

	loadermcall(imframe, frf, frm);
	relreg(imframe.d);
}

#
# Does thrown object match handler for exception class exname ?
#

chkhandler(exname: string): ref Addr
{
	print("chkhandler()\n");
	imframe, i: ref Inst;
	rtc: ref RTClass;
	cr: ref Creloc;
	frm, frf: ref Freloc;

	rtc = getRTClass(exname);
	callrtload(rtc, exname);

	cr = getCreloc(RLOADER);
	frm = getFreloc(cr, RMP, nil, 0);
	frf = getFreloc(cr, "instanceof", nil, 0);

	imframe = loadermframe(frm, frf);

	i = newi(IMOVP);
	addrsind(i.s, Afp, EXOBJ);
	addrdind(i.d, Afpind, imframe.d.offset, REGSIZE);

	i = newi(IMOVP);
	addrsind(i.s, Amp, 0);
	RTIpatch(getRTReloc(rtc, RADT, nil, 0), i, PSRC, PSIND);
	addrdind(i.d, Afpind, imframe.d.offset, REGSIZE+IBY2WD);

	i = newi(ILEA);
	addrsind(i.s, Afp, getreg(DIS_W));
	addrdind(i.d, Afpind, imframe.d.offset, REGRET*IBY2WD);

	loadermcall(imframe, frf, frm);
	relreg(imframe.d);

	return i.s;
}

#
# Start of a try block.  Install exception handler for try block t.
#

trystart(t: ref Try)
{
	print("trystart()\n");
	ijmp, i: ref Inst;
	a: ref Addr;
	c: ref Catch;

	# always skip this block in normal flow
	ijmp = newi(IJMP);
	addrimm(ijmp.d, 0);

	catch();

	for(c = t.catch; c != nil; c = c.next) {
		a = chkhandler(c.exname);
		i = newi(IBEQW);
		*i.s = *a;
		relreg(a);
		addrimm(i.m, 1);
		addrimm(i.d, c.handler_pc);
		saveehinst(i);
	}

	if(t.any_pc > 0) {
		i = newi(IJMP);
		addrimm(i.d, t.any_pc);
		saveehinst(i);
	} else
		i = rethrow();

	ijmp.d.ival = i.pc + 1;
	t.any_pc = ijmp.pc + 1;
	print("Generated handler block at %d - %d\n", ijmp.pc, i.pc);

	#
	# rtload()'s done in handler branch are not valid
	# for normal flow, as they are not executed
	#
	rtncache = 0;
}

#
# At the start or end of a try block ?
#

tryhandling()
{
	for(t := trylist; t != nil; t = t.next) {
		# FIXME
		# > 1 try block can have the same start_pc
		if(t.start_pc == J.pc)
			trystart(t);
	}
}

#
# Generate Dis assembly code for one method.
#

java2dis()
{
	jnext: ref Jinst;
	jix: int;

	jix = 0;
	while(jix < code.code_length) {
		J = code.j[jix];
		J.pcdis = pcdis;
		if(J.bb.js == J) {	# start of a basic block ?
			# ignore unreachable code
			if((J.bb.flags & BB_REACHABLE) == byte 0) {
				jix = J.bb.je.pc + J.bb.je.size;
				continue;
			}
			# initialize fp temporary pool
			clearreg();
			reservereg(J.bb.entrystk, J.bb.entrysz);
			reservereg(J.bb.exitstk, J.bb.exitsz);
			# flush run-time load cache
			rtncache = 0;
		}

		# start of a synchronized method ?
		if(J.pc == 0 && M.access_flags & ACC_SYNCHRONIZED)
			mon_or_throw(Jmonitorenter, M.access_flags, 0);

		tryhandling();

		if(jix+J.size < code.code_length)
			jnext = code.j[jix+J.size];
		else
			jnext = nil;
		# "optimize" loads and stores
		if(jnext != nil && isstore(jnext) && jnext.bb.js != jnext) {
			if(J.dst.mode == Afp && J.dst.offset == -1) {
				*J.dst = *jnext.dst;
				# mark jnext so mov not generated for it
				jnext.dst.mode = Anone;
			} else if(isload(J) && J.movsrc.mode == Anone) {
				*J.movsrc = *J.dst;
				*J.dst = *jnext.dst;
				# mark jnext so mov not generated for it
				jnext.dst.mode = Anone;
			}
		}

		jpi: ref Jinst.Pi;
		jpx1c: ref Jinst.Px1c;
		jpw: ref Jinst.Pw;

		pick jp := J {
		Pi =>
			jpi = jp;
		Px1c =>
			jpx1c = jp;
		Pw =>
			jpw = jp;
		}

		case int J.op {
		Jnop =>
			;
		Jaconst_null =>
			xjavaload(IMOVP);
		Jiconst_m1 or
		Jiconst_0 or
		Jiconst_1 or
		Jiconst_2 or
		Jiconst_3 or
		Jiconst_4 or
		Jiconst_5 or
		Jbipush or
		Jsipush =>
			xjavaload(IMOVW);
		Jlconst_0 or
		Jlconst_1 =>
			xjavaload(IMOVL);
		Jfconst_0 or
		Jdconst_0 or
		Jfconst_1 or
		Jdconst_1 or
		Jfconst_2 =>
			xjavaload(IMOVF);
		Jldc or
		Jldc_w or
		Jldc2_w =>
			xldc();
		Jiload or
		Jiload_0 or
		Jiload_1 or
		Jiload_2 or
		Jiload_3 =>
			xjavaload(IMOVW);
		Jlload or
		Jlload_0 or
		Jlload_1 or
		Jlload_2 or
		Jlload_3 =>
			xjavaload(IMOVL);
		Jfload or
		Jdload or
		Jfload_0 or
		Jdload_0 or
		Jfload_1 or
		Jdload_1 or
		Jfload_2 or
		Jdload_2 or
		Jfload_3 or
		Jdload_3 =>
			xjavaload(IMOVF);
		Jaload or
		Jaload_0 or
		Jaload_1 or
		Jaload_2 or
		Jaload_3 =>
			xjavaload(IMOVP);
		Jbaload =>
			xarrayload(IINDB, ICVTBW, DIS_W);
		Jcaload or
		Jsaload or
		Jiaload =>
			xarrayload(IINDW, IMOVW, DIS_W);
		Jlaload =>
			xarrayload(IINDL, IMOVL, DIS_L);
		Jfaload or
		Jdaload =>
			xarrayload(IINDF, IMOVF, DIS_L);
		Jaaload =>
			xarrayload(IINDX, IMOVP, DIS_P);
		Jistore or
		Jistore_0 or
		Jistore_1 or
		Jistore_2 or
		Jistore_3 =>
			xjavastore(IMOVW);
		Jlstore or
		Jlstore_0 or
		Jlstore_1 or
		Jlstore_2 or
		Jlstore_3 =>
			xjavastore(IMOVL);
		Jfstore or
		Jdstore or
		Jfstore_0 or
		Jdstore_0 or
		Jfstore_1 or
		Jdstore_1 or
		Jfstore_2 or
		Jdstore_2 or
		Jfstore_3 or
		Jdstore_3 =>
			xjavastore(IMOVF);
		Jastore or
		Jastore_0 or
		Jastore_1 or
		Jastore_2 or
		Jastore_3 =>
			xjavastore(IMOVP);
		Jbastore =>
			xarraystore(IINDB, ICVTWB);
		Jcastore or
		Jsastore or
		Jiastore =>
			xarraystore(IINDW, IMOVW);
		Jlastore =>
			xarraystore(IINDL, IMOVL);
		Jfastore or
		Jdastore =>
			xarraystore(IINDF, IMOVF);
		Jaastore =>
			aastore();
			xarraystore(IINDX, IMOVP);
		Jpop or
		Jpop2 =>
			xjavapop();
		Jdup or
		Jdup_x1 or
		Jdup_x2 or
		Jdup2 or
		Jdup2_x1 or
		Jdup2_x2 =>
			xjavadup();
		Jswap =>
			;
		Jiadd =>
			xbinop(IADDW, DIS_W, 0);
		Jisub =>
			xbinop(ISUBW, DIS_W, 0);
		Jimul =>
			xbinop(IMULW, DIS_W, 0);
		Jidiv =>
			xbinop(IDIVW, DIS_W, 0);
		Jishl =>
			shift(ISHLW, DIS_W);
		Jishr =>
			shift(ISHRW, DIS_W);
		Jiushr =>
			shift(ILSRW, DIS_W);
		Jirem =>
			xbinop(IMODW, DIS_W, 0);
		Jiand =>
			xbinop(IANDW, DIS_W, 0);
		Jior =>
			xbinop(IORW, DIS_W, 0);
		Jixor =>
			xbinop(IXORW, DIS_W, 0);
		Jladd =>
			xbinop(IADDL, DIS_L, 0);
		Jlsub =>
			xbinop(ISUBL, DIS_L, 0);
		Jlmul =>
			xbinop(IMULL, DIS_L, 0);
		Jldiv =>
			xbinop(IDIVL, DIS_L, 0);
		Jlrem =>
			xbinop(IMODL, DIS_L, 0);
		Jland =>
			xbinop(IANDL, DIS_L, 0);
		Jlor =>
			xbinop(IORL, DIS_L, 0);
		Jlxor =>
			xbinop(IXORL, DIS_L, 0);
		Jfadd =>
			xbinop(IADDF, DIS_L, 1);
		Jdadd =>
			xbinop(IADDF, DIS_L, 0);
		Jfsub =>
			xbinop(ISUBF, DIS_L, 1);
		Jdsub =>
			xbinop(ISUBF, DIS_L, 0);
		Jfmul =>
			xbinop(IMULF, DIS_L, 1);
		Jdmul =>
			xbinop(IMULF, DIS_L, 0);
		Jfdiv =>
			xbinop(IDIVF, DIS_L, 1);
		Jddiv =>
			xbinop(IDIVF, DIS_L, 0);
		Jfrem or
		Jdrem =>
			jmath("drem", IMOVF, DIS_L);
		Jineg =>
			neg(ISUBW, DIS_W);
		Jlneg =>
			neg(ISUBL, DIS_L);
		Jfneg or
		Jdneg =>
			neg(INEGF, DIS_L);
		Jlshl =>
			shift(ISHLL, DIS_L);
		Jlshr =>
			shift(ISHRL, DIS_L);
		Jlushr =>
			shift(ILSRL, DIS_L);
		Jiinc =>
			iinc(jpx1c.x1c.icon, jpx1c.x1c.ix);
		Ji2l =>
			cvt(ICVTWL, DIS_L, 0);
		Ji2f =>
			cvt(ICVTWF, DIS_L, 1);
		Ji2d =>
			cvt(ICVTWF, DIS_L, 0);
		Jl2i =>
			cvt(ICVTLW, DIS_W, 0);
		Jl2f =>
			cvt(ICVTLF, DIS_L, 1);
		Jl2d =>
			cvt(ICVTLF, DIS_L, 0);
		Jf2i or
		Jd2i =>
			jmath("d2i", IMOVF, DIS_W);
		Jf2l or
		Jd2l =>
			jmath("d2l", IMOVF, DIS_L);
		Jf2d =>
			cvt(IMOVF, DIS_L, 0);
		Jd2f =>
			cvt(IMOVF, DIS_L, 1);
		Ji2b =>
			i2bs(24);
		Ji2c =>
			i2c();
		Ji2s =>
			i2bs(16);
		Jlcmp =>
			jmath("lcmp", IMOVL, DIS_W);
		Jfcmpl or
		Jdcmpl =>
			jmath("dcmpl", IMOVF, DIS_W);
		Jfcmpg or
		Jdcmpg =>
			jmath("dcmpg", IMOVF, DIS_W);
		Jifeq =>
			javaif(IBEQW, CMPZERO);
		Jifne =>
			javaif(IBNEW, CMPZERO);
		Jiflt =>
			javaif(IBLTW, CMPZERO);
		Jifge =>
			javaif(IBGEW, CMPZERO);
		Jifgt =>
			javaif(IBGTW, CMPZERO);
		Jifle =>
			javaif(IBLEW, CMPZERO);
		Jif_acmpeq or
		Jif_icmpeq =>
			javaif(IBEQW, CMP2OP);
		Jif_acmpne or
		Jif_icmpne =>
			javaif(IBNEW, CMP2OP);
		Jif_icmplt =>
			javaif(IBLTW, CMP2OP);
		Jif_icmpge =>
			javaif(IBGEW, CMP2OP);
		Jif_icmpgt =>
			javaif(IBGTW, CMP2OP);
		Jif_icmple =>
			javaif(IBLEW, CMP2OP);
		Jgoto or
		Jgoto_w =>
			javagoto();
		Jjsr or
		Jjsr_w =>
			jsr(jpi.i);
		Jret =>
			ret();
		Jtableswitch =>
			tableswitch();
		Jlookupswitch =>
			lookupswitch();
		Jireturn =>
			xjavareturn(IMOVW);
		Jlreturn =>
			xjavareturn(IMOVL);
		Jfreturn or
		Jdreturn =>
			xjavareturn(IMOVF);
		Jareturn =>
			xjavareturn(IMOVP);
		Jreturn =>
			xjavareturn(0);
		Jgetfield =>
			getfield();
		Jgetstatic =>
			getstatic();
		Jputfield =>
			putfield();
		Jputstatic =>
			putstatic();
		Jinvokevirtual =>
			invokev();
		Jinvokespecial =>
			invokess(Rinvokespecial, Rspecialmp);
		Jinvokestatic =>
			invokess(Rinvokestatic, Rstaticmp);
		Jinvokeinterface =>
			invokei();
		Jxxxunusedxxx =>
			;
		Jnew =>
			xjavanew(CLASSNAME(jpi.i), jpi.dst);
		Jnewarray =>
			newarray();
		Janewarray =>
			xanewarray();
		Jarraylength =>
			arraylength();
		Jcheckcast or
		Jinstanceof =>
			rtti();
		Jathrow or
		Jmonitorenter or
		Jmonitorexit =>
			if(J.op == byte Jathrow
			&& M.access_flags & ACC_SYNCHRONIZED
			&& trylevel(J.pc) == 0) {
				mon_or_throw(Jmonitorexit, M.access_flags, 0);
			}
			mon_or_throw(int J.op, 0, 1);
		Jwide =>
			case int jpw.w.op {
			Jiload =>
				xjavaload(IMOVW);
			Jlload =>
				xjavaload(IMOVL);
			Jfload or
			Jdload =>
				xjavaload(IMOVF);
			Jaload =>
				xjavaload(IMOVP);
			Jistore =>
				xjavastore(IMOVW);
			Jlstore =>
				xjavastore(IMOVL);
			Jfstore or
			Jdstore =>
				xjavastore(IMOVF);
			Jastore =>
				xjavastore(IMOVP);
			Jret =>
				ret();
			Jiinc =>
				iinc(jpw.w.icon, jpw.w.ix);
			}
		Jmultianewarray =>
			xmultianewarray();
		Jifnull =>
			javaif(IBEQW, CMPNULL);
		Jifnonnull =>
			javaif(IBNEW, CMPNULL);
		}
		if(callunrescue == 1) {
			#unrescue(1);
			callunrescue = 0;
		}
		jix += J.size;
	}
	# handle exception handlers
	for(t := trylist; t != nil; t = t.next) {
		# by this time all the needed code is already translated, so we can
		# just convert pc's and prepend the entries to global handlers section
		# the final list will be reverted, and that is what we need
		class.handlers = ref Handler(instpc(t.start_pc), instpc(t.end_pc),
			t.any_pc, 0) :: class.handlers;
	}
	J = nil;
}

#
# If there are exception handlers, then allocate a 'ref Sys->Exception'
# to pass to Sys->rescue() and Loader->culprit().
# Not needed anymore
#

#ref_sys_except()
#{
#	i: ref Inst;
#
#	if(code.nex == 0)
#		return;
#
#	i = newi(INEW);
#	addrimm(i.s, descid(3*IBY2WD, 1, array [1] of { byte 16rc0 }));
#	addrsind(i.d, Afp, REFSYSEX);
#}

#
# Generate initialization code for 'static final' fields that have
# ConstantValue attributes.
#

clinitinits(): ref Inst
{
	movi: int;
	j, ix, offset, value: int;
	sig: string;
	a: ref Addr;
	as: ref Addr;
	fp: ref Field;
	fi: ref FieldInfo;
	i, reti: ref Inst;

	as = ref Addr(Afp, 0, 0);
	fi = ref FieldInfo(THISCLASS, nil, nil, 0);
	reti = nil;

	for(j = 0; j < class.fields_count; j++) {
		fp = class.fields[j];
		if((fp.access_flags & ACC_STATIC) && (ix = CVattrindex(fp))) {
			sig = STRING(fp.sig_index);
			pick cp := class.cps[ix] {
			Ptint =>
				if(cp.tint == 0)
					continue;
				if(sig[0] == 'Z' || sig[0] == 'B')
					movi = ICVTWB;
				else
					movi = IMOVW;
				if(notimmable(cp.tint))
					offset = mpint(cp.tint);
				else {
					offset = -1;
					value = cp.tint;
				}
			Ptvlong =>
				if(cp.tvlong == big 0)
					continue;
				movi = IMOVL;
				offset = mplong(cp.tvlong);
			Ptdouble =>
				if(cp.tdouble == 0.0)
					continue;
				movi = IMOVF;
				offset = mpreal(cp.tdouble);
			Pstring_index =>
				movi = IMOVP;
				offset = mpstring(STRING(cp.string_index));
				break;
			* =>
				badpick("clinitinits");
			}
			fi.fieldname = STRING(fp.name_index);
			fi.sig = sig;
			a = ltstaticadd(fi);
			if(reti == nil)
				reti = itail;
			if(movi == IMOVP) {
				as.offset = -1;
				xjavanew("java/lang/String", as);
				i = newi(IMOVP);
				addrsind(i.s, Amp, offset);
				*i.d = *as;
				sind2dind(i.d, STR_DISSTR);
				addDreloc(i, PSRC, PSIND);
			}
			i = newi(movi);
			if(movi == IMOVP) {
				*i.s = *as;
				relreg(as);
			} else if(offset >= 0) {
				addrsind(i.s, Amp, offset);
				addDreloc(i, PSRC, PSIND);
			} else
				addrimm(i.s, value);
			*i.d = *a;
			sind2dind(i.d, 0);
			relreg(a);
		}
	}
	return reti;
}

#
# Cook up a <clinit> static method.
#

genclinit()
{
	savepc: int;

	savepc = pcdis;
	openframe("()V", ACC_STATIC);
	clinitclone = clinitinits();		# save for -v option
	newi(IRET);
	xtrnlink(closeframe(), savepc, "<clinit>", "()V");
}

#
# Cook up link entry and body for <clone> static method.
#

genclone(): ref Inst
{
	i, clone: ref Inst;
	fr: ref Freloc;

	xtrnlink(descid(40, 2, array [2] of { byte 0, byte 16rc0 }), pcdis, "<clone>", "()V");

	#
	# new    @Class, 36(fp)
	# movmp  0(32(fp)), @Class, 0(36(fp))
	# movp   36(fp), 0(16(fp))
	# ret
	#

	fr = getFreloc(getCreloc(THISCLASS), RCLASS, nil, 0);

	i = newi(INEW);
	addrimm(i.s, 0);
	LTIpatch(fr, i, PSRC, PIMM);
	addrsind(i.d, Afp, 36);
	clone = i;	# save for -v option

	i = newi(IMOVMP);
	addrdind(i.s, Afpind, 32, 0);
	addrimm(i.m, 0);
	LTIpatch(fr, i, PMID, PIMM);
	addrdind(i.d, Afpind, 36, 0);

	i = newi(IMOVP);
	addrsind(i.s, Afp, 36);
	addrdind(i.d, Afpind, 16, 0);

	newi(IRET);

	return clone;
}

#
# Translate the methods in class cl.
#

xlate()
{
	i, j, n: int;
	savepcdis: int;
	a: ref Attr;
	clone: ref Inst;
	m: ref Method;
	name, sig: string;

	n = 0;
	for(i = 0; i < class.methods_count; i++) {
		m = class.methods[i];
		name = STRING(m.name_index);
		pcode[n].name = name;
		sig = STRING(m.sig_index);
		pcode[n].sig = sig;
		for(j = 0; j < m.attr_count; j++) {
			a = m.attr_info[j];
			if(STRING(a.name) == "Code") {
				M = m;
				code = javadas(a);
				pcode[n].code = code;
				cvtehinfo();
				# exception object TODO: needs fix
				addrsind(code.j[code.code_length].dst, Afp, EXOBJ);
				#addrsind(code.j[code.code_length].dst, Afp, 0);
				openframe(sig, m.access_flags&ACC_STATIC);
				savepcdis = pcdis;
				flowgraph();
				simjvm(sig);
				unify();
				J = code.j[0];
				#ref_sys_except();
				if(doclinitinits && name == "<clinit>") {
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
				trylist = nil;
			}
		}
		n += 1;
	}

	if(doclinitinits)
		genclinit();

	if((class.access_flags & (ACC_INTERFACE | ACC_ABSTRACT)) == 0) {
		clone = genclone();
		if(clinitclone == nil)
			clinitclone = clone;
	}
}

#include "java.h"
#include "javaisa.h"

/*
 * "Simulate" the Java VM on a method.
 */

typedef struct Result	Result;

struct Result {
	uchar	jtype;
	int	pc;
};

static	Result	*jvmstack;	/* simulated JVM stack */
static	int	jvmtos;		/* number of items in jvmstack */
static	int	jvmwords;	/* number of words that would be on JVM stack */
static	uchar	rettype;	/* return type of simulated method */

static Result
jvmpop(void)
{
	Result r;

	if(jvmtos == 0)
		goto bad;
	r = jvmstack[--jvmtos];
	if(r.jtype == 'J' || r.jtype == 'D')
		jvmwords -= 2;
	else
		jvmwords -= 1;
	if(jvmwords < 0)
bad:		verifyerrormess("stack underflow");
	return r;
}

static void
jvmpush(Result r)
{
	if(r.jtype == 'J' || r.jtype == 'D')
		jvmwords += 2;
	else
		jvmwords += 1;
	if(jvmwords > code->max_stack)
		verifyerrormess("stack overflow");
	jvmstack[jvmtos++] = r;
}

/*
 * Initialize jvmstack to process basic block bb.
 */

static void
jvminit(BB *bb)
{
	int i;
	Result r;
	StkSnap *s;

	jvmtos = 0;
	jvmwords = 0;
	if(bb->flags & (BB_FINALLY | BB_HANDLER)) {
		r.jtype = 'L';
		r.pc = code->code_length;
		jvmpush(r);	/* push a dummy */
		return;
	}

	/* set jvmstack to bb->entrystk */
	s = bb->entrystk;
	for(i = 0; i < bb->entrysz; i++) {
		r.jtype = s[i].jtype;
		r.pc = s[i].pc[0];
		jvmpush(r);
	}
}

static void
typecheck(Result *r, uchar jtype)
{
	/* assumes 'L' and '[' are interchangeable */
	if(r->jtype != jtype && r->jtype + jtype != 'L' + '[')
		verifyerror(&code->j[r->pc]);
}

static uchar
jvmtype(uchar jtype)
{
	switch(jtype) {
	case 'Z':
	case 'B':
	case 'C':
	case 'S':
		jtype = 'I';
		break;
	}
	return jtype;
}

static void
setresult(Result *r, uchar jtype, Jinst *j)
{
	r->jtype = jtype;
	r->pc = j->pc;
	j->jtype = jtype;
}

static void
srcalloc(Jinst *j, int n)
{
	j->nsrc = n;
	j->src = Malloc(n*sizeof(int));
}

static void
iconst(Jinst *j, int ival)
{
	Result r;

	addrimm(&j->dst, ival);
	setresult(&r, 'I', j);
	jvmpush(r);
}

static void
mpconst(Jinst *j, uchar jtype, int off)
{
	Result r;

	addrsind(&j->dst, Amp, off);
	setresult(&r, jtype, j);
	jvmpush(r);
}

static void
verifyindex(Jinst *j, uchar jtype, int ix)
{
	int n;

	switch(jtype) {
	case 'I':
	case 'F':
	case 'L':
		n = code->max_locals-1;
		break;
	case 'J':
	case 'D':
		n = code->max_locals-2;
		break;
	default:
		fatal("verifyindex: invalid jtype");
		return;
	}
	if(ix > n)
		verifyerror(j);
}

static int
getfpoff(uchar jtype, int ix)
{
	int off;

	switch(jtype) {
	case 'I':
		off = localix(DIS_W, ix);
		break;
	case 'J':
	case 'F':
	case 'D':
		off = localix(DIS_L, ix);
		break;
	case 'L':
		off = localix(DIS_P, ix);
		break;
	default:
		fatal("getfpoff: invalid jtype");
		return -1;
	}
	return off;
}

static void
javaload(Jinst *j, uchar jtype, int ix)
{
	Result r;

	verifyindex(j, jtype, ix);
	addrsind(&j->dst, Afp, getfpoff(jtype, ix));
	setresult(&r, jtype, j);
	jvmpush(r);
}

static void
javastore(Jinst *j, uchar jtype, int ix)
{
	Result r;

	verifyindex(j, jtype, ix);

	srcalloc(j, 1);

	r = jvmpop();
	typecheck(&r, jtype);
	j->src[0] = r.pc;

	addrsind(&j->dst, Afp, getfpoff(jtype, ix));
}

static void
arrayload(Jinst *j, uchar jtype)
{
	Result r;

	srcalloc(j, 2);

	r = jvmpop();
	typecheck(&r, 'I');
	j->src[1] = r.pc;

	r = jvmpop();
	typecheck(&r, '[');
	j->src[0] = r.pc;

	addrsind(&j->dst, Afp, -1);
	setresult(&r, jtype, j);
	jvmpush(r);
}

static void
arraystore(Jinst *j, uchar jtype)
{
	Result r;

	srcalloc(j, 3);

	r = jvmpop();
	typecheck(&r, jtype);
	j->src[2] = r.pc;

	r = jvmpop();
	typecheck(&r, 'I');
	j->src[1] = r.pc;

	r = jvmpop();
	typecheck(&r, '[');
	j->src[0] = r.pc;

}

static void
binop(Jinst *j, uchar loptype, uchar roptype, uchar dsttype)
{
	Result r;

	srcalloc(j, 2);

	r = jvmpop();
	typecheck(&r, roptype);
	j->src[1] = r.pc;

	r = jvmpop();
	typecheck(&r, loptype);
	j->src[0] = r.pc;

	addrsind(&j->dst, Afp, -1);
	setresult(&r, dsttype, j);
	jvmpush(r);
}

static void
unop(Jinst *j, uchar srctype, uchar dsttype)
{
	Result r;

	srcalloc(j, 1);

	r = jvmpop();
	typecheck(&r, srctype);
	j->src[0] = r.pc;

	addrsind(&j->dst, Afp, -1);
	setresult(&r, dsttype, j);
	jvmpush(r);
}

/*
 * If the local variable being stored into corresponds to a local
 * that is on the stack, then an explicit mov_ MUST be generated
 * for the load instruction that put it on the stack.
 */

static void
storechk(int six, uchar stype)
{
	int i, lix;
	uchar ltype;
	Jinst *j;

	for(i = 0; i < jvmtos; i++) {
		j = &code->j[jvmstack[i].pc];
		lix = -1;
		switch(j->op) {
		case Jiload:
		case Jlload:
		case Jfload:
		case Jdload:
		case Jaload:
			lix = j->u.i;
			break;
		case Jiload_0:
		case Jlload_0:
		case Jfload_0:
		case Jdload_0:
		case Jaload_0:
			lix = 0;
			break;
		case Jiload_1:
		case Jlload_1:
		case Jfload_1:
		case Jdload_1:
		case Jaload_1:
			lix = 1;
			break;
		case Jiload_2:
		case Jlload_2:
		case Jfload_2:
		case Jdload_2:
		case Jaload_2:
			lix = 2;
			break;
		case Jiload_3:
		case Jlload_3:
		case Jfload_3:
		case Jdload_3:
		case Jaload_3:
			lix = 3;
			break;
		case Jwide:
			switch(j->u.w.op) {
			case Jiload:
			case Jlload:
			case Jfload:
			case Jdload:
			case Jaload:
				lix = j->u.w.ix;
			}
			break;
		}
		ltype = '-';
		switch(j->op) {
		case Jiload:
		case Jiload_0:
		case Jiload_1:
		case Jiload_2:
		case Jiload_3:
			ltype = 'I';
			break;
		case Jlload:
		case Jlload_0:
		case Jlload_1:
		case Jlload_2:
		case Jlload_3:
			ltype = 'J';
			break;
		case Jfload:
		case Jfload_0:
		case Jfload_1:
		case Jfload_2:
		case Jfload_3:
			ltype = 'F';
			break;
		case Jdload:
		case Jdload_0:
		case Jdload_1:
		case Jdload_2:
		case Jdload_3:
			ltype = 'D';
			break;
		case Jaload:
		case Jaload_0:
		case Jaload_1:
		case Jaload_2:
		case Jaload_3:
			ltype = 'L';
			break;
		case Jwide:
			switch(j->u.w.op) {
			case Jiload:
				ltype = 'I';
				break;
			case Jlload:
				ltype = 'J';
				break;
			case Jfload:
				ltype = 'F';
				break;
			case Jdload:
				ltype = 'D';
				break;
			case Jaload:
				ltype = 'L';
				break;
			}
			break;
		}
		if(lix == six && ltype == stype && j->movsrc.mode == Anone) {
			j->movsrc = j->dst;
			addrsind(&j->dst, Afp, -1);
		}
	}
}

static void
useone(Jinst *j, uchar jtype)
{
	Result r;

	srcalloc(j, 1);

	r = jvmpop();
	typecheck(&r, jtype);
	j->src[0] = r.pc;
}

static void
usetwo(Jinst *j, uchar loptype, uchar roptype)
{
	Result r;

	srcalloc(j, 2);

	r = jvmpop();
	typecheck(&r, roptype);
	j->src[1] = r.pc;

	r = jvmpop();
	typecheck(&r, loptype);
	j->src[0] = r.pc;
}

static void
javanew(Jinst *j)
{
	Result r;
	char *name;

	name = CLASSNAME(j->u.i);
	if(name[0] == '[')
		verifyerror(j);

	addrsind(&j->dst, Afp, -1);
	setresult(&r, 'L', j);
	jvmpush(r);
	crefenter(name, j->bb);
}

static int
checkdim(Jinst *j, int ix)
{
	int ndim;
	char *name;

	ndim = 0;
	name = CLASSNAME(ix);
	while(name[0] == '[') {
		ndim++;
		name++;
	}
	if(ndim > 255)
		verifyerror(j);
	crefenter(name, j->bb);
	return ndim;
}

static void
anewarray(Jinst *j)
{
	checkdim(j, j->u.i);
	unop(j, 'I', '[');
}

static void
multianewarray(Jinst *j)
{
	Result r;
	int i, ndim;

	ndim = checkdim(j, j->u.x2d.ix);
	if(ndim == 0 || j->u.x2d.dim > ndim)
		verifyerror(j);

	srcalloc(j, j->u.x2d.dim);

	for(i = j->u.x2d.dim-1; i >= 0; i--) {
		r = jvmpop();
		typecheck(&r, 'I');
		j->src[i] = r.pc;
	}

	addrsind(&j->dst, Afp, -1);
	setresult(&r, '[', j);
	jvmpush(r);
}

static char*
getclassname(Jinst *j)
{
	Const *c;
	int ix;

	if(j->op == Jinvokeinterface)
		ix = j->u.x2c0.ix;
	else
		ix = j->u.i;
	c = &class->cps[ix];
	return CLASSNAME(c->fmiref.class_index);
}

static char*
getname(Jinst *j)
{
	Const *c, *n;
	int ix;

	if(j->op == Jinvokeinterface)
		ix = j->u.x2c0.ix;
	else
		ix = j->u.i;
	c = &class->cps[ix];
	n = &class->cps[c->fmiref.name_type_index];
	return STRING(n->nat.name_index);
}

static char*
getsig(Jinst *j)
{
	Const *c, *n;
	int ix;

	if(j->op == Jinvokeinterface)
		ix = j->u.x2c0.ix;
	else
		ix = j->u.i;
	c = &class->cps[ix];
	n = &class->cps[c->fmiref.name_type_index];
	return STRING(n->nat.sig_index);
}

static void
getfs(Jinst *j)
{
	Result r;
	char *sig;

	sig = getsig(j);
	if(j->op == Jgetfield)
		useone(j, 'L');
	addrsind(&j->dst, Afp, -1);
	setresult(&r, jvmtype(sig[0]), j);
	jvmpush(r);
	crefenter(getclassname(j), j->bb);
}

static void
putfs(Jinst *j)
{
	char *sig;

	sig = getsig(j);
	if(j->op == Jputstatic)
		useone(j, jvmtype(sig[0]));
	else
		usetwo(j, 'L', jvmtype(sig[0]));
	crefenter(getclassname(j), j->bb);
}

static void
invoke(Jinst *j)
{
	char *name, *sig, *savesig;
	int i, nargs, wargs;
	Result *args;
	Result rv;

	name = getname(j);
	if(name[0] == '<'
	&& (strcmp(name, "<init>") != 0 || j->op != Jinvokespecial))
		verifyerror(j);

	/* count arguments */
	sig = getsig(j);
	nargs = 0;	/* number of arguments */
	wargs = 0;	/* width of arguments (number of Java words) */
	sig++;	/* skip '(' */
	savesig = sig;
	while(sig[0] != ')') {
		nargs++;
		wargs++;
		if(sig[0] == 'J' || sig[0] == 'D')
			wargs++;
		sig = nextjavatype(sig);
	}
	if(j->op != Jinvokestatic) {
		nargs++;
		wargs++;
	}
	if(wargs > 255 || (j->op == Jinvokeinterface && j->u.x2c0.narg != wargs))
		verifyerror(j);

	/* collect and typecheck arguments */
	if(nargs > 0) {
		srcalloc(j, nargs);
		args = Malloc(nargs*sizeof(Result));
		for(i = nargs-1; i >= 0; i--) {
			args[i] = jvmpop();
			j->src[i] = args[i].pc;
		}
		i = 0;
		if(j->op != Jinvokestatic) {
			typecheck(&args[0], 'L');
			i++;
		}
		sig = savesig;
		while(sig[0] != ')') {
			typecheck(&args[i], jvmtype(sig[0]));
			i++;
			sig = nextjavatype(sig);
		}
		free(args);
	}

	/* return type */
	if(sig[1] != 'V') {	/* skip ')' */
		addrsind(&j->dst, Afp, -1);
		setresult(&rv, jvmtype(sig[1]), j);
		jvmpush(rv);
	}
	crefenter(getclassname(j), j->bb);
}

static void
javareturn(Jinst *j)
{
	uchar jtype;

	switch(j->op) {
	case Jireturn:
		jtype = 'I';
		break;
	case Jlreturn:
		jtype = 'J';
		break;
	case Jfreturn:
		jtype = 'F';
		break;
	case Jdreturn:
		jtype = 'D';
		break;
	case Jareturn:
		jtype = 'L';
		break;
	case Jreturn:
		jtype = 'V';
		break;
	default:
		fatal("javareturn: invalid j->op");
		return;
	}
	if(jtype != rettype && jtype + rettype != 'L' + '[')
		verifyerror(j);
	if(j->op != Jreturn)
		useone(j, jtype);
}

static void
ldc(Jinst *j)
{
	Const *c;

	c = &class->cps[j->u.i];
	switch(class->cts[j->u.i]) {
	case CON_Integer:
		if(notimmable(c->tint))
			mpconst(j, 'I', mpint(c->tint));
		else
			iconst(j, c->tint);
		break;
	case CON_Float:
		mpconst(j, 'F', mpreal(c->tdouble));
		break;
	case CON_Double:
		mpconst(j, 'D', mpreal(c->tdouble));
		break;
	case CON_Long:
		mpconst(j, 'J', mplong(c->tvlong));
		break;
	case CON_String:
		mpconst(j, 'L', mpstring(STRING(c->string_index)));
		j->movsrc = j->dst;
		addrsind(&j->dst, Afp, -1);
		break;
	}
}

static void
oneword(Jinst *j, uchar jtype)
{
	if(jtype == 'J' || jtype == 'D')
		verifyerror(j);
}

static void
javapop(Jinst *j)
{
	Result r1, r2;
	int n;

	r1 = jvmpop();
	n = 1;
	switch(j->op) {
	case Jpop:
		oneword(j, r1.jtype);
		break;
	case Jpop2:
		if(r1.jtype != 'J' && r1.jtype != 'D') {
			r2 = jvmpop();
			n = 2;
			oneword(j, r2.jtype);
		}
		break;
	}
	srcalloc(j, n);
	j->src[0] = r1.pc;
	if(n == 2)	/* pop2 */
		j->src[1] = r2.pc;
}

static void
javadup(Jinst *j)
{
	Result w1, w2, w3, w4;
	int n;		/* number of stack items duplicated */

	n = 1;
	switch(j->op) {
	case Jdup:
		w1 = jvmpop();
		oneword(j, w1.jtype);
		jvmpush(w1);
		jvmpush(w1);
		break;
	case Jdup_x1:
		w1 = jvmpop();
		oneword(j, w1.jtype);
		w2 = jvmpop();
		oneword(j, w2.jtype);
		jvmpush(w1);
		jvmpush(w2);
		jvmpush(w1);
		break;
	case Jdup_x2:
		w1 = jvmpop();
		oneword(j, w1.jtype);
		w2 = jvmpop();
		if(w2.jtype == 'J' || w2.jtype == 'D') {
			jvmpush(w1);
		} else {
			w3 = jvmpop();
			oneword(j, w3.jtype);
			jvmpush(w1);
			jvmpush(w3);
		}
		jvmpush(w2);
		jvmpush(w1);
		break;
	case Jdup2:
		w1 = jvmpop();
		if(w1.jtype == 'J' || w1.jtype == 'D') {
			jvmpush(w1);
		} else {
			n = 2;
			w2 = jvmpop();
			oneword(j, w2.jtype);
			jvmpush(w2);
			jvmpush(w1);
			jvmpush(w2);
		}
		jvmpush(w1);
		break;
	case Jdup2_x1:
		w1 = jvmpop();
		if(w1.jtype == 'J' || w1.jtype == 'D') {
			w3 = jvmpop();
			oneword(j, w3.jtype);
			jvmpush(w1);
			jvmpush(w3);
		} else {
			n = 2;
			w2 = jvmpop();
			oneword(j, w2.jtype);
			w3 = jvmpop();
			oneword(j, w3.jtype);
			jvmpush(w2);
			jvmpush(w1);
			jvmpush(w3);
			jvmpush(w2);
		}
		jvmpush(w1);
		break;
	case Jdup2_x2:
		w1 = jvmpop();
		if(w1.jtype != 'J' && w1.jtype != 'D') {
			n = 2;
			w2 = jvmpop();
			oneword(j, w2.jtype);
		}
		w3 = jvmpop();
		if(w3.jtype != 'J' && w3.jtype != 'D') {
			w4 = jvmpop();
			oneword(j, w4.jtype);
		}

		if(w1.jtype != 'J' && w1.jtype != 'D')
			jvmpush(w2);
		jvmpush(w1);
		if(w3.jtype != 'J' && w3.jtype != 'D')
			jvmpush(w4);
		jvmpush(w3);
		if(w1.jtype != 'J' && w1.jtype != 'D')
			jvmpush(w2);
		jvmpush(w1);
		break;
	}
	srcalloc(j, n);
	j->src[0] = w1.pc;
	if(n == 2)
		j->src[1] = w2.pc;
}

static void
javaswap(Jinst *j)
{
	Result w1, w2;

	w1 = jvmpop();
	oneword(j, w1.jtype);
	w2 = jvmpop();
	oneword(j, w2.jtype);
	jvmpush(w1);
	jvmpush(w2);
}

static void
simjinst(Jinst *j)
{
	switch(j->op) {
	case Jnop:
		break;
	case Jaconst_null:
		mpconst(j, 'L', 0);
		break;
	case Jiconst_m1:
		iconst(j, -1);
		break;
	case Jiconst_0:
		iconst(j, 0);
		break;
	case Jiconst_1:
		iconst(j, 1);
		break;
	case Jiconst_2:
		iconst(j, 2);
		break;
	case Jiconst_3:
		iconst(j, 3);
		break;
	case Jiconst_4:
		iconst(j, 4);
		break;
	case Jiconst_5:
		iconst(j, 5);
		break;
	case Jlconst_0:
		mpconst(j, 'J', mplong(0));
		break;
	case Jlconst_1:
		mpconst(j, 'J', mplong(1));
		break;
	case Jfconst_0:
		mpconst(j, 'F', mpreal(0.0));
		break;
	case Jfconst_1:
		mpconst(j, 'F', mpreal(1.0));
		break;
	case Jfconst_2:
		mpconst(j, 'F', mpreal(2.0));
		break;
	case Jdconst_0:
		mpconst(j, 'D', mpreal(0.0));
		break;
	case Jdconst_1:
		mpconst(j, 'D', mpreal(1.0));
		break;
	case Jbipush:
	case Jsipush:
		iconst(j, j->u.i);
		break;
	case Jldc:
	case Jldc_w:
	case Jldc2_w:
		ldc(j);
		break;
	case Jiload:
		javaload(j, 'I', j->u.i);
		break;
	case Jlload:
		javaload(j, 'J', j->u.i);
		break;
	case Jfload:
		javaload(j, 'F', j->u.i);
		break;
	case Jdload:
		javaload(j, 'D', j->u.i);
		break;
	case Jaload:
		javaload(j, 'L', j->u.i);
		break;
	case Jiload_0:
		javaload(j, 'I', 0);
		break;
	case Jiload_1:
		javaload(j, 'I', 1);
		break;
	case Jiload_2:
		javaload(j, 'I', 2);
		break;
	case Jiload_3:
		javaload(j, 'I', 3);
		break;
	case Jlload_0:
		javaload(j, 'J', 0);
		break;
	case Jlload_1:
		javaload(j, 'J', 1);
		break;
	case Jlload_2:
		javaload(j, 'J', 2);
		break;
	case Jlload_3:
		javaload(j, 'J', 3);
		break;
	case Jfload_0:
		javaload(j, 'F', 0);
		break;
	case Jfload_1:
		javaload(j, 'F', 1);
		break;
	case Jfload_2:
		javaload(j, 'F', 2);
		break;
	case Jfload_3:
		javaload(j, 'F', 3);
		break;
	case Jdload_0:
		javaload(j, 'D', 0);
		break;
	case Jdload_1:
		javaload(j, 'D', 1);
		break;
	case Jdload_2:
		javaload(j, 'D', 2);
		break;
	case Jdload_3:
		javaload(j, 'D', 3);
		break;
	case Jaload_0:
		javaload(j, 'L', 0);
		break;
	case Jaload_1:
		javaload(j, 'L', 1);
		break;
	case Jaload_2:
		javaload(j, 'L', 2);
		break;
	case Jaload_3:
		javaload(j, 'L', 3);
		break;
	case Jbaload:
	case Jcaload:
	case Jsaload:
	case Jiaload:
		arrayload(j, 'I');
		break;
	case Jlaload:
		arrayload(j, 'J');
		break;
	case Jfaload:
		arrayload(j, 'F');
		break;
	case Jdaload:
		arrayload(j, 'D');
		break;
	case Jaaload:
		arrayload(j, 'L');
		break;
	case Jistore:
		storechk(j->u.i, 'I');
		javastore(j, 'I', j->u.i);
		break;
	case Jlstore:
		storechk(j->u.i, 'J');
		javastore(j, 'J', j->u.i);
		break;
	case Jfstore:
		storechk(j->u.i, 'F');
		javastore(j, 'F', j->u.i);
		break;
	case Jdstore:
		storechk(j->u.i, 'D');
		javastore(j, 'D', j->u.i);
		break;
	case Jastore:	/* could be start of finally block or handler */
		storechk(j->u.i, 'L');
		javastore(j, 'L', j->u.i);
		break;
	case Jistore_0:
		storechk(0, 'I');
		javastore(j, 'I', 0);
		break;
	case Jistore_1:
		storechk(1, 'I');
		javastore(j, 'I', 1);
		break;
	case Jistore_2:
		storechk(2, 'I');
		javastore(j, 'I', 2);
		break;
	case Jistore_3:
		storechk(3, 'I');
		javastore(j, 'I', 3);
		break;
	case Jlstore_0:
		storechk(0, 'J');
		javastore(j, 'J', 0);
		break;
	case Jlstore_1:
		storechk(1, 'J');
		javastore(j, 'J', 1);
		break;
	case Jlstore_2:
		storechk(2, 'J');
		javastore(j, 'J', 2);
		break;
	case Jlstore_3:
		storechk(3, 'J');
		javastore(j, 'J', 3);
		break;
	case Jfstore_0:
		storechk(0, 'F');
		javastore(j, 'F', 0);
		break;
	case Jfstore_1:
		storechk(1, 'F');
		javastore(j, 'F', 1);
		break;
	case Jfstore_2:
		storechk(2, 'F');
		javastore(j, 'F', 2);
		break;
	case Jfstore_3:
		storechk(3, 'F');
		javastore(j, 'F', 3);
		break;
	case Jdstore_0:
		storechk(0, 'D');
		javastore(j, 'D', 0);
		break;
	case Jdstore_1:
		storechk(1, 'D');
		javastore(j, 'D', 1);
		break;
	case Jdstore_2:
		storechk(2, 'D');
		javastore(j, 'D', 2);
		break;
	case Jdstore_3:
		storechk(3, 'D');
		javastore(j, 'D', 3);
		break;
	case Jastore_0:	/* could be start of finally block or handler */
		storechk(0, 'L');
		javastore(j, 'L', 0);
		break;
	case Jastore_1:
		storechk(1, 'L');
		javastore(j, 'L', 1);
		break;
	case Jastore_2:
		storechk(2, 'L');
		javastore(j, 'L', 2);
		break;
	case Jastore_3:
		storechk(3, 'L');
		javastore(j, 'L', 3);
		break;
	case Jbastore:
	case Jcastore:
	case Jsastore:
	case Jiastore:
		arraystore(j, 'I');
		break;
	case Jlastore:
		arraystore(j, 'J');
		break;
	case Jfastore:
		arraystore(j, 'F');
		break;
	case Jdastore:
		arraystore(j, 'D');
		break;
	case Jaastore:
		arraystore(j, 'L');
		break;
	case Jpop:
	case Jpop2:
		javapop(j);
		break;
	case Jdup:
	case Jdup_x1:
	case Jdup_x2:
	case Jdup2:
	case Jdup2_x1:
	case Jdup2_x2:
		javadup(j);
		break;
	case Jswap:
		javaswap(j);
		break;
	case Jiadd:
	case Jisub:
	case Jimul:
	case Jidiv:
	case Jirem:
	case Jishl:
	case Jishr:
	case Jiushr:
	case Jiand:
	case Jior:
	case Jixor:
		binop(j, 'I', 'I', 'I');
		break;
	case Jladd:
	case Jlsub:
	case Jlmul:
	case Jldiv:
	case Jlrem:
	case Jland:
	case Jlor:
	case Jlxor:
		binop(j, 'J', 'J', 'J');
		break;
	case Jfadd:
	case Jfsub:
	case Jfmul:
	case Jfdiv:
	case Jfrem:
		binop(j, 'F', 'F', 'F');
		break;
	case Jdadd:
	case Jdsub:
	case Jdmul:
	case Jddiv:
	case Jdrem:
		binop(j, 'D', 'D', 'D');
		break;
	case Jineg:
		unop(j, 'I', 'I');
		break;
	case Jlneg:
		unop(j, 'J', 'J');
		break;
	case Jfneg:
		unop(j, 'F', 'F');
		break;
	case Jdneg:
		unop(j, 'D', 'D');
		break;
	case Jlshl:
	case Jlshr:
	case Jlushr:
		binop(j, 'J', 'I', 'J');
		break;
	case Jiinc:
		verifyindex(j, 'I', j->u.x1c.ix);
		storechk(j->u.x1c.ix, 'I');
		break;
	case Ji2l:
		unop(j, 'I', 'J');
		break;
	case Ji2f:
		unop(j, 'I', 'F');
		break;
	case Ji2d:
		unop(j, 'I', 'D');
		break;
	case Jl2i:
		unop(j, 'J', 'I');
		break;
	case Jl2f:
		unop(j, 'J', 'F');
		break;
	case Jl2d:
		unop(j, 'J', 'D');
		break;
	case Jf2i:
		unop(j, 'F', 'I');
		break;
	case Jf2l:
		unop(j, 'F', 'J');
		break;
	case Jf2d:
		unop(j, 'F', 'D');
		break;
	case Jd2i:
		unop(j, 'D', 'I');
		break;
	case Jd2l:
		unop(j, 'D', 'J');
		break;
	case Jd2f:
		unop(j, 'D', 'F');
		break;
	case Ji2b:
	case Ji2c:
	case Ji2s:
		unop(j, 'I', 'I');
		break;
	case Jlcmp:
		binop(j, 'J', 'J', 'I');
		break;
	case Jfcmpl:
	case Jfcmpg:
		binop(j, 'F', 'F', 'I');
		break;
	case Jdcmpl:
	case Jdcmpg:
		binop(j, 'D', 'D', 'I');
		break;
	case Jifeq:
	case Jifne:
	case Jiflt:
	case Jifge:
	case Jifgt:
	case Jifle:
		useone(j, 'I');
		break;
	case Jif_icmpeq:
	case Jif_icmpne:
	case Jif_icmplt:
	case Jif_icmpge:
	case Jif_icmpgt:
	case Jif_icmple:
		usetwo(j, 'I', 'I');
		break;
	case Jif_acmpeq:
	case Jif_acmpne:
		usetwo(j, 'L', 'L');
		break;
	case Jgoto:
	case Jgoto_w:
	case Jjsr:	/* no push; not following ... */
	case Jjsr_w:	/* ... these branches */
		break;
	case Jret:
		verifyindex(j, 'L', j->u.i);
		break;
	case Jtableswitch:
	case Jlookupswitch:
		useone(j, 'I');
		break;
	case Jireturn:
	case Jlreturn:
	case Jfreturn:
	case Jdreturn:
	case Jareturn:
	case Jreturn:
		javareturn(j);
		break;
	case Jgetfield:
	case Jgetstatic:
		getfs(j);
		break;
	case Jputfield:
	case Jputstatic:
		putfs(j);
		break;
	case Jinvokevirtual:
	case Jinvokespecial:
	case Jinvokestatic:
	case Jinvokeinterface:
		invoke(j);
		break;
	case Jxxxunusedxxx:
		break;
	case Jnew:
		javanew(j);
		break;
	case Jnewarray:
		unop(j, 'I', '[');
		break;
	case Janewarray:
		anewarray(j);
		break;
	case Jarraylength:
		unop(j, '[', 'I');
		break;
	case Jathrow:
		useone(j, 'L');
		break;
	case Jcheckcast:
	case Jinstanceof:
		unop(j, 'L', (j->op == Jcheckcast) ? 'L' : 'I');
		crefenter(CLASSNAME(j->u.i), j->bb);
		break;
	case Jmonitorenter:
	case Jmonitorexit:
		useone(j, 'L');
		break;
	case Jwide:
		switch(j->u.w.op) {
		case Jiload:
			javaload(j, 'I', j->u.w.ix);
			break;
		case Jlload:
			javaload(j, 'J', j->u.w.ix);
			break;
		case Jfload:
			javaload(j, 'F', j->u.w.ix);
			break;
		case Jdload:
			javaload(j, 'D', j->u.w.ix);
			break;
		case Jaload:
			javaload(j, 'L', j->u.w.ix);
			break;
		case Jistore:
			storechk(j->u.w.ix, 'I');
			javastore(j, 'I', j->u.w.ix);
			break;
		case Jlstore:
			storechk(j->u.w.ix, 'J');
			javastore(j, 'J', j->u.w.ix);
			break;
		case Jfstore:
			storechk(j->u.w.ix, 'F');
			javastore(j, 'F', j->u.w.ix);
			break;
		case Jdstore:
			storechk(j->u.w.ix, 'D');
			javastore(j, 'D', j->u.w.ix);
			break;
		case Jastore:
			storechk(j->u.w.ix, 'L');
			javastore(j, 'L', j->u.w.ix);
			break;
		case Jret:
			verifyindex(j, 'L', j->u.w.ix);
			break;
		case Jiinc:
			verifyindex(j, 'I', j->u.w.ix);
			storechk(j->u.w.ix, 'I');
			break;
		}
		break;
	case Jmultianewarray:
		multianewarray(j);
		break;
	case Jifnull:
	case Jifnonnull:
		useone(j, 'L');
		break;
	}
}

/*
 * Take snapshot of current stack.
 */

static StkSnap*
snapstack(void)
{
	StkSnap *s;
	int i;

	s = Malloc(jvmtos*sizeof(StkSnap));
	for(i = 0; i < jvmtos; i++) {
		s[i].jtype = jvmstack[i].jtype;
		s[i].npc = 1;
		s[i].pc = Malloc(sizeof(int));
		s[i].pc[0] = jvmstack[i].pc;
	}
	return s;
}

/*
 * Merge current stack into bb.entrystk.
 */

static void
stackmerge(BB *bb)
{
	StkSnap *s;
	int i, j;
	int pct;
	uchar jtype1, jtype2;

	if(jvmtos == 0) {
		if(bb->entrysz != 0)
			verifyerrormess("stack merge");
		return;
	}
	if(bb->entrystk == nil) {
		bb->entrysz = jvmtos;
		bb->entrystk = snapstack();
		return;
	}
	/* true stack merge */
	if(bb->entrysz != jvmtos)
		verifyerrormess("stack merge");
	for(i = 0; i < jvmtos; i++) {
		jtype1 = jvmstack[i].jtype;
		jtype2 = bb->entrystk[i].jtype;
		if(jtype1 != jtype2 && jtype1 + jtype2 != 'L' + '[')
			verifyerrormess("stack merge");
		s = &bb->entrystk[i];
		for(j = 0; j < s->npc; j++) {
			if(s->pc[j] == jvmstack[i].pc)
				goto continue_outer;
		}
		s->pc = Realloc(s->pc, (s->npc+1)*sizeof(int));
		s->pc[s->npc++] = jvmstack[i].pc;
		/* percolate into sorted order */
		for(j = s->npc-1; j > 0; j--) {
			if(s->pc[j-1] > s->pc[j]) {
				pct = s->pc[j-1];
				s->pc[j-1] = s->pc[j];
				s->pc[j] = pct;
			} else
				break;
		}
		continue_outer: ;
	}
}

/*
 * Simulate the instructions in a basic block.
 */

static void
simbb(BB *bb)
{
	Jinst *j;
	BBList *l;

	if(bb->state == BB_POSTSIM)
		fatal("simbb: BB_POSTSIM\n");

	jvminit(bb);
	j = bb->js;
	while(j <= bb->je) {
		simjinst(j);
		j += j->size;
	}
	bb->state = BB_POSTSIM;

	if(jvmtos != 0) {
		bb->exitsz = jvmtos;
		bb->exitstk = snapstack();
	}

	for(l = bb->succ; l; l = l->next) {
		stackmerge(l->bb);
		if(l->bb->state == BB_PRESIM)
			bbput(l->bb);
	}
}

/*
 * Simulate the Java VM on each of the method's basic blocks.
 */

void
simjvm(char *sig)
{
	BB *bb;

	sig++;	/* skip '(' */
	while(sig[0] != ')')
		sig++;
	rettype = jvmtype(sig[1]);

	jvmstack = Malloc(code->max_stack*sizeof(Result));

	bbinit();
	while(bb = bbget())
		simbb(bb);

	free(jvmstack);
}

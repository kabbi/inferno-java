#include "java.h"
#include "javaisa.h"

/*
 * Java bytecode disassembler.
 */

enum			/* Java operand classifications */
{
	AT,		/* unsigned byte (newarray) */
	B2,		/* 2-byte signed branch offset */
	B4,		/* 4-byte signed branch offset */
	X1,		/* 1-byte unsigned index (ldc) */
	X1C,		/* iinc */
	X2,		/* 2-byte unsigned index */
	X2C0,		/* invokeinterface */
	X2D,		/* multianewarray */
	T1,		/* tableswitch */
	T2,		/* lookupswitch */
	V1,		/* 1-byte signed value (bipush) */
	V2,		/* 2-byte signed value (sipush) */
	W,		/* wide */
	Z		/* zero operands */
};

typedef struct	Jmnemon	Jmnemon;

struct Jmnemon
{
	char	*op;
	uchar	kind;
};

/*
 * Java bytecode mnemonics.
 */

static Jmnemon tab[MAXJAVA] =
{
	"nop",		Z,
	"aconst_null",	Z,
	"iconst_m1",	Z,
	"iconst_0",	Z,
	"iconst_1",	Z,
	"iconst_2",	Z,
	"iconst_3",	Z,
	"iconst_4",	Z,
	"iconst_5",	Z,
	"lconst_0",	Z,
	"lconst_1",	Z,
	"fconst_0",	Z,
	"fconst_1",	Z,
	"fconst_2",	Z,
	"dconst_0",	Z,
	"dconst_1",	Z,
	"bipush",	V1,
	"sipush",	V2,
	"ldc",		X1,
	"ldc_w",	X2,
	"ldc2_w",	X2,
	"iload",	X1,
	"lload",	X1,
	"fload",	X1,
	"dload",	X1,
	"aload",	X1,
	"iload_0",	Z,
	"iload_1",	Z,
	"iload_2",	Z,
	"iload_3",	Z,
	"lload_0",	Z,
	"lload_1",	Z,
	"lload_2",	Z,
	"lload_3",	Z,
	"fload_0",	Z,
	"fload_1",	Z,
	"fload_2",	Z,
	"fload_3",	Z,
	"dload_0",	Z,
	"dload_1",	Z,
	"dload_2",	Z,
	"dload_3",	Z,
	"aload_0",	Z,
	"aload_1",	Z,
	"aload_2",	Z,
	"aload_3",	Z,
	"iaload",	Z,
	"laload",	Z,
	"faload",	Z,
	"daload",	Z,
	"aaload",	Z,
	"baload",	Z,
	"caload",	Z,
	"saload",	Z,
	"istore",	X1,
	"lstore",	X1,
	"fstore",	X1,
	"dstore",	X1,
	"astore",	X1,
	"istore_0",	Z,
	"istore_1",	Z,
	"istore_2",	Z,
	"istore_3",	Z,
	"lstore_0",	Z,
	"lstore_1",	Z,
	"lstore_2",	Z,
	"lstore_3",	Z,
	"fstore_0",	Z,
	"fstore_1",	Z,
	"fstore_2",	Z,
	"fstore_3",	Z,
	"dstore_0",	Z,
	"dstore_1",	Z,
	"dstore_2",	Z,
	"dstore_3",	Z,
	"astore_0",	Z,
	"astore_1",	Z,
	"astore_2",	Z,
	"astore_3",	Z,
	"iastore",	Z,
	"lastore",	Z,
	"fastore",	Z,
	"dastore",	Z,
	"aastore",	Z,
	"bastore",	Z,
	"castore",	Z,
	"sastore",	Z,
	"pop",		Z,
	"pop2",		Z,
	"dup",		Z,
	"dup_x1",	Z,
	"dup_x2",	Z,
	"dup2",		Z,
	"dup2_x1",	Z,
	"dup2_x2",	Z,
	"swap",		Z,
	"iadd",		Z,
	"ladd",		Z,
	"fadd",		Z,
	"dadd",		Z,
	"isub",		Z,
	"lsub",		Z,
	"fsub",		Z,
	"dsub",		Z,
	"imul",		Z,
	"lmul",		Z,
	"fmul",		Z,
	"dmul",		Z,
	"idiv",		Z,
	"ldiv",		Z,
	"fdiv",		Z,
	"ddiv",		Z,
	"irem",		Z,
	"lrem",		Z,
	"frem",		Z,
	"drem",		Z,
	"ineg",		Z,
	"lneg",		Z,
	"fneg",		Z,
	"dneg",		Z,
	"ishl",		Z,
	"lshl",		Z,
	"ishr",		Z,
	"lshr",		Z,
	"iushr",	Z,
	"lushr",	Z,
	"iand",		Z,
	"land",		Z,
	"ior",		Z,
	"lor",		Z,
	"ixor",		Z,
	"lxor",		Z,
	"iinc",		X1C,
	"i2l",		Z,
	"i2f",		Z,
	"i2d",		Z,
	"l2i",		Z,
	"l2f",		Z,
	"l2d",		Z,
	"f2i",		Z,
	"f2l",		Z,
	"f2d",		Z,
	"d2i",		Z,
	"d2l",		Z,
	"d2f",		Z,
	"i2b",		Z,
	"i2c",		Z,
	"i2s",		Z,
	"lcmp",		Z,
	"fcmpl",	Z,
	"fcmpg",	Z,
	"dcmpl",	Z,
	"dcmpg",	Z,
	"ifeq",		B2,
	"ifne",		B2,
	"iflt",		B2,
	"ifge",		B2,
	"ifgt",		B2,
	"ifle",		B2,
	"if_icmpeq",	B2,
	"if_icmpne",	B2,
	"if_icmplt",	B2,
	"if_icmpge",	B2,
	"if_icmpgt",	B2,
	"if_icmple",	B2,
	"if_acmpeq",	B2,
	"if_acmpne",	B2,
	"goto",		B2,
	"jsr",		B2,
	"ret",		X1,
	"tableswitch",	T1,
	"lookupswitch",	T2,
	"ireturn",	Z,
	"lreturn",	Z,
	"freturn",	Z,
	"dreturn",	Z,
	"areturn",	Z,
	"return",	Z,
	"getstatic",	X2,
	"putstatic",	X2,
	"getfield",	X2,
	"putfield",	X2,
	"invokevirtual",X2,
	"invokespecial",	X2,
	"invokestatic",		X2,
	"invokeinterface",	X2C0,
	"xxxunusedxxx",	Z,
	"new",		X2,
	"newarray",	AT,
	"anewarray",	X2,
	"arraylength",	Z,
	"athrow",	Z,
	"checkcast",	X2,
	"instanceof",	X2,
	"monitorenter",	Z,
	"monitorexit",	Z,
	"wide",		W,
	"multianewarray",	X2D,
	"ifnull",	B2,
	"ifnonnull",	B2,
	"goto_w",	B4,
	"jsr_w",	B4,
};

/*
 * %J format conversion.
 */

int
Jconv(va_list *jinst, Fconv *f)
{
	Jinst *j;
	Jmnemon *t;
	int i, k;
	char buf[2048]; /* not big enough for tableswitch, lookupswitch ??? */

	j = va_arg(*jinst, Jinst*);
	t = &tab[j->op];

	switch(t->kind) {
	case Z:
		sprint(buf, "%s", t->op);
		break;
	case X1:
	case X2:
	case V1:
	case V2:
	case B2:
	case B4:
		sprint(buf, "%s %d", t->op, j->u.i);
		break;
	case X1C:
		sprint(buf, "%s %d,%d", t->op, j->u.x1c.ix, j->u.x1c.icon);
		break;
	case X2D:
		sprint(buf, "%s %d,%d", t->op, j->u.x2d.ix, j->u.x2d.dim);
		break;
	case AT:
		sprint(buf, "%s %d", t->op, j->u.i);
		break;
	case T1:
		i = sprint(buf, "%s %d,%d,%d", t->op, j->u.t1.dflt,
			j->u.t1.lb, j->u.t1.hb);
		if(j->u.t1.tbl) {
			for(k = 0; k < j->u.t1.hb - j->u.t1.lb + 1; k++)
				i += sprint(buf+i, ",%d", j->u.t1.tbl[k]);
		}
		break;
	case T2:
		i = sprint(buf, "%s %d,%d", t->op, j->u.t2.dflt, j->u.t2.np);
		if(j->u.t2.tbl) {
			for(k = 0; k < 2*j->u.t2.np; k++)
				i += sprint(buf+i, ",%d", j->u.t2.tbl[k]);
		}
		break;
	case W:
		i = sprint(buf, "%s %d,%d", t->op, j->u.w.op, j->u.w.ix);
		if(j->u.w.op == Jiinc)
			sprint(buf+i, ",%d", j->u.w.icon);
		break;
	case X2C0:
		sprint(buf, "%s %d,%d,%d", t->op, j->u.x2c0.ix,
			j->u.x2c0.narg, j->u.x2c0.zero);
		break;
	}
	strconv(buf, f);
	return sizeof(char*);
}

/*
 * Verify an exception handler.
 */

static void
verifyehpc(Code *c, int pc)
{
	if(pc >= c->code_length || c->j[pc].size == 0)
		verifyerrormess("handler pc");
}

static void
verifyhandler(Code *c, Handler *h)
{
	verifyehpc(c, h->start_pc);

	if(h->end_pc != c->code_length)
		verifyehpc(c, h->end_pc);

	verifyehpc(c, h->handler_pc);

	if(h->catch_type != 0)
		verifycpindex(nil, h->catch_type, 1 << CON_Class);
}

/*
 * Disassemble code for a method.
 */

Code*
javadas(Attr *a)
{
	Attr at;
	Code *c;
	Handler *h, *h1, *h2;
	Jinst *j;
	int pc, codelen;
	int l, i, k, n, nat, nln, CON_bits;

	uSet(a->info);
	c = Malloc(sizeof(Code));
	c->max_stack = u2();
	c->max_locals = u2();
	c->code_length = u4();
	if(c->code_length == 0 || c->code_length > 65535)
		verifyerrormess("code_length");
	/* +1 is for exception object */
	c->j = Mallocz((c->code_length+1)*sizeof(Jinst));

	l = -1;
	CON_bits = -1;
	pc = 0;
	codelen = c->code_length;
	while(codelen > 0) {
		j = &c->j[pc];
		j->op = u1();
		j->pc = pc;
		switch(tab[j->op].kind) {
		case Z:
			l = 1;
			j->size = l;
			break;
		case V1:
			j->u.i = (schar)u1();
			l = 2;
			j->size = l;
			break;
		case B2:
		case V2:
			j->u.i = (short)u2();
			l = 3;
			j->size = l;
			break;
		case B4:
			j->u.i = (int)u4();
			l = 5;
			j->size = l;
			break;
		case X1:
			j->u.i = u1();
			if(j->op == Jldc) {
				CON_bits = 1 << CON_Integer | 1 << CON_Float | 1 << CON_String;
				verifycpindex(j, j->u.i, CON_bits);
			}
			l = 2;
			j->size = l;
			break;
		case X2:
			j->u.i = u2();
			switch(j->op) {
			case Jldc_w:
				CON_bits = 1 << CON_Integer | 1 << CON_Float | 1 << CON_String;
				break;
			case Jldc2_w:
				CON_bits = 1 << CON_Long | 1 << CON_Double;
				if(j->u.i == class->cp_count-1)
					verifyerror(j);
				break;
			case Jgetstatic:
			case Jputstatic:
			case Jgetfield:
			case Jputfield:
				CON_bits = 1 << CON_Fieldref;
				break;
			case Jinvokevirtual:
			case Jinvokespecial:
			case Jinvokestatic:
				CON_bits = 1 << CON_Methodref;
				break;
			case Jnew:
			case Janewarray:
			case Jcheckcast:
			case Jinstanceof:
				CON_bits = 1 << CON_Class;
				break;
			}
			verifycpindex(j, j->u.i, CON_bits);
			l = 3;
			j->size = l;
			break;
		case X1C:
			j->u.x1c.ix = u1();
			j->u.x1c.icon = (schar)u1();
			l = 3;
			j->size = l;
			break;
		case X2D:
			j->u.x2d.ix = u2();
			j->u.x2d.dim = u1();
			verifycpindex(j, j->u.x2d.ix, 1 << CON_Class);
			if(j->u.x2d.dim < 1)
				verifyerror(j);
			l = 4;
			j->size = l;
			break;
		case AT:
			j->u.i = u1();
			if(j->u.i < T_BOOLEAN || j->u.i > T_LONG)
				verifyerror(j);
			l = 2;
			j->size = l;
			break;
		case T1:
			if((pc+1)%4)	/* <0-3 byte pad> */
				n = 4-(pc+1)%4;
			else
				n = 0;
			l = n;
			while(n--)
				u1();
			j->u.t1.dflt = (int)u4();
			j->u.t1.lb = (int)u4();
			j->u.t1.hb = (int)u4();
			if(j->u.t1.lb > j->u.t1.hb)
				verifyerror(j);
			n = j->u.t1.hb - j->u.t1.lb + 1;
			j->u.t1.tbl = Malloc(n*sizeof(int));
			for(i = 0; i < n; i++)
				j->u.t1.tbl[i] = (int)u4();
			l += 13 + n * 4;
			j->size = l;
			break;
		case T2:
			if((pc+1)%4)	/* <0-3 byte pad> */
				n = 4-(pc+1)%4;
			else
				n = 0;
			l = n;
			while(n--)
				u1();
			j->u.t2.dflt = (int)u4();
			j->u.t2.np = (int)u4();
			n = j->u.t2.np;
			if(n < 0)
				verifyerror(j);
			j->u.t2.tbl = Malloc(n*2*sizeof(int));
			for(i = 0; i < n*2; i++)
				j->u.t2.tbl[i] = (int)u4();
			for(i = 2; i < n*2; i += 2) {
				if(j->u.t2.tbl[i-2] > j->u.t2.tbl[i])
					verifyerror(j);
			}
			l += 9 + n * 8;
			j->size = l;
			break;
		case W:
			j->u.w.op = u1();
			j->u.w.ix = u2();
			switch(j->u.w.op) {
			case Jiload:
			case Jlload:
			case Jfload:
			case Jdload:
			case Jaload:
			case Jistore:
			case Jlstore:
			case Jfstore:
			case Jdstore:
			case Jastore:
			case Jret:
				l = 4;
				break;
			case Jiinc:
				j->u.w.icon = (short)u2();
				l = 6;
				break;
			default:
				verifyerror(j);
			}
			j->size = l;
			break;
		case X2C0:
			j->u.x2c0.ix = u2();
			j->u.x2c0.narg = u1();
			j->u.x2c0.zero = u1();	/* must be 0 */
			verifycpindex(j, j->u.x2c0.ix, 1 << CON_InterfaceMref);
			if(j->u.x2c0.narg < 1 || j->u.x2c0.zero != 0)
				verifyerror(j);
			l = 5;
			j->size = l;
			break;
		default:
			verifyerrormess("illegal opcode");
			return nil;	/* for compiler */
		}
		codelen -= l;
		pc += l;
	}
	if(codelen != 0)
		verifyerrormess("code_length");

	c->nex = u2();
	if(c->nex == 0)
		c->ex = nil;
	else {
		c->ex = Malloc(c->nex*sizeof(Handler*));
		for(i = 0; i < c->nex; i++) {
			h = Malloc(sizeof(Handler));
			h->start_pc = u2();
			h->end_pc = u2();
			h->handler_pc = u2();
			h->catch_type = u2();
			c->ex[i] = h;
			verifyhandler(c, h);
			/*
			 * sort nested try blocks that have same start_pc,
			 * outer-most go first (see cvtehinfo() [xlate.c])
			 */
			for(k = i; k > 0; k--) {
				h1 = c->ex[k];
				h2 = c->ex[k-1];
				if(h1->start_pc == h2->start_pc
				&& h1->end_pc > h2->end_pc) {
					c->ex[k] = h2;
					c->ex[k-1] = h1;
				}
			}
		}
	}

	if(gensbl == 0)
		return c;

	/* interpret LineNumberTable attributes */
	nat = u2();
	for(i = 0; i < nat; i++) {
		getattr(&at);
		if(strcmp(STRING(at.name), "LineNumberTable") == 0) {
			nln = (at.info[0] << 8) | at.info[1];
			for(k = 2; k < nln*4+2; k += 4) {
				pc = (at.info[k] << 8) | at.info[k+1];
				c->j[pc].line = (at.info[k+2] << 8) | at.info[k+3];
			}
		}
		free(at.info);
	}
	pc = 0;
	n = 0;
	while(pc < c->code_length) {
		if(c->j[pc].line == 0)
			c->j[pc].line = n;
		else
			n = c->j[pc].line;
		pc += c->j[pc].size;
	}

	return c;
}

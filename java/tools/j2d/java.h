#include "lib9.h"
#include "bio.h"
#include "isa.h"

enum {
	/* Java constant pool tags */

	CON_Utf8		= 1,
	/* CON_Unicode		= 2, */		/* obsolete */
	CON_Integer		= 3,
	CON_Float		= 4,
	CON_Long		= 5,
	CON_Double		= 6,
	CON_Class		= 7,
	CON_String		= 8,
	CON_Fieldref		= 9,
	CON_Methodref		= 10,
	CON_InterfaceMref	= 11,
	CON_NameAndType		= 12,

	/* Java access flags */

	ACC_PUBLIC		= 0x0001,
	ACC_PRIVATE		= 0x0002,
	ACC_PROTECTED		= 0x0004,
	ACC_STATIC		= 0x0008,
	ACC_FINAL		= 0x0010,
	ACC_SUPER		= 0x0020,
	ACC_SYNCHRONIZED	= 0x0020,	/* sic */
	ACC_VOLATILE		= 0x0040,
	ACC_TRANSIENT		= 0x0080,
	ACC_NATIVE		= 0x0100,
	ACC_INTERFACE		= 0x0200,
	ACC_ABSTRACT		= 0x0400,

	_MUSTCOMPILE		= MUSTCOMPILE<<16,
	_DONTCOMPILE		= DONTCOMPILE<<16,

	/* basic block flags */

	BB_LDR		= 1 << 0,	/* set for all leaders */
	BB_ENTRY	= 1 << 1,	/* method entry point */
	BB_FINALLY	= 1 << 2,	/* finally block entry point */
	BB_HANDLER	= 1 << 3,	/* EH entry point */
	BB_REACHABLE	= 1 << 4,	/* reachable basic block */

	/* basic block states */

	BB_PRESIM	= 1 << 0,	/* not simulated yet */
	BB_ACTIVE	= 1 << 1,	/* simulating or being unified */
	BB_POSTSIM	= 1 << 2,	/* simulated */
	BB_POSTUNIFY	= 1 << 3,	/* unified */

	/* Dis operand classification */

	Anone		= 0,
	Aimm,
	Amp,
	Ampind,
	Afp,
	Afpind,
	Aend,

	/* Dis n(fp) types */

	DIS_X		= 0,	/* not yet typed */
	DIS_W,			/* 'B', 'Z', 'C', 'S', 'I' */
	DIS_L,			/* 'F', 'J', 'D' */
	DIS_P,			/* 'L', '[' */

	/* inferno/vm/Array */

	ARY_DATA	= IBY2WD,	/* Array data (Dis array) */
	ARY_NDIM	= 2*IBY2WD,	/* number of dimensions */
	ARY_ADT		= 3*IBY2WD,	/* 'ref Class' of element type */
	ARY_ETYPE	= 4*IBY2WD,	/* primitive element type code */

	/* java/lang/String */

	STR_DISSTR	= IBY2WD,	/* offset to Dis string in a String */

	/* miscellaneous */

	REFSYSEX	= 24,		/* 24(fp) is a 'ref Sys->Exception' */
	EXOBJ		= 28,		/* 28(fp) is exception object */
	THISOFF		= 32,		/* 32(fp) is "this" pointer */
	REGSIZE		= 32,		/* 32(fp) is first usable frame cell */
	Hashsize	= 31,
	ALLOCINCR	= 16
};

typedef struct	Attr	Attr;
typedef struct	Field	Field;
typedef struct	Method	Method;
typedef union	Const	Const;
typedef struct	Class	Class;
typedef struct	Jinst	Jinst;
typedef struct	StkSnap	StkSnap;
typedef struct	BB	BB;
typedef struct	BBList	BBList;
typedef struct	Code	Code;
typedef struct	PCode	PCode;
typedef struct	Handler	Handler;

typedef struct	Addr	Addr;
typedef struct	Inst	Inst;

union Const {
	double	tdouble;		/* CONSTANT_[Float|Double]_info */
	vlong	tvlong;			/* CONSTANT_Long_info */
	int	tint;			/* CONSTANT_Integer_info */
	ushort	string_index;		/* CONSTANT_String_info */
	struct {			/* CONSTANT_Class_info */
		ushort	name_index;
	} ci;
	/* CONSTANT_[Fieldref|Methodref|InterfaceMethodref]_info */
	struct {
		ushort	class_index;
		ushort	name_type_index;
	} fmiref;
	struct {			/* CONSTANT_NameAndType */
		ushort	name_index;
		ushort	sig_index;
	} nat;
	struct {			/* CONSTANT_Utf8_info */
		ushort	ln;
		char	*utf8;
	} utf8;
};

struct Attr {				/* attribute_info */
	ushort	name;
	uint	ln;
	uchar	*info;
};

struct Field {				/* field_info */
	ushort	access_flags;
	ushort	name_index;
	ushort	sig_index;
	ushort	attr_count;
	Attr	*attr_info;		/* ConstantValue attributes */
};

struct Method {				/* method_info */
	ushort	access_flags;
	ushort	name_index;
	ushort	sig_index;
	ushort	attr_count;
	Attr	*attr_info;		/* Code, Exceptions attributes */
};

struct Class {				/* ClassFile */
	/* uint	magic; */		/* 0xcafebabe */
	ushort	min;
	ushort	maj;
	ushort	cp_count;
	Const	*cps;
	char	*cts;
	ushort	access_flags;
	ushort	this_class;
	ushort	super_class;
	ushort	interfaces_count;
	ushort	*interfaces;
	ushort	fields_count;
	Field	*fields;
	ushort	methods_count;
	Method	*methods;
	ushort	source_file;
};

struct Addr {				/* Dis operand */
	uchar	mode;			/* Anone, Aimm, Amp, etc. */
	union {
		int	ival;		/* immediate, $ival */
		int	offset;		/* single indirect, offset(fp) */
		struct {		/* double indirect, si(fi(fp)) */
			ushort	fi;
			ushort	si;
		} b;
	} u;
};

struct Jinst {			/* Java instruction */
	uchar	op;		/* op code */
	uchar	jtype;		/* Java type of dst ('I', '[', etc.) */
	int	pc;		/* pc offset */
	int	line;		/* source line number */
	int	size;		/* size of this instruction */
	Inst	*dis;		/* Dis code for this instruction */
	BB	*bb;		/* the instruction's basic block */
	int	nsrc;		/* 0 or more source operands */
	int	*src;
	Addr	dst;		/* usual destination operand */
	Addr	movsrc;		/* source operand if mov generated for load */
	union {
		int	i;	/* AT, X1, X2, B2, B4, V1, V2 */
		struct {	/* iinc */
			uint	ix;
			int	icon;
		} x1c;
		struct {	/* invokeinterface */
			uint	ix;
			uint	narg;
			uint	zero;
		} x2c0;
		struct {	/* multianewarray */
			uint	ix;
			uint	dim;
		} x2d;
		struct {	/* tableswitch */
			int	dflt;
			int	lb;
			int	hb;
			int	*tbl;
		} t1;
		struct {	/* lookupswitch */
			int	dflt;
			int	np;
			int	*tbl;
		} t2;
		struct {	/* wide */
			uchar	op;
			uint	ix;
			int	icon;
		} w;
	} u;
};

struct Handler {		/* exception_table entry */
	ushort	start_pc;
	ushort	end_pc;
	ushort	handler_pc;
	ushort	catch_type;
};

struct Code {			/* one Java method */
	int	max_stack;
	int	max_locals;
	int	code_length;
	Jinst	*j;
	int	nex;
	Handler	**ex;
};

struct PCode {
	Code	*code;
	char	*name;
	char	*sig;
};

struct StkSnap {		/* snapshot of simulated Java VM stack */
	uchar	jtype;
	int	npc;
	int	*pc;
};

struct BB {			/* basic block */
	int	id;		/* unique identifier */
	Jinst	*js;		/* first instruction in basic block */
	Jinst	*je;		/* last instruction in basic block */
	BBList	*succ;		/* successors */
	BBList	*pred;		/* predecessors */
	uchar	*dom;		/* bit-vector of dominators */
	uchar	flags;		/* basic block leader flags */
	uchar	state;		/* BB_PRESIM, etc. */
	int	entrysz;	/* size of saved entry stack */
	StkSnap	*entrystk;	/* snapshot of entry stack */
	int	exitsz;		/* size of saved exit stack */
	StkSnap	*exitstk;	/* snapshot of exit stack */
};

struct BBList {
	BB	*bb;
	BBList	*next;
};

struct Inst {			/* Dis instruction */
	uchar	op;		/* op code */
	Addr	s;		/* source */
	Addr	m;		/* middle */
	Addr	d;		/* destination */
	int	pc;		/* 0-based instruction offset */
	Jinst	*j;
	Inst	*next;
};

/* asm.c */
extern	int	Aconv(va_list*, Fconv*);
extern	int	Iconv(va_list*, Fconv*);
extern	void	asminst(void);
extern	void	sblinst(Biobuf*);
extern	Inst	*clinitclone;

/* bb.c */
extern	void	flowgraph(void);
extern	void	bbfree(void);
extern	void	bbinit(void);
extern	void	bbput(BB*);
extern	BB	*bbget(void);
extern	void	crefseed(void);
extern	void	crefenter(char*, BB*);
extern	int	crefstate(char*, BB*, int);
extern	void	creffree(void);

/* desc.c */
extern	int	descid(int, int, uchar*);
extern	void	mpdescid(int, int, uchar*);
extern	void	asmdesc(void);
extern	void	disndesc(void);
extern	void	disdesc(void);

/* dis.c */
extern	void	discon(int);
extern	void	disword(int);
extern	void	disdata(int, int);
extern	void	disflush(int, int, int);
extern	void	disbyte(int, int);
extern	void	disint(int, int);
extern	void	dislong(int, vlong);
extern	void	disreal(int, double);
extern	void	disstring(int, char*);
extern	void	disarray(int, int, int);
extern	void	disapop(void);
extern	void	disout(void);
extern	Inst	*ihead;
extern	Inst	*itail;

/* entry.c */
extern	void	setentry(int, int);
extern	void	asmentry(void);
extern	void	disentry(void);

/* finally.c */
extern	void	finallyentry(int);
extern	void	finallyalloc(void);
extern	void	jsrfixup(Addr*, Addr*, int, int);
extern	void	retfixup(Addr*, Addr*, int);
extern	void	finallyfree(void);

/* frame.c */
extern	void	openframe(char*, int);
extern	int	closeframe(void);
extern	int	localix(uchar, int);
extern	void	reservereg(StkSnap*, int);
extern	int	getreg(uchar);
extern	void	acqreg(Addr*);
extern	void	relreg(Addr*);
extern	void	clearreg(void);
extern	void	disstackext(void);

/* javadas.c */
extern	int	Jconv(va_list*, Fconv*);
extern	Code	*javadas(Attr*);

/* javatbl.c */
extern	int	isload(Jinst*);
extern	int	isstore(Jinst*);

/* links.c */
extern	void	xtrnlink(int, int, char*, char*);
extern	void	addfcpatch(Inst*, Inst*, char*, char*);
extern	void	dofcpatch(void);
extern	void	asmlinks(void);
extern	void	disnlinks(void);
extern	void	dislinks(void);
extern	void	sbllinks(Biobuf*);

/* loader.c */
extern	void	ClassLoader(char*);
extern	void	dumpcpool(void);
extern	char	*CLASSNAME(int);
extern	char	*STRING(int);
extern	Class	*class;
extern	PCode	*pcode;
extern	char	*THISCLASS;
extern	char	*SUPERCLASS;

/* main.c */
extern	int	compileflag;
extern	int	gensbl;
extern	int	verbose;
extern	Biobuf	*bout;
extern	char	*ofile;

/* mdata.c */
extern	int	mpint(int);
extern	int	mplong(vlong);
extern	int	mpreal(double);
extern	int	mpstring(char*);
extern	int	mpcase(int, int*);
extern	void	mpdesc(void);
extern	int	mpgoto(int, int*);
extern	void	asmarray(int, int, int, int);
extern	void	asmint(int, int);
extern	void	asmstring(int, char*);
extern	void	asmvar(void);
extern	void	disnvar(void);
extern	void	disvar(void);

/* module.c */
extern	void	asmmod(void);
extern	void	dismod(void);

/* patch.c */
extern	void	patchop(Inst*);
extern	void	patchcase(Inst*, int, int*);
extern	void	patchmethod(int);
extern	void	patchfree(void);

/* sbl.c */
extern	void	sblout(char*);

/* simjvm.c */
extern	void	simjvm(char*);

/* unify.c */
extern	void	unify(void);

/* util.c */
extern	void	uSet(uchar*);
extern	void	uN(int);
extern	uchar	u1(void);
extern	ushort	u2(void);
extern	uint	u4(void);
extern	void	getattr(Attr*);
extern	int	CVattrindex(Field*);
extern	char	*uPtr(void);
extern	int	align(int, int);
extern	void	pstring(char*);
extern	void	fatal(char*, ...);
extern	void	verifycpindex(Jinst*, int, int);
extern	void	verifyerror(Jinst*);
extern	void	verifyerrormess(char*);
extern	char	*nextjavatype(char*);
extern	uchar	j2dtype(uchar);
extern	void	addrimm(Addr*, int);
extern	int	notimmable(int);
extern	void	addrsind(Addr*, uchar, int);
extern	void	addrdind(Addr*, uchar, uint, uint);
extern	void	dstreg(Addr*, uchar);
extern	void	setbit(uchar*, int);
extern	int	hashval(char*);
extern	void	*Malloc(uint);
extern	void	*Mallocz(uint);
extern	void	*Realloc(void*, uint);
extern	int	cellsize[];

/* xlate.c */
extern	void	xlate(void);
extern	Code	*code;
#pragma varargck	type	"A" Addr*

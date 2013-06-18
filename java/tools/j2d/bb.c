#include "java.h"
#include "javaisa.h"
#include "reloc.h"

static	BB	**roots;	/* root basic blocks */
static	int	nr;		/* number of root basic blocks */
static	int	maxr;		/* maximum number of roots */

static	BB	**bbtbl;	/* basic blocks */
static	int	nbb;		/* number of basic blocks */

static void
setflags(int pc, uchar flags)
{
	Jinst *j;

	j = &code->j[pc];
	if(j->bb == nil) {
		j->bb = Mallocz(sizeof(BB));
		j->bb->id = -1;
		j->bb->js = j;
		j->bb->state = BB_PRESIM;
		nbb += 1;
		/* record root basic blocks */
		if(flags & (BB_ENTRY | BB_FINALLY | BB_HANDLER)) {
			if(nr >= maxr) {
				maxr += ALLOCINCR;
				roots = Realloc(roots, maxr*sizeof(BB*));
			}
			roots[nr] = j->bb;
			nr += 1;
		}
	}
	j->bb->flags |= flags;
}

/*
 * Verify that the target of a jump is valid.
 */

static void
verifyjump(Jinst *j, int offset)
{
	int dst;

	dst = j->pc + offset;
	if(dst < 0 || dst >= code->code_length || code->j[dst].size == 0)
		verifyerror(j);
}

/*
 * Mark the instructions of a method that are basic block leaders.
 */

static void
markldrs(void)
{
	Jinst *j;
	int i;
	int pc, pcnext;

	/* first instruction is a leader */
	setflags(0, BB_LDR | BB_ENTRY);

	/* exception handler entry points are leaders */
	for(i = 0; i < code->nex; i++)
		setflags(code->ex[i]->handler_pc, BB_LDR | BB_HANDLER);

	pc = 0;
	while(pc < code->code_length) {
		j = &code->j[pc];
		pcnext = pc+j->size;
		switch(j->op) {
		case Jwide:
			if(j->u.w.op != Jret)
				break;
		case Jret:
		case Jireturn:
		case Jlreturn:
		case Jfreturn:
		case Jdreturn:
		case Jareturn:
		case Jreturn:
		case Jathrow:
			if(pcnext < code->code_length)
				setflags(pcnext, BB_LDR);
			break;
		case Jifeq:
		case Jifne:
		case Jiflt:
		case Jifge:
		case Jifgt:
		case Jifle:
		case Jif_icmpeq:
		case Jif_icmpne:
		case Jif_icmplt:
		case Jif_icmpge:
		case Jif_icmpgt:
		case Jif_icmple:
		case Jif_acmpeq:
		case Jif_acmpne:
		case Jifnull:
		case Jifnonnull:
			verifyjump(j, j->u.i);
			setflags(pc+j->u.i, BB_LDR);
			setflags(pcnext, BB_LDR);
			break;
		case Jgoto:
		case Jgoto_w:
			verifyjump(j, j->u.i);
			setflags(pc+j->u.i, BB_LDR);
			if(pcnext < code->code_length)
				setflags(pcnext, BB_LDR);
			break;
		case Jjsr:
		case Jjsr_w:
			/* target of jsr is leader, jsr successor isn't */
			verifyjump(j, j->u.i);
			setflags(pc+j->u.i, BB_LDR | BB_FINALLY);
			finallyentry(pc+j->u.i);
			break;
		case Jtableswitch:
			for(i = 0; i < j->u.t1.hb - j->u.t1.lb + 1; i++) {
				verifyjump(j, j->u.t1.tbl[i]);
				setflags(pc+j->u.t1.tbl[i], BB_LDR);
			}
			verifyjump(j, j->u.t1.dflt);
			setflags(pc+j->u.t1.dflt, BB_LDR);
			if(pcnext < code->code_length)
				setflags(pcnext, BB_LDR);
			break;
		case Jlookupswitch:
			for(i = 0; i < j->u.t2.np; i++) {
				verifyjump(j, j->u.t2.tbl[2*i+1]);
				setflags(pc+j->u.t2.tbl[2*i+1], BB_LDR);
			}
			verifyjump(j, j->u.t2.dflt);
			setflags(pc+j->u.t2.dflt, BB_LDR);
			if(pcnext < code->code_length)
				setflags(pcnext, BB_LDR);
			break;
		}
		pc = pcnext;
	}
}

/*
 * b2 is a successor of b1; add appropriate links.
 */

static void
addedges(BB *b1, BB *b2)
{
	BBList *l;

	/* add successor link from b1 to b2 */
	l = Malloc(sizeof(BBList));
	l->bb = b2;
	l->next = b1->succ;
	b1->succ = l;

	/* add predecessor link from b2 to b1 */
	l = Malloc(sizeof(BBList));
	l->bb = b1;
	l->next = b2->pred;
	b2->pred = l;
}

/*
 * Connect basic blocks to their successors and predecessors.
 */

static void
connect(BB *bb)
{
	int i;
	Jinst *je;
	int pc;

	je = bb->je;
	pc = je->pc;
	switch(je->op) {
	case Jwide:
		if(je->u.w.op == Jret)
			break;
	default:
		if(pc+je->size < code->code_length)
			addedges(bb, code->j[pc+je->size].bb);
		break;
	case Jret:
	case Jireturn:
	case Jlreturn:
	case Jfreturn:
	case Jdreturn:
	case Jareturn:
	case Jreturn:
	case Jathrow:
		break;
	case Jifeq:
	case Jifne:
	case Jiflt:
	case Jifge:
	case Jifgt:
	case Jifle:
	case Jif_icmpeq:
	case Jif_icmpne:
	case Jif_icmplt:
	case Jif_icmpge:
	case Jif_icmpgt:
	case Jif_icmple:
	case Jif_acmpeq:
	case Jif_acmpne:
	case Jifnull:
	case Jifnonnull:
		addedges(bb, code->j[pc+je->u.i].bb);	/* branch target */
		addedges(bb, code->j[pc+je->size].bb);	/* fall through */
		break;
	case Jgoto:
	case Jgoto_w:
		addedges(bb, code->j[pc+je->u.i].bb);
		break;
	case Jtableswitch:
		for(i = 0; i < je->u.t1.hb - je->u.t1.lb + 1; i++)
			addedges(bb, code->j[pc+je->u.t1.tbl[i]].bb);
		addedges(bb, code->j[pc+je->u.t1.dflt].bb);
		break;
	case Jlookupswitch:
		for(i = 0; i < je->u.t2.np; i++)
			addedges(bb, code->j[pc+je->u.t2.tbl[2*i+1]].bb);
		addedges(bb, code->j[pc+je->u.t2.dflt].bb);
		break;
	}
}

static void dominators(void);

/*
 * Build the basic block control flow graph.
 */

void
flowgraph(void)
{
	Jinst *js, *je;
	int pc, pcnext;

	markldrs();

	pc = 0;
	while(pc < code->code_length) {
		js = &code->j[pc];
		if(js->bb == nil)
			fatal("flowgraph: nil bb\n");
		/* find last instruction in basic block */
		je = js;
		while(1) {
			pcnext = je->pc + je->size;
			if(pcnext >= code->code_length
			|| code->j[pcnext].bb != nil)	/* hence a leader */
				break;
			je += je->size;
			je->bb = js->bb;
		}
		js->bb->je = je;
		connect(js->bb);
		pc = pcnext;
	}

	dominators();
	finallyalloc();
}

/*
 * Free basic block structures after each method is translated.
 */

static void
bblistfree(BBList *l)
{
	BBList *l2;

	while(l) {
		l2 = l->next;
		free(l);
		l = l2;
	}
}

void
bbfree(void)
{
	int i;
	BB *bb;

	for(i = 0; i < nbb; i++) {
		bb = bbtbl[i];
		if(bb) {
			bblistfree(bb->succ);
			bblistfree(bb->pred);
			free(bb->dom);
			free(bb->entrystk);
			free(bb->exitstk);
			free(bb);
		}
	}
	free(roots);
	roots = nil;
	nr = 0;
	maxr = 0;
	free(bbtbl);
	bbtbl = nil;
	nbb = 0;
}

/*
 * The following stuff is used during method simulation.
 */

#define SSIZE	256
static	BB	*bbstack[SSIZE];
static	int	bbtos;

void
bbput(BB *bb)
{
	if(bbtos == SSIZE)
		fatal("bbstack overflow\n");
	bb->state = BB_ACTIVE;
	bb->flags |= BB_REACHABLE;
	bbstack[bbtos++] = bb;
}

BB*
bbget(void)
{
	return (bbtos == 0) ? nil : bbstack[--bbtos];
}

void
bbinit(void)
{
	int i;

	bbtos = 0;
	for(i = 0; i < nr; i++)
		bbput(roots[i]);
}

static void
bbinit2(void)
{
	bbtos = 0;
}

static void
bbput2(BB *bb)
{
	if(bbtos == SSIZE)
		fatal("bbstack overflow\n");
	bbstack[bbtos++] = bb;
}

static void
intersect(uchar *doml, uchar *domr, int domsz)
{
	int i;

	for(i = 0; i < domsz; i++)
		doml[i] &= domr[i];
}

#define	IBIT2UCHAR	8
static uchar mask[IBIT2UCHAR] = {
	0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01
};

static void
setdombit(uchar *dom, int n)
{
	dom[n/IBIT2UCHAR] |= mask[n%IBIT2UCHAR];
}

static int
getdombit(uchar *dom, int n)
{
	return dom[n/IBIT2UCHAR] & mask[n%IBIT2UCHAR];
}

/*
 * Determine dominators for the basic blocks of a sub-graph.
 * rid is the id of the root basic block.
 * n basic blocks are reachable from rid.
 * Algorithm 10.16 from Aho, Sethi, Ullman.
 */

static void
dom(int rid, int n)
{
	int changes, i, domsz;
	uchar *dom;
	BB *bb;
	BBList *l;

	domsz = (nbb-1)/IBIT2UCHAR + 1;
	dom = Mallocz(domsz);
	setdombit(dom, rid);
	bbtbl[rid]->dom = dom;

	dom = Mallocz(domsz);
	for(i = rid; i < rid+n; i++)
		setdombit(dom, i);
	for(i = rid+1; i < rid+n; i++) {
		bb = bbtbl[i];
		/* this bb may have been seen in another sub-graph */
		if(bb->dom == nil)
			bb->dom = Malloc(domsz);
		memcpy(bb->dom, dom, domsz);
	}

	do {
		changes = 0;
		for(i = rid+1; i < rid+n; i++) {
			bb = bbtbl[i];
			memcpy(dom, bb->dom, domsz);
			memset(bb->dom, 0, domsz);
			for(l = bb->pred; l; l = l->next) {
				/*
				 * If predecessor is out of range of the
				 * sub-graph being considered, then mark
				 * this bb as undominable.
				 */
				if(l->bb->id < rid || l->bb->id >= rid+n) {
					memset(bb->dom, 0, domsz);
					break;
				}
				if(l == bb->pred)
					memcpy(bb->dom, l->bb->dom, domsz);
				else
					intersect(bb->dom, l->bb->dom, domsz);
			}
			setdombit(bb->dom, i);
			if(memcmp(dom, bb->dom, domsz) != 0)
				changes = 1;
		}
	} while(changes);
	free(dom);
}

/*
 * Determine dominators of the basic blocks in the flow graph.
 */

static void
dominators(void)
{
	int i, id, rid;
	BB *bb;
	BBList *l;

	bbtbl = Malloc(nbb*sizeof(BB*));
	id = 0;

	bbinit2();
	for(i = 0; i < nr; i++) {
		if(roots[i]->id != -1)
			continue;
		rid = id;
		bbput2(roots[i]);
		while(bb = bbget()) {
			if(bb->id == -1) {
				bb->id = id;
				bbtbl[id] = bb;
				id += 1;
			}
			for(l = bb->succ; l; l = l->next) {
				if(l->bb->id == -1)
					bbput2(l->bb);
			}
		}
		dom(rid, id - rid);
	}
}

typedef struct CRef	CRef;
typedef struct Hash	Hash;

struct CRef {
	char	*name;	/* class name */
	int	kind;	/* LTCODE or RTCODE */
	int	last;	/* most recent basic block in which rtload() */
			/* called for this class */
	BBList	*l;	/* basic blocks in which class is referenced */
};

struct Hash {
	CRef	*cr;
	Hash	*next;
};

static	Hash	*crtbl[Hashsize];	/* hash table of referenced classes */

enum {
	LOOKONLY,
	LOOKENTER
};

static CRef*
creflook(char *classname, int enter)
{
	int i;
	Hash *h;
	CRef *cr;

	i = hashval(classname);
	for(h = crtbl[i]; h; h = h->next) {
		if(strcmp(classname, h->cr->name) == 0)
			return h->cr;
	}
	if(enter == LOOKONLY)
		return nil;
	cr = Mallocz(sizeof(CRef));
	cr->name = classname;
	cr->last = -1;
	h = Malloc(sizeof(Hash));
	h->cr = cr;
	h->next = crtbl[i];
	crtbl[i] = h;
	return cr;
}

/*
 * Seed hash table with classes to be resolved at link-time.
 */

static char *ltload[] = {
	nil,			/* THISCLASS */
	nil,			/* SUPERCLASS */
	"inferno/vm/Array",
	"java/lang/Class",
	"java/lang/Object",
	"java/lang/String",
	"java/lang/StringBuffer",
	"java/io/Serializable"
};

void
crefseed(void)
{
	CRef *cr;
	int i;

	ltload[0] = THISCLASS;
	ltload[1] = SUPERCLASS;
	for(i = 0; i < sizeof(ltload)/sizeof(char*); i++) {
		if(ltload[i]) {	/* SUPERCLASS == nil for Object */
			cr = creflook(ltload[i], LOOKENTER);
			cr->kind = LTCODE;
		}
	}
}

void
crefenter(char *name, BB *bb)
{
	CRef *cr;
	BBList *l;

	cr = creflook(name, LOOKENTER);
	if(cr->kind == LTCODE)
		return;

	/* cr->kind == RTCODE */
	for(l = cr->l; l; l = l->next) {
		if(bb->id == l->bb->id)
			return;
	}
	l = Malloc(sizeof(BBList));
	l->bb = bb;
	l->next = cr->l;
	cr->l = l;
}

/*
 * Class name referenced in basic block bb.
 * Should it be resolved at load-time (LTCODE) or run-time (RTCODE)?
 * Must rtload() be called (RTCALL)?
 */

int
crefstate(char *name, BB *bb, int handler)
{
	CRef *cr;
	BBList *l;

	cr = creflook(name, LOOKONLY);
	/*
	 * Class not directly referenced in bytecode.
	 * So assume it is referenced in an exception table.
	 */
	if(cr == nil)
		return RTCODE | RTCALL;

	if(cr->kind == LTCODE)
		return LTCODE;

	if(cr->last == bb->id)	/* rtload() already called in this bb */
		return RTCODE;

	for(l = cr->l; l; l = l->next) {
		if(bb->id == l->bb->id)
			continue;
		if(getdombit(bb->dom, l->bb->id))
			return RTCODE;
	}

	/*
	 * When setting up exception handlers, class names in catch clauses
	 * (i.e., class names in exception tables) should not be marked as
	 * having been rtloaded for the current basic block.  rtload()
	 * must be called separately in the try block for those classes
	 * (if referenced therein).
	 */
	if(!handler)
		cr->last = bb->id;
	return RTCODE | RTCALL;
}

void
creffree(void)
{
	int i;
	Hash *h;
	CRef *cr;

	for(i = 0; i < Hashsize; i++) {
		for(h = crtbl[i]; h; h = h->next) {
			cr = h->cr;
			cr->last = -1;
			bblistfree(cr->l);
			cr->l = nil;
		}
	}
}

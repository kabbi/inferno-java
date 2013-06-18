#include "java.h"
#include "javaisa.h"

/*
 * Manage method frame.
 */

/*
 * Local variables (including function parameters).
 */

typedef struct Local	Local;

struct Local {			/* local variable */
	uchar	dtype;		/* type of local (DIS_[BWLP]) */
	int	offset;		/* fp offset of this local */
	Local	*next;		/* for locals that are reused */
};

static	int	frameoff;	/* tracks growth of frame */
static	int	maxframe;	/* size of largest frame */
static	Local	*locals;	/* local variables */
static	int	nlocals;	/* number of locals (in the Java sense) */

/*
 * fp temporaries.
 */

typedef struct Fp	Fp;

struct Fp {
	uchar	dtype;
	int	refcnt;
};

static	int	tmpslwm;	/* lowest temporary fp offset */
static	int	tmpssz;		/* size of tmps array */
static	Fp	*tmps;		/* temporary arena */

/*
 * Resize the locals array.
 *
 * Since the Java VM reuses local variables (e.g., perhaps using
 * the same slot for an int and an Object reference), max_locals
 * doesn't always give the number of Dis locals to allow for.
 */

static void
resizelocals(int ix)
{
	int oldsz;

	oldsz = nlocals;
	while(ix >= nlocals)
		nlocals += ALLOCINCR;
	locals = Realloc(locals, nlocals*sizeof(Local));
	memset(&locals[oldsz], 0, ALLOCINCR*sizeof(Local));
}

/*
 * Reserve a frame cell for a local variable of the given type.
 * The Java VM reuses local variables.
 */

static void
reservelocal(uchar dtype, int ix)
{
	Local *l;

	if(ix >= nlocals)
		resizelocals(ix);
	if(locals[ix].dtype == dtype)
		return;
	if(locals[ix].dtype == DIS_X)	/* not yet reserved */
		l = &locals[ix];
	else {				/* check reuse list */
		for(l = locals[ix].next; l; l = l->next) {
			if(dtype == l->dtype)
				return;
		}
		l = Malloc(sizeof(Local));
		l->next = locals[ix].next;
		locals[ix].next = l;
	}
	l->dtype = dtype;
	frameoff = align(frameoff, cellsize[dtype]);
	l->offset = frameoff;
	frameoff += cellsize[dtype];
}

/*
 * Map the signature parameter types into 'locals' array.
 */

static void
mapmethodsig(char *sig, int isstatic)
{
	int index;

	index = 0;
	if(isstatic == 0) {
		reservelocal(DIS_P, index);	/* this pointer */
		index += 1;
	}
	sig++;	/* skip '(' */
	while(sig[0] != ')') {
		switch(sig[0]) {
		case 'Z':
		case 'B':
		case 'C':
		case 'S':
		case 'I':
			reservelocal(DIS_W, index);
			index += 1;
			break;
		case 'F':
			reservelocal(DIS_L, index);
			index += 1;
			break;
		case 'J':
		case 'D':
			reservelocal(DIS_L, index);
			index += 2;
			break;
		case 'L':
		case '[':
			reservelocal(DIS_P, index);
			index += 1;
			break;
		}
		sig = nextjavatype(sig);
	}
}

/*
 * Map references to local variables in the Java bytecode into 'locals' array.
 */

static void
maplocalrefs(void)
{
	Jinst *j, *je;

	j = &code->j[0];
	je = j + code->code_length;
	while(j < je) {
		switch(j->op) {
		case Jiinc:
			reservelocal(DIS_W, j->u.x1c.ix);
			break;
		case Jiload:
		case Jistore:
			reservelocal(DIS_W, j->u.i);
			break;
		case Jiload_0:
		case Jistore_0:
			reservelocal(DIS_W, 0);
			break;
		case Jiload_1:
		case Jistore_1:
			reservelocal(DIS_W, 1);
			break;
		case Jiload_2:
		case Jistore_2:
			reservelocal(DIS_W, 2);
			break;
		case Jiload_3:
		case Jistore_3:
			reservelocal(DIS_W, 3);
			break;
		case Jlload:
		case Jlstore:
		case Jfload:
		case Jfstore:
		case Jdload:
		case Jdstore:
			reservelocal(DIS_L, j->u.i);
			break;
		case Jlload_0:
		case Jlstore_0:
		case Jfload_0:
		case Jfstore_0:
		case Jdload_0:
		case Jdstore_0:
			reservelocal(DIS_L, 0);
			break;
		case Jlload_1:
		case Jlstore_1:
		case Jfload_1:
		case Jfstore_1:
		case Jdload_1:
		case Jdstore_1:
			reservelocal(DIS_L, 1);
			break;
		case Jlload_2:
		case Jlstore_2:
		case Jfload_2:
		case Jfstore_2:
		case Jdload_2:
		case Jdstore_2:
			reservelocal(DIS_L, 2);
			break;
		case Jlload_3:
		case Jlstore_3:
		case Jfload_3:
		case Jfstore_3:
		case Jdload_3:
		case Jdstore_3:
			reservelocal(DIS_L, 3);
			break;
		case Jret:
		case Jaload:
		case Jastore:
			reservelocal(DIS_P, j->u.i);
			break;
		case Jaload_0:
		case Jastore_0:
			reservelocal(DIS_P, 0);
			break;
		case Jaload_1:
		case Jastore_1:
			reservelocal(DIS_P, 1);
			break;
		case Jaload_2:
		case Jastore_2:
			reservelocal(DIS_P, 2);
			break;
		case Jaload_3:
		case Jastore_3:
			reservelocal(DIS_P, 3);
			break;
		case Jwide:	/* repeat from above */
			switch(j->u.w.op) {
			case Jiinc:
			case Jiload:
			case Jistore:
				reservelocal(DIS_W, j->u.w.ix);
				break;
			case Jlload:
			case Jlstore:
			case Jfload:
			case Jfstore:
			case Jdload:
			case Jdstore:
				reservelocal(DIS_L, j->u.w.ix);
				break;
			case Jaload:
			case Jastore:
			case Jret:
				reservelocal(DIS_P, j->u.w.ix);
				break;
			}
			break;
		}
		j += j->size;
	}
}

/*
 * Prepare a method's frame prior to translating its code.
 */

void
openframe(char *sig, int isstatic)
{
	frameoff = REGSIZE;
	/* 'code' can == nil; e.g, when generating <clinit> for an interface */
	if(code)
		nlocals = code->max_locals;
	else
		nlocals = 2;
	locals = Mallocz(nlocals*sizeof(Local));
	mapmethodsig(sig, isstatic);
	if(code)
		maplocalrefs();
	frameoff = align(frameoff, IBY2WD);
	tmpslwm = frameoff;
	tmpssz = frameoff;
	tmps = Mallocz(tmpssz*sizeof(Fp));
}

/*
 * Return fp index of a local variable.
 */

int
localix(uchar dtype, int ix)
{
	Local *l;

	if(dtype == locals[ix].dtype)
		return locals[ix].offset;
	for(l = locals[ix].next; l; l = l->next) {
		if(dtype == l->dtype)
			return l->offset;
	}
	fatal("localix: %d, %d\n", dtype, ix);
	return -1;	/* for the compiler */
}

/* fp temporary management starts here */

static void
incref(int off)
{
	if(off >= tmpslwm)		/* if <, then local variable */
		tmps[off-tmpslwm].refcnt++;
}

void
acqreg(Addr *a)
{
	switch(a->mode) {
	case Anone:
	case Aimm:
	case Amp:
	case Ampind:
		break;
	case Afp:
		incref(a->u.offset);
		break;
	case Afpind:
		incref(a->u.b.fi);
		break;
	}
}

/*
 * Reserve the fp temporaries referenced by a StkSnap of some basic block.
 */

void
reservereg(StkSnap *s, int sz)
{
	int i;

	for(i = 0; i < sz; i++)
		acqreg(&code->j[s[i].pc[0]].dst);
}

/*
 * Get fp offset of the next available register of the given type.
 */

static int
getoff(uchar dtype)
{
	int off;
	int stride;

	if(dtype == DIS_L) {
		stride = IBY2LG;
		off = tmpslwm % IBY2LG;
	} else {
		stride = IBY2WD;
		off = 0;
	}
	while(off < tmpssz) {
		if(tmps[off].refcnt == 0
		&& (tmps[off].dtype == dtype || tmps[off].dtype == DIS_X)) {
			return off;
		}
		off += stride;
	}
	return off;
}

/*
 * Get a register (fp offset thereof) of the appropriate type.
 */

int
getreg(uchar dtype)
{
	int off;
	int oldsz;

	off = getoff(dtype);
	if(off >= tmpssz) {	/* increase size of temporary arena */
		oldsz = tmpssz;
		tmpssz += ALLOCINCR*IBY2LG;
		tmps = Realloc(tmps, tmpssz*sizeof(Fp));
		memset(&tmps[oldsz], 0, (ALLOCINCR*IBY2LG)*sizeof(Fp));
	}
	tmps[off].dtype = dtype;
	if(dtype == DIS_L)	/* also reserve next word */
		tmps[off+IBY2WD].dtype = dtype;
	tmps[off].refcnt = 1;
	if(tmpslwm+off+cellsize[dtype] > frameoff)
		frameoff = tmpslwm+off+cellsize[dtype];
	return tmpslwm+off;
}

static void
decref(int off)
{
	if(off >= tmpslwm) {		/* if <, then local variable */
		if(--tmps[off-tmpslwm].refcnt < 0)
			fatal("decref: refcnt < 0\n");
	}
}

/*
 * "Free" register used by a.
 */

void
relreg(Addr *a)
{
	/* don't mess with exception object */
	if(code != nil && a == &code->j[code->code_length].dst)
		return;
	switch(a->mode) {
	case Anone:
	case Aimm:
	case Amp:
	case Ampind:
		break;
	case Afp:
		decref(a->u.offset);
		break;
	case Afpind:
		decref(a->u.b.fi);
		break;
	}
}

/*
 * Mark all temporary fp registers as available.  Leave typing as is.
 */

void
clearreg(void)
{
	int i;

	i = 0;
	while(i < frameoff-tmpslwm) {
		tmps[i].refcnt = 0;
		i += IBY2WD;
	}
}

/*
 * Calculate the type descriptor for a frame.
 */

static int
framedesc(void)
{
	int ln, id, i;
	uchar *map;
	Local *l;

	ln = frameoff / (8*IBY2WD) + (frameoff % (8*IBY2WD) != 0);
	map = Mallocz(ln);
	setbit(map, REFSYSEX);	/* slot for 'ref Sys->Exception' */
	setbit(map, EXOBJ);	/* slot for exception object */
	for(i = 0; i < nlocals; i++) {
		if(locals[i].dtype == DIS_P)
			setbit(map, locals[i].offset);
		for(l = locals[i].next; l; l = l->next) {
			if(l->dtype == DIS_P)
				setbit(map, l->offset);
		}
	}
	i = 0;
	while(i < frameoff-tmpslwm) {
		if(tmps[i].dtype == DIS_P)
			setbit(map, tmpslwm+i);
		i += IBY2WD;
	}
	id = descid(frameoff, ln, map);
	return id;
}

/*
 * Dispense with a frame.
 */

int
closeframe(void)
{
	int tid, i;
	Local *l, *l2;

	/* frame size is always a multiple of 8 */
	frameoff = align(frameoff, IBY2LG);
	if(frameoff > maxframe)
		maxframe = frameoff;
	tid = framedesc();
	for(i = 0; i < nlocals; i++) {
		for(l = locals[i].next; l; l = l2) {
			l2 = l->next;
			free(l);
		}
	}
	free(locals);
	frameoff = 0;
	tmpslwm = 0;
	tmpssz = 0;
	free(tmps);
	return tid;
}

/*
 * Minimum stack extent size.
 */

void
disstackext(void)
{
	discon(10*maxframe);
}

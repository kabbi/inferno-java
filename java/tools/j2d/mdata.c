#include "java.h"
#include "reloc.h"

/*
 * Manage module Data Section.
 */

enum {
	MP_INT,
	MP_LONG,
	MP_REAL,
	MP_STRING,
	MP_CASE,
	MP_GOTO
};

typedef struct Hentry	Hentry;
typedef	struct Datum	Datum;

struct Datum {
	uchar	kind;			/* MP_INT, etc. */
	int	offset;			/* byte offset in Data Section */
	union {
		struct {
			union {
				vlong	ival;	/* MP_INT, MP_LONG */
				double	rval;	/* MP_REAL */
			} u;
			Datum *next;
		} v;
		char *s;		/* MP_STRING */
		struct {		/* MP_CASE */
			int	n;	/* number of cases in jmptbl */
			int	*jmptbl;/* 3 words per case, plus default */
		} c;
		struct {		/* MP_GOTO (for finally blocks) */
			int	n;	/* number of entries in gototbl */
			int	*gototbl;
		} g;
	} u;
	Datum *next;
};

struct Hentry
{
	Datum	*md;
	Hentry	*next;
};

static	Hentry	*htable[Hashsize];
static	int	mpoff;

static	Datum	*mplist	= nil;
static	Datum	*mptail	= nil;
static	Datum	*llist	= nil;
static	Datum	*rlist	= nil;

/*
 * Allocate a Datum structure.
 */

static Datum*
newDatum(uchar kind)
{
	Datum *md;

	md = Malloc(sizeof(Datum));
	md->kind = kind;
	md->next = nil;
	md->u.v.next = nil;
	return md;
}

/*
 * Append a module datum to mplist.
 */

static void
append(Datum *md)
{
	if(mplist == nil)
		mplist = md;
	else
		mptail->next = md;
	mptail = md;
}

/*
 * Add a 'byte', int 'word', or 'long'.
 */

static int
mpintegral(uchar kind, vlong ival)
{
	Datum *md;
	int size;

	md = newDatum(kind);
	md->u.v.u.ival = ival;
	switch(kind) {
	case MP_INT:
		size = IBY2WD;
		mpoff = align(mpoff, IBY2WD);
		break;
	case MP_LONG:
		size = IBY2LG;
		mpoff = align(mpoff, IBY2LG);
		md->u.v.next = llist;
		llist = md;
		break;
	default:
		SET(size);	/* not reached */
	}
	md->offset = mpoff;
	mpoff += size;
	append(md);
	return md->offset;
}

/*
 * Add a 'word' (int).
 */

int
mpint(int ival)
{
	return mpintegral(MP_INT, ival);
}

/*
 * Add a 'long'.
 */

int
mplong(vlong lval)
{
	Datum *md;

	for(md = llist; md; md = md->u.v.next) {
		if(lval == md->u.v.u.ival)
			return md->offset;
	}
	return mpintegral(MP_LONG, lval);
}

/*
 * Add a 'real'.
 */

/* from math/dtoa.c */
#ifdef __LITTLE_ENDIAN
#define word0(x) ((unsigned long*)&x)[1]
#else
#define word0(x) ((unsigned long*)&x)[0]
#endif
#define Sign_bit 0x80000000

int
mpreal(double rval)
{
	Datum *md;

	for(md = rlist; md; md = md->u.v.next) {
		/* distinguish 0.0 from -0.0 */
		if(rval == md->u.v.u.rval &&
		(word0(rval) & Sign_bit) == (word0(md->u.v.u.rval) & Sign_bit))
			return md->offset;
	}
	md = newDatum(MP_REAL);
	md->u.v.u.rval = rval;
	md->u.v.next = rlist;
	rlist = md;
	mpoff = align(mpoff, IBY2FT);
	md->offset = mpoff;
	mpoff += IBY2FT;
	append(md);
	return md->offset;
}

/*
 * Add a 'case' jump table.
 */

int
mpcase(int sz, int *jt)
{
	Datum *md;

	md = newDatum(MP_CASE);
	mpoff = align(mpoff, IBY2WD);
	md->offset = mpoff;
	mpoff += (sz*3+2)*IBY2WD;
	md->u.c.n = sz;
	md->u.c.jmptbl = jt;
	append(md);
	return md->offset;
}

/*
 * Add a 'goto' jump table; used for implementing finally blocks.
 */

int
mpgoto(int n, int *gototbl)
{
	Datum *md;

	md = newDatum(MP_GOTO);
	mpoff = align(mpoff, IBY2WD);
	md->offset = mpoff;
	mpoff += (n+2)*IBY2WD;
	md->u.g.n = n;
	md->u.g.gototbl = gototbl;
	append(md);
	return md->offset+IBY2WD;
}

/*
 * Hash table lookup function.
 */

static Hentry*
htlook(char *s)
{
	Hentry *he;

	for(he = htable[hashval(s)]; he; he = he->next)
		if(strcmp(s, he->md->u.s) == 0)
			return he;
	return nil;
}

/*
 * Hash table enter function.
 */

static Hentry*
htenter(Datum *md)
{
	uint h;
	Hentry *he;

	h = hashval(md->u.s);
	he = Malloc(sizeof(Hentry));
	he->md = md;
	he->next = htable[h];
	htable[h] = he;
	return he;
}

/*
 * Add a 'string'.
 */

int
mpstring(char *s)
{
	Hentry *he;
	Datum *md;

	if(he = htlook(s))
		return he->md->offset;
	md = newDatum(MP_STRING);
	md->u.s = s;
	mpoff = align(mpoff, IBY2WD);
	md->offset = mpoff;
	mpoff += IBY2WD;
	append(md);
	htenter(md);
	return md->offset;
}

/*
 * Calculate the type descriptor for the Module Data section.
 */

void
mpdesc(void)
{
	Datum *md;
	int ltsize, rtsize, ln, mdsize;
	uchar *map;

	ltsize = LTrelocsize();		/* link-time reloc data */
	mpoff = align(mpoff, IBY2WD);
	rtsize = RTrelocsize();		/* run-time reloc data */
	mdsize = ltsize + mpoff + rtsize;
	ln = mdsize / (8*IBY2WD) + (mdsize % (8*IBY2WD) != 0);
	map = Mallocz(ln);
	LTrelocdesc(map);
	for(md = mplist; md; md = md->next) {
		if(md->kind == MP_STRING)
			setbit(map, ltsize + md->offset);
	}
	RTrelocdesc(map, ltsize + mpoff);
	RTfixoff(ltsize + mpoff);
	mpdescid(mdsize, ln, map);
}

static void
asmprefix(int off, char *s)
{
	Bprint(bout, "\t%s\t@mp+%d,", s, off);
}

/*
 * Begin an array initializer.
 */

void
asmarray(int off, int tid, int nelt, int reloff)
{
	asmprefix(off, "array");
	Bprint(bout, "$%d,%d\n", tid, nelt);
	asmprefix(off, "indir");
	Bprint(bout, "%d\n", reloff);
}

void
asmint(int off, int val)
{
	asmprefix(off, "word");
	Bprint(bout, "%d\n", val);
}

static void
asmlong(int off, vlong val)
{
	asmprefix(off, "long");
	Bprint(bout, "%lld\n", val);
}

static void
asmreal(int off, double val)
{
	asmprefix(off, "real");
	Bprint(bout, "%g\n", val);
}

void
asmstring(int off, char *s)
{
	asmprefix(off, "string");
	Bputc(bout, '"');
	pstring(s);
	Bprint(bout, "\"\n");
}

static void
asmcase(int off, Datum *md)
{
	int i;

	asmprefix(off, "word");
	Bprint(bout, "%d", md->u.c.n);
	for(i = 0; i < md->u.c.n; i++) {
		Bprint(bout, ",%d", md->u.c.jmptbl[i*3]);
		Bprint(bout, ",%d", md->u.c.jmptbl[i*3+1]);
		Bprint(bout, ",%d", md->u.c.jmptbl[i*3+2]);
	}
	Bprint(bout, ",%d\n", md->u.c.jmptbl[md->u.c.n*3]);
}

static void
asmgoto(int off, Datum *md)
{
	int i;

	asmprefix(off, "word");
	Bprint(bout, "%d", md->u.g.n);
	for(i = 0; i < md->u.g.n; i++)
		Bprint(bout, ",%d", md->u.g.gototbl[i]);
	Bputc(bout, '\n');
}

/*
 * Write Module Data to .s file.
 */

void
asmvar(void)
{
	Datum *md;
	int ltsize, rtsize, off;

	ltsize = LTrelocsize();
	rtsize = RTrelocsize();
	Bprint(bout, "\tvar\t@mp,%d\n", ltsize + mpoff + rtsize);
	off = asmthisCreloc(0);
	asmint(off, mpoff + rtsize);
	off += IBY2WD;
	asmDreloc(off);
	off += IBY2WD;
	off = asmCreloc(off);
	off = align(off, 32);
	if(off != ltsize)
		fatal("asmvar: off %d, ltsize %d\n", off, ltsize);

	for(md = mplist; md; md = md->next) {
		off = ltsize + md->offset;
		switch(md->kind) {
		case MP_INT:
			asmint(off, md->u.v.u.ival);
			break;
		case MP_LONG:
			asmlong(off, md->u.v.u.ival);
			break;
		case MP_REAL:
			asmreal(off, md->u.v.u.rval);
			break;
		case MP_STRING:
			asmstring(off, md->u.s);
			break;
		case MP_CASE:
			asmcase(off, md);
			break;
		case MP_GOTO:
			asmgoto(off, md);
			break;
		}
	}
	asmRTClass(ltsize + mpoff);
}

/*
 * Put Module Data size into .dis Header.
 */

void
disnvar(void)
{
	discon(LTrelocsize() + mpoff + RTrelocsize());
}

static void
discase(int off, Datum *md)
{
	int i;

	disint(off, md->u.c.n);
	off += IBY2WD;
	for(i = 0; i < md->u.c.n; i++) {
		disint(off, md->u.c.jmptbl[i*3]);
		off += IBY2WD;
		disint(off, md->u.c.jmptbl[i*3+1]);
		off += IBY2WD;
		disint(off, md->u.c.jmptbl[i*3+2]);
		off += IBY2WD;
	}
	disint(off, md->u.c.jmptbl[md->u.c.n*3]);
}

static void
disgoto(int off, Datum *md)
{
	int i;

	disint(off, md->u.g.n);
	for(i = 0; i < md->u.g.n; i++) {
		off += IBY2WD;
		disint(off, md->u.g.gototbl[i]);
	}
}

/*
 * Write Module Data to .dis file.
 */

void
disvar(void)
{
	Datum *md;
	int ltsize, rtsize, off;

	ltsize = LTrelocsize();
	rtsize = RTrelocsize();
	off = disthisCreloc(0);
	disint(off, mpoff + rtsize);
	off += IBY2WD;
	disDreloc(off);
	off += IBY2WD;
	off = disCreloc(off);
	off = align(off, 32);
	if(off != ltsize)
		fatal("disvar: off %d, ltsize %d\n", off, ltsize);

	for(md = mplist; md; md = md->next) {
		off = ltsize + md->offset;
		switch(md->kind) {
		case MP_INT:
			disint(off, md->u.v.u.ival);
			break;
		case MP_LONG:
			dislong(off, md->u.v.u.ival);
			break;
		case MP_REAL:
			disreal(off, md->u.v.u.rval);
			break;
		case MP_STRING:
			disstring(off, md->u.s);
			break;
		case MP_CASE:
			discase(off, md);
			break;
		case MP_GOTO:
			disgoto(off, md);
			break;
		}
	}
	disRTClass(ltsize + mpoff);
	disflush(-1, -1, 0);
	Bputc(bout, 0);
}

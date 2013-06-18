#include "java.h"

Inst	*ihead;		/* first instruction generated for .class file */
Inst	*itail;		/* last instruction (for appending to list) */

static	uchar	*cache;		/* module data cache */
static	int	ncached;	/* number of bytes in cache */
static	int	ndatum;		/* number of non-string basic datums in cache */
static	int	startoff;	/* offset of first datum in cache */
static	int	lastoff;	/* 1 past last byte offset in cache */
static	int	lastkind = -1;	/* last kind of datum put in cache */
static	int	lencache;	/* capacity of cache */

/*
 * Generate Dis object file (.dis).
 */

void
discon(int val)
{
	if(val >= -64 && val <= 63) {
		Bputc(bout, val & ~0x80);
		return;
	}
	if(val >= -8192 && val <= 8191) {
		Bputc(bout, ((val>>8) & ~0xC0) | 0x80);
		Bputc(bout, val);
		return;
	}
	if(notimmable(val))
		fatal("discon: overflow 16r%ux\n", val);
	Bputc(bout, (val>>24) | 0xC0);
	Bputc(bout, val>>16);
	Bputc(bout, val>>8);
	Bputc(bout, val);
}

void
disword(int w)
{
	Bputc(bout, w >> 24);
	Bputc(bout, w >> 16);
	Bputc(bout, w >> 8);
	Bputc(bout, w);
}

void
disdata(int kind, int n)
{
	if(n < DMAX && n != 0)
		Bputc(bout, DBYTE(kind, n));
	else{
		Bputc(bout, DBYTE(kind, 0));
		discon(n);
	}
}

void
disflush(int kind, int off, int size)
{
	if(kind != lastkind || off != lastoff){
		if(lastkind != -1 && ncached){
			disdata(lastkind, ndatum);
			discon(startoff);
			Bwrite(bout, cache, ncached);
		}
		startoff = off;
		lastkind = kind;
		ncached = 0;
		ndatum = 0;
	}
	lastoff = off + size;
	while(kind >= 0 && ncached + size >= lencache){
		lencache = ncached+1024;
		cache = Realloc(cache, lencache);
	}
}

void
disbyte(int off, int v)
{
	disflush(DEFB, off, 1);
	cache[ncached++] = v;
	ndatum++;
}

void
disint(int off, int v)
{
	disflush(DEFW, off, IBY2WD);
	cache[ncached++] = v >> 24;
	cache[ncached++] = v >> 16;
	cache[ncached++] = v >> 8;
	cache[ncached++] = v;
	ndatum++;
}

void
dislong(int off, vlong v)
{
	uint iv;

	disflush(DEFL, off, IBY2LG);
	iv = v >> 32;
	cache[ncached++] = iv >> 24;
	cache[ncached++] = iv >> 16;
	cache[ncached++] = iv >> 8;
	cache[ncached++] = iv;
	iv = v;
	cache[ncached++] = iv >> 24;
	cache[ncached++] = iv >> 16;
	cache[ncached++] = iv >> 8;
	cache[ncached++] = iv;
	ndatum++;
}

static void
dtocanon(double f, uint v[])
{
	union { double d; uint ui[2]; } a;

	a.d = 1.;
	if(a.ui[0]) {
		a.d = f;
		v[0] = a.ui[0];
		v[1] = a.ui[1];
	} else {
		a.d = f;
		v[0] = a.ui[1];
		v[1] = a.ui[0];
	}
}

void
disreal(int off, double v)
{
	uint bv[2];
	uint iv;

	disflush(DEFF, off, IBY2LG);
	dtocanon(v, bv);
	iv = bv[0];
	cache[ncached++] = iv >> 24;
	cache[ncached++] = iv >> 16;
	cache[ncached++] = iv >> 8;
	cache[ncached++] = iv;
	iv = bv[1];
	cache[ncached++] = iv >> 24;
	cache[ncached++] = iv >> 16;
	cache[ncached++] = iv >> 8;
	cache[ncached++] = iv;
	ndatum++;
}

void
disstring(int offset, char *s)
{
	int n, src, dst;
	char *a;

	/* null char represented as 0xC080 in String literals */
	n = strlen(s);
	a = Malloc(n);
	src = 0;
	dst = 0;
	while(src < n) {
		if(src+1 < n && (uchar)s[src] == 0xC0 && (uchar)s[src+1] == 0x80) {
			a[dst] = '\0';
			src++;
		} else
			a[dst] = s[src];
		src++;
		dst++;
	}
	disflush(-1, -1, 0);
	disdata(DEFS, dst);
	discon(offset);
	Bwrite(bout, a, dst);
	free(a);
}

/*
 * Begin an array initializer.
 */

void
disarray(int off, int tid, int nelt)
{
	disflush(-1, -1, 0);
	disdata(DEFA, 1);	/* 1 is ignored */
	discon(off);
	disword(tid);
	disword(nelt);
	disdata(DIND, 1);	/* 1 is ignored */
	discon(off);
	disword(0);
}

/*
 * Terminate an array initializer.
 */

void
disapop(void)
{
	disflush(-1, -1, 0);
	disdata(DAPOP, 1);	/* 1 is ignored */
	discon(0);
}

/*
 * Put number of instructions into .dis Header.
 */

void
disninst(void)
{
	discon(itail ? itail->pc + 1 : 0);
}

static int dismode[Aend] = {
	/* Anone */	AXXX,
	/* Aimm */	AIMM,
	/* Amp */	AMP,
	/* Ampind */	AMP|AIND,
	/* Afp */	AFP,
	/* Afpind */	AFP|AIND
};

static int disregmode[Aend] = {
	/* Anone */	AXNON,
	/* Aimm */	AXIMM,
	/* Amp */	AXINM,
	/* Ampind */	AXNON,
	/* Afp */	AXINF,
	/* Afpind */	AXNON
};

enum
{
	MAXCON	= 4,
	MAXADDR	= 2*MAXCON,
	MAXINST	= 3*MAXCON+2,
	NIBUF	= 1024
};

static	uchar	*ibuf;
static	int	nibuf;

static void
disbcon(int val)
{
	if(val >= -64 && val <= 63){
		ibuf[nibuf++] = val & ~0x80;
		return;
	}
	if(val >= -8192 && val <= 8191){
		ibuf[nibuf++] = val>>8 & ~0xC0 | 0x80;
		ibuf[nibuf++] = val;
		return;
	}
	if(notimmable(val))
		fatal("disbcon: overflow 16r%x\n", val);
	ibuf[nibuf++] = val>>24 | 0xC0;
	ibuf[nibuf++] = val>>16;
	ibuf[nibuf++] = val>>8;
	ibuf[nibuf++] = val;
}

static void
disaddr(Addr *a)
{
	int val;

	val = 0;
	switch(a->mode){
	case Aimm:
		val = a->u.ival;
		break;
	case Afp:
	case Amp:
		val = a->u.offset;
		break;
	case Afpind:
	case Ampind:
		disbcon(a->u.b.fi);
		val = a->u.b.si;
		break;
	}
	disbcon(val);
}

static void
disinst(void)
{
	Inst *i;

	ibuf = Malloc(NIBUF);
	nibuf = 0;
	for(i = ihead; i; i = i->next){
		if(nibuf >= NIBUF-MAXINST){
			Bwrite(bout, ibuf, nibuf);
			nibuf = 0;
		}
		ibuf[nibuf++] = i->op;
		ibuf[nibuf++] = SRC(dismode[i->s.mode])
			| DST(dismode[i->d.mode]) | disregmode[i->m.mode];
		if(i->m.mode != Anone)
			disaddr(&i->m);
		if(i->s.mode != Anone)
			disaddr(&i->s);
		if(i->d.mode != Anone)
			disaddr(&i->d);
	}
	if(nibuf > 0)
		Bwrite(bout, ibuf, nibuf);
	free(ibuf);
}

void
disout(void)
{
	discon(XMAGIC);
	discon(DONTCOMPILE);	/* runtime "hints" */
	disstackext();		/* minimum stack extent size */
	disninst();
	disnvar();
	disndesc();
	disnlinks();
	disentry();
	disinst();
	disdesc();
	disvar();
	dismod();
	dislinks();
}

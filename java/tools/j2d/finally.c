#include "java.h"

/*
 * Maintain information about 'finally' blocks.
 */

typedef	struct	Finally	Finally;

static	Finally	*finally;	/* linked list of finally block records */

struct Finally {
	int	npc;		/* Java pc of finally entry (jsr target) */
	int	xpc;		/* Java pc of finally exit (ret) */
	int	n;		/* number of jsr slots in gototbl */
	int	*gototbl;	/* goto jump table */
	int	off;		/* mp offset to gototbl */
	Finally	*next;
};

/*
 * Get record for finally block whose entry point is pc.
 */

static Finally*
getfinally(int pc)
{
	Finally *f;

	for(f = finally; f; f = f->next) {
		if(f->npc == pc)
			return f;
	}
	return nil;
}

/*
 * Count jsr's to the finally block whose entry point is pc.
 */

void
finallyentry(int pc)
{
	Finally *f;

	f = getfinally(pc);
	if(f == nil) {
		f = Malloc(sizeof(Finally));
		f->npc = pc;
		f->xpc = 0;
		f->n = 0;
		f->next = finally;
		finally = f;
	}
	f->n += 1;
}

/*
 * Allocate the gototbl's and pass them to mdata.c.
 */

void
finallyalloc(void)
{
	Finally *f;

	for(f = finally; f; f = f->next) {
		f->gototbl = Mallocz(f->n*sizeof(int));
		f->off = mpgoto(f->n, f->gototbl);
	}
}

/*
 * Fix up operands of a Dis movw that implements Java jsr/jsr_w.
 */

void
jsrfixup(Addr *s, Addr *d, int dispc, int javapc)
{
	Finally *f;
	int i;

	f = getfinally(javapc);
	for(i = 0; i < f->n; i++) {
		if(f->gototbl[i] == 0) {
			f->gototbl[i] = dispc;
			break;
		}
	}
	if(i == f->n)
		fatal("jsrfixup: %d, %d\n", dispc, javapc);
	s->u.ival = i;
	d->u.offset = f->off + f->n*IBY2WD;
}

/*
 * Fix up operands of a Dis goto that implements Java ret.
 */

void
retfixup(Addr *s, Addr *d, int retpc)
{
	Finally *fi, *f;

	f = nil;
	for(fi = finally; fi; fi = fi->next) {
		if(fi->xpc == 0 && fi->npc < retpc
		&& (f == nil || f->npc < fi->npc)) {
			f = fi;
		}
	}
	if(f == nil)
		fatal("retfixup: %d\n", retpc);
	f->xpc = retpc;		/* claim this finally block for this 'ret' */
	s->u.offset = f->off + f->n*IBY2WD;
	d->u.offset = f->off;
}

/*
 * Free finally information after each method is translated.
 */

void
finallyfree(void)
{
	Finally *f, *f2;

	for(f = finally; f; f = f2) {
		f2 = f->next;
		free(f);
	}
	finally = nil;
}

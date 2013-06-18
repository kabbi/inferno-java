#include "java.h"

/*
 * Patch operands, etc. that reference pc offsets.
 */

enum {
	P_CASE = 1,
	P_OTHER
};

typedef struct Patch	Patch;

struct Patch {
	uchar	kind;		/* P_xxx */
	Inst	*i;
	int	n;		/* number of cases in ... */
	int	*jmptbl;	/* ... case jump table */
	Patch	*next;
};

static	Patch	*plist;

/*
 * Allocate a Patch structure.
 */

static Patch*
newPatch(uchar kind, Inst *i)
{
	Patch *p;

	p = Malloc(sizeof(Patch));
	p->kind = kind;
	p->i = i;
	p->next = plist;
	plist = p;
	return p;
}

/*
 * Record non-case branch instruction for later patching.
 */

void
patchop(Inst *i)
{
	newPatch(P_OTHER, i);
}

/*
 * Record case jump table for later patching.
 */

void
patchcase(Inst *i, int n, int *jmptbl)
{
	Patch *p;

	p = newPatch(P_CASE, i);
	p->n = n;
	p->jmptbl = jmptbl;
}

/*
 * Calculate patch address; Java branches are relative.
 */

static int
patchaddr(Inst *i, int pc)
{
	Jinst *j;
	int span, srcjpc, dstjpc;

	span = pc;
	srcjpc = i->j->pc;
	dstjpc = srcjpc + span;
	j = &code->j[dstjpc];

	/* account for no-op's (dup, swap, pop, etc.), elided loads/stores */
	while(j->dis == nil)
		j += j->size;

	return j->dis->pc;
}

/*
 * Patch branch instructions and case jump tables of a method.
 */

void
patchmethod(int startpc)
{
	Patch *p;
	Inst *i;
	int *jt;
	int n;

	for(p = plist; p; p = p->next) {
		i = p->i;
		if(p->kind == P_CASE) {
			jt = p->jmptbl;
			for(n = 0; n < p->n; n++)
				jt[n*3+2] = patchaddr(i, jt[n*3+2]);
			jt[p->n*3] = patchaddr(i, jt[p->n*3]);
		} else {	/* P_OTHER */
			i->d.u.ival = patchaddr(i, i->d.u.ival);
			/*
			 * jmp $start_of_method  ->  jmp $start_of_method+1
			 * skip (re-)allocation of Sys->Exception object
			 */
			if(i->d.u.ival == startpc && i->op == IJMP && code->nex != 0)
				i->d.u.ival += 1;
		}
	}
}

/*
 * Clear the patch list after each method.
 */

void
patchfree(void)
{
	Patch *p, *p2;

	for(p = plist; p; p = p2) {
		p2 = p->next;
		free(p);
	}
	plist = nil;
}

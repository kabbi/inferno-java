#include "java.h"
#include "javaisa.h"

/*
 * "Unify" results that are produced in one basic block and consumed
 * in another.  I.e., ensure that producers and consumers access results
 * through consistent fp offsets.
 */

static void
pushsucc(BB *bb)
{
	BBList *l;

	for(l = bb->succ; l; l = l->next) {
		if(l->bb->state == BB_POSTSIM)
			bbput(l->bb);
	}
}

static int
pass1(StkSnap *s)
{
	Jinst *j;
	int i;
	int fpoff;

	fpoff = -1;
	for(i = 0; i < s->npc; i++) {
		j = &code->j[s->pc[i]];
		if((isload(j) && j->movsrc.mode != Anone)
		|| (!isload(j) && j->dst.u.offset != -1)) {
			if(fpoff == -1)
				fpoff = j->dst.u.offset;
			else if(fpoff != j->dst.u.offset)
				fatal("pass1: can't\n");
		}
	}
	if(fpoff == -1)
		fpoff = getreg(j2dtype(s->jtype));
	return fpoff;
}

static void
pass2(StkSnap *s, int fpoff)
{
	Jinst *j;
	int i;

	for(i = 0; i < s->npc; i++) {
		j = &code->j[s->pc[i]];
		if(isload(j) && j->movsrc.mode == Anone) {
			j->movsrc = j->dst;
			j->dst.mode = Afp;
		}
		j->dst.u.offset = fpoff;
	}
}

static void
unifybb(BB *bb)
{
	StkSnap *s;
	int n, m;

	if(bb->state == BB_POSTUNIFY)
		fatal("unifybb: BB_POSTUNIFY\n");

	if(bb->entrystk == nil) {
		pushsucc(bb);
		return;
	}

	clearreg();
	reservereg(bb->entrystk, bb->entrysz);
	reservereg(bb->exitstk, bb->exitsz);

	for(n = 0; n < bb->entrysz; n++) {
		s = &bb->entrystk[n];
		for(m = 0; m < s->npc; m++) {
			reservereg(code->j[s->pc[m]].bb->entrystk,
				code->j[s->pc[m]].bb->entrysz);
		}
	}

	for(n = 0; n < bb->entrysz; n++) {
		s = &bb->entrystk[n];
		if(s->npc == 1)
			dstreg(&code->j[s->pc[0]].dst, j2dtype(s->jtype));
		else
			pass2(s, pass1(s));
	}

	bb->state = BB_POSTUNIFY;
	pushsucc(bb);
}

void
unify(void)
{
	BB *bb;

	bbinit();
	while(bb = bbget())
		unifybb(bb);
}

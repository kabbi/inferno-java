#include "java.h"

/*
 * 'entry' assembly directive.
 */

static int pc = -1;
static int tid = -1;

/*
 * Set the entry point; entry is the beginning of "main".
 */

void
setentry(int l, int i)
{
	if(pc != -1)
		verifyerrormess("main overloaded");
	pc = l;
	tid = i;
}

/*
 * Emit 'entry' assembly directive.
 */

void
asmentry(void)
{
	if(pc == -1)
		return;
	Bprint(bout, "\tentry\t%d, %d\n", pc, tid);
}

void
disentry(void)
{
	discon(pc);
	discon(tid);
}

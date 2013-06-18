#include "java.h"

/*
 * Emit 'module' assembly directive.
 */

void
asmmod(void)
{
	Bprint(bout, "\tmodule\t%s\n", THISCLASS);
}

void
dismod(void)
{
	char name[NAMELEN];

	strncpy(name, THISCLASS, NAMELEN);
	name[NAMELEN-1] = '\0';
	Bwrite(bout, name, strlen(name)+1);
}

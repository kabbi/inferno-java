#include "java.h"

/*
 * Generate symbol table file (.sbl).
 */

#define	SBLVERSION	"limbo .sbl 2.0"
#define	EXT		".sbl"

void
sblout(char *out)
{
	int n;
	char *sym;
	Biobuf *bsym;

	n = strlen(out);
	if(n > 2 && out[n-1] == 's') {		/* .s or .dis file ? */
		if(out[n-2] == '.')
			n -= 2;
		else if(n > 4 && out[n-2] == 'i'
		&& out[n-3] == 'd' && out[n-4] == '.')
			n -= 4;
	}
	sym = Malloc(n + strlen(EXT) + 1);
	memmove(sym, out, n);
	strcpy(sym+n, EXT);

	bsym = Bopen(sym, OWRITE);
	if(bsym == nil)
		fatal("can't open %s: %r\n", sym);

	Bprint(bsym, "%s\n", SBLVERSION);
	Bprint(bsym, "%s\n", THISCLASS);
	Bprint(bsym, "1\n");
	if(class->source_file)
		Bprint(bsym, "%s\n", STRING(class->source_file));
	else
		Bprint(bsym, "%s.java\n", THISCLASS);
	sblinst(bsym);			/* Dis instructions */
	Bprint(bsym, "0\n");		/* adts */
	sbllinks(bsym);			/* functions */
	Bprint(bsym, "0\n");		/* globals */

	Bterm(bsym);
}

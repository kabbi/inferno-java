#include "java.h"

/*
 * Manage .dis Link Section.
 */

typedef struct	Link	Link;

struct Link
{
	int	id;	/* dis type identifier */
	int	pc;	/* method entry pc */
	uint	sig;	/* MD5 signature */
	char	*name;	/* method name */
	Link	*next;
};

static	Link	*links	= nil;
static	Link	*last	= nil;
static	int	nlinks;

/*
 * Create a Link entry; one for each method defined in the class.
 */

void
xtrnlink(int id, int pc, char *name, char *sig)
{
	Link *l;
	char *n;

	l = Malloc(sizeof(Link));
	l->id = id;
	l->pc = pc;
	if(strcmp(name, "main") == 0)
		setentry(pc, id);
	l->sig = 1247901281;
	n = Malloc(strlen(name) + strlen(sig) + 1);
	strcpy(n, name);
	strcat(n, sig);
	l->name = n;
	l->next = nil;
	if(links == nil)
		links = l;
	else
		last->next = l;
	last = l;
	nlinks += 1;
}

/*
 * Functions for patching frame & call instructions.
 */

typedef	struct	FCPatch	FCPatch;

struct FCPatch {
	Inst	*frame;
	Inst	*call;
	char	*name;
	char	*sig;
	FCPatch	*next;
};

static	FCPatch	*fcplist;

/*
 * Record a frame/call pair for later patching.
 */

void
addfcpatch(Inst *frame, Inst *call, char *name, char *sig)
{
	FCPatch *fcp;

	fcp = Malloc(sizeof(FCPatch));
	fcp->frame = frame;
	fcp->call = call;
	fcp->name = name;
	fcp->sig = sig;
	fcp->next = fcplist;
	fcplist = fcp;
}

static Link*
getLink(char *name, char *sig)
{
	Link *l;
	int nlen;

	nlen = strlen(name);
	l = links;
	while(l) {
		if(strncmp(l->name, name, nlen) == 0
		&& strncmp(l->name+nlen, sig, strlen(sig)) == 0) {
			return l;
		}
		l = l->next;
	}
	fatal("getLink: %s, %s\n", name, sig);
	return nil;	/* for compiler */
}

/*
 * Patch frame/call pairs.
 */

void
dofcpatch(void)
{
	FCPatch *fcp, *fcp2;
	Link *l;

	fcp = fcplist;
	while(fcp) {
		l = getLink(fcp->name, fcp->sig);
		fcp->frame->s.u.ival = l->id;
		fcp->call->d.u.ival = l->pc;
		fcp2 = fcp->next;
		free(fcp);
		fcp = fcp2;
	}
}

/*
 * Emit assembly 'link' directives.
 */

void
asmlinks(void)
{
	Link *l;

	for(l = links; l; l = l->next) {
		Bprint(bout, "\tlink\t%d,%d,0x%x,\"%s\"\n",
			l->id, l->pc, l->sig, l->name);
	}
}

void
sbllinks(Biobuf *bsym)
{
	Link *l;

	Bprint(bsym, "%d\n", nlinks);
	for(l = links; l; l = l->next) {
		Bprint(bsym, "%d:%s\n", l->pc, l->name);
		Bprint(bsym, "0\n");	/* args */
		Bprint(bsym, "0\n");	/* locals */
		Bprint(bsym, "n\n");	/* return type */
	}
}

void
disnlinks(void)
{
	discon(nlinks);
}

void
dislinks(void)
{
	Link *l;

	for(l = links; l; l = l->next) {
		discon(l->pc);
		discon(l->id);
		disword(l->sig);
		Bprint(bout, "%s", l->name);
		Bputc(bout, '\0');
	}
}

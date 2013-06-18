#include "java.h"

/*
 * 'desc' assembly directives.
 */

typedef struct	Desc	Desc;

struct Desc
{
	int	id;	/* Dis type identifier */
	int	ln;	/* length, in bytes, of mapped object */
	uchar	*map;	/* bit map of pointers */
	int	nmap;	/* number of bytes in map */
	Desc	*next;
};

static	Desc	*dlist = nil;
static	Desc	*dtail = nil;
static	int	id = 0; /* reserve id == 0 for Module Data type descriptor */

/*
 * Allocate a Desc structure.
 */

static Desc*
newDesc(int id, int ln, int nmap, uchar *map)
{
	Desc *d;

	d = Malloc(sizeof(Desc));
	d->id = id;
	d->ln = ln;
	d->nmap = nmap;
	d->map = map;
	d->next = nil;
	return d;
}

/*
 * Save a type descriptor; reuse existing descriptor if identical.
 */

int
descid(int ln, int nmap, uchar *map)
{
	Desc *d;

	for(d = dlist; d; d = d->next) {
		if(d->ln == ln && d->nmap == nmap
		&& (memcmp(d->map, map, nmap) == 0)) {
			return d->id;
		}
	}

	id += 1;
	d = newDesc(id, ln, nmap, map);
	if(dlist == nil)
		dlist = d;
	else
		dtail->next = d;
	dtail = d;

	return d->id;
}

/*
 * Save type descriptor for module data.
 */

void
mpdescid(int ln, int nmap, uchar *map)
{
	Desc *d;

	d = newDesc(0, ln, nmap, map);
	d->next = dlist;
	dlist = d;
}

/*
 * Emit assembly 'desc' directives.
 */

void
asmdesc(void)
{
	Desc *d;
	uchar *m, *e;

	for(d = dlist; d; d = d->next) {
		Bprint(bout, "\tdesc\t$%d,%d,\"", d->id, d->ln);
		e = d->map + d->nmap;
		for(m = d->map; m < e; m++)
			Bprint(bout, "%.2x", *m);
		Bprint(bout, "\"\n");
	}
}

void
disndesc(void)
{
	discon(id+1);
}

void
disdesc(void)
{
	Desc *d;

	for(d = dlist; d; d = d->next) {
		discon(d->id);
		discon(d->ln);
		discon(d->nmap);
		Bwrite(bout, d->map, d->nmap);
	}
}

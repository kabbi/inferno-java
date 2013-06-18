#include "java.h"
#include "reloc.h"

/*
 * Manage run-time resolution information.
 */

typedef struct RTHash	RTHash;

struct RTHash
{
	RTClass	*rtc;
	RTHash	*next;
};

static	RTHash	*rttbl[Hashsize];	/* hash table of referenced classes */
static	int	nrtclasses;		/* no. of classes referenced */

static void
rtappend(RTClass *rtc, RTReloc *rtr)
{
	if(rtc->rtr == nil)
		rtc->rtr = rtr;
	else
		rtc->tail->next = rtr;
	rtc->tail = rtr;
}

static void
rtprepend(RTClass *rtc, RTReloc *rtr)
{
	if(rtc->rtr == nil)
		rtc->tail = rtr;
	rtr->next = rtc->rtr;
	rtc->rtr = rtr;
}

/*
 * Add RTReloc entry.
 */

static RTReloc*
addRTReloc(RTClass *rtc, char *field, char *sig, uint flags)
{
	RTReloc *rtr;

	rtr = Malloc(sizeof(RTReloc));
	rtr->field = field;
	rtr->sig = sig;
	rtr->flags = flags;
	rtr->ipatch = Mallocz(sizeof(Ipatch));
	rtr->next = nil;
	if(field[0] == '@')	/* these must go first in the list ! */
		rtprepend(rtc, rtr);
	else
		rtappend(rtc, rtr);
	rtc->n += 1;
	return rtr;
}

/*
 * Allocate a RTClass structure.
 */

static RTClass*
newRTClass(char *s)
{
	RTClass *rtc;

	rtc = Malloc(sizeof(RTClass));
	rtc->classname = s;
	rtc->rtr = nil;
	rtc->tail = nil;
	rtc->n = 0;
	rtc->off = 0;
	nrtclasses += 1;
	/* want the order: @mp, @np, @adt, @Class */
	addRTReloc(rtc, RCLASS, nil, 0);
	addRTReloc(rtc, RADT, nil, 0);
	addRTReloc(rtc, RNP, nil, 0);
	addRTReloc(rtc, RMP, nil, 0);
	return rtc;
}

/*
 * Add RTClass entry for classname.
 */

static RTClass*
addRTClass(char *classname)
{
	uint h;
	RTHash *he;

	h = hashval(classname);
	he = Malloc(sizeof(RTHash));
	he->rtc = newRTClass(classname);
	he->next = rttbl[h];
	rttbl[h] = he;
	return he->rtc;
}

/*
 * Get RTClass entry for classname.
 */

RTClass*
getRTClass(char *classname)
{
	RTHash *he;

	for(he = rttbl[hashval(classname)]; he; he = he->next) {
		if(strcmp(classname, he->rtc->classname) == 0)
			return he->rtc;
	}
	return addRTClass(classname);
}

/*
 * Get RTReloc entry.  Ignore signature if nil.
 */

RTReloc*
getRTReloc(RTClass *rtc, char *field, char *sig, uint flags)
{
	RTReloc *rtr;
	uint lowflags;

	lowflags = 0;
	for(rtr = rtc->rtr; rtr; rtr = rtr->next) {
		if(strcmp(rtr->field, field) == 0
		&& (sig == nil || strcmp(rtr->sig, sig) == 0)) {
			if(rtr->flags >> 16 == 0) {
				rtr->flags |= flags;
				return rtr;
			} else if(rtr->flags >> 16 == flags >> 16)
				return rtr;
			lowflags = rtr->flags & 0xffff;
		}
	}

	return addRTReloc(rtc, field, sig, flags|lowflags);
}

/*
 * Add instruction patch information to RTReloc rtr.
 */

void
RTIpatch(RTReloc *rtr, Inst *i, int operand, int patchkind)
{
	addDreloc(i, operand, patchkind);
	addIpatch(rtr->ipatch, i, operand, patchkind, SAVEINST);
}

/*
 * Fix RTClass and RTReloc 'off' fields to prepare for instruction patch.
 */

void
RTfixoff(int off)
{
	RTHash *he;
	int i;

	if(nrtclasses > 0) {
		for(i = 0; i < Hashsize; i++) {
			for(he = rttbl[i]; he; he = he->next) {
				he->rtc->off = off;
				off += he->rtc->n * IBY2WD;
			}
		}
	}
}

/*
 * Patch instructions for run-time relocation.
 */

void
doRTpatch(void)
{
	Addr *a;
	RTHash *he;
	Ipatch *ip;
	RTReloc *rtr;
	int i, j;
	int off, ltsize;

	if(nrtclasses == 0)
		return;

	ltsize = LTrelocsize();
	a = nil;
	for(i = 0; i < Hashsize; i++) {
		for(he = rttbl[i]; he; he = he->next) {
			off = he->rtc->off - ltsize;
			for(rtr = he->rtc->rtr; rtr; rtr = rtr->next) {
				ip = rtr->ipatch;
				for(j = 0; j < ip->n; j++) {
					switch(ip->pinfo[j] & (0x3 << 2)) {
					case PSRC:
						a = &ip->i[j]->s;
						break;
					case PDST:
						a = &ip->i[j]->d;
						break;
					case PMID:
						a = &ip->i[j]->m;
						break;
					}
					switch(ip->pinfo[j] & 0x3) {
					case PIMM:
						a->u.ival = off;
						break;
					case PSIND:
						a->u.offset = off;
						break;
					case PDIND1:
						a->u.b.fi = off;
						break;
					case PDIND2:
						a->u.b.si = off;
						break;
					}
				}
				off += IBY2WD;
			}
		}
	}
}

/*
 * Size of Module Data space taken by run-time relocation information.
 */

int
RTrelocsize(void)
{
	int i;
	int n;
	RTHash *he;

	n = 0;
	if(nrtclasses > 0) {
		for(i = 0; i < Hashsize; i++) {
			for(he = rttbl[i]; he; he = he->next)
				n += he->rtc->n;
		}
	}
	return n * IBY2WD;
}

/*
 * Fix type descriptor for run-time relocation information.
 */

static int RTReloctid;

void
RTrelocdesc(uchar *map, int off)
{
	int i;
	RTHash *he;
	RTReloc *rtr;

	if(nrtclasses == 0)
		return;

	RTReloctid = descid(3*IBY2WD, 1, (uchar*)"\xc0");

	for(i = 0; i < Hashsize; i++) {
		for(he = rttbl[i]; he; he = he->next) {
			setbit(map, off);	/* @mp cell */
			off += 4;
			setbit(map, off);	/* @np cell */
			off += 4;
			setbit(map, off);	/* @adt cell */
			off += 8;
			rtr = he->rtc->rtr->next->next->next->next;
			while(rtr) {
				if(rtr->flags & (Rspecialmp | Rstaticmp))
					setbit(map, off);
				off += 4;
				rtr = rtr->next;
			}
		}
	}
}

/*
 * Write RTReloc array to .s file.
 */

static void
asmRTReloc(int off, RTClass *rtc)
{
	RTReloc *rtr;
	int reloff;		/* relative offset for array elements */

	if(rtc->n <= 4)
		return;

	reloff = 0;
	asmarray(off, RTReloctid, rtc->n - 4, reloff);
	/* skip @mp @np @adt @Class */
	rtr = rtc->rtr->next->next->next->next;
	while(rtr) {
		asmstring(reloff, rtr->field);
		reloff += IBY2WD;
		if(rtr->sig)
			asmstring(reloff, rtr->sig);
		reloff += IBY2WD;
		asmint(reloff, rtr->flags);
		reloff += IBY2WD;
		rtr = rtr->next;
	}
	Bprint(bout, "\tapop\n");
}

/*
 * Write RTClass information to .s file.
 */

int
asmRTClass(int off)
{
	RTHash *he;
	int i;
	int ltsize;

	if(nrtclasses > 0) {
		ltsize = LTrelocsize();
		for(i = 0; i < Hashsize; i++) {
			for(he = rttbl[i]; he; he = he->next) {
				off += IBY2WD;	/* @mp cell */
				asmstring(off, he->rtc->classname);
				off += IBY2WD;
				asmRTReloc(off, he->rtc);
				off += IBY2WD;
				asmint(off, he->rtc->off - ltsize);
				off += IBY2WD;
				/* account for fields beyond @Class */
				off += (he->rtc->n - 4) * IBY2WD;
			}
		}
	}
	return off;
}

/*
 * Write RTReloc array to .dis file.
 */

static void
disRTReloc(int off, RTClass *rtc)
{
	RTReloc *rtr;
	int reloff;		/* relative offset for array elements */

	if(rtc->n <= 4)
		return;

	reloff = 0;
	disarray(off, RTReloctid, rtc->n - 4);
	/* skip @mp @np @adt @Class */
	rtr = rtc->rtr->next->next->next->next;
	while(rtr) {
		disstring(reloff, rtr->field);
		reloff += IBY2WD;
		if(rtr->sig)
			disstring(reloff, rtr->sig);
		reloff += IBY2WD;
		disint(reloff, rtr->flags);
		reloff += IBY2WD;
		rtr = rtr->next;
	}
	disapop();
}

/*
 * Write RTClass information to .dis file.
 */

int
disRTClass(int off)
{
	RTHash *he;
	int i;
	int ltsize;

	if(nrtclasses > 0) {
		ltsize = LTrelocsize();
		for(i = 0; i < Hashsize; i++) {
			for(he = rttbl[i]; he; he = he->next) {
				off += IBY2WD;	/* @mp cell */
				disstring(off, he->rtc->classname);
				off += IBY2WD;
				disRTReloc(off, he->rtc);
				off += IBY2WD;
				disint(off, he->rtc->off - ltsize);
				off += IBY2WD;
				/* account for fields beyond @Class */
				off += (he->rtc->n - 4) * IBY2WD;
			}
		}
	}
	return off;
}

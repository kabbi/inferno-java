#include "java.h"
#include "reloc.h"

/*
 * Manage load-time resolution information.
 */

typedef struct LTHash	LTHash;

struct LTHash
{
	Creloc	*cr;
	LTHash	*next;
};

	int	doclinitinits;
static	LTHash	*lttbl[Hashsize];	/* hash table of referenced classes */
static	Creloc	*thisclass;		/* class under translation */
static	int	nltclasses;		/* no. of classes referenced */

/*
 * Allocate a Creloc structure.
 */

static Creloc*
newCreloc(char *s)
{
	Creloc *cr;

	cr = Malloc(sizeof(Creloc));
	cr->classname = s;
	cr->fr = nil;
	cr->tail = nil;
	cr->n = 0;
	nltclasses += 1;
	return cr;
}

static void
ltappend(Creloc *cr, Freloc *fr)
{
	if(cr->fr == nil)
		cr->fr = fr;
	else
		cr->tail->next = fr;
	cr->tail = fr;
}

static void
ltprepend(Creloc *cr, Freloc *fr)
{
	if(cr->fr == nil)
		cr->tail = fr;
	fr->next = cr->fr;
	cr->fr = fr;
}

/*
 * Add Freloc entry.
 */

static Freloc*
addFreloc(Creloc *cr, char *field, char *sig, uint flags)
{
	Freloc *fr;

	fr = Malloc(sizeof(Freloc));
	fr->field = field;
	fr->sig = sig;
	fr->flags = flags;
	fr->ipatch = Mallocz(sizeof(Ipatch));
	fr->next = nil;
	if(field[0] == '@')	/* these must go first in the list ! */
		ltprepend(cr, fr);
	else
		ltappend(cr, fr);
	cr->n += 1;
	return fr;
}

/*
 * Add Creloc entry for classname.
 */

static Creloc*
addCreloc(char *classname)
{
	uint h;
	LTHash *he;

	h = hashval(classname);
	he = Malloc(sizeof(LTHash));
	he->cr = newCreloc(classname);
	he->next = lttbl[h];
	lttbl[h] = he;
	return he->cr;
}

/*
 * Get Creloc entry for classname.
 */

Creloc*
getCreloc(char *classname)
{
	LTHash *he;

	for(he = lttbl[hashval(classname)]; he; he = he->next) {
		if(strcmp(classname, he->cr->classname) == 0)
			return he->cr;
	}
	return addCreloc(classname);
}

/*
 * Get Freloc entry.  Ignore signature if nil.
 */

Freloc*
getFreloc(Creloc *cr, char *field, char *sig, uint flags)
{
	Freloc *fr;
	uint lowflags;

	lowflags = 0;
	for(fr = cr->fr; fr; fr = fr->next) {
		if(strcmp(fr->field, field) == 0
		&& (sig == nil || strcmp(fr->sig, sig) == 0)) {
			if(fr->flags >> 16 == 0) {
				fr->flags |= flags;
				return fr;
			} else if(fr->flags >> 16 == flags >> 16)
				return fr;
			lowflags = fr->flags & 0xffff;
		}
	}

	return addFreloc(cr, field, sig, flags|lowflags);
}

/*
 * Seed Creloc for this class.
 */

void
thisCreloc(void)
{
	int i, haveclinit;
	Field *fp;
	Method *mp;

	thisclass = addCreloc(THISCLASS);

	/* class access_flags here for the benefit of interfaces */
	addFreloc(thisclass, RCLASS, nil, class->access_flags|compileflag);

	/* data */
	for(i = 0, fp = class->fields; i < class->fields_count; i++, fp++) {
		addFreloc(thisclass, STRING(fp->name_index),
			STRING(fp->sig_index), fp->access_flags);
		if((fp->access_flags & ACC_STATIC) && CVattrindex(fp))
			doclinitinits = 1;
	}

	/* methods */
	haveclinit = 0;
	for(i = 0, mp = class->methods; i < class->methods_count; i++, mp++) {
		addFreloc(thisclass, STRING(mp->name_index),
			STRING(mp->sig_index), mp->access_flags);
		if(strcmp(STRING(mp->name_index), "<clinit>") == 0)
			haveclinit = 1;
	}
	if(doclinitinits && haveclinit == 0)
		addFreloc(thisclass, "<clinit>", "()V", ACC_STATIC);
	if((class->access_flags & (ACC_INTERFACE | ACC_ABSTRACT)) == 0)
		addFreloc(thisclass, "<clone>", "()V", ACC_STATIC);
}

/*
 * Add instruction patch information to Freloc fr.
 */

void
LTIpatch(Freloc *fr, Inst *i, int operand, int patchkind)
{
	addIpatch(fr->ipatch, i, operand, patchkind, !SAVEINST);
}

/*
 * Size of Module Data space taken by load-time relocation information.
 * Includes nil terminator.
 */

int
LTrelocsize(void)
{
	return align((9 + 2*(nltclasses-1)) * IBY2WD, 32);
}

/*
 * Fix type descriptor for relocation information.
 */

static int Freloctid, Ifacetid;

void
LTrelocdesc(uchar *map)
{
	int i, bit;

	Freloctid = descid(4*IBY2WD, 1, (uchar*)"\xd0");
	setIpatchtid();		/* force type id for patch info */
	Ifacetid = descid(IBY2WD, 1, (uchar*)"\x80");

	setbit(map, 8);		/* Class name */
	setbit(map, 12);	/* Superclass name */
	setbit(map, 16);	/* Interfaces */
	setbit(map, 20);	/* Class relocation */
	setbit(map, 28);	/* Data relocation */
	/*
	 * even i: Class name
	 * odd i:  Class relocation
	 */
	bit = 32;
	for(i = 0; i < (nltclasses-1)*2; i++) {
		setbit(map, bit);
		bit += 4;
	}
	setbit(map, bit);	/* nil */
}

/*
 * Write Freloc array to .s file.
 */

static void
asmFreloc(int off, Creloc *cr)
{
	Freloc *fr;
	int reloff;		/* relative offset for array elements */

	reloff = 0;
	asmarray(off, Freloctid, cr->n, reloff);	/* cr->n != 0, always */
	for(fr = cr->fr; fr; fr = fr->next) {
		asmstring(reloff, fr->field);
		reloff += IBY2WD;
		if(fr->sig)
			asmstring(reloff, fr->sig);
		reloff += IBY2WD;
		asmint(reloff, fr->flags);
		reloff += IBY2WD;
		asmIpatch(reloff, fr->ipatch);
		reloff += IBY2WD;
	}
	Bprint(bout, "\tapop\n");
}

/*
 * Write Creloc's (except for this_class) to .s file.
 */

int
asmCreloc(int off)
{
	LTHash *he;
	int i;

	for(i = 0; i < Hashsize; i++) {
		for(he = lttbl[i]; he; he = he->next) {
			if(he->cr == thisclass)
				continue;
			asmstring(off, he->cr->classname);
			off += IBY2WD;
			asmFreloc(off, he->cr);
			off += IBY2WD;
		}
	}
	off += IBY2WD;	/* skip past nil */
	return off;
}

enum {
	JVNO = '4',
	JMAGIC = ('J'<<24)|('a'<<16)|('v'<<8)|'a',
	JVERSION = ('S'<<24)|('u'<<16)|('x'<<8)|JVNO
};

/*
 * Write Creloc for this_class to .s file.
 */

int
asmthisCreloc(int off)
{
	int i;
	int reloff;		/* relative offset for array elements */

	asmint(off, JMAGIC);
	off += IBY2WD;
	asmint(off, JVERSION);
	off += IBY2WD;
	asmstring(off, THISCLASS);
	off += IBY2WD;
	if(SUPERCLASS)		/* Object has no superclass */
		asmstring(off, SUPERCLASS);
	off += IBY2WD;
	if(class->interfaces_count > 0) {
		reloff = 0;
		asmarray(off, Ifacetid, class->interfaces_count, reloff);
		for(i = 0; i < class->interfaces_count; i++) {
			asmstring(reloff, CLASSNAME(class->interfaces[i]));
			reloff += IBY2WD;
		}
		Bprint(bout, "\tapop\n");
	}
	off += IBY2WD;
	asmFreloc(off, thisclass);
	off += IBY2WD;
	return off;
}

/*
 * Write Freloc array to .dis file.
 */

static void
disFreloc(int off, Creloc *cr)
{
	Freloc *fr;
	int reloff;		/* relative offset for array elements */

	reloff = 0;
	disarray(off, Freloctid, cr->n);
	for(fr = cr->fr; fr; fr = fr->next) {
		disstring(reloff, fr->field);
		reloff += IBY2WD;
		if(fr->sig)
			disstring(reloff, fr->sig);
		reloff += IBY2WD;
		disint(reloff, fr->flags);
		reloff += IBY2WD;
		disIpatch(reloff, fr->ipatch);
		reloff += IBY2WD;
	}
	disapop();
}

/*
 * Write Creloc's (except for this_class) to .dis file.
 */

int
disCreloc(int off)
{
	LTHash *he;
	int i;

	for(i = 0; i < Hashsize; i++) {
		for(he = lttbl[i]; he; he = he->next) {
			if(he->cr == thisclass)
				continue;
			disstring(off, he->cr->classname);
			off += IBY2WD;
			disFreloc(off, he->cr);
			off += IBY2WD;
		}
	}
	off += IBY2WD;	/* skip past nil */
	return off;
}

/*
 * Write Creloc for this_class to .dis file.
 */

int
disthisCreloc(int off)
{
	int i;
	int reloff;		/* relative offset for array elements */

	disint(off, JMAGIC);
	off += IBY2WD;
	disint(off, JVERSION);
	off += IBY2WD;
	disstring(off, THISCLASS);
	off += IBY2WD;
	if(SUPERCLASS)		/* Object has no superclass */
		disstring(off, SUPERCLASS);
	off += IBY2WD;
	if(class->interfaces_count > 0) {
		reloff = 0;
		disarray(off, Ifacetid, class->interfaces_count);
		for(i = 0; i < class->interfaces_count; i++) {
			disstring(reloff, CLASSNAME(class->interfaces[i]));
			reloff += IBY2WD;
		}
		disapop();
	}
	off += IBY2WD;
	disFreloc(off, thisclass);
	off += IBY2WD;
	return off;
}

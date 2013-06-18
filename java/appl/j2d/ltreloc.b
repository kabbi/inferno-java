#
# Manage load-time resolution information.
#

LTHash: adt {
	cr:	ref Creloc;
	next:	cyclic ref LTHash;
};

doclinitinits:	int;
lttbl :=	array [Hashsize] of ref LTHash;	# hash table of ref'd classes
thisclass:	ref Creloc;			# class under translation
nltclasses:	int;				# no. of classes referenced

#
# Allocate a Creloc structure.
#

newCreloc(s: string): ref Creloc
{
	nltclasses += 1;
	return ref Creloc(s, nil, nil, 0);
}

ltappend(cr: ref Creloc, fr: ref Freloc)
{
	if(cr.fr == nil)
		cr.fr = fr;
	else
		cr.tail.next = fr;
	cr.tail = fr;
}

ltprepend(cr: ref Creloc, fr: ref Freloc)
{
	if(cr.fr == nil)
		cr.tail = fr;
	fr.next = cr.fr;
	cr.fr = fr;
}

#
# Add Freloc entry.
#

addFreloc(cr: ref Creloc, field: string, sig: string, flags: int): ref Freloc
{
	fr: ref Freloc;

	fr = ref Freloc(field, sig, flags, nil, nil);
	fr.ipatch = ref Ipatch(0, 0, nil, nil);
	if(field[0] == '@')	# these must go first in the list !
		ltprepend(cr, fr);
	else
		ltappend(cr, fr);
	cr.n += 1;
	return fr;
}

#
# Add Creloc entry for classname.
#

addCreloc(classname: string): ref Creloc
{
	h: int;
	he: ref LTHash;

	h = hashval(classname);
	he = ref LTHash(newCreloc(classname), lttbl[h]);
	lttbl[h] = he;
	return he.cr;
}

#
# Get Creloc entry for classname.
#

getCreloc(classname: string): ref Creloc
{
	he: ref LTHash;

	for(he = lttbl[hashval(classname)]; he != nil; he = he.next) {
		if(classname == he.cr.classname)
			return he.cr;
	}
	return addCreloc(classname);
}

#
# Get Freloc entry.  Ignore signature if nil.
#

getFreloc(cr: ref Creloc, field: string, sig: string, flags: int): ref Freloc
{
	fr: ref Freloc;
	lowflags: int;

	lowflags = 0;
	for(fr = cr.fr; fr != nil; fr = fr.next) {
		if(fr.field == field && (sig == nil || fr.sig == sig)) {
			if(fr.flags >> 16 == 0) {
				fr.flags |= flags;
				return fr;
			} else if(fr.flags >> 16 == flags >> 16)
				return fr;
			lowflags = fr.flags & 16rffff;
		}
	}

	return addFreloc(cr, field, sig, flags|lowflags);
}

#
# Seed Creloc for this class.
#

thisCreloc()
{
	i, haveclinit: int;
	fp: ref Field;
	mp: ref Method;

	thisclass = addCreloc(THISCLASS);

	# class access_flags here for the benefit of interfaces
	addFreloc(thisclass, RCLASS, nil, class.access_flags|compileflag);

	# data
	for(i = 0; i < class.fields_count; i++) {
		fp = class.fields[i];
		addFreloc(thisclass, STRING(fp.name_index),
			STRING(fp.sig_index), fp.access_flags);
		if((fp.access_flags & ACC_STATIC) && CVattrindex(fp))
			doclinitinits = 1;
	}

	# methods
	haveclinit = 0;
	for(i = 0; i < class.methods_count; i++) {
		mp = class.methods[i];
		addFreloc(thisclass, STRING(mp.name_index),
			STRING(mp.sig_index), mp.access_flags);
		if(STRING(mp.name_index) == "<clinit>")
			haveclinit = 1;
	}
	if(doclinitinits && haveclinit == 0)
		addFreloc(thisclass, "<clinit>", "()V", ACC_STATIC);
	if((class.access_flags & (ACC_INTERFACE | ACC_ABSTRACT)) == 0)
		addFreloc(thisclass, "<clone>", "()V", ACC_STATIC);
}

#
# Add instruction patch information to Freloc fr.
#

LTIpatch(fr: ref Freloc, i: ref Inst, operand: int, patchkind: int)
{
	addIpatch(fr.ipatch, i, operand, patchkind, !SAVEINST);
}

#
# Size of Module Data space taken by load-time relocation information.
# Includes nil terminator.
#

LTrelocsize(): int
{
	return align((9 + 2*(nltclasses-1)) * IBY2WD, 32);
}

#
# Fix type descriptor for relocation information.
#

Freloctid, Ifacetid:	int;

LTrelocdesc(map: array of byte)
{
	i, bit: int;

	Freloctid = descid(4*IBY2WD, 1, array [1] of { byte 16rd0 });
	setIpatchtid();		# force type id for patch info
	Ifacetid = descid(IBY2WD, 1, array [1] of { byte 16r80 });

	setbit(map, 8);		# Class name
	setbit(map, 12);	# Superclass name
	setbit(map, 16);	# Interfaces
	setbit(map, 20);	# Class relocation
	setbit(map, 28);	# Data relocation
	#
	# even i: Class name
	# odd i:  Class relocation
	#
	bit = 32;
	for(i = 0; i < (nltclasses-1)*2; i++) {
		setbit(map, bit);
		bit += 4;
	}
	setbit(map, bit);	# nil
}

#
# Write Freloc array to .s file.
#

asmFreloc(off: int, cr: ref Creloc)
{
	fr: ref Freloc;
	reloff: int;		# relative offset for array elements

	reloff = 0;
	asmarray(off, Freloctid, cr.n, reloff);	# cr.n != 0, always
	for(fr = cr.fr; fr != nil; fr = fr.next) {
		asmstring(reloff, fr.field);
		reloff += IBY2WD;
		if(fr.sig != nil)
			asmstring(reloff, fr.sig);
		reloff += IBY2WD;
		asmint(reloff, fr.flags);
		reloff += IBY2WD;
		asmIpatch(reloff, fr.ipatch);
		reloff += IBY2WD;
	}
	bout.puts("\tapop\n");
}

#
# Write Creloc's (except for this_class) to .s file.
#

asmCreloc(off: int): int
{
	he: ref LTHash;
	i: int;

	for(i = 0; i < Hashsize; i++) {
		for(he = lttbl[i]; he != nil; he = he.next) {
			if(he.cr == thisclass)
				continue;
			asmstring(off, he.cr.classname);
			off += IBY2WD;
			asmFreloc(off, he.cr);
			off += IBY2WD;
		}
	}
	off += IBY2WD;	# skip past nil
	return off;
}

JVNO:		con '4';
JMAGIC:		con ('J'<<24)|('a'<<16)|('v'<<8)|'a';
JVERSION:	con ('S'<<24)|('u'<<16)|('x'<<8)|JVNO;

#
# Write Creloc for this_class to .s file.
#

asmthisCreloc(off: int): int
{
	i: int;
	reloff: int;		# relative offset for array elements

	asmint(off, JMAGIC);
	off += IBY2WD;
	asmint(off, JVERSION);
	off += IBY2WD;
	asmstring(off, THISCLASS);
	off += IBY2WD;
	if(SUPERCLASS != nil)	# Object has no superclass
		asmstring(off, SUPERCLASS);
	off += IBY2WD;
	if(class.interfaces_count > 0) {
		reloff = 0;
		asmarray(off, Ifacetid, class.interfaces_count, reloff);
		for(i = 0; i < class.interfaces_count; i++) {
			asmstring(reloff, CLASSNAME(class.interfaces[i]));
			reloff += IBY2WD;
		}
		bout.puts("\tapop\n");
	}
	off += IBY2WD;
	asmFreloc(off, thisclass);
	off += IBY2WD;
	return off;
}

#
# Write Freloc array to .dis file.
#

disFreloc(off: int, cr: ref Creloc)
{
	fr: ref Freloc;
	reloff: int;		# relative offset for array elements

	reloff = 0;
	disarray(off, Freloctid, cr.n);
	for(fr = cr.fr; fr != nil; fr = fr.next) {
		disstring(reloff, fr.field);
		reloff += IBY2WD;
		if(fr.sig != nil)
			disstring(reloff, fr.sig);
		reloff += IBY2WD;
		disint(reloff, fr.flags);
		reloff += IBY2WD;
		disIpatch(reloff, fr.ipatch);
		reloff += IBY2WD;
	}
	disapop();
}

#
# Write Creloc's (except for this_class) to .dis file.
#

disCreloc(off: int): int
{
	he: ref LTHash;
	i: int;

	for(i = 0; i < Hashsize; i++) {
		for(he = lttbl[i]; he != nil; he = he.next) {
			if(he.cr == thisclass)
				continue;
			disstring(off, he.cr.classname);
			off += IBY2WD;
			disFreloc(off, he.cr);
			off += IBY2WD;
		}
	}
	off += IBY2WD;	# skip past nil
	return off;
}

#
# Write Creloc for this_class to .dis file.
#

disthisCreloc(off: int): int
{
	i: int;
	reloff: int;		# relative offset for array elements

	disint(off, JMAGIC);
	off += IBY2WD;
	disint(off, JVERSION);
	off += IBY2WD;
	disstring(off, THISCLASS);
	off += IBY2WD;
	if(SUPERCLASS != nil)	# Object has no superclass
		disstring(off, SUPERCLASS);
	off += IBY2WD;
	if(class.interfaces_count > 0) {
		reloff = 0;
		disarray(off, Ifacetid, class.interfaces_count);
		for(i = 0; i < class.interfaces_count; i++) {
			disstring(reloff, CLASSNAME(class.interfaces[i]));
			reloff += IBY2WD;
		}
		disapop();
	}
	off += IBY2WD;
	disFreloc(off, thisclass);
	off += IBY2WD;
	return off;
}

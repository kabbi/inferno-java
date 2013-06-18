#
# Manage run-time resolution information.
#

LTLOAD:	con 6;

ltload :=	array [LTLOAD] of {
	"java/lang/Class",
	"java/lang/Object",
	"java/lang/String",
	"java/lang/StringBuffer",
	"inferno/vm/Array",
	"java/io/Serializable"
};

dortload(name: string): int
{
	i: int;

	if(name == nil || name == THISCLASS || name == SUPERCLASS)
		return 0;
	for(i = 0; i < LTLOAD; i++) {
		if(name == ltload[i])
			return 0;
	}
	return 1;
}

RTHash: adt {
	rtc:	ref RTClass;
	next:	cyclic ref RTHash;
};

rttbl :=	array [Hashsize] of ref RTHash;	# hash table of ref'd classes
nrtclasses:	int;				# no. of classes referenced

rtappend(rtc: ref RTClass, rtr: ref RTReloc)
{
	if(rtc.rtr == nil)
		rtc.rtr = rtr;
	else
		rtc.tail.next = rtr;
	rtc.tail = rtr;
}

rtprepend(rtc: ref RTClass, rtr: ref RTReloc)
{
	if(rtc.rtr == nil)
		rtc.tail = rtr;
	rtr.next = rtc.rtr;
	rtc.rtr = rtr;
}

#
# Add RTReloc entry.
#

addRTReloc(rtc: ref RTClass, field: string, sig: string, flags: int): ref RTReloc
{
	rtr: ref RTReloc;

	rtr = ref RTReloc(field, sig, flags, nil, nil);
	rtr.ipatch = ref Ipatch(0, 0, nil, nil);
	if(field[0] == '@')	# these must go first in the list !
		rtprepend(rtc, rtr);
	else
		rtappend(rtc, rtr);
	rtc.n += 1;
	return rtr;
}

#
# Allocate a RTClass structure.
#

newRTClass(s: string): ref RTClass
{
	rtc: ref RTClass;

	rtc = ref RTClass(s, nil, nil, 0, 0);
	nrtclasses += 1;
	# want the order: @mp, @np, @adt, @Class
	addRTReloc(rtc, RCLASS, nil, 0);
	addRTReloc(rtc, RADT, nil, 0);
	addRTReloc(rtc, RNP, nil, 0);
	addRTReloc(rtc, RMP, nil, 0);
	return rtc;
}

#
# Add RTClass entry for classname.
#

addRTClass(classname: string): ref RTClass
{
	h: int;
	he: ref RTHash;

	h = hashval(classname);
	he = ref RTHash(newRTClass(classname), rttbl[h]);
	rttbl[h] = he;
	return he.rtc;
}

#
# Get RTClass entry for classname.
#

getRTClass(classname: string): ref RTClass
{
	he: ref RTHash;

	for(he = rttbl[hashval(classname)]; he != nil; he = he.next) {
		if(classname == he.rtc.classname)
			return he.rtc;
	}
	return addRTClass(classname);
}

#
# Get RTReloc entry.  Ignore signature if nil.
#

getRTReloc(rtc: ref RTClass, field: string, sig: string, flags: int): ref RTReloc
{
	rtr: ref RTReloc;
	lowflags: int;

	lowflags = 0;
	for(rtr = rtc.rtr; rtr != nil; rtr = rtr.next) {
		if(rtr.field == field && (sig == nil || rtr.sig == sig)) {
			if(rtr.flags >> 16 == 0) {
				rtr.flags |= flags;
				return rtr;
			} else if(rtr.flags >> 16 == flags >> 16)
				return rtr;
			lowflags = rtr.flags & 16rffff;
		}
	}

	return addRTReloc(rtc, field, sig, flags|lowflags);
}

#
# Add instruction patch information to RTReloc rtr.
#

RTIpatch(rtr: ref RTReloc, i: ref Inst, operand: int, patchkind: int)
{
	addDreloc(i, operand, patchkind);
	addIpatch(rtr.ipatch, i, operand, patchkind, SAVEINST);
}

#
# Fix RTClass and RTReloc 'off' fields to prepare for instruction patch.
#

RTfixoff(off: int)
{
	he: ref RTHash;
	i: int;

	if(nrtclasses > 0) {
		for(i = 0; i < Hashsize; i++) {
			for(he = rttbl[i]; he != nil; he = he.next) {
				he.rtc.off = off;
				off += he.rtc.n * IBY2WD;
			}
		}
	}
}

#
# Patch instructions for run-time relocation.
#

doRTpatch()
{
	a: ref Addr;
	he: ref RTHash;
	ip: ref Ipatch;
	rtr: ref RTReloc;
	i, j: int;
	off, ltsize: int;

	if(nrtclasses == 0)
		return;

	ltsize = LTrelocsize();
	for(i = 0; i < Hashsize; i++) {
		for(he = rttbl[i]; he != nil; he = he.next) {
			off = he.rtc.off - ltsize;
			for(rtr = he.rtc.rtr; rtr != nil; rtr = rtr.next) {
				ip = rtr.ipatch;
				for(j = 0; j < ip.n; j++) {
					case(ip.pinfo[j] & (16r3 << 2)) {
					PSRC =>
						a = ip.i[j].s;
					PDST =>
						a = ip.i[j].d;
					PMID =>
						a = ip.i[j].m;
					}
					case (ip.pinfo[j] & 16r3) {
					PIMM or
					PDIND1 =>
						a.ival = off;
					PSIND or
					PDIND2 =>
						a.offset = off;
					}
				}
				off += IBY2WD;
			}
		}
	}
}

#
# Size of Module Data space taken by run-time relocation information.
#

RTrelocsize(): int
{
	i: int;
	n: int;
	he: ref RTHash;

	n = 0;
	if(nrtclasses > 0) {
		for(i = 0; i < Hashsize; i++) {
			for(he = rttbl[i]; he != nil; he = he.next)
				n += he.rtc.n;
		}
	}
	return n * IBY2WD;
}

#
# Fix type descriptor for run-time relocation information.
#

RTReloctid:	int;

RTrelocdesc(map: array of byte, off: int)
{
	i: int;
	he: ref RTHash;
	rtr: ref RTReloc;

	if(nrtclasses == 0)
		return;

	RTReloctid = descid(3*IBY2WD, 1, array [1] of { byte 16rc0 });

	for(i = 0; i < Hashsize; i++) {
		for(he = rttbl[i]; he != nil; he = he.next) {
			setbit(map, off);	# @mp cell
			off += 4;
			setbit(map, off);	# @np cell
			off += 4;
			setbit(map, off);	# @adt cell
			off += 8;
			rtr = he.rtc.rtr.next.next.next.next;
			while(rtr != nil) {
				if(rtr.flags & (Rspecialmp | Rstaticmp))
					setbit(map, off);
				off += 4;
				rtr = rtr.next;
			}
		}
	}
}

#
# Write RTReloc array to .s file.
#

asmRTReloc(off: int, rtc: ref RTClass)
{
	rtr: ref RTReloc;
	reloff: int;		# relative offset for array elements

	if(rtc.n <= 4)
		return;

	reloff = 0;
	asmarray(off, RTReloctid, rtc.n - 4, reloff);
	# skip @mp @np @adt @Class
	rtr = rtc.rtr.next.next.next.next;
	while(rtr != nil) {
		asmstring(reloff, rtr.field);
		reloff += IBY2WD;
		if(rtr.sig != nil)
			asmstring(reloff, rtr.sig);
		reloff += IBY2WD;
		asmint(reloff, rtr.flags);
		reloff += IBY2WD;
		rtr = rtr.next;
	}
	bout.puts("\tapop\n");
}

#
# Write RTClass information to .s file.
#

asmRTClass(off: int): int
{
	he: ref RTHash;
	i: int;
	ltsize: int;

	if(nrtclasses > 0) {
		ltsize = LTrelocsize();
		for(i = 0; i < Hashsize; i++) {
			for(he = rttbl[i]; he != nil; he = he.next) {
				off += IBY2WD;	# @mp cell
				asmstring(off, he.rtc.classname);
				off += IBY2WD;
				asmRTReloc(off, he.rtc);
				off += IBY2WD;
				asmint(off, he.rtc.off - ltsize);
				off += IBY2WD;
				# account for fields beyond @Class
				off += (he.rtc.n - 4) * IBY2WD;
			}
		}
	}
	return off;
}

#
# Write RTReloc array to .dis file.
#

disRTReloc(off: int, rtc: ref RTClass)
{
	rtr: ref RTReloc;
	reloff: int;		# relative offset for array elements

	if(rtc.n <= 4)
		return;

	reloff = 0;
	disarray(off, RTReloctid, rtc.n - 4);
	# skip @mp @np @adt @Class
	rtr = rtc.rtr.next.next.next.next;
	while(rtr != nil) {
		disstring(reloff, rtr.field);
		reloff += IBY2WD;
		if(rtr.sig != nil)
			disstring(reloff, rtr.sig);
		reloff += IBY2WD;
		disint(reloff, rtr.flags);
		reloff += IBY2WD;
		rtr = rtr.next;
	}
	disapop();
}

#
# Write RTClass information to .dis file.
#

disRTClass(off: int): int
{
	he: ref RTHash;
	i: int;
	ltsize: int;

	if(nrtclasses > 0) {
		ltsize = LTrelocsize();
		for(i = 0; i < Hashsize; i++) {
			for(he = rttbl[i]; he != nil; he = he.next) {
				off += IBY2WD;	# @mp cell
				disstring(off, he.rtc.classname);
				off += IBY2WD;
				disRTReloc(off, he.rtc);
				off += IBY2WD;
				disint(off, he.rtc.off - ltsize);
				off += IBY2WD;
				# account for fields beyond @Class
				off += (he.rtc.n - 4) * IBY2WD;
			}
		}
	}
	return off;
}

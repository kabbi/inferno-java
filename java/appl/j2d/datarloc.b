#
# Manage module data relocation and instruction patch information.
#

dreloc:		ref Ipatch;
Ipatchtid:	int;

setIpatchtid()
{
	Ipatchtid = descid(1, 0, array [1] of { byte 0 });
}

#
# Add an instruction patch directive to ip.
# (flag == SAVEINST) <=> runtime relocation: Inst* needed later
# (flag == !SAVEINST) <=> other: pinfo expected in sequential order
#

addIpatch(ip: ref Ipatch, i: ref Inst, operand: int, patchkind: int, flag: int)
{
	j: int;

	if(ip.n >= ip.max) {
		oldmax := ip.max;
		ip.max += ALLOCINCR;
		newippinfo := array [ip.max] of int;
		for(j = 0; j < oldmax; j++)
			newippinfo[j] = ip.pinfo[j];
		ip.pinfo = newippinfo;
		if(flag == SAVEINST) {
			newipi := array [ip.max] of ref Inst;
			for(j = 0; j < oldmax; j++)
				newipi[j] = ip.i[j];
			ip.i = newipi;
		}
	}
	ip.pinfo[ip.n] = (i.pc << 8) | operand | patchkind;
	if(flag == SAVEINST)
		ip.i[ip.n] = i;
	ip.n += 1;
}

operand := array [] of {
	"?",
	"src",		# PSRC >> 2
	"dst",		# PDST >> 2
	"mid"		# PMID >> 2
};

mode := array [] of {
	"$x",		# PIMM
	"x(reg)",	# PSIND
	"n(x(reg))",	# PDIND1
	"x(n(reg))"	# PDIND2
};

ba:		array of byte;
nba:		int;
HIGHBIT:	con byte 16r80;

sizeba(sz: int)
{
	if(sz > len ba) {
		newba := array [sz] of byte;
		for(i := 0; i < nba; i++)
			newba[i] = ba[i];
		ba = newba;
	}
}

fillba(ip: ref Ipatch)
{
	i: int;
	pclast, pcnext, delta, skip: int;

	sizeba(2*ip.n);
	pclast = 0;
	for(i = 0; i < ip.n; i++) {
		pcnext = ip.pinfo[i] >> 8;
		delta = pcnext-pclast;
		sizeba(nba + delta/1024 + 2);
		while(delta > 7) {
			if(delta > 1024)
				skip = 1024;
			else
				skip = delta & int 16rfffffff8;
			ba[nba++] = byte(256 - (skip >> 3));
			delta -= skip;
		}
		ba[nba++] = byte((delta << 4) | (ip.pinfo[i] & 16rf));
		pclast = pcnext;
	}
}

#
# Write Ipatch information to .s file.
#

asmIpatch(off: int, ip: ref Ipatch)
{
	i: int;
	reloff: int;		# relative offset for array elements
	pc: int;

	if(ip == nil || ip.n == 0)
		return;

	fillba(ip);

	reloff = 0;
	asmarray(off, Ipatchtid, nba, reloff);
	pc = 0;
	for(i = 0; i < nba; i++) {
		bout.puts("\tbyte\t@mp+" + string reloff + "," + string ba[i]);
		if(int(ba[i] & HIGHBIT))
			pc += (256 - int ba[i]) << 3;
		else
			pc += int ba[i] >> 4;
		bout.puts("\t# " + string pc);
		if(!int(ba[i] & HIGHBIT)) {
			bout.puts(", " + operand[(int ba[i] >> 2) & 16r3]
				+ ", " + mode[int ba[i] & 16r3]);
		}
		bout.putc('\n');
		reloff += 1;
	}
	bout.puts("\tapop\n");

	ba = nil;
	nba = 0;
}

#
# Write Ipatch information to .dis file.
#

disIpatch(off: int, ip: ref Ipatch)
{
	i: int;
	reloff: int;		# relative offset for array elements

	if(ip == nil || ip.n == 0)
		return;

	fillba(ip);

	disarray(off, Ipatchtid, nba);
	reloff = 0;
	for(i = 0; i < nba; i++) {
		disbyte(reloff, ba[i]);
		reloff += 1;
	}
	disapop();

	ba = nil;
	nba = 0;
}

#
# Add instruction patch information to dreloc.
#

addDreloc(i: ref Inst, operand: int, patchkind: int)
{
	if(dreloc == nil)
		dreloc = ref Ipatch(0, 0, nil, nil);
	addIpatch(dreloc, i, operand, patchkind, !SAVEINST);
}

#
# Write Dreloc information to .s file.
#

asmDreloc(off: int)
{
	asmIpatch(off, dreloc);
}

#
# Write Dreloc information to .dis file.
#

disDreloc(off: int)
{
	disIpatch(off, dreloc);
}

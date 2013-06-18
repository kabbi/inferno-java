#
# Maintain information about 'finally' blocks.
#

Finally: adt {
	npc:		int;		# Java pc of finally entry (jsr target)
	xpc:		int;		# Java pc of finally exit (ret)
	n:		int;		# number of jsr slots in gototbl
	gototbl:	array of int;	# goto jump table
	off:		int;		# mp offset to gototbl
	next:		cyclic ref Finally;
};

finally:	ref Finally;	# linked list of finally block records

#
# Get record for finally block whose entry point is pc.
#

getfinally(pc: int): ref Finally
{
	f: ref Finally;

	for(f = finally; f != nil; f = f.next) {
		if(f.npc == pc)
			return f;
	}
	return nil;
}

#
# Count jsr's to the finally block whose entry point is pc.
#

finallyentry(pc: int)
{
	f: ref Finally;

	f = getfinally(pc);
	if(f == nil) {
		f = ref Finally(pc, 0, 0, nil, 0, finally);
		finally = f;
	}
	f.n += 1;
}

#
# Allocate the gototbl's and pass them to mdata.c.
#

finallyalloc()
{
	f: ref Finally;

	for(f = finally; f != nil; f = f.next) {
		f.gototbl = array [f.n] of { * => 0 };
		f.off = mpgoto(f.n, f.gototbl);
	}
}

#
# Fix up operands of a Dis movw that implements Java jsr/jsr_w.
#

jsrfixup(s: ref Addr, d: ref Addr, dispc: int, javapc: int)
{
	f: ref Finally;
	i: int;

	f = getfinally(javapc);
	for(i = 0; i < f.n; i++) {
		if(f.gototbl[i] == 0) {
			f.gototbl[i] = dispc;
			break;
		}
	}
	if(i == f.n)
		fatal("jsrfixup: " + string dispc + ", " + string javapc);
	s.ival = i;
	d.offset = f.off + f.n*IBY2WD;
}

#
# Fix up operands of a Dis goto that implements Java ret.
#

retfixup(s: ref Addr, d: ref Addr, retpc: int)
{
	fi, f: ref Finally;

	f = nil;
	for(fi = finally; fi != nil; fi = fi.next) {
		if(fi.xpc == 0 && fi.npc < retpc
		&& (f == nil || f.npc < fi.npc)) {
			f = fi;
		}
	}
	if(f == nil)
		fatal("retfixup: " + string retpc);
	f.xpc = retpc;		# claim this finally block for this 'ret'
	s.offset = f.off + f.n*IBY2WD;
	d.offset = f.off;
}

#
# Free finally information after each method is translated.
#

finallyfree()
{
	finally = nil;
}

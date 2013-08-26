#
# Manage method frame.
#

#
# Local variables (including function parameters).
#

Local: adt {				# local variable
	dtype:	byte;			# type of local (DIS_[BWLP])
	offset:	int;			# fp offset of this local
	next:	cyclic ref Local;	# for locals that are reused
};

frameoff:	int;			# tracks growth of frame
maxframe:	int;			# size of largest frame
locals:		array of ref Local;	# local variables
nlocals:	int;			# number of locals (in the Java sense)

#
# fp temporaries.
#

Fp: adt {
	dtype:	byte;
	refcnt:	int;
};

tmpslwm:	int;		# lowest temporary fp offset
tmpssz:		int;		# size of tmps array
tmps:		array of Fp;	# temporary arena

#
# Resize the locals array.
#
# Since the Java VM reuses local variables (e.g., perhaps using
# the same slot for an int and an Object reference), max_locals
# doesn't always give the number of Dis locals to allow for.
#

resizelocals(ix: int)
{
	oldsz: int;

	oldsz = nlocals;
	while(ix >= nlocals)
		nlocals += ALLOCINCR;
	newlocals := array [nlocals] of ref Local;
	for(i := 0; i < oldsz; i++)
		newlocals[i] = locals[i];
	for(i = oldsz; i < nlocals; i++)
		newlocals[i] = ref Local(byte 0, 0, nil);
	locals = newlocals;
}

#
# Reserve a frame cell for a local variable of the given type.
# The Java VM reuses local variables.
#

reservelocal(dtype: byte, ix: int)
{
	l: ref Local;

	if(ix >= nlocals)
		resizelocals(ix);
	if(locals[ix].dtype == dtype)
		return;
	if(locals[ix].dtype == DIS_X)	# not yet reserved
		l = locals[ix];
	else {				# check reuse list
		for(l = locals[ix].next; l != nil; l = l.next) {
			if(dtype == l.dtype)
				return;
		}
		l = ref Local(byte 0, 0, nil);
		l.next = locals[ix].next;
		locals[ix].next = l;
	}
	l.dtype = dtype;
	frameoff = align(frameoff, cellsize[int dtype]);
	l.offset = frameoff;
	frameoff += cellsize[int dtype];
}

#
# Map the signature parameter types into 'locals' array.
#

mapmethodsig(sig: string, isstatic: int)
{
	index: int;

	index = 0;
	if(isstatic == 0) {
		reservelocal(DIS_P, index);	# this pointer
		index += 1;
	}
	sig = sig[1:];	# skip '('
	while(sig[0] != ')') {
		case sig[0] {
		'Z' or
		'B' or
		'C' or
		'S' or
		'I' =>
			reservelocal(DIS_W, index);
			index += 1;
		'F' =>
			reservelocal(DIS_L, index);
			index += 1;
		'J' or
		'D' =>
			reservelocal(DIS_L, index);
			index += 2;
		'L' or
		'[' =>
			reservelocal(DIS_P, index);
			index += 1;
		}
		sig = nextjavatype(sig);
	}
}

#
# Map references to local variables in the Java bytecode into 'locals' array.
#

maplocalrefs()
{
	j: ref Jinst;
	jpi: ref Jinst.Pi;
	jpw: ref Jinst.Pw;
	jpx1c: ref Jinst.Px1c;
	jix: int;

	jix = 0;
	while(jix < code.code_length) {
		j = code.j[jix];
		pick jp := j {
		Pi =>
			jpi = jp;
		Px1c =>
			jpx1c = jp;
		Pw =>
			jpw = jp;
		}
		case int j.op {
		Jiinc =>
			reservelocal(DIS_W, jpx1c.x1c.ix);
		Jiload or
		Jistore =>
			reservelocal(DIS_W, jpi.i);
		Jiload_0 or
		Jistore_0 =>
			reservelocal(DIS_W, 0);
		Jiload_1 or
		Jistore_1 =>
			reservelocal(DIS_W, 1);
		Jiload_2 or
		Jistore_2 =>
			reservelocal(DIS_W, 2);
		Jiload_3 or
		Jistore_3 =>
			reservelocal(DIS_W, 3);
		Jlload or
		Jlstore or
		Jfload or
		Jfstore or
		Jdload or
		Jdstore =>
			reservelocal(DIS_L, jpi.i);
		Jlload_0 or
		Jlstore_0 or
		Jfload_0 or
		Jfstore_0 or
		Jdload_0 or
		Jdstore_0 =>
			reservelocal(DIS_L, 0);
		Jlload_1 or
		Jlstore_1 or
		Jfload_1 or
		Jfstore_1 or
		Jdload_1 or
		Jdstore_1 =>
			reservelocal(DIS_L, 1);
		Jlload_2 or
		Jlstore_2 or
		Jfload_2 or
		Jfstore_2 or
		Jdload_2 or
		Jdstore_2 =>
			reservelocal(DIS_L, 2);
		Jlload_3 or
		Jlstore_3 or
		Jfload_3 or
		Jfstore_3 or
		Jdload_3 or
		Jdstore_3 =>
			reservelocal(DIS_L, 3);
		Jret or
		Jaload or
		Jastore =>
			reservelocal(DIS_P, jpi.i);
		Jaload_0 or
		Jastore_0 =>
			reservelocal(DIS_P, 0);
		Jaload_1 or
		Jastore_1 =>
			reservelocal(DIS_P, 1);
		Jaload_2 or
		Jastore_2 =>
			reservelocal(DIS_P, 2);
		Jaload_3 or
		Jastore_3 =>
			reservelocal(DIS_P, 3);
		Jwide =>	# repeat from above
			case int jpw.w.op {
			Jiinc or
			Jiload or
			Jistore =>
				reservelocal(DIS_W, jpw.w.ix);
			Jlload or
			Jlstore or
			Jfload or
			Jfstore or
			Jdload or
			Jdstore =>
				reservelocal(DIS_L, jpw.w.ix);
			Jaload or
			Jastore or
			Jret =>
				reservelocal(DIS_P, jpw.w.ix);
			}
		}
		jix += j.size;
	}
}

#
# Prepare a method's frame prior to translating its code.
#

openframe(sig: string, isstatic: int)
{
	frameoff = REGSIZE;
	# 'code' can == nil; e.g, when generating <clinit> for an interface
        if(code != nil)
		nlocals = code.max_locals;
        else
                nlocals = 2;
	locals = array [nlocals] of { * => ref Local(byte 0, 0, nil) };
	mapmethodsig(sig, isstatic);
	if(code != nil)
		maplocalrefs();
	frameoff = align(frameoff, IBY2WD);
	tmpslwm = frameoff;
	tmpssz = frameoff;
	tmps = array [tmpssz] of { * => (byte 0, 0) };
}

#
# Return fp index of a local variable.
#

localix(dtype: byte, ix: int): int
{
	l: ref Local;

	if(dtype == locals[ix].dtype)
		return locals[ix].offset;
	for(l = locals[ix].next; l != nil; l = l.next) {
		if(dtype == l.dtype)
			return l.offset;
	}
	fatal("localix: " + string dtype + ", " + string ix);
	return 0;
}

# fp temporary management starts here

incref(off: int)
{
	if(off >= tmpslwm)		# if <, then local variable
		tmps[off-tmpslwm].refcnt++;
}

acqreg(a: ref Addr)
{
	case int a.mode {
	int Anone or
	int Aimm or
	int Amp or
	int Ampind =>
		;
	int Afp =>
		incref(a.offset);
	int Afpind =>
		incref(a.ival);
	}
}

#
# Reserve the fp temporaries referenced by a StkSnap of some basic block.
#

reservereg(s: array of ref StkSnap, sz: int)
{
	i: int;

	for(i = 0; i < sz; i++)
		acqreg(code.j[s[i].pc[0]].dst);
}

#
# Get fp offset of the next available register of the given type.
#

getoff(dtype: byte): int
{
	off: int;
	stride: int;

	if(dtype == DIS_L) {
		stride = IBY2LG;
		off = tmpslwm % IBY2LG;
	} else {
		stride = IBY2WD;
		off = 0;
	}
	while(off < tmpssz) {
		if(tmps[off].refcnt == 0
		&& (tmps[off].dtype == dtype || tmps[off].dtype == DIS_X)) {
			return off;
		}
		off += stride;
	}
	return off;
}

#
# Get a register (fp offset thereof) of the appropriate type.
#

getreg(dtype: byte): int
{
	off: int;
	oldsz: int;

	off = getoff(dtype);
	if(off >= tmpssz) {	# increase size of temporary arena
		oldsz = tmpssz;
		tmpssz += ALLOCINCR*IBY2LG;
		newtmps := array [tmpssz] of Fp;
		for(i := 0; i < oldsz; i++)
			newtmps[i] = tmps[i];
		for(i = oldsz; i < tmpssz; i++)
			newtmps[i] = Fp(byte 0, 0);
		tmps = newtmps;
	}
	tmps[off].dtype = dtype;
	if(dtype == DIS_L)	# also reserve next word
		tmps[off+IBY2WD].dtype = dtype;
	tmps[off].refcnt = 1;
	if(tmpslwm+off+cellsize[int dtype] > frameoff)
		frameoff = tmpslwm+off+cellsize[int dtype];
	return tmpslwm+off;
}

decref(off: int)
{
	if(off >= tmpslwm) {		# if <, then local variable
		if(--tmps[off-tmpslwm].refcnt < 0)
			fatal("decref: refcnt < 0");
	}
}

#
# "Free" register used by a.
#

relreg(a: ref Addr)
{
	# don't mess with exception object
	if(code != nil && a == code.j[code.code_length].dst)
		return;
	case int a.mode {
	int Anone or
	int Aimm or
	int Amp or
	int Ampind =>
		;
	int Afp =>
		decref(a.offset);
	int Afpind =>
		decref(a.ival);
	}
}

#
# Mark all temporary fp registers as available.  Leave typing as is.
#

clearreg()
{
	i: int;

	i = 0;
	while(i < frameoff-tmpslwm) {
		tmps[i].refcnt = 0;
		i += IBY2WD;
	}
}

#
# Calculate the type descriptor for a frame.
#

framedesc(): int
{
	ln, id, i: int;
	map: array of byte;
	l: ref Local;

	ln = frameoff / (8*IBY2WD) + (frameoff % (8*IBY2WD) != 0);
	map = array [ln] of { * => byte 0 };
	#setbit(map, REFSYSEX);	# slot for 'ref Sys->Exception'
	setbit(map, EXSTR);	# slot for exception string
	setbit(map, EXOBJ);	# slot for exception object
	for(i = 0; i < nlocals; i++) {
		if(locals[i].dtype == DIS_P)
			setbit(map, locals[i].offset);
		for(l = locals[i].next; l != nil; l = l.next) {
			if(l.dtype == DIS_P)
				setbit(map, l.offset);
		}
	}
	i = 0;
	while(i < frameoff-tmpslwm) {
		if(tmps[i].dtype == DIS_P)
			setbit(map, tmpslwm+i);
		i += IBY2WD;
	}
	id = descid(frameoff, ln, map);
	return id;
}

#
# Dispense with a frame.
#

closeframe(): int
{
	tid: int;

	# frame size is always a multiple of 8
	frameoff = align(frameoff, IBY2LG);
	if(frameoff > maxframe)
		maxframe = frameoff;
	tid = framedesc();
	locals = nil;
	frameoff = 0;
	tmpslwm = 0;
	tmpssz = 0;
	tmps = nil;
	return tid;
}

#
# Minimum stack extent size.
#

disstackext()
{
	discon(10*maxframe);
}

#
# Utility functions.
#

codeix:	array of byte;
ix:	int;

uSet(x: array of byte)
{
	codeix = x;
	ix = 0;
}

boundscheck(n: int)
{
	if(ix+n-1 >= len codeix)
		verifyerrormess("Attribute bounds");
}

uPtr(i: int): array of byte
{
	boundscheck(i);
	return codeix[ix:ix+i];
}

uN(i: int)
{
	ix += i;
}

u1(): byte
{
	boundscheck(1);
	return codeix[ix++];
}

u2(): int
{
	l: int;

	boundscheck(2);
	l = (int(codeix[ix])<<8) | int(codeix[ix+1]);
	ix += 2;
	return l;
}

u4(): int
{
	l: int;

	boundscheck(4);
	l = (int(codeix[ix])<<24) | (int(codeix[ix+1])<<16)
		| (int(codeix[ix+2])<<8) | int(codeix[ix+3]);
	ix += 4;
	return l;
}

getattr(): ref Attr
{
	a := ref Attr(0, 0, nil);
	a.name = u2();
	verifycpindex(nil, a.name, 1 << CON_Utf8);
	a.ln = u4();
	boundscheck(a.ln);
	a.info = array [a.ln] of byte;
	a.info[:] = codeix[ix:ix+a.ln];
	ix += a.ln;
	return a;
}

#
# Get the constantvalue_index of a ConstantValue attribute.
#

CVattrindex(fp: ref Field): int
{
	i: int;
	a: ref Attr;

	for(i = 0; i < fp.attr_count; i++) {
		a = fp.attr_info[i];
		if(STRING(a.name) != "ConstantValue")
			continue;
		if(a.ln != 2)
			verifyerrormess("ConstantValue attribute");
		return ((int a.info[0])<<8) | int a.info[1];
	}
	return 0;
}

#
# Align 'off' on an 'align'-byte boundary ('align' is a power of 2).
#

align(off: int, align: int): int
{
	align--;
	return (off + align) & ~align;
}

#
# Set 'offset' bit in type descriptor 'map'.
#

setbit(map: array of byte, offset: int)
{
	map[offset / (8*IBY2WD)] |= byte(1 << (7 - (offset / IBY2WD % 8)));
}

#
# Trivial hash function from asm.
#

hashval(s: string): int
{
	h, i: int;

	h = 0;
	for(i = 0; i < len s; i++)
		h = h*3 + s[i];
	if(h < 0)
		h = -h;
	return h % Hashsize;
}

#
# Advance to the next Java type in a method descriptor.
#

nextjavatype(s: string): string
{
	nlb: int;

	nlb = 0;
	while(1) {
		case s[0] {
		'L' =>
			(nil, s) = str->splitl(s, ";");
			return s[1:];
		'V' or
		'Z' or
		'B' or
		'C' or
		'S' or
		'I' or
		'J' or
		'F' or
		'D' =>
			return s[1:];
		'[' =>
			if(++nlb < 256)
				s = s[1:];
			else
				s[0] = 'X';	# force verifyerrormess()
		* =>
			verifyerrormess("field/method descriptor");
		}
	}
}

j2dtype(jtype: byte): byte
{
	dtype: byte;

	case int jtype {
	'Z' or
	'B' or
	'C' or
	'S' or
	'I' =>
		dtype = byte DIS_W;
	'J' or
	'F' or
	'D' =>
		dtype = byte DIS_L;
	'L' or
	'[' =>
		dtype = byte DIS_P;
	}
	return dtype;
}

#
# $i operands
#

addrimm(a: ref Addr, ival: int)
{
	a.mode = byte Aimm;
	a.ival = ival;
}

#
# Is an int too big to be an immediate operand?
#

notimmable(val: int): int
{
	return val < 0 && ((val >> 29) & 7) != 7 || val > 0 && (val >> 29) != 0;
}

#
# i(fp) and i(mp) operands
#

addrsind(a: ref Addr, mode: byte, off: int)
{
	a.mode = mode;
	a.offset = off;
}

#
# i(j(fp)) and i(j(mp)) operands
#

addrdind(a: ref Addr, mode: byte, fi: int, si: int)
{
	a.mode = mode;
	a.ival = fi;
	a.offset = si;
}

#
# Assign a register to a destination operand if not already done so.
#

dstreg(a: ref Addr, dtype: byte)
{
	if(a.mode == Afp && a.offset == -1)
		a.offset = getreg(dtype);
}

#
# Print a string.
#

pstring(s: string)
{
	slen, c: int;

	slen = len s;
	for(i := 0; i < slen; i++) {
		c = s[i];
		if(c == '\n')
			bout.puts("\\n");
		else if(c == '\t')
			bout.puts("\\t");
		else if(c == '"')
			bout.puts("\\\"");
		else if(c == '\\')
			bout.puts("\\\\");
		else
			bout.putc(c);
	}
}

#
# Die.
#

fatal(msg: string)
{
	print("fatal j2d error: %s\n", msg);
	if(bout != nil)
		sys->remove(ofile);
	reset();
	if(fabort) {
		j: ref Jinst;
		if(j.dst == nil);	# abort
	}
	raise "fail:fail";
	#exit;
}

#
# Bytecode verification.
#

#
# Verify a constant pool index.
#

verifycpindex(j: ref Jinst, ix: int, CON_bits: int)
{
	if(ix > 0 && ix < class.cp_count && ((1 << int class.cts[ix]) & CON_bits))
		return;

	if(j != nil)
		verifyerror(j);
	else
		verifyerrormess("constant pool index");
}

verifyerror(j: ref Jinst)
{
	fatal("VerifyError: " + jinstconv(j));
}

verifyerrormess(mess: string)
{
	fatal("VerifyError: " + mess);
}

badpick(s: string)
{
	fatal("bad pick in " + s);
}

hex(v, n: int): string
{
	return sprint("%.*ux", n, v);
}

#
# Size of frame cell of given type.
#

cellsize := array [int DIS_P + 1] of {
	0,		# DIS_X
	IBY2WD,		# DIS_W
	IBY2LG,		# DIS_L
	IBY2WD,		# DIS_P
};

#
# enable consecutive runs of J2d->init() without having to reload
#

reset()
{
	i: int;

	# asm.b
	clinitclone = nil;

	# bb.b
	roots = nil;
	nr = 0;
	maxr = 0;

	# datarloc.b
	dreloc = nil;
	Ipatchtid = 0;

	# desc.b
	dlist = nil;
	dtail = nil;
	id = 0;

	# dis.b
	ihead = nil;
	itail = nil;
	cache = nil;
	ncached = 0;
	ndatum = 0;
	startoff = 0;
	lastoff = 0;
	lastkind = -1;
	lencache = 0;
	ibuf = nil;
	nibuf = 0;

	# entry.b
	pc = -1;
	tid = -1;

	# finally.b
	finally = nil;

	# frame.b
	frameoff = 0;
	maxframe = 0;
	locals = nil;
	nlocals = 0;
	tmpslwm = 0;
	tmpssz = 0;
	tmps = nil;

	# links.b
	links = nil;
	nlinks = 0;
	fcplist = nil;

	# loader.b
	pcode = nil;
	THISCLASS = nil;
	SUPERCLASS = nil;

	# ltreloc.b
	doclinitinits = 0;
	for(i = 0; i < Hashsize; i++)
		lttbl[i] = nil;
	thisclass = nil;
	nltclasses = 0;
	Freloctid = 0;
	Ifacetid = 0;

	# main.b
	gendis = 1;
	fabort = 0;
	emitcpool = 0;
	verbose = 0;
	bout = nil;

	# mdata.b
	for(i = 0; i < Hashsize; i++)
		htable[i] = nil;
	mpoff = 0;
	mplist = nil;
	mptail = nil;
	llist = nil;
	rlist = nil;

	# patch.b
	plist = nil;

	# rtreloc.b
	for(i = 0; i < Hashsize; i++)
		rttbl[i] = nil;
	nrtclasses = 0;
	RTReloctid = 0;

	# xlate.b
	code = nil;
	pcdis = 0;
	callunrescue = 0;
	rtcache = nil;
	rtncache = 0;
	rtnmax = 0;
	ehinst = nil;
	trylist = nil;
}

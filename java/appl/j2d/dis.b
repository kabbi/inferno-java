ihead:	ref Inst;	# first instruction generated for .class file
itail:	ref Inst;	# last instruction (for appending to list)

cache:		array of byte;	# module data cache
ncached:	int;		# number of bytes in cache
ndatum:		int;		# number of non-string basic datums in cache
startoff:	int;		# offset of first datum in cache
lastoff:	int;		# 1 past last byte offset in cache
lastkind:	int = -1;	# last kind of datum put in cache
lencache:	int;		# capacity of cache

#
# Generate Dis object file (.dis).
#

discon(val: int)
{
	if(val >= -64 && val <= 63) {
		bout.putb(byte(val & ~16r80));
		return;
	}
	if(val >= -8192 && val <= 8191) {
		bout.putb(byte(((val>>8) & ~16rC0) | 16r80));
		bout.putb(byte val);
		return;
	}
	if(notimmable(val))
		fatal("discon: overflow 16r" + hex(val, 0));
	bout.putb(byte((val>>24) | 16rC0));
	bout.putb(byte(val>>16));
	bout.putb(byte(val>>8));
	bout.putb(byte val);
}

disword(w: int)
{
	bout.putb(byte(w >> 24));
	bout.putb(byte(w >> 16));
	bout.putb(byte(w >> 8));
	bout.putb(byte w);
}

disdata(kind: int, n: int)
{
	if(n < DMAX && n != 0)
		bout.putb(byte((kind << DBYTE) | n));
	else{
		bout.putb(byte(kind << DBYTE));
		discon(n);
	}
}

disflush(kind: int, off: int, size: int)
{
	if(kind != lastkind || off != lastoff){
		if(lastkind != -1 && ncached){
			disdata(lastkind, ndatum);
			discon(startoff);
			bout.write(cache, ncached);
		}
		startoff = off;
		lastkind = kind;
		ncached = 0;
		ndatum = 0;
	}
	lastoff = off + size;
	while(kind >= 0 && ncached + size >= len cache){
		c := array[ncached + 1024] of byte;
		c[0:] = cache;
		cache = c;
	}
}

disbyte(off: int, v: byte)
{
	disflush(DEFB, off, 1);
	cache[ncached++] = v;
	ndatum++;
}

disint(off: int, v: int)
{
	disflush(DEFW, off, IBY2WD);
	cache[ncached++] = byte(v >> 24);
	cache[ncached++] = byte(v >> 16);
	cache[ncached++] = byte(v >> 8);
	cache[ncached++] = byte v;
	ndatum++;
}

dislong(off: int, v: big)
{
	iv: int;

	disflush(DEFL, off, IBY2LG);
	iv = int(v >> 32);
	cache[ncached++] = byte(iv >> 24);
	cache[ncached++] = byte(iv >> 16);
	cache[ncached++] = byte(iv >> 8);
	cache[ncached++] = byte iv;
	iv = int v;
	cache[ncached++] = byte(iv >> 24);
	cache[ncached++] = byte(iv >> 16);
	cache[ncached++] = byte(iv >> 8);
	cache[ncached++] = byte iv;
	ndatum++;
}

disreal(off: int, v: real)
{
	disflush(DEFF, off, IBY2LG);
	bv := math->realbits64(v);
	iv := int(bv >> 32);
	cache[ncached++] = byte(iv >> 24);
	cache[ncached++] = byte(iv >> 16);
	cache[ncached++] = byte(iv >> 8);
	cache[ncached++] = byte(iv);
	iv = int bv;
	cache[ncached++] = byte(iv >> 24);
	cache[ncached++] = byte(iv >> 16);
	cache[ncached++] = byte(iv >> 8);
	cache[ncached++] = byte(iv);
	ndatum++;
}

disstring(offset: int, s: string)
{
	disflush(-1, -1, 0);
	d := array of byte s;
	disdata(DEFS, len d);
	discon(offset);
	bout.write(d, len d);
}

#
# Begin an array initializer.
#

disarray(off: int, tid: int, nelt: int)
{
	disflush(-1, -1, 0);
	disdata(DEFA, 1);	# 1 is ignored
	discon(off);
	disword(tid);
	disword(nelt);
	disdata(DIND, 1);	# 1 is ignored
	discon(off);
	disword(0);
}

#
# Terminate an array initializer.
#

disapop()
{
	disflush(-1, -1, 0);
	disdata(DAPOP, 1);	# 1 is ignored
	discon(0);
}

#
# Put number of instructions into .dis Header.
#

disninst()
{
	i: int;

	if(itail != nil)
		i = itail.pc + 1;
	else
		i = 0;
	discon(i);
}

dismode := array [int Aend] of {
	byte AXXX,		# Anone
	byte AIMM,		# Aimm
	byte AMP,		# Amp
	byte (AMP|AIND),	# Ampind
	byte AFP,		# Afp
	byte (AFP|AIND)		# Afpind
};

disregmode := array [int Aend] of {
	byte AXNON,		# Anone
	byte AXIMM,		# Aimm
	byte AXINM,		# Amp
	byte AXNON,		# Ampind
	byte AXINF,		# Afp
	byte AXNON		# Afpind
};

MAXCON:		con 4;
MAXADDR:	con 2*MAXCON;
MAXINST:	con 3*MAXCON+2;
NIBUF:		con 1024;

ibuf:	array of byte;
nibuf:	int;

disbcon(val: int)
{
	if(val >= -64 && val <= 63){
		ibuf[nibuf++] = byte(val & ~16r80);
		return;
	}
	if(val >= -8192 && val <= 8191){
		ibuf[nibuf++] = byte(val>>8 & ~16rC0 | 16r80);
		ibuf[nibuf++] = byte val;
		return;
	}
	if(notimmable(val))
		fatal("disbcon: overflow 16r" + hex(val, 0));
	ibuf[nibuf++] = byte(val>>24 | 16rC0);
	ibuf[nibuf++] = byte(val>>16);
	ibuf[nibuf++] = byte(val>>8);
	ibuf[nibuf++] = byte val;
}

disaddr(a: ref Addr)
{
	val: int;

	val = 0;
	case int a.mode {
	int Aimm =>
		val = a.ival;
	int Afp or
	int Amp =>
		val = a.offset;
	int Afpind or
	int Ampind =>
		disbcon(a.ival);
		val = a.offset;
	}
	disbcon(val);
}

disinst()
{
	i: ref Inst;

	ibuf = array [NIBUF] of byte;
	nibuf = 0;
	for(i = ihead; i != nil; i = i.next){
		if(nibuf >= NIBUF-MAXINST){
			bout.write(ibuf, nibuf);
			nibuf = 0;
		}
		ibuf[nibuf++] = i.op;
		o := dismode[int i.s.mode] << SRC;
		o |= dismode[int i.d.mode] << DST;
		o |= disregmode[int i.m.mode];
		ibuf[nibuf++] = o;
		if(i.m.mode != Anone)
			disaddr(i.m);
		if(i.s.mode != Anone)
			disaddr(i.s);
		if(i.d.mode != Anone)
			disaddr(i.d);
	}
	if(nibuf > 0)
		bout.write(ibuf, nibuf);
	ibuf = nil;
}

disout()
{
	discon(XMAGIC);
	discon(DONTCOMPILE);	# runtime "hints"
	disstackext();		# minimum stack extent size
	disninst();
	disnvar();
	disndesc();
	disnlinks();
	disentry();
	disinst();
	disdesc();
	disvar();
	dismod();
	dislinks();
}

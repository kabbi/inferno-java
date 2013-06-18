#
# Manage module Data Section.
#

MP_INT,
MP_LONG,
MP_REAL,
MP_STRING,
MP_CASE,
MP_GOTO:	con iota;

Datum_v: adt {
	ival:	big;		# MP_[INT|LONG]
	rval:	real;		# MP_REAL
	next:	cyclic ref Datum.Pv;
};

Datum_c: adt {			# MP_CASE
	n:	int;		# number of cases in jmptbl
	jmptbl: array of int;	# 3 words per case, plus default
};

Datum_g: adt {			# MP_GOTO (for finally blocks)
	n:	int;		# number of entries in gototbl
	gototbl:array of int;
};

Datum: adt {
	kind:	byte;				# MP_INT, etc.
	offset:	int;				# byte offset in Data Section
	next:	cyclic ref Datum;
	pick {
		Pv =>
			v:	ref Datum_v;	# MP_[INT|LONG|REAL]
		Ps =>
			s:	string;		# MP_STRING
		Pc =>
			c:	ref Datum_c;	# MP_CASE
		Pg =>
			g:	ref Datum_g;	# MP_GOTO
	}
};

Hentry: adt {
	md:	ref Datum.Ps;
	next:	cyclic ref Hentry;
};

htable :=	array [Hashsize] of ref Hentry;
mpoff:		int;

mplist:		ref Datum;
mptail:		ref Datum;
llist:		ref Datum.Pv;
rlist:		ref Datum.Pv;

#
# Append a module datum to mplist.
#

append(md: ref Datum)
{
	if(mplist == nil)
		mplist = md;
	else
		mptail.next = md;
	mptail = md;
}

#
# Add a 'byte', int 'word', or 'long'.
#

mpintegral(kind: int, ival: big): int
{
	size: int;

	md := ref Datum.Pv;
	md.v = ref Datum_v;
	md.v.ival = ival;
	case kind {
	MP_INT =>
		md.kind = byte MP_INT;
		size = IBY2WD;
		mpoff = align(mpoff, IBY2WD);
	MP_LONG =>
		md.kind = byte MP_LONG;
		size = IBY2LG;
		mpoff = align(mpoff, IBY2LG);
		md.v.next = llist;
		llist = md;
	}
	md.offset = mpoff;
	mpoff += size;
	append(md);
	return md.offset;
}

#
# Add a 'word' (int).
#

mpint(ival: int): int
{
	return mpintegral(MP_INT, big ival);
}

#
# Add a 'long'.
#

mplong(lval: big): int
{
	md: ref Datum.Pv;

	for(md = llist; md != nil; md = md.v.next) {
		if(lval == md.v.ival)
			return md.offset;
	}
	return mpintegral(MP_LONG, lval);
}

#
# Add a 'real'.
#

mpreal(rval: real): int
{
	md: ref Datum.Pv;

	for(md = rlist; md != nil; md = md.v.next) {
		# distinguish 0.0 from -0.0
		if(rval == md.v.rval
		&& math->realbits64(rval) == math->realbits64(md.v.rval))
			return md.offset;
	}
	md = ref Datum.Pv;
	md.kind = byte MP_REAL;
	md.v = ref Datum_v;
	md.v.rval = rval;
	md.v.next = rlist;
	rlist = md;
	mpoff = align(mpoff, IBY2FT);
	md.offset = mpoff;
	mpoff += IBY2FT;
	append(md);
	return md.offset;
}

#
# Add a 'case' jump table.
#

mpcase(sz: int, jt: array of int): int
{
	md := ref Datum.Pc;
	md.kind = byte MP_CASE;
	mpoff = align(mpoff, IBY2WD);
	md.offset = mpoff;
	mpoff += (sz*3+2)*IBY2WD;
	md.c = ref Datum_c;
	md.c.n = sz;
	md.c.jmptbl = jt;
	append(md);
	return md.offset;
}

#
# Add a 'goto' jump table; used for implementing finally blocks.
#

mpgoto(n: int, gototbl: array of int): int
{
	md := ref Datum.Pg;
	md.kind = byte MP_GOTO;
	mpoff = align(mpoff, IBY2WD);
	md.offset = mpoff;
	mpoff += (n+2)*IBY2WD;
	md.g = ref Datum_g;
	md.g.n = n;
	md.g.gototbl = gototbl;
	append(md);
	return md.offset+IBY2WD;
}

#
# Hash table lookup function.
#

htlook(s: string): ref Hentry
{
	he: ref Hentry;

	for(he = htable[hashval(s)]; he != nil; he = he.next)
		if(s == he.md.s)
			return he;
	return nil;
}

#
# Hash table enter function.
#

htenter(md: ref Datum.Ps): ref Hentry
{
	h: int;
	he: ref Hentry;

	h = hashval(md.s);
	he = ref Hentry(md, htable[h]);
	htable[h] = he;
	return he;
}

#
# Add a 'string'.
#

mpstring(s: string): int
{
	he: ref Hentry;
	md: ref Datum.Ps;

	if((he = htlook(s)) != nil)
		return he.md.offset;
	md = ref Datum.Ps;
	md.kind = byte MP_STRING;
	md.s = s;
	mpoff = align(mpoff, IBY2WD);
	md.offset = mpoff;
	mpoff += IBY2WD;
	append(md);
	htenter(md);
	return md.offset;
}

#
# Calculate the type descriptor for the Module Data section.
#

mpdesc()
{
	md: ref Datum;
	ltsize, rtsize, ln, mdsize: int;
	map: array of byte;

	ltsize = LTrelocsize();		# link-time reloc data
	mpoff = align(mpoff, IBY2WD);
	rtsize = RTrelocsize();		# run-time reloc data
	mdsize = ltsize + mpoff + rtsize;
	ln = mdsize / (8*IBY2WD) + (mdsize % (8*IBY2WD) != 0);
	map = array [ln] of { * => byte 0 };
	LTrelocdesc(map);
	for(md = mplist; md != nil; md = md.next) {
		if(int md.kind == MP_STRING)
			setbit(map, ltsize + md.offset);
	}
	RTrelocdesc(map, ltsize + mpoff);
	RTfixoff(ltsize + mpoff);
	mpdescid(mdsize, ln, map);
}

asmprefix(off: int, s: string)
{
	bout.puts("\t" + s + "\t@mp+" + string off + ",");
}

#
# Begin an array initializer.
#

asmarray(off: int, tid: int, nelt: int, reloff: int)
{
	asmprefix(off, "array");
	bout.puts("$" + string tid + "," + string nelt + "\n");
	asmprefix(off, "indir");
	bout.puts(string reloff + "\n");
}

asmint(off: int, val: int)
{
	asmprefix(off, "word");
	bout.puts(string val + "\n");
}

asmlong(off: int, val: big)
{
	asmprefix(off, "long");
	bout.puts(string val + "\n");
}

asmreal(off: int, val: real)
{
	asmprefix(off, "real");
	bout.puts(string val + "\n");
}

asmstring(off: int, s: string)
{
	asmprefix(off, "string");
	bout.putc('"');
	pstring(s);
	bout.puts("\"\n");
}

asmcase(off: int, md: ref Datum.Pc)
{
	i: int;

	asmprefix(off, "word");
	bout.puts(string md.c.n);
	for(i = 0; i < md.c.n; i++) {
		bout.puts("," + string md.c.jmptbl[i*3]);
		bout.puts("," + string md.c.jmptbl[i*3+1]);
		bout.puts("," + string md.c.jmptbl[i*3+2]);
	}
	bout.puts("," + string md.c.jmptbl[md.c.n*3] + "\n");
}

asmgoto(off: int, md: ref Datum.Pg)
{
	i: int;

	asmprefix(off, "word");
	bout.puts(string md.g.n);
	for(i = 0; i < md.g.n; i++)
		bout.puts("," + string md.g.gototbl[i]);
	bout.putc('\n');
}

#
# Write Module Data to .s file.
#

asmvar()
{
	md: ref Datum;
	ltsize, rtsize, off: int;

	ltsize = LTrelocsize();
	rtsize = RTrelocsize();
	bout.puts("\tvar\t@mp," + string(ltsize + mpoff + rtsize) + "\n");
	off = asmthisCreloc(0);
	asmint(off, mpoff + rtsize);
	off += IBY2WD;
	asmDreloc(off);
	off += IBY2WD;
	off = asmCreloc(off);
	off = align(off, 32);
	if(off != ltsize)
		fatal("asmvar: off " + string off + ", " + string ltsize);

	for(md = mplist; md != nil; md = md.next) {
		off = ltsize + md.offset;
		pick mdp := md {
		Pv =>
			case int mdp.kind {
			MP_INT =>
				asmint(off, int mdp.v.ival);
			MP_LONG =>
				asmlong(off, mdp.v.ival);
			MP_REAL =>
				asmreal(off, mdp.v.rval);
			}
		Ps =>
			asmstring(off, mdp.s);
		Pc =>
			asmcase(off, mdp);
		Pg =>
			asmgoto(off, mdp);
		* =>
			badpick("asmvar");
		}
	}
	asmRTClass(ltsize + mpoff);
}

#
# Put Module Data size into .dis Header.
#

disnvar()
{
	discon(LTrelocsize() + mpoff + RTrelocsize());
}

discase(off: int, md: ref Datum.Pc)
{
	i: int;

	disint(off, md.c.n);
	off += IBY2WD;
	for(i = 0; i < md.c.n; i++) {
		disint(off, md.c.jmptbl[i*3]);
		off += IBY2WD;
		disint(off, md.c.jmptbl[i*3+1]);
		off += IBY2WD;
		disint(off, md.c.jmptbl[i*3+2]);
		off += IBY2WD;
	}
	disint(off, md.c.jmptbl[md.c.n*3]);
}

disgoto(off: int, md: ref Datum.Pg)
{
	i: int;

	disint(off, md.g.n);
	for(i = 0; i < md.g.n; i++) {
		off += IBY2WD;
		disint(off, md.g.gototbl[i]);
	}
}

#
# Write Module Data to .dis file.
#

disvar()
{
	md: ref Datum;
	ltsize, rtsize, off: int;

	ltsize = LTrelocsize();
	rtsize = RTrelocsize();
	off = disthisCreloc(0);
	disint(off, mpoff + rtsize);
	off += IBY2WD;
	disDreloc(off);
	off += IBY2WD;
	off = disCreloc(off);
	off = align(off, 32);
	if(off != ltsize)
		fatal("disvar: off " + string off + ", ltsize " + string ltsize);

	for(md = mplist; md != nil; md = md.next) {
		off = ltsize + md.offset;
		pick mdp := md {
		Pv =>
			case int mdp.kind {
			MP_INT =>
				disint(off, int mdp.v.ival);
			MP_LONG =>
				dislong(off, mdp.v.ival);
			MP_REAL =>
				disreal(off, mdp.v.rval);
			}
		Ps =>
			disstring(off, mdp.s);
		Pc =>
			discase(off, mdp);
		Pg =>
			disgoto(off, mdp);
		* =>
			badpick("disvar");
		}
	}
	disRTClass(ltsize + mpoff);
	disflush(-1, -1, 0);
	bout.putb(byte 0);
}

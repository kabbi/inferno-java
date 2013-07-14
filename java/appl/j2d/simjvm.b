#
# "Simulate" the Java VM on a method.
#

Result: adt {
	jtype:	byte;
	pc:	int;
};

jvmstack:	array of ref Result;	# simulated JVM stack
jvmtos:		int;			# number of items in jvmstack
jvmwords:	int;			# number of words that would be on JVM stack
rettype:	int;			# return type of simulated method

jvmpop(): ref Result
{
	r: ref Result;

	if(jvmtos == 0)
		verifyerrormess("stack underflow");
	r = jvmstack[--jvmtos];
	if(r.jtype == byte 'J' || r.jtype == byte 'D')
		jvmwords -= 2;
	else
		jvmwords -= 1;
	if(jvmwords < 0)
		verifyerrormess("stack underflow");
	return r;
}

jvmpush(r: ref Result)
{
	if(r.jtype == byte 'J' || r.jtype == byte 'D')
		jvmwords += 2;
	else
		jvmwords += 1;
	if(jvmwords > code.max_stack)
		verifyerrormess("stack overflow");
	jvmstack[jvmtos++] = r;
}

#
# Initialize jvmstack to process basic block bb.
#

jvminit(bb: ref BB)
{
	i: int;
	r: ref Result;
	s: array of ref StkSnap;

	jvmtos = 0;
	jvmwords = 0;
	if(int (bb.flags & (BB_FINALLY | BB_HANDLER))) {
		r = ref Result(byte 'L', code.code_length);
		jvmpush(r);	# push a dummy
		return;
	}

	# set jvmstack to bb.entrystk
	s = bb.entrystk;
	for(i = 0; i < bb.entrysz; i++) {
		r = ref Result(s[i].jtype, s[i].pc[0]);
		jvmpush(r);
	}
}

typecheck(r: ref Result, jtype: byte)
{
	# assumes 'L' and '[' are interchangeable
	if(r.jtype != jtype && (int r.jtype + int jtype) != 'L' + '[')
		verifyerror(code.j[r.pc]);
}

jvmtype(jtype: int): byte
{
	case jtype {
	'Z' or
	'B' or
	'C' or
	'S' =>
		jtype = 'I';
	}
	return byte jtype;
}

srcalloc(j: ref Jinst, n: int)
{
	j.nsrc = n;
	j.src = array [n] of int;
}

iconst(j: ref Jinst, ival: int)
{
	r: ref Result;

	addrimm(j.dst, ival);
	r = ref Result(byte 'I', j.pc);
	j.jtype = byte 'I';
	jvmpush(r);
}

mpconst(j: ref Jinst, jtype: int, off: int)
{
	r: ref Result;

	addrsind(j.dst, Amp, off);
	r = ref Result(byte jtype, j.pc);
	j.jtype = byte jtype;
	jvmpush(r);
}

verifyindex(j: ref Jinst, jtype: int, ix: int)
{
	n: int;

	case jtype {
	'I' or
	'F' or
	'L' =>
		n = code.max_locals-1;
	'J' or
	'D' =>
		n = code.max_locals-2;
	}
	if(ix > n)
		verifyerror(j);
}

getfpoff(jtype: int, ix: int): int
{
	off: int;

	case jtype {
	'I' =>
		off = localix(DIS_W, ix);
	'J' or
	'F' or
	'D' =>
		off = localix(DIS_L, ix);
	'L' =>
		off = localix(DIS_P, ix);
	}
	return off;
}

javaload(j: ref Jinst, jtype: int, ix: int)
{
	r: ref Result;

	verifyindex(j, jtype, ix);
	addrsind(j.dst, Afp, getfpoff(jtype, ix));
	r = ref Result(byte jtype, j.pc);
	j.jtype = byte jtype;
	jvmpush(r);
}

javastore(j: ref Jinst, jtype: int, ix: int)
{
	r: ref Result;

	verifyindex(j, jtype, ix);

	srcalloc(j, 1);

	r = jvmpop();
	typecheck(r, byte jtype);
	j.src[0] = r.pc;

	addrsind(j.dst, Afp, getfpoff(jtype, ix));
}

arrayload(j: ref Jinst, jtype: int)
{
	r: ref Result;

	srcalloc(j, 2);

	r = jvmpop();
	typecheck(r, byte 'I');
	j.src[1] = r.pc;

	r = jvmpop();
	typecheck(r, byte '[');
	j.src[0] = r.pc;

	addrsind(j.dst, Afp, -1);
	r = ref Result(byte jtype, j.pc);
	j.jtype = byte jtype;
	jvmpush(r);
}

arraystore(j: ref Jinst, jtype: int)
{
	r: ref Result;

	srcalloc(j, 3);

	r = jvmpop();
	typecheck(r, byte jtype);
	j.src[2] = r.pc;

	r = jvmpop();
	typecheck(r, byte 'I');
	j.src[1] = r.pc;

	r = jvmpop();
	typecheck(r, byte '[');
	j.src[0] = r.pc;

}

binop(j: ref Jinst, loptype: int, roptype: int, dsttype: int)
{
	r: ref Result;

	srcalloc(j, 2);

	r = jvmpop();
	typecheck(r, byte roptype);
	j.src[1] = r.pc;

	r = jvmpop();
	typecheck(r, byte loptype);
	j.src[0] = r.pc;

	addrsind(j.dst, Afp, -1);
	r = ref Result(byte dsttype, j.pc);
	j.jtype = byte dsttype;
	jvmpush(r);
}

unop(j: ref Jinst, srctype: int, dsttype: int)
{
	r: ref Result;

	srcalloc(j, 1);

	r = jvmpop();
	typecheck(r, byte srctype);
	j.src[0] = r.pc;

	addrsind(j.dst, Afp, -1);
	r = ref Result(byte dsttype, j.pc);
	j.jtype = byte dsttype;
	jvmpush(r);
}

#
# If the local variable being stored into corresponds to a local
# that is on the stack, then an explicit mov_ MUST be generated
# for the load instruction that put it on the stack.
#

storechk(six: int, stype: int)
{
	i, lix: int;
	ltype: byte;
	j: ref Jinst;
	jpi: ref Jinst.Pi;
	jpw: ref Jinst.Pw;

	for(i = 0; i < jvmtos; i++) {
		j = code.j[jvmstack[i].pc];
		lix = -1;
		pick jp := j {
		Pi =>
			jpi = jp;
		Pw =>
			jpw = jp;
		}
		case int j.op {
		Jiload or
		Jlload or
		Jfload or
		Jdload or
		Jaload =>
			lix = jpi.i;
		Jiload_0 or
		Jlload_0 or
		Jfload_0 or
		Jdload_0 or
		Jaload_0 =>
			lix = 0;
		Jiload_1 or
		Jlload_1 or
		Jfload_1 or
		Jdload_1 or
		Jaload_1 =>
			lix = 1;
		Jiload_2 or
		Jlload_2 or
		Jfload_2 or
		Jdload_2 or
		Jaload_2 =>
			lix = 2;
		Jiload_3 or
		Jlload_3 or
		Jfload_3 or
		Jdload_3 or
		Jaload_3 =>
			lix = 3;
		Jwide =>
			case int jpw.w.op {
			Jiload or
			Jlload or
			Jfload or
			Jdload or
			Jaload =>
				lix = jpw.w.ix;
			}
		}
		ltype = byte '-';
		case int j.op {
		Jiload or
		Jiload_0 or
		Jiload_1 or
		Jiload_2 or
		Jiload_3 =>
			ltype = byte 'I';
		Jlload or
		Jlload_0 or
		Jlload_1 or
		Jlload_2 or
		Jlload_3 =>
			ltype = byte 'J';
		Jfload or
		Jfload_0 or
		Jfload_1 or
		Jfload_2 or
		Jfload_3 =>
			ltype = byte 'F';
		Jdload or
		Jdload_0 or
		Jdload_1 or
		Jdload_2 or
		Jdload_3 =>
			ltype = byte 'D';
		Jaload or
		Jaload_0 or
		Jaload_1 or
		Jaload_2 or
		Jaload_3 =>
			ltype = byte 'L';
		Jwide =>
			case int jpw.w.op {
			Jiload =>
				ltype = byte 'I';
			Jlload =>
				ltype = byte 'J';
			Jfload =>
				ltype = byte 'F';
			Jdload =>
				ltype = byte 'D';
			Jaload =>
				ltype = byte 'L';
			}
		}
		if(lix == six && ltype == byte stype && j.movsrc != nil && j.movsrc.mode == byte Anone) {
			*j.movsrc = *j.dst;
			addrsind(j.dst, Afp, -1);
		}
	}
}

useone(j: ref Jinst, jtype: int)
{
	r: ref Result;

	srcalloc(j, 1);

	r = jvmpop();
	typecheck(r, byte jtype);
	j.src[0] = r.pc;
}

usetwo(j: ref Jinst, loptype: byte, roptype: byte)
{
	r: ref Result;

	srcalloc(j, 2);

	r = jvmpop();
	typecheck(r, roptype);
	j.src[1] = r.pc;

	r = jvmpop();
	typecheck(r, loptype);
	j.src[0] = r.pc;
}

javanew(j: ref Jinst.Pi)
{
	r: ref Result;
	name: string;

	name = CLASSNAME(j.i);
	if(name[0] == '[')
		verifyerror(j);

	addrsind(j.dst, Afp, -1);
	r = ref Result(byte 'L', j.pc);
	j.jtype = byte 'L';
	jvmpush(r);
}

checkdim(j: ref Jinst, ix: int): int
{
	ndim: int;
	name: string;

	ndim = 0;
	name = CLASSNAME(ix);
	while(name[ndim] == '[')
		ndim++;
	if(ndim > 255)
		verifyerror(j);
	return ndim;
}

anewarray(j: ref Jinst.Pi)
{
	checkdim(j, j.i);
	unop(j, 'I', '[');
}

multianewarray(j: ref Jinst.Px2d)
{
	r: ref Result;
	i, ndim: int;

	ndim = checkdim(j, j.x2d.ix);
	if(ndim == 0 || j.x2d.dim > ndim)
		verifyerror(j);

	srcalloc(j, j.x2d.dim);
	for(i = j.x2d.dim-1; i >= 0; i--) {
		r = jvmpop();
		typecheck(r, byte 'I');
		j.src[i] = r.pc;
	}

	addrsind(j.dst, Afp, -1);
	r = ref Result(byte '[', j.pc);
	j.jtype = byte '[';
	jvmpush(r);
}

getname(j: ref Jinst): string
{
	ix: int;

	pick jp := j {
	Pi =>
		ix = jp.i;
	Px2c0 =>
		ix = jp.x2c0.ix;
	* =>
		badpick("getname[Pi|Px2c0]");
	}
	pick c := class.cps[ix] {
	Pfmiref =>
		pick n := class.cps[c.fmiref.name_type_index] {
		Pnat =>
			return STRING(n.nat.name_index);
		* =>
			badpick("getname[Pnat]");
		}
	* =>
		badpick("getname[Pfmiref]");
	}
	return nil;
}

getsig(j: ref Jinst): string
{
	ix: int;

	pick jp := j {
	Pi =>
		ix = jp.i;
	Px2c0 =>
		ix = jp.x2c0.ix;
	* =>
		badpick("getsig[Pi|Px2c0]");
	}
	pick c := class.cps[ix] {
	Pfmiref =>
		pick n := class.cps[c.fmiref.name_type_index] {
		Pnat =>
			return STRING(n.nat.sig_index);
		* =>
			badpick("getsig[Pnat]");
		}
	* =>
		badpick("getsig[Pfmiref]");
	}
	return nil;
}

getfs(j: ref Jinst)
{
	r: ref Result;
	sig: string;

	sig = getsig(j);
	if(int j.op == Jgetfield)
		useone(j, 'L');
	addrsind(j.dst, Afp, -1);
	r = ref Result(jvmtype(sig[0]), j.pc);
	j.jtype = jvmtype(sig[0]);
	jvmpush(r);
}

putfs(j: ref Jinst)
{
	sig: string;

	sig = getsig(j);
	if(int j.op == Jputstatic)
		useone(j, int jvmtype(sig[0]));
	else
		usetwo(j, byte 'L', jvmtype(sig[0]));
}

invoke(j: ref Jinst)
{
	name, sig, savesig: string;
	i, nargs, wargs: int;
	args: array of ref Result;
	rv: ref Result;

	name = getname(j);
	if(name[0] == '<' && (name != "<init>" || int j.op != Jinvokespecial))
		verifyerror(j);

	# count arguments
	sig = getsig(j);
	nargs = 0;
	wargs = 0;
	sig = sig[1:];	# skip '('
	savesig = sig;
	while(sig[0] != ')') {
		nargs++;
		wargs++;
		if(sig[0] == 'J' || sig[0] == 'D')
			wargs++;
		sig = nextjavatype(sig);
	}
	if(int j.op != Jinvokestatic) {
		nargs++;
		wargs++;
	}
	if(wargs > 255)
		verifyerror(j);
	pick jp := j {
	Px2c0 =>
		if(jp.x2c0.narg != wargs)
			verifyerror(j);
	}

	# collect and typecheck arguments
	if(nargs > 0) {
		srcalloc(j, nargs);
		args = array [nargs] of ref Result;
		for(i = nargs-1; i >= 0; i--) {
			args[i] = jvmpop();
			j.src[i] = args[i].pc;
		}
		i = 0;
		if(int j.op != Jinvokestatic) {
			typecheck(args[0], byte 'L');
			i++;
		}
		sig = savesig;
		while(sig[0] != ')') {
			typecheck(args[i], jvmtype(sig[0]));
			i++;
			sig = nextjavatype(sig);
		}
		args = nil;
	}

	# return type
	if(sig[1] != 'V') {	# skip ')'
		addrsind(j.dst, Afp, -1);
		rv = ref Result(jvmtype(sig[1]), j.pc);
		j.jtype = jvmtype(sig[1]);
		jvmpush(rv);
	}
}

javareturn(j: ref Jinst)
{
	jtype: int;

	case int j.op {
	Jireturn =>
		jtype = 'I';
	Jlreturn =>
		jtype = 'J';
	Jfreturn =>
		jtype = 'F';
	Jdreturn =>
		jtype = 'D';
	Jareturn =>
		jtype = 'L';
	Jreturn =>
		jtype = 'V';
	}
	if(jtype != rettype && jtype + rettype != 'L' + '[')
		verifyerror(j);
	if(int j.op != Jreturn)
		useone(j, jtype);
}

ldc(j: ref Jinst)
{
	pick jp := j {
	Pi =>
		ix = jp.i;
	* =>
		badpick("ldc[1]");
	}

	pick c := class.cps[ix] {
	Ptdouble =>
		jtype: int;
		if(int class.cts[ix] == CON_Float)
			jtype = 'F';
		else
			jtype = 'D';
		mpconst(j, jtype, mpreal(c.tdouble));
	Ptvlong =>
		mpconst(j, 'J', mplong(c.tvlong));
	Ptint =>
		if(notimmable(c.tint))
			mpconst(j, 'I', mpint(c.tint));
		else
			iconst(j, c.tint);
	Pstring_index =>
		mpconst(j, 'L', mpstring(STRING(c.string_index)));
		*j.movsrc = *j.dst;
		addrsind(j.dst, Afp, -1);
	Pci =>
		if (class.maj < 50)
			badpick("ldc[2]");
		# TODO: is this actually correct?
		mpconst(j, 'L', mpstring(STRING(c.ci.name_index)));
		*j.movsrc = *j.dst;
		addrsind(j.dst, Afp, -1);
	* =>
		badpick("ldc[2]");
	}
}

oneword(j: ref Jinst, jtype: byte)
{
	if(jtype == byte 'J' || jtype == byte 'D')
		verifyerror(j);
}

javapop(j: ref Jinst)
{
	r1, r2: ref Result;
	n: int;

	r1 = jvmpop();
	n = 1;
	case int j.op {
	Jpop =>
		oneword(j, r1.jtype);
	Jpop2 =>
		if(r1.jtype != byte 'J' && r1.jtype != byte 'D') {
			r2 = jvmpop();
			n = 2;
			oneword(j, r2.jtype);
		}
	}
	srcalloc(j, n);
	j.src[0] = r1.pc;
	if(n == 2)	# pop2
		j.src[1] = r2.pc;
}

javadup(j: ref Jinst)
{
	w1, w2, w3, w4: ref Result;
	n: int;		# number of stack items duplicated

	n = 1;
	case int j.op {
	Jdup =>
		w1 = jvmpop();
		oneword(j, w1.jtype);
		jvmpush(w1);
		jvmpush(w1);
	Jdup_x1 =>
		w1 = jvmpop();
		oneword(j, w1.jtype);
		w2 = jvmpop();
		oneword(j, w2.jtype);
		jvmpush(w1);
		jvmpush(w2);
		jvmpush(w1);
	Jdup_x2 =>
		w1 = jvmpop();
		oneword(j, w1.jtype);
		w2 = jvmpop();
		if(w2.jtype == byte 'J' || w2.jtype == byte 'D') {
			jvmpush(w1);
		} else {
			w3 = jvmpop();
			oneword(j, w3.jtype);
			jvmpush(w1);
			jvmpush(w3);
		}
		jvmpush(w2);
		jvmpush(w1);
	Jdup2 =>
		w1 = jvmpop();
		if(w1.jtype == byte 'J' || w1.jtype == byte 'D') {
			jvmpush(w1);
		} else {
			n = 2;
			w2 = jvmpop();
			oneword(j, w2.jtype);
			jvmpush(w2);
			jvmpush(w1);
			jvmpush(w2);
		}
		jvmpush(w1);
	Jdup2_x1 =>
		w1 = jvmpop();
		if(w1.jtype == byte 'J' || w1.jtype == byte 'D') {
			w3 = jvmpop();
			oneword(j, w3.jtype);
			jvmpush(w1);
			jvmpush(w3);
		} else {
			n = 2;
			w2 = jvmpop();
			oneword(j, w2.jtype);
			w3 = jvmpop();
			oneword(j, w3.jtype);
			jvmpush(w2);
			jvmpush(w1);
			jvmpush(w3);
			jvmpush(w2);
		}
		jvmpush(w1);
	Jdup2_x2 =>
		w1 = jvmpop();
		if(w1.jtype != byte 'J' && w1.jtype != byte 'D') {
			n = 2;
			w2 = jvmpop();
			oneword(j, w2.jtype);
		}
		w3 = jvmpop();
		if(w3.jtype != byte 'J' && w3.jtype != byte 'D') {
			w4 = jvmpop();
			oneword(j, w4.jtype);
		}

		if(w1.jtype != byte 'J' && w1.jtype != byte 'D')
			jvmpush(w2);
		jvmpush(w1);
		if(w3.jtype != byte 'J' && w3.jtype != byte 'D')
			jvmpush(w4);
		jvmpush(w3);
		if(w1.jtype != byte 'J' && w1.jtype != byte 'D')
			jvmpush(w2);
		jvmpush(w1);
	}
	srcalloc(j, n);
	j.src[0] = w1.pc;
	if(n == 2)
		j.src[1] = w2.pc;
}

javaswap(j: ref Jinst)
{
	w1, w2: ref Result;

	w1 = jvmpop();
	oneword(j, w1.jtype);
	w2 = jvmpop();
	oneword(j, w2.jtype);
	jvmpush(w1);
	jvmpush(w2);
}

simjinst(j: ref Jinst)
{
	jpi: ref Jinst.Pi;
	jpx1c: ref Jinst.Px1c;
	jpx2d: ref Jinst.Px2d;
	jpw: ref Jinst.Pw;

	pick jp := j {
	Pi =>
		jpi = jp;
	Px1c =>
		jpx1c = jp;
	Px2d =>
		jpx2d = jp;
	Pw =>
		jpw = jp;
	}

	case int j.op {
	Jnop =>
		;
	Jaconst_null =>
		mpconst(j, 'L', 0);
	Jiconst_m1 =>
		iconst(j, -1);
	Jiconst_0 =>
		iconst(j, 0);
	Jiconst_1 =>
		iconst(j, 1);
	Jiconst_2 =>
		iconst(j, 2);
	Jiconst_3 =>
		iconst(j, 3);
	Jiconst_4 =>
		iconst(j, 4);
	Jiconst_5 =>
		iconst(j, 5);
	Jlconst_0 =>
		mpconst(j, 'J', mplong(big 0));
	Jlconst_1 =>
		mpconst(j, 'J', mplong(big 1));
	Jfconst_0 =>
		mpconst(j, 'F', mpreal(0.0));
	Jfconst_1 =>
		mpconst(j, 'F', mpreal(1.0));
	Jfconst_2 =>
		mpconst(j, 'F', mpreal(2.0));
	Jdconst_0 =>
		mpconst(j, 'D', mpreal(0.0));
	Jdconst_1 =>
		mpconst(j, 'D', mpreal(1.0));
	Jbipush or
	Jsipush =>
		iconst(j, jpi.i);
	Jldc or
	Jldc_w or
	Jldc2_w =>
		ldc(j);
	Jiload =>
		javaload(j, 'I', jpi.i);
	Jlload =>
		javaload(j, 'J', jpi.i);
	Jfload =>
		javaload(j, 'F', jpi.i);
	Jdload =>
		javaload(j, 'D', jpi.i);
	Jaload =>
		javaload(j, 'L', jpi.i);
	Jiload_0 =>
		javaload(j, 'I', 0);
	Jiload_1 =>
		javaload(j, 'I', 1);
	Jiload_2 =>
		javaload(j, 'I', 2);
	Jiload_3 =>
		javaload(j, 'I', 3);
	Jlload_0 =>
		javaload(j, 'J', 0);
	Jlload_1 =>
		javaload(j, 'J', 1);
	Jlload_2 =>
		javaload(j, 'J', 2);
	Jlload_3 =>
		javaload(j, 'J', 3);
	Jfload_0 =>
		javaload(j, 'F', 0);
	Jfload_1 =>
		javaload(j, 'F', 1);
	Jfload_2 =>
		javaload(j, 'F', 2);
	Jfload_3 =>
		javaload(j, 'F', 3);
	Jdload_0 =>
		javaload(j, 'D', 0);
	Jdload_1 =>
		javaload(j, 'D', 1);
	Jdload_2 =>
		javaload(j, 'D', 2);
	Jdload_3 =>
		javaload(j, 'D', 3);
	Jaload_0 =>
		javaload(j, 'L', 0);
	Jaload_1 =>
		javaload(j, 'L', 1);
	Jaload_2 =>
		javaload(j, 'L', 2);
	Jaload_3 =>
		javaload(j, 'L', 3);
	Jbaload or
	Jcaload or
	Jsaload or
	Jiaload =>
		arrayload(j, 'I');
	Jlaload =>
		arrayload(j, 'J');
	Jfaload =>
		arrayload(j, 'F');
	Jdaload =>
		arrayload(j, 'D');
	Jaaload =>
		arrayload(j, 'L');
	Jistore =>
		storechk(jpi.i, 'I');
		javastore(j, 'I', jpi.i);
	Jlstore =>
		storechk(jpi.i, 'J');
		javastore(j, 'J', jpi.i);
	Jfstore =>
		storechk(jpi.i, 'F');
		javastore(j, 'F', jpi.i);
	Jdstore =>
		storechk(jpi.i, 'D');
		javastore(j, 'D', jpi.i);
	Jastore =>	# could be start of finally block or handler
		storechk(jpi.i, 'L');
		javastore(j, 'L', jpi.i);
	Jistore_0 =>
		storechk(0, 'I');
		javastore(j, 'I', 0);
	Jistore_1 =>
		storechk(1, 'I');
		javastore(j, 'I', 1);
	Jistore_2 =>
		storechk(2, 'I');
		javastore(j, 'I', 2);
	Jistore_3 =>
		storechk(3, 'I');
		javastore(j, 'I', 3);
	Jlstore_0 =>
		storechk(0, 'J');
		javastore(j, 'J', 0);
	Jlstore_1 =>
		storechk(1, 'J');
		javastore(j, 'J', 1);
	Jlstore_2 =>
		storechk(2, 'J');
		javastore(j, 'J', 2);
	Jlstore_3 =>
		storechk(3, 'J');
		javastore(j, 'J', 3);
	Jfstore_0 =>
		storechk(0, 'F');
		javastore(j, 'F', 0);
	Jfstore_1 =>
		storechk(1, 'F');
		javastore(j, 'F', 1);
	Jfstore_2 =>
		storechk(2, 'F');
		javastore(j, 'F', 2);
	Jfstore_3 =>
		storechk(3, 'F');
		javastore(j, 'F', 3);
	Jdstore_0 =>
		storechk(0, 'D');
		javastore(j, 'D', 0);
	Jdstore_1 =>
		storechk(1, 'D');
		javastore(j, 'D', 1);
	Jdstore_2 =>
		storechk(2, 'D');
		javastore(j, 'D', 2);
	Jdstore_3 =>
		storechk(3, 'D');
		javastore(j, 'D', 3);
	Jastore_0 =>	# could be start of finally block or handler
		storechk(0, 'L');
		javastore(j, 'L', 0);
	Jastore_1 =>
		storechk(1, 'L');
		javastore(j, 'L', 1);
	Jastore_2 =>
		storechk(2, 'L');
		javastore(j, 'L', 2);
	Jastore_3 =>
		storechk(3, 'L');
		javastore(j, 'L', 3);
	Jbastore or
	Jcastore or
	Jsastore or
	Jiastore =>
		arraystore(j, 'I');
	Jlastore =>
		arraystore(j, 'J');
	Jfastore =>
		arraystore(j, 'F');
	Jdastore =>
		arraystore(j, 'D');
	Jaastore =>
		arraystore(j, 'L');
	Jpop or
	Jpop2 =>
		javapop(j);
	Jdup or
	Jdup_x1 or
	Jdup_x2 or
	Jdup2 or
	Jdup2_x1 or
	Jdup2_x2 =>
		javadup(j);
	Jswap =>
		javaswap(j);
	Jiadd or
	Jisub or
	Jimul or
	Jidiv or
	Jirem or
	Jishl or
	Jishr or
	Jiushr or
	Jiand or
	Jior or
	Jixor =>
		binop(j, 'I', 'I', 'I');
	Jladd or
	Jlsub or
	Jlmul or
	Jldiv or
	Jlrem or
	Jland or
	Jlor or
	Jlxor =>
		binop(j, 'J', 'J', 'J');
	Jfadd or
	Jfsub or
	Jfmul or
	Jfdiv or
	Jfrem =>
		binop(j, 'F', 'F', 'F');
	Jdadd or
	Jdsub or
	Jdmul or
	Jddiv or
	Jdrem =>
		binop(j, 'D', 'D', 'D');
	Jineg =>
		unop(j, 'I', 'I');
	Jlneg =>
		unop(j, 'J', 'J');
	Jfneg =>
		unop(j, 'F', 'F');
	Jdneg =>
		unop(j, 'D', 'D');
	Jlshl or
	Jlshr or
	Jlushr =>
		binop(j, 'J', 'I', 'J');
	Jiinc =>
		verifyindex(j, 'I', jpx1c.x1c.ix);
		storechk(jpx1c.x1c.ix, 'I');
	Ji2l =>
		unop(j, 'I', 'J');
	Ji2f =>
		unop(j, 'I', 'F');
	Ji2d =>
		unop(j, 'I', 'D');
	Jl2i =>
		unop(j, 'J', 'I');
	Jl2f =>
		unop(j, 'J', 'F');
	Jl2d =>
		unop(j, 'J', 'D');
	Jf2i =>
		unop(j, 'F', 'I');
	Jf2l =>
		unop(j, 'F', 'J');
	Jf2d =>
		unop(j, 'F', 'D');
	Jd2i =>
		unop(j, 'D', 'I');
	Jd2l =>
		unop(j, 'D', 'J');
	Jd2f =>
		unop(j, 'D', 'F');
	Ji2b or
	Ji2c or
	Ji2s =>
		unop(j, 'I', 'I');
	Jlcmp =>
		binop(j, 'J', 'J', 'I');
	Jfcmpl or
	Jfcmpg =>
		binop(j, 'F', 'F', 'I');
	Jdcmpl or
	Jdcmpg =>
		binop(j, 'D', 'D', 'I');
	Jifeq or
	Jifne or
	Jiflt or
	Jifge or
	Jifgt or
	Jifle =>
		useone(j, 'I');
	Jif_icmpeq or
	Jif_icmpne or
	Jif_icmplt or
	Jif_icmpge or
	Jif_icmpgt or
	Jif_icmple =>
		usetwo(j, byte 'I', byte 'I');
	Jif_acmpeq or
	Jif_acmpne =>
		usetwo(j, byte 'L', byte 'L');
	Jgoto or
	Jgoto_w or
	Jjsr or		# no push; not following ...
	Jjsr_w =>	# ... these branches
		;
	Jret =>
		verifyindex(j, 'L', jpi.i);
	Jtableswitch or
	Jlookupswitch =>
		useone(j, 'I');
	Jireturn or
	Jlreturn or
	Jfreturn or
	Jdreturn or
	Jareturn or
	Jreturn =>
		javareturn(j);
	Jgetfield or
	Jgetstatic =>
		getfs(j);
	Jputfield or
	Jputstatic =>
		putfs(j);
	Jinvokevirtual or
	Jinvokespecial or
	Jinvokestatic or
	Jinvokeinterface =>
		invoke(j);
	Jxxxunusedxxx =>
		;
	Jnew =>
		javanew(jpi);
	Jnewarray =>
		unop(j, 'I', '[');
	Janewarray =>
		anewarray(jpi);
	Jarraylength =>
		unop(j, '[', 'I');
	Jathrow =>
		useone(j, 'L');
	Jcheckcast =>
		unop(j, 'L', 'L');
	Jinstanceof =>
		unop(j, 'L', 'I');
	Jmonitorenter or
	Jmonitorexit =>
		useone(j, 'L');
	Jwide =>
		case int jpw.w.op {
		Jiload =>
			javaload(j, 'I', jpw.w.ix);
		Jlload =>
			javaload(j, 'J', jpw.w.ix);
		Jfload =>
			javaload(j, 'F', jpw.w.ix);
		Jdload =>
			javaload(j, 'D', jpw.w.ix);
		Jaload =>
			javaload(j, 'L', jpw.w.ix);
		Jistore =>
			storechk(jpw.w.ix, 'I');
			javastore(j, 'I', jpw.w.ix);
		Jlstore =>
			storechk(jpw.w.ix, 'J');
			javastore(j, 'J', jpw.w.ix);
		Jfstore =>
			storechk(jpw.w.ix, 'F');
			javastore(j, 'F', jpw.w.ix);
		Jdstore =>
			storechk(jpw.w.ix, 'D');
			javastore(j, 'D', jpw.w.ix);
		Jastore =>
			storechk(jpw.w.ix, 'L');
			javastore(j, 'L', jpw.w.ix);
		Jret =>
			verifyindex(j, 'L', jpw.w.ix);
		Jiinc =>
			verifyindex(j, 'I', jpw.w.ix);
			storechk(jpw.w.ix, 'I');
		}
	Jmultianewarray =>
		multianewarray(jpx2d);
	Jifnull or
	Jifnonnull =>
		useone(j, 'L');
	}
}

#
# Take snapshot of current stack.
#

snapstack(): array of ref StkSnap
{
	s: array of ref StkSnap;
	i: int;

	s = array [jvmtos] of ref StkSnap;
	for(i = 0; i < jvmtos; i++) {
		s[i] = ref StkSnap(byte 0, 0, nil);
		s[i].jtype = jvmstack[i].jtype;
		s[i].npc = 1;
		s[i].pc = array [1] of int;
		s[i].pc[0] = jvmstack[i].pc;
	}
	return s;
}

#
# Merge current stack into bb.entrystk.
#

stackmerge(bb: ref BB)
{
	s: ref StkSnap;
	i, j: int;
	pct: int;
	jtype1, jtype2: byte;

	if(jvmtos == 0) {
		if(bb.entrysz != 0)
			verifyerrormess("stack merge");
		return;
	}
	if(bb.entrystk == nil) {
		bb.entrysz = jvmtos;
		bb.entrystk = snapstack();
		return;
	}
	# true stack merge
	if(bb.entrysz != jvmtos)
		verifyerrormess("stack merge");
outer:	for(i = 0; i < jvmtos; i++) {
		jtype1 = jvmstack[i].jtype;
		jtype2 = bb.entrystk[i].jtype;
		if(jtype1 != jtype2 && (int jtype1 + int jtype2) != 'L' + '[')
			verifyerrormess("stack merge");
		s = bb.entrystk[i];
		for(j = 0; j < s.npc; j++) {
			if(s.pc[j] == jvmstack[i].pc)
				continue outer;
		}
		newpc := array [s.npc+1] of int;
		for(k := 0; k < s.npc; k++)
			newpc[k] = s.pc[k];
		s.pc = newpc;
		s.pc[s.npc++] = jvmstack[i].pc;
		# percolate into sorted order
		for(j = s.npc-1; j > 0; j--) {
			if(s.pc[j-1] > s.pc[j]) {
				pct = s.pc[j-1];
				s.pc[j-1] = s.pc[j];
				s.pc[j] = pct;
			} else
				break;
		}
	}
}

#
# Simulate the instructions in a basic block.
#

simbb(bb: ref BB)
{
	i: int;
	j: ref Jinst;
	pc: int;

	if(bb.state == BB_POSTSIM)
		fatal("simbb: BB_POSTSIM");

	jvminit(bb);
	pc = bb.js.pc;
	while(pc <= bb.je.pc) {
		j = code.j[pc];
		simjinst(j);
		pc += j.size;
	}
	bb.state = BB_POSTSIM;

	if(jvmtos != 0) {
		bb.exitsz = jvmtos;
		bb.exitstk = snapstack();
	}

	for(i = 0; i < bb.nsucc; i++) {
		stackmerge(bb.succ[i]);
		if(bb.succ[i].state == BB_PRESIM)
			bbput(bb.succ[i]);
	}
}

#
# Simulate the Java VM on each of the method's basic blocks.
#

simjvm(sig: string)
{
	bb: ref BB;
	ix: int;

	ix = 1;	# skip '('
	while(sig[ix] != ')')
		ix++;
	rettype = int jvmtype(sig[ix+1]);

	jvmstack = array [code.max_stack] of ref Result;

	bbinit();
	while((bb = bbget()) != nil)
		simbb(bb);

	jvmstack = nil;
}

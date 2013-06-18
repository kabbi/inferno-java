#
# Java bytecode disassembler.
#

# Java operand classifications

AT,				# unsigned byte (newarray)
B2,				# 2-byte signed branch offset
B4,				# 4-byte signed branch offset
X1,				# 1-byte unsigned index (ldc)
X1C,				# iinc
X2,				# 2-byte unsigned index
X2C0,				# invokeinterface
X2D,				# multianewarray
T1,				# tableswitch
T2,				# lookupswitch
V1,				# 1-byte signed value (bipush)
V2,				# 2-byte signed value (sipush)
W,				# wide
Z:		con iota;	# zero operands

Jmnemon: adt {
	op:	string;
	kind:	int;
};

#
# Java bytecode mnemonics.
#

tab: array of Jmnemon = array [MAXJAVA] of {
	("nop",			Z),
	("aconst_null",		Z),
	("iconst_m1",		Z),
	("iconst_0",		Z),
	("iconst_1",		Z),
	("iconst_2",		Z),
	("iconst_3",		Z),
	("iconst_4",		Z),
	("iconst_5",		Z),
	("lconst_0",		Z),
	("lconst_1",		Z),
	("fconst_0",		Z),
	("fconst_1",		Z),
	("fconst_2",		Z),
	("dconst_0",		Z),
	("dconst_1",		Z),
	("bipush",		V1),
	("sipush",		V2),
	("ldc",			X1),
	("ldc_w",		X2),
	("ldc2_w",		X2),
	("iload",		X1),
	("lload",		X1),
	("fload",		X1),
	("dload",		X1),
	("aload",		X1),
	("iload_0",		Z),
	("iload_1",		Z),
	("iload_2",		Z),
	("iload_3",		Z),
	("lload_0",		Z),
	("lload_1",		Z),
	("lload_2",		Z),
	("lload_3",		Z),
	("fload_0",		Z),
	("fload_1",		Z),
	("fload_2",		Z),
	("fload_3",		Z),
	("dload_0",		Z),
	("dload_1",		Z),
	("dload_2",		Z),
	("dload_3",		Z),
	("aload_0",		Z),
	("aload_1",		Z),
	("aload_2",		Z),
	("aload_3",		Z),
	("iaload",		Z),
	("laload",		Z),
	("faload",		Z),
	("daload",		Z),
	("aaload",		Z),
	("baload",		Z),
	("caload",		Z),
	("saload",		Z),
	("istore",		X1),
	("lstore",		X1),
	("fstore",		X1),
	("dstore",		X1),
	("astore",		X1),
	("istore_0",		Z),
	("istore_1",		Z),
	("istore_2",		Z),
	("istore_3",		Z),
	("lstore_0",		Z),
	("lstore_1",		Z),
	("lstore_2",		Z),
	("lstore_3",		Z),
	("fstore_0",		Z),
	("fstore_1",		Z),
	("fstore_2",		Z),
	("fstore_3",		Z),
	("dstore_0",		Z),
	("dstore_1",		Z),
	("dstore_2",		Z),
	("dstore_3",		Z),
	("astore_0",		Z),
	("astore_1",		Z),
	("astore_2",		Z),
	("astore_3",		Z),
	("iastore",		Z),
	("lastore",		Z),
	("fastore",		Z),
	("dastore",		Z),
	("aastore",		Z),
	("bastore",		Z),
	("castore",		Z),
	("sastore",		Z),
	("pop",			Z),
	("pop2",		Z),
	("dup",			Z),
	("dup_x1",		Z),
	("dup_x2",		Z),
	("dup2",		Z),
	("dup2_x1",		Z),
	("dup2_x2",		Z),
	("swap",		Z),
	("iadd",		Z),
	("ladd",		Z),
	("fadd",		Z),
	("dadd",		Z),
	("isub",		Z),
	("lsub",		Z),
	("fsub",		Z),
	("dsub",		Z),
	("imul",		Z),
	("lmul",		Z),
	("fmul",		Z),
	("dmul",		Z),
	("idiv",		Z),
	("ldiv",		Z),
	("fdiv",		Z),
	("ddiv",		Z),
	("irem",		Z),
	("lrem",		Z),
	("frem",		Z),
	("drem",		Z),
	("ineg",		Z),
	("lneg",		Z),
	("fneg",		Z),
	("dneg",		Z),
	("ishl",		Z),
	("lshl",		Z),
	("ishr",		Z),
	("lshr",		Z),
	("iushr",		Z),
	("lushr",		Z),
	("iand",		Z),
	("land",		Z),
	("ior",			Z),
	("lor",			Z),
	("ixor",		Z),
	("lxor",		Z),
	("iinc",		X1C),
	("i2l",			Z),
	("i2f",			Z),
	("i2d",			Z),
	("l2i",			Z),
	("l2f",			Z),
	("l2d",			Z),
	("f2i",			Z),
	("f2l",			Z),
	("f2d",			Z),
	("d2i",			Z),
	("d2l",			Z),
	("d2f",			Z),
	("i2b",			Z),
	("i2c",			Z),
	("i2s",			Z),
	("lcmp",		Z),
	("fcmpl",		Z),
	("fcmpg",		Z),
	("dcmpl",		Z),
	("dcmpg",		Z),
	("ifeq",		B2),
	("ifne",		B2),
	("iflt",		B2),
	("ifge",		B2),
	("ifgt",		B2),
	("ifle",		B2),
	("if_icmpeq",		B2),
	("if_icmpne",		B2),
	("if_icmplt",		B2),
	("if_icmpge",		B2),
	("if_icmpgt",		B2),
	("if_icmple",		B2),
	("if_acmpeq",		B2),
	("if_acmpne",		B2),
	("goto",		B2),
	("jsr",			B2),
	("ret",			X1),
	("tableswitch",		T1),
	("lookupswitch",	T2),
	("ireturn",		Z),
	("lreturn",		Z),
	("freturn",		Z),
	("dreturn",		Z),
	("areturn",		Z),
	("return",		Z),
	("getstatic",		X2),
	("putstatic",		X2),
	("getfield",		X2),
	("putfield",		X2),
	("invokevirtual",	X2),
	("invokespecial",	X2),
	("invokestatic",	X2),
	("invokeinterface",	X2C0),
	("xxxunusedxxx",	Z),
	("new",			X2),
	("newarray",		AT),
	("anewarray",		X2),
	("arraylength",		Z),
	("athrow",		Z),
	("checkcast",		X2),
	("instanceof",		X2),
	("monitorenter",	Z),
	("monitorexit",		Z),
	("wide",		W),
	("multianewarray",	X2D),
	("ifnull",		B2),
	("ifnonnull",		B2),
	("goto_w",		B4),
	("jsr_w",		B4),
};

#
# %J format conversion.
#

jinstconv(j: ref Jinst): string
{
	t: Jmnemon;
	i: int;

	t = tab[int j.op];
	s := t.op;
	if(t.kind != Z)
		s += " ";
	pick jp := j {
	Pz =>
		;
	Pi =>
		s += string jp.i;
	Px1c =>
		s += string jp.x1c.ix + "," + string jp.x1c.icon;
	Px2c0 =>
		s += string jp.x2c0.ix + "," + string jp.x2c0.narg;
		s += "," + string jp.x2c0.zero;
	Px2d =>
		s += string jp.x2d.ix + "," + string jp.x2d.dim;
	Pt1 =>
		s += string jp.t1.dflt + "," + string jp.t1.lb;
		s += "," + string jp.t1.hb;
		if(jp.t1.tbl != nil) {
			for(i = 0; i < jp.t1.hb - jp.t1.lb + 1; i++)
				s += "," + string jp.t1.tbl[i];
		}
	Pt2 =>
		s += string jp.t2.dflt + "," + string jp.t2.np;
		if(jp.t2.tbl != nil) {
			for(i = 0; i < 2*jp.t2.np; i++)
				s += "," + string jp.t2.tbl[i];
		}
	Pw =>
		s += string jp.w.op + "," + string jp.w.ix;
		if(int jp.w.op == Jiinc)
			s += "," + string jp.w.icon;
	}
	return s;
}

#
# Verify an exception handler.
#

verifyehpc(c: ref Code, pc: int)
{
	if(pc >= c.code_length || c.j[pc] == nil)
		verifyerrormess("handler pc");
}

verifyhandler(c: ref Code, h: ref Handler)
{
	verifyehpc(c, h.start_pc);

	if(h.end_pc != c.code_length)
		verifyehpc(c, h.end_pc);

	verifyehpc(c, h.handler_pc);

	if(h.catch_type != 0)
		verifycpindex(nil, h.catch_type, 1 << CON_Class);
}

#
# Disassemble code for a method.
#

javadas(a: ref Attr): ref Code
{
	c: ref Code;
	h, h1, h2: ref Handler;
	pc, codelen: int;
	l, i, k, n, nat, nln, CON_bits: int;
	op: byte;

	uSet(a.info);
	c = ref Code(0, 0, 0, nil, 0, nil);
	c.max_stack = u2();
	c.max_locals = u2();
	c.code_length = u4();
	if(c.code_length == 0 || c.code_length > 65535)
		verifyerrormess("code_length");
	# +1 is for exception object
	c.j = array [c.code_length+1] of ref Jinst;
	c.j[c.code_length] = ref Jinst.Pi;
	c.j[c.code_length].dst = ref Addr;

	pc = 0;
	codelen = c.code_length;
	while(codelen > 0) {
		op = u1();
		case int tab[int op].kind {
		Z =>
			j := ref Jinst.Pz;
			j.op = op;
			l = 1;
			c.j[pc] = j;
		V1 =>
			j := ref Jinst.Pi;
			j.op = op;
			j.i = (int u1() << 24) >> 24;	# sign-extend
			l = 2;
			c.j[pc] = j;
		B2 or
		V2 =>
			j := ref Jinst.Pi;
			j.op = op;
			j.i = (u2() << 16) >> 16;	# sign-extend
			l = 3;
			c.j[pc] = j;
		B4 =>
			j := ref Jinst.Pi;
			j.op = op;
			j.i = u4();
			l = 5;
			c.j[pc] = j;
		X1 =>
			j := ref Jinst.Pi;
			j.op = op;
			j.i = int u1();
			if(int j.op == Jldc) {
				CON_bits = 1 << CON_Integer | 1 << CON_Float | 1 << CON_String;
				verifycpindex(j, j.i, CON_bits);
			}
			l = 2;
			c.j[pc] = j;
		X2 =>
			j := ref Jinst.Pi;
			j.op = op;
			j.i = u2();
			case int j.op {
			Jldc_w =>
				CON_bits = 1 << CON_Integer | 1 << CON_Float | 1 << CON_String;
				if (class.maj >= 50)
					CON_bits |= 1 << CON_Class;
				if (class.maj >= 51)
					CON_bits |= 1 << CON_MethodType | 1 << CON_MethodHandle;
			Jldc2_w =>
				CON_bits = 1 << CON_Long | 1 << CON_Double;
				if (class.maj >= 50)
					CON_bits |= 1 << CON_Class;
				if (class.maj >= 51)
					CON_bits |= 1 << CON_MethodType | 1 << CON_MethodHandle;
				if(j.i == class.cp_count-1)
					verifyerror(j);
			Jgetstatic or
			Jputstatic or
			Jgetfield or
			Jputfield =>
				CON_bits = 1 << CON_Fieldref;
			Jinvokevirtual or
			Jinvokespecial or
			Jinvokestatic =>
				CON_bits = 1 << CON_Methodref;
			Jnew or
			Janewarray or
			Jcheckcast or
			Jinstanceof =>
				CON_bits = 1 << CON_Class;
			}
			verifycpindex(j, j.i, CON_bits);
			l = 3;
			c.j[pc] = j;
		X1C =>
			j := ref Jinst.Px1c;
			j.op = op;
			j.x1c = ref Jinst_x1c;
			j.x1c.ix = int u1();
			j.x1c.icon = (int u1() << 24) >> 24;     # sign-extend
			l = 3;
			c.j[pc] = j;
		X2D =>
			j := ref Jinst.Px2d;
			j.op = op;
			j.x2d = ref Jinst_x2d;
			j.x2d.ix = u2();
			j.x2d.dim = int u1();
			verifycpindex(j, j.x2d.ix, 1 << CON_Class);
			if(j.x2d.dim < 1)
				verifyerror(j);
			l = 4;
			c.j[pc] = j;
		AT =>
			j := ref Jinst.Pi;
			j.op = op;
			j.i = int u1();
			if(j.i < T_BOOLEAN || j.i > T_LONG)
				verifyerror(j);
			l = 2;
			c.j[pc] = j;
		T1 =>
			j := ref Jinst.Pt1;
			j.op = op;
			j.t1 = ref Jinst_t1;
			if((pc+1)%4)	# <0-3 byte pad>
				n = 4-(pc+1)%4;
			else
				n = 0;
			l = n;
			while(n--)
				u1();
			j.t1.dflt = u4();
			j.t1.lb = u4();
			j.t1.hb = u4();
			if(j.t1.lb > j.t1.hb)
				verifyerror(j);
			n = j.t1.hb - j.t1.lb + 1;
			j.t1.tbl = array [n] of int;
			for(i = 0; i < n; i++)
				j.t1.tbl[i] = u4();
			l += 13 + n * 4;
			c.j[pc] = j;
		T2 =>
			j := ref Jinst.Pt2;
			j.op = op;
			j.t2 = ref Jinst_t2;
			if((pc+1)%4)	# <0-3 byte pad>
				n = 4-(pc+1)%4;
			else
				n = 0;
			l = n;
			while(n--)
				u1();
			j.t2.dflt = u4();
			j.t2.np = u4();
			n = j.t2.np;
			if(n < 0)
				verifyerror(j);
			j.t2.tbl = array [n*2] of int;
			for(i = 0; i < n*2; i++)
				j.t2.tbl[i] = u4();
			for(i = 2; i < n*2; i += 2) {
				if(j.t2.tbl[i-2] > j.t2.tbl[i])
					verifyerror(j);
			}
			l += 9 + n * 8;
			c.j[pc] = j;
		W =>
			j := ref Jinst.Pw;
			j.op = op;
			j.w = ref Jinst_w;
			j.w.op = u1();
			j.w.ix = u2();
			case int j.w.op {
			Jiload or
			Jlload or
			Jfload or
			Jdload or
			Jaload or
			Jistore or
			Jlstore or
			Jfstore or
			Jdstore or
			Jastore or
			Jret =>
				l = 4;
			Jiinc =>
				j.w.icon = (u2() << 16) >> 16;  # sign-extend
				l = 6;
			* =>
				verifyerror(j);
			}
			c.j[pc] = j;
		X2C0 =>
			j := ref Jinst.Px2c0;
			j.op = op;
			j.x2c0 = ref Jinst_x2c0;
			j.x2c0.ix = u2();
			j.x2c0.narg = int u1();
			j.x2c0.zero = int u1();	# must be 0
			verifycpindex(j, j.x2c0.ix, 1 << CON_InterfaceMref);
			if(j.x2c0.narg < 1 || j.x2c0.zero != 0)
				verifyerror(j);
			l = 5;
			c.j[pc] = j;
		* =>
			verifyerrormess("illegal opcode");
		}
		c.j[pc].pc = pc;
		c.j[pc].line = 0;
		c.j[pc].size = l;
		c.j[pc].nsrc = 0;
		c.j[pc].dst = ref Addr(byte 0, 0, 0);
		c.j[pc].movsrc = ref Addr(byte 0, 0, 0);
		codelen -= l;
		pc += l;
	}
	if(codelen != 0)
		verifyerrormess("code_length");

	c.nex = u2();
	if(c.nex > 0) {
		c.ex = array [c.nex] of ref Handler;
		for(i = 0; i < c.nex; i++) {
			c.ex[i] = ref Handler(0, 0, 0, 0);
			h = c.ex[i];
			h.start_pc = u2();
			h.end_pc = u2();
			h.handler_pc = u2();
			h.catch_type = u2();
			verifyhandler(c, h);
			#
			# sort nested try blocks that have same start_pc,
			# outer-most go first (see cvtehinfo() [xlate.c])
			#
			for(k = i; k > 0; k--) {
				h1 = c.ex[k];
				h2 = c.ex[k-1];
				if(h1.start_pc == h2.start_pc
				&& h1.end_pc > h2.end_pc) {
					c.ex[k] = h2;
					c.ex[k-1] = h1;
				}
			}
		}
	}

	if(gensbl == 0)
		return c;

	# interpret LineNumberTable attributes */
	nat = u2();
	for(i = 0; i < nat; i++) {
		at := getattr();
		if(STRING(at.name) == "LineNumberTable") {
			nln = (int at.info[0] << 8) | int at.info[1];
			for(k = 2; k < nln*4+2; k += 4) {
				pc = (int at.info[k] << 8) | int at.info[k+1];
				c.j[pc].line = (int at.info[k+2] << 8) | int at.info[k+3];
			}
		}
	}
	pc = 0;
	n = 0;
	while(pc < c.code_length) {
		if(c.j[pc].line == 0)
			c.j[pc].line = n;
		else
			n = c.j[pc].line;
		pc += c.j[pc].size;
	}

	return c;
}

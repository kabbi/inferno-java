#
# Class loader.
#

class:		ref Class;	# class under translation
pcode:		array of PCode;	# pointers to byte code of defined methods
THISCLASS:	string;
SUPERCLASS:	string;

STRING(i: int): string
{
	pick cp := class.cps[i] {
	Putf8 =>
		return cp.utf8.utf8;
	* =>
		badpick("STRING");
	}
	return nil;
}

CLASSNAME(i: int): string
{
	pick cp := class.cps[i] {
	Pci =>
		return STRING(cp.ci.name_index);
	* =>
		badpick("CLASSNAME");
	}
	return nil;
}

u8(): big
{
	b1, b2: big;

	b1 = big u4() << 32;
	b2 = big u4() & 16rffffffff;
	return b1 | b2;
}

#
# Bytecode verification.
#

verifyutf8index(index: int)
{
	verifycpindex(nil, index, 1 << CON_Utf8);
	if(STRING(index) == nil)
		verifyerrormess("nil name or descriptor");
}

verifyclassindex(index: int)
{
	verifycpindex(nil, index, 1 << CON_Class);
	pick cp := class.cps[index] {
	Pci =>
		verifyutf8index(cp.ci.name_index);
	* =>
		badpick("verifyclassindex");
	}
}

verifyfielddesc(name_index: int, sig_index: int)
{
	sig: string;
	ftype: int;

	verifyutf8index(name_index);
	verifyutf8index(sig_index);
	sig = STRING(sig_index);
	ftype = sig[0];
	sig = nextjavatype(sig);
	if(ftype == 'V' || sig != nil)
		verifyerrormess("field descriptor");
}

verifymethoddesc(name_index: int, sig_index: int)
{
	name, sig: string;
	rtype: int;
	wargs: int;

	verifyutf8index(name_index);
	name = STRING(name_index);
	verifyutf8index(sig_index);
	sig = STRING(sig_index);

	# check special <method> names
	if(name[0] == '<') {
		if(name == "<init>")
			;
		else if(name == "<clinit>") {
			if(sig != "()V")
				verifyerrormess("<clinit> signature");
			return;
		} else
			verifyerrormess("<method> name");
	}

	# check signature
	if(sig[0] != '(')
		verifyerrormess("method descriptor");
	sig = sig[1:];
	wargs = 0;
	while(sig[0] != ')') {
		wargs++;
		if(sig[0] == 'J' || sig[0] == 'D')
			wargs++;
		sig = nextjavatype(sig);
	}
	sig = sig[1:];
	rtype = sig[0];
	sig = nextjavatype(sig);
	if(wargs > 255 || sig != nil || (name[0] == '<' && rtype != 'V'))
		verifyerrormess("method descriptor");
}

verifycpindexes()
{
	i: int;
	nameindex, sigindex, natindex: int;

	for(i = 1; i < class.cp_count; i++) {
		pick cp := class.cps[i] {
		Pci =>
			verifyutf8index(cp.ci.name_index);
		Pfmiref =>
			verifyclassindex(cp.fmiref.class_index);
			natindex = cp.fmiref.name_type_index;
			verifycpindex(nil, natindex, 1 << CON_NameAndType);
			pick cpnat := class.cps[natindex] {
			Pnat =>
				nameindex = cpnat.nat.name_index;
				sigindex = cpnat.nat.sig_index;
			* =>
				badpick("verifycpindexes (inner)");
			}
			if(int class.cts[i] == CON_Fieldref)
				verifyfielddesc(nameindex, sigindex);
			else
				verifymethoddesc(nameindex, sigindex);
		Pstring_index =>
			verifycpindex(nil, cp.string_index, 1 << CON_Utf8);
		Ptint =>
			;
		Pnat =>
			# CON_NameAndType is verified through
			# CON_Fieldref, CON_Methodref, CON_InterfaceMref
			;
		Putf8 =>
			;
		Ptvlong =>
			i++;
		Ptdouble =>
			if(int class.cts[i] == CON_Double)	# else CON_Float
				i++;
		# since 49.0
		Pmethodhandle =>
			case cp.mh.ref_kind {
			# TODO: implement all ref_kinds handling
			* =>
				verifyerrormess("bad method_handle ref_kind");
			}
		Pmethodtype =>
			verifycpindex(nil, cp.mt.descriptor_index, 1 << CON_Utf8);
		Pinvokedyn =>
			# TODO: verify bs_method_attr_index field
			verifycpindex(nil, cp.invokedyn.name_type_index, 1 << CON_NameAndType);
		* =>
			badpick("verifycpindexes (outer)");
		}
	}
}

CLASSMUTEX:	con ACC_FINAL|ACC_ABSTRACT;

verifyclassflags()
{
	bad: int;

	if(class.access_flags & ACC_INTERFACE) {
		if(SUPERCLASS != "java/lang/Object")
			verifyerrormess("superclass");
		# java bug: ACC_ABSTRACT should be set ???
		# bad = (class.access_flags & ACC_ABSTRACT) != ACC_ABSTRACT;
		bad = 0;
		bad += (class.access_flags & ACC_FINAL) != 0;
	} else {
		bad = (class.access_flags & CLASSMUTEX) == CLASSMUTEX;
	}
	if(bad)
		verifyerrormess("access_flags");
}

multippp(flag: int): int
{
	ret: int;

	case flag & (ACC_PUBLIC|ACC_PRIVATE|ACC_PROTECTED) {
	0 or
	ACC_PUBLIC or
	ACC_PRIVATE or
	ACC_PROTECTED =>
		ret = 0;
	* =>
		ret = 1;
	}
	return ret;
}

IFACEFIELD:	con ACC_PUBLIC|ACC_STATIC|ACC_FINAL;
_IFACEFIELD:	con ACC_PRIVATE|ACC_PROTECTED|ACC_VOLATILE|ACC_TRANSIENT;
FIELDMUTEX:	con ACC_FINAL|ACC_VOLATILE;
CVATTRTAGS:	con ((1<<CON_Integer)|(1<<CON_Long)|(1<<CON_Float)|(1<<CON_Double)|(1<<CON_String));

verifyfield(fp: ref Field)
{
	bad, n: int;
	c: int;

	verifyfielddesc(fp.name_index, fp.sig_index);
	if(class.access_flags & ACC_INTERFACE) {
		bad = (fp.access_flags & _IFACEFIELD) != 0;
		bad += (fp.access_flags & IFACEFIELD) != IFACEFIELD;
	} else {
		bad = multippp(fp.access_flags);
		bad += (fp.access_flags & FIELDMUTEX) == FIELDMUTEX;
	}
	if(bad)
		verifyerrormess("access_flags");

	# verify ConstantValue attribute
	n = CVattrindex(fp);
	if(n == 0)
		return;
	verifycpindex(nil, n, CVATTRTAGS);
	c = STRING(fp.sig_index)[0];
	pick cp := class.cps[n] {
	Ptdouble =>
		if(int class.cts[n] == CON_Float)
			bad = (c != 'F');
		else
			bad = (c != 'D');
	Ptvlong =>
		bad = (c != 'J');
	Ptint =>
		case c {
		'Z' or
		'B' or
		'C' or
		'S' or
		'I' =>
			bad = 0;
		* =>
			bad = 1;
		}
	Pstring_index =>
		bad = (c != 'L');
	* =>
		bad = 1;
	}
	if(bad)
		verifyerrormess("ConstantValue attribute");
}

IFACEMETHOD:	con ACC_PUBLIC|ACC_ABSTRACT;
_IFACEMETHOD:	con ACC_PRIVATE|ACC_PROTECTED|ACC_STATIC|ACC_FINAL|ACC_SYNCHRONIZED|ACC_NATIVE;
_INITFLAGS:	con ACC_STATIC|ACC_FINAL|ACC_SYNCHRONIZED|ACC_NATIVE|ACC_ABSTRACT;
# java bug: ACC_SYNCHRONIZED wrongly allowed with ACC_ABSTRACT ???
#METHODMUTEX:	con ACC_PRIVATE|ACC_STATIC|ACC_FINAL|ACC_SYNCHRONIZED|ACC_NATIVE;
METHODMUTEX:	con ACC_PRIVATE|ACC_STATIC|ACC_FINAL|ACC_NATIVE;

verifymethod(mp: ref Method)
{
	bad: int;
	name: string;

	verifymethoddesc(mp.name_index, mp.sig_index);
	name = STRING(mp.name_index);
	if(name == "<clinit>")
		return;
	if(class.access_flags & ACC_INTERFACE) {
		bad = (mp.access_flags & _IFACEMETHOD) != 0;
		bad += (mp.access_flags & IFACEMETHOD) != IFACEMETHOD;
	} else {
		bad = multippp(mp.access_flags);
		if(name == "<init>")
			bad += (mp.access_flags & _INITFLAGS) != 0;
		if(mp.access_flags & ACC_ABSTRACT)
			bad += (mp.access_flags & METHODMUTEX) != 0;
	}
	if(bad)
		verifyerrormess("access_flags");
	#
	# Code attribute verified during disassembly
	# ignore Exceptions attribute for now
	#
}

#
# Parse a byte stream into a Class stucture.
#

byte2Class(text: array of byte)
{
	i, j: int;
	fp: ref Field;
	mp: ref Method;

	uSet(text);
	class = ref Class(0, 0, 0, nil, nil, 0, 0, 0, 0, nil, 0, nil, 0, nil, 0);

	if(u4() != int 16rCAFEBABE)
		verifyerrormess("magic");

	class.min = u2();
	class.maj = u2();

	class.cp_count = u2();
	class.cps = array [class.cp_count] of ref Const;
	class.cts = array [class.cp_count] of { * => byte 0 };

	for(i = 1; i < class.cp_count; i++) {
		class.cts[i] = byte u1();
		case int class.cts[i] {
		CON_Class =>
			cp := ref Const.Pci;
			cp.ci = ref Const_ci;
			cp.ci.name_index = u2();
			class.cps[i] = cp;
		CON_Fieldref or
		CON_Methodref or
		CON_InterfaceMref =>
			cp := ref Const.Pfmiref;
			cp.fmiref = ref Const_fmiref;
			cp.fmiref.class_index = u2();
			cp.fmiref.name_type_index = u2();
			class.cps[i] = cp;
		CON_String =>
			cp := ref Const.Pstring_index;
			cp.string_index = u2();
			class.cps[i] = cp;
		CON_Integer =>
			cp := ref Const.Ptint;
			cp.tint = u4();
			class.cps[i] = cp;
		CON_Float =>
			cp := ref Const.Ptdouble;
			cp.tdouble = math->bits32real(u4());
			class.cps[i] = cp;
		CON_Long =>
			cp := ref Const.Ptvlong;
			cp.tvlong = u8();
			class.cps[i] = cp;
			i++;
		CON_Double =>
			cp := ref Const.Ptdouble;
			cp.tdouble = math->bits64real(u8());
			class.cps[i] = cp;
			i++;
		CON_NameAndType =>
			cp := ref Const.Pnat;
			cp.nat = ref Const_nat;
			cp.nat.name_index = u2();
			cp.nat.sig_index = u2();
			class.cps[i] = cp;
		CON_Utf8 =>
			cp := ref Const.Putf8;
			cp.utf8 = ref Const_utf8;
			cp.utf8.ln = u2();
			# null char represented as 16rC080 in String literals
			a := uPtr(cp.utf8.ln);
			(src, dst) := (0, 0);
			while(src < cp.utf8.ln) {
				if(src+1 < cp.utf8.ln && a[src] == byte 16rC0
				&& a[src+1] == byte 16r80) {
					a[dst] = byte 0;
					src++;
				} else
					a[dst] = a[src];
				src++;
				dst++;
			}
			cp.utf8.utf8 = string a[0:dst];
			uN(cp.utf8.ln);
			class.cps[i] = cp;
		# since 49.0
		CON_MethodHandle =>
			verifyerrormess("MethodHandles are not implemented");
			cp := ref Const.Pmethodhandle;
			cp.mh = ref Const_methodhandle;
			cp.mh.ref_kind = int u1();
			cp.mh.ref_index = u2();
			class.cps[i] = cp;
		CON_MethodType =>
			verifyerrormess("MethodTypes are not implemented");
			cp := ref Const.Pmethodtype;
			cp.mt = ref Const_methodtype;
			cp.mt.descriptor_index = u2();
			class.cps[i] = cp;
		CON_InvokeDynamic =>
			verifyerrormess("InvokeDynamics are not implemented");
			cp := ref Const.Pinvokedyn;
			cp.invokedyn = ref Const_invokedyn;
			cp.invokedyn.bs_method_attr_index = u2();
			cp.invokedyn.name_type_index = u2();
			class.cps[i] = cp;
		* =>
			verifyerrormess("constant pool tag");
		}
	}

	verifycpindexes();		# verify after all are established

	class.access_flags = u2();	# verify after [THIS|SUPER]CLASS set

	class.this_class = u2();
	verifyclassindex(class.this_class);
	THISCLASS = CLASSNAME(class.this_class);

	class.super_class = u2();
	if(class.super_class) {
		verifyclassindex(class.super_class);
		SUPERCLASS = CLASSNAME(class.super_class);
	} else if(THISCLASS != "java/lang/Object")
		verifyerrormess("superclass");

	verifyclassflags();

	# for compatibility with JavaSoft VM
	if(len THISCLASS > len "inferno/vm/"
	&& THISCLASS[0:len "inferno/vm/"] == "inferno/vm/") {
		#
		# ACC_ABSTRACT & ACC_FINAL are both set in JVM,
		# but a class can't be declared that way
		#
		class.access_flags |= ACC_ABSTRACT;
		#
		# ACC_SUPER not set in JVM, but javac sets it
		# for inferno/vm/Array
		#
		class.access_flags &= ~ACC_SUPER;
	} else if(class.access_flags & ACC_INTERFACE) {
		# interfaces are implicitly abstract
		class.access_flags |= ACC_ABSTRACT;
	}

	class.interfaces_count = u2();
	if(class.interfaces_count > 0)
		class.interfaces = array [class.interfaces_count] of int;
	for(i = 0; i < class.interfaces_count; i++) {
		class.interfaces[i] = u2();
		verifyclassindex(class.interfaces[i]);
	}

	class.fields_count = u2();
	if(class.fields_count > 0)
		class.fields = array [class.fields_count] of ref Field;
	for(i = 0; i < class.fields_count; i++) {
		class.fields[i] = ref Field(0, 0, 0, 0, nil);
		fp = class.fields[i];
		fp.access_flags = u2();
		fp.name_index = u2();
		fp.sig_index = u2();
		fp.attr_count = u2();
		if(fp.attr_count > 0)
			fp.attr_info = array [fp.attr_count] of ref Attr;
		for(j = 0; j < fp.attr_count; j++)
			fp.attr_info[j] = getattr();
		verifyfield(fp);
	}

	class.methods_count = u2();
	if(class.methods_count > 0) {
		class.methods = array [class.methods_count] of ref Method;
		pcode = array [class.methods_count] of PCode;
	}
	for(i = 0; i < class.methods_count; i++) {
		class.methods[i] = ref Method(0, 0, 0, 0, nil);
		mp = class.methods[i];
		mp.access_flags = u2();
		mp.name_index = u2();
		mp.sig_index = u2();
		mp.attr_count = u2();
		if(mp.attr_count > 0)
			mp.attr_info = array [mp.attr_count] of ref Attr;
		for(j = 0; j < mp.attr_count; j++)
			mp.attr_info[j] = getattr();
		verifymethod(mp);
	}

	# get SourceFile attribute
	i = u2();
	for(j = 0; j < i; j++) {
		a := getattr();
		if(STRING(a.name) == "SourceFile") {
			class.source_file = (int a.info[0] << 8) | int a.info[1];
			verifyutf8index(class.source_file);
			break;
		}
	}
}

#
# Return Class structure for named class.
#

ClassLoader(name: string)
{
	fd := sys->open(name, Sys->OREAD);
	if(fd == nil)
		fatal("ClassLoader: can't open " + name + ": " + sprint("%r"));

	(i, dir) := sys->fstat(fd);
	if(i < 0)
		fatal("ClassLoader: can't stat " + name + ": " + sprint("%r"));

	bytecode := array [int dir.length] of byte;
	if(sys->read(fd, bytecode, int dir.length) != int dir.length)
		fatal("ClassLoader: read " + name + ": " + sprint("%r"));

	byte2Class(bytecode);

	fd = nil;
	bytecode = nil;
}

#
# Print access flag mnemonics.
#

accessflags(flags: int, isclass: int)
{
	if(flags == 0)
		return;
	bout.putc('\t');
	if(flags & ACC_PUBLIC)
		bout.puts("|public");
	if(flags & ACC_PRIVATE)
		bout.puts("|private");
	if(flags & ACC_PROTECTED)
		bout.puts("|protected");
	if(flags & ACC_STATIC)
		bout.puts("|static");
	if(flags & ACC_FINAL)
		bout.puts("|final");
	if(flags & ACC_SUPER) {	# ACC_SYNCHRONIZED == ACC_SUPER
		if(isclass)
			bout.puts("|super");
		else
			bout.puts("|synchronized");
	}
	if(flags & ACC_VOLATILE)
		bout.puts("|volatile");
	if(flags & ACC_TRANSIENT)
		bout.puts("|transient");
	if(flags & ACC_NATIVE)
		bout.puts("|native");
	if(flags & ACC_INTERFACE)
		bout.puts("|interface");
	if(flags & ACC_ABSTRACT)
		bout.puts("|abstract");
	bout.putc('|');
}

#
# Print out the constant pool (-c option).
#

dumpcpool()
{
	i, n: int;
	fp: ref Field;
	mp: ref Method;

	bout.puts("# -- Constant Pool Start --\n");
	bout.puts("# minor: " + string class.min + "\n");
	bout.puts("# major: " + string class.maj + "\n");

	bout.puts("# constant pool count: " + string class.cp_count + "\n");

	for(i = 1; i < class.cp_count; i++) {
		bout.puts("# " + string i + " ");
		pick cp := class.cps[i] {
		Ptdouble =>
			if(int class.cts[i] == CON_Float)
				bout.puts("Float " + string cp.tdouble + "\n");
			else {
				bout.puts("Double " + string cp.tdouble + "\n");
				i++;
			}
		Ptvlong =>
			bout.puts("Long " + string cp.tvlong + "\n");
			i++;
		Ptint =>
			bout.puts("Int " + string cp.tint + "\n");
		Pstring_index =>
			bout.puts("String " + string cp.string_index);
			bout.puts("\t\"");
			pstring(STRING(cp.string_index));
			bout.puts("\"\n");
		Pci =>
			bout.puts("Class " + string cp.ci.name_index);
			bout.puts("\t\"" + STRING(cp.ci.name_index) + "\"\n");
		Pfmiref =>
			case int class.cts[i] {
			CON_Fieldref =>
				bout.puts("Field");
			CON_Methodref =>
				bout.puts("Method");
			CON_InterfaceMref =>
				bout.puts("InterfaceMethod");
			}
			bout.puts(" Ref " + string cp.fmiref.class_index + " "
				+ string cp.fmiref.name_type_index + "\n");
		Pnat =>
			bout.puts("N&T " + string cp.nat.name_index + " "
				+ string cp.nat.sig_index);
			bout.puts("\t\"" + STRING(cp.nat.name_index) + "\", \""
				+ STRING(cp.nat.sig_index) + "\"\n");
		Putf8 =>
			bout.puts("utf8 \"");
			pstring(cp.utf8.utf8);
			bout.puts("\"\n");
		# since 49.0
		Pmethodhandle =>
			bout.puts("niy\n");
		Pmethodtype =>
			bout.puts("niy\n");
		Pinvokedyn =>
			bout.puts("niy\n");
		* =>
			badpick("dumpcpool");
		}
	}

	bout.puts("# access flags: " + string class.access_flags);
	accessflags(class.access_flags, 1);
	bout.putc('\n');

	bout.puts("# this_class: " + string class.this_class + "\t\""
		+ THISCLASS + "\"\n");
	bout.puts("# super_class: " + string class.super_class);
	if(SUPERCLASS != nil)
		bout.puts("\t\"" + SUPERCLASS + "\"");
	bout.putc('\n');

	bout.puts("# interfaces: " + string class.interfaces_count + "\n");
	for(i = 0; i < class.interfaces_count; i++) {
		bout.puts("#\t" + CLASSNAME(class.interfaces[i]) + "\n");
	}

	bout.puts("# fields: " + string class.fields_count + "\n");
	for(i = 0; i < class.fields_count; i++) {
		fp = class.fields[i];
		bout.puts("#\t" + STRING(fp.name_index)
			+ ": " + STRING(fp.sig_index));
		accessflags(fp.access_flags, 0);
		bout.putc('\n');
		n = CVattrindex(fp);
		if(n == 0)
			continue;
		bout.puts("#\t\tConstantValue: ");
		pick cp := class.cps[n] {
		Ptdouble =>
			if(int class.cts[n] == CON_Float)
				bout.puts("Float " + string cp.tdouble + "\n");
			else			# CON_Double
				bout.puts("Double " + string cp.tdouble + "\n");
		Ptvlong =>
			bout.puts("Long " + string cp.tvlong + "\n");
		Ptint =>
			bout.puts("Int " + string cp.tint + "\n");
		Pstring_index =>
			bout.puts("String \"" + STRING(cp.string_index) + "\"\n");
		}
	}

	bout.puts("# methods: " + string class.methods_count + "\n");
	for(i = 0; i < class.methods_count; i++) {
		mp = class.methods[i];
		bout.puts("# " + string i + " Method " + string mp.name_index
			+ " sig " + string mp.sig_index);
		bout.puts("\t" + STRING(mp.name_index) + STRING(mp.sig_index));
		accessflags(mp.access_flags, 0);
		bout.putc('\n');
	}

	bout.puts("# class attribute ignored\n");
	bout.puts("# -- Constant Pool End --\n");
}

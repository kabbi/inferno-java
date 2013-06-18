# Java constant pool tags

CON_Utf8:		con 1;
# CON_Unicode:		con 2;		# obsolete
CON_Integer:		con 3;
CON_Float:		con 4;
CON_Long:		con 5;
CON_Double:		con 6;
CON_Class:		con 7;
CON_String:		con 8;
CON_Fieldref:		con 9;
CON_Methodref:		con 10;
CON_InterfaceMref:	con 11;
CON_NameAndType:	con 12;
# since 49.0
CON_MethodHandle:	con 15;
CON_MethodType:		con 16;
CON_InvokeDynamic:	con 18;

# Java access flags

ACC_PUBLIC:		con 16r0001;
ACC_PRIVATE:		con 16r0002;
ACC_PROTECTED:		con 16r0004;
ACC_STATIC:		con 16r0008;
ACC_FINAL:		con 16r0010;
ACC_SUPER:		con 16r0020;
ACC_SYNCHRONIZED:	con 16r0020;	# sic
ACC_VOLATILE:		con 16r0040;
ACC_TRANSIENT:		con 16r0080;
ACC_NATIVE:		con 16r0100;
ACC_INTERFACE:		con 16r0200;
ACC_ABSTRACT:		con 16r0400;

_MUSTCOMPILE:		con MUSTCOMPILE<<16;
_DONTCOMPILE:		con DONTCOMPILE<<16;

# basic block flags

BB_LDR,						# set for all leaders
BB_ENTRY,					# method entry point
BB_FINALLY,					# finally block entry point
BB_HANDLER,					# EH entry point
BB_REACHABLE:		con byte(1 << iota);	# reachable basic block */

# basic block states

BB_PRESIM,					# not simulated yet
BB_ACTIVE,					# simulating or being unified
BB_POSTSIM,					# simulated
BB_POSTUNIFY:		con byte(1 << iota);	# unified

# Dis operand classification

Anone,
Aimm,
Amp,
Ampind,
Afp,
Afpind,
Aend:			con byte iota;

# Dis n(fp) types

DIS_X,					# not yet typed
DIS_W,					# 'B', 'Z', 'C', 'S', 'I'
DIS_L,					# 'F', 'J', 'D'
DIS_P:			con byte iota;	# 'L', '['

# inferno/vm/Array

ARY_DATA:		con IBY2WD;	# Array data (Dis array)
ARY_NDIM:		con 2*IBY2WD;	# number of dimensions
ARY_ADT:		con 3*IBY2WD;	# 'ref Class' of element type
ARY_ETYPE:		con 4*IBY2WD;	# primitive element type code

# java/lang/String

STR_DISSTR:		con IBY2WD;	# offset to Dis string in a String

# miscellaneous

#REFSYSEX:		con 24;		# 24(fp) is a 'ref Sys->Exception'
EXOBJ:			con 28;		# 28(fp) is exception object
THISOFF:		con 32;		# 32(fp) is "this" pointer
REGSIZE:		con 32;		# 32(fp) is first usable frame cell
Hashsize:		con 31;
ALLOCINCR:		con 16;

Const_ci: adt {
	name_index:	int;
};

Const_fmiref: adt {
	class_index:		int;
	name_type_index:	int;
};

Const_nat: adt {
	name_index:	int;
	sig_index:	int;
};

Const_utf8: adt {
	ln:	int;
	utf8:	string;
};

# since 49.0

Const_methodhandle: adt {
	ref_kind:	int;
	ref_index:	int;
};

Const_methodtype: adt {
	descriptor_index:	int;
};

Const_invokedyn: adt {
	bs_method_attr_index:	int;
	name_type_index:	int;
};

Const: adt {
	pick {
		# CONSTANT_[Float|Double]_info
		Ptdouble =>
			tdouble:	real;
		# CONSTANT_Long_info
		Ptvlong =>
			tvlong:		big;
		# CONSTANT_Integer_info
		Ptint =>
			tint:		int;
		# CONSTANT_String_info
		Pstring_index =>
			string_index:	int;
		# CONSTANT_Class_info
		Pci =>
			ci:		ref Const_ci;
		# CONSTANT_[Fieldref|Methodref|InterfaceMethodref]_info
		Pfmiref =>
			fmiref:		ref Const_fmiref;
		# CONSTANT_NameAndType
		Pnat =>
			nat:		ref Const_nat;
		# CONSTANT_Utf8_info
		Putf8 =>
			utf8:		ref Const_utf8;

		# since 49.0

		# CONSTANT_MethodHandle_info
		Pmethodhandle =>
			mh:		ref Const_methodhandle;
		# CONSTANT_MethodType_info
		Pmethodtype =>
			mt:		ref Const_methodtype;
		# CONSTANT_InvokeDynamic_info
		Pinvokedyn =>
			invokedyn:	ref Const_invokedyn;
	}
};

Attr: adt {					# attribute_info
	name:	int;
	ln:	int;
	info:	array of byte;
};

Field: adt {					# field_info
	access_flags:	int;
	name_index:	int;
	sig_index:	int;
	attr_count:	int;
	attr_info:	array of ref Attr;	# ConstantValue attributes
};

Method: adt {					# method_info
	access_flags:	int;
	name_index:	int;
	sig_index:	int;
	attr_count:	int;
	attr_info:	array of ref Attr;	# Code, Exceptions attributes
};

Class: adt {				# ClassFile
#	magic			int;	# 0xcafebabe
	min:			int;
	maj:			int;
	cp_count:		int;
	cps:			array of ref Const;
	cts:			array of byte;
	access_flags:		int;
	this_class:		int;
	super_class:		int;
	interfaces_count:	int;
	interfaces:		array of int;
	fields_count:		int;
	fields:			array of ref Field;
	methods_count:		int;
	methods:		array of ref Method;
	source_file:		int;
};

Addr: adt {			# Dis operand
	mode:	byte;		# Anone, Aimm, Amp, etc.
	ival:	int;		# immediate, $ival
	offset:	int;		# single indirect, offset(fp)
				# double indirect, offset(ival(fp))
};

Jinst_x1c: adt {		# iinc
	ix:	int;
	icon:	int;
};

Jinst_x2c0: adt {		# invokeinterface
	ix:	int;
	narg:	int;
	zero:	int;
};

Jinst_x2d: adt {		# multianewarray
	ix:	int;
	dim:	int;
};

Jinst_t1: adt {			# tableswitch
	dflt:	int;
	lb:	int;
	hb:	int;
	tbl:	array of int;
};

Jinst_t2: adt {			# lookupswitch
	dflt:	int;
	np:	int;
	tbl:	array of int;
};

Jinst_w: adt {			# wide
	op:	byte;
	ix:	int;
	icon:	int;
};

Jinst: adt {				# Java instruction
	op:	byte;			# op code
	jtype:	byte;			# Java type of dst ('I', '[', etc.)
	pc:	int;			# pc offset
	pcdis:	int;			# pc offset counted in dis instructions
	line:	int;			# source line number
	size:	int;			# size of this instruction
	dis:	cyclic ref Inst;	# Dis code for this instruction
	bb:	cyclic ref BB;		# the instruction's basic block
	nsrc:	int;			# 0 or more source operands
	src:	array of int;		# the source operands
	dst:	ref Addr;		# usual destination operand
	movsrc:	ref Addr;		# source operand if mov generated for load
	pick {
		Pz =>
			dummy:	int;		# Z
		Pi =>
			i:	int;		# AT, X1, X2, B2, B4, V1, V2
		Px1c =>
			x1c:	ref Jinst_x1c;	# iinc
		Px2c0 =>
			x2c0:	ref Jinst_x2c0;	# invokeinterface
		Px2d =>
			x2d:	ref Jinst_x2d;	# multianewarray
		Pt1 =>
			t1:	ref Jinst_t1;	# tableswitch
		Pt2 =>
			t2:	ref Jinst_t2;	# lookupswitch
		Pw =>
			w:	ref Jinst_w;	# wide
	}
};

Handler: adt {			# exception_table entry
	start_pc:	int;
	end_pc:		int;
	handler_pc:	int;
	catch_type:	int;
};

Code: adt {			# one Java method
	max_stack:	int;
	max_locals:	int;
	code_length:	int;
	j:		array of ref Jinst;
	nex:		int;
	ex:		array of ref Handler;
};

PCode: adt {
	code:	ref Code;
	name:	string;
	sig:	string;
};

StkSnap: adt {		# snapshot of simulated Java VM stack
	jtype:	byte;
	npc:	int;
	pc:	array of int;
};

BB: adt {				# basic block
	js:		ref Jinst;	# first instruction in basic block
	je:		cyclic ref Jinst;	# last instruction in basic block
	nsucc:		int;		# number of successors
	succ:		cyclic array of ref BB;	# successors
	flags:		byte;		# basic block leader flags
	state:		byte;		# BB_PRESIM, etc.
	entrysz:	int;		# size of saved entry stack
	entrystk:	array of ref StkSnap;	# snapshot of entry stack
	exitsz:		int;		# size of saved exit stack
	exitstk:	array of ref StkSnap;	# snapshot of exit stack
};

Inst: adt {				# Dis instruction
	op:	byte;			# op code
	s:	ref Addr;		# source
	m:	ref Addr;		# middle
	d:	ref Addr;		# destination
	pc:	int;			# 0-based instruction offset
	j:	ref Jinst;
	next:	cyclic ref Inst;
};

# Bytecode Behaviors for Method Handles (see section 5.4.3.5 of jvm 1.7 specs)
REF_getfield:		con 1;
REF_getstatic:		con 2;
REF_putfield:		con 3;
REF_putstatic:		con 4;
REF_invokevirtual:	con 5;
REF_invokestatic:	con 6;
REF_invokespecial:	con 7;
REF_newinvokespecial:	con 8;
REF_invokeinterface:	con 9;


include "draw.m";
#
#	Java Class Loader.
#

JavaClassLoader: module
{
	PATH:			con "/dis/java/classloader.dis";
	ROOT:			con "/dis/java/java/";
	PROG:			con "#p";
	LOADER:			con "@Loader";
	CLASS:			con "@Class";
	MP:			con "@mp";
	ADT:			con "@adt";
	NP:			con "@np";
	OBJ:			con "@obj";
	JEX:			con "@jex";
	SYS:			con "@sys";
	EXIST:			con "does not exist";
	MAINFIELD:		con "main";
	MAINSIGNATURE:		con "([Ljava/lang/String;)V";
	VOIDSIGNATURE:		con "()V";
	ARRAYCLASS:		con "inferno/vm/Array";
	STRINGCLASS:		con "java/lang/String";
	EXCEPTIONPATH:		con "java/lang/";
	JAVAEXCEPTION:		con "java ex";
	SPECIALINIT:		con "<init>";
	SPECIALCLINIT:		con "<clinit>";
	SPECIALCLONE:		con "<clone>";
	SUXV:			con '4';
	JAVA:			con ('J'<<24)|('a'<<16)|('v'<<8)|'a';
	SUX:			con ('S'<<24)|('u'<<16)|('x'<<8)|SUXV;
	NEW, HIER, RESOLVE, LOADED, INITED:
				con iota;
	MAGIC, VERSION, NAME, SUPER, INTERFACES, RELOC, DSIZE, DRELOC, CLASSREF:
				con (iota * 4);
	CMP, CADT, CNP, COBJ, CJEX, CSYS:
				con iota;
	VVAL, VMP, VNP, VOBJ:	con iota;
	PVALUE, PEXTRA, PMETHOD, PSTATIC:
				con iota;
	WORDZ:			con 4;
	BIGZ:			con 8;
	MAPZ:			con WORDZ * 8;
	STACKSIZE:		con 1024;
	METHODOFFSET:		con 2;
	RTCLASSOFFSET:		con 1 * WORDZ;
	RTRELOCOFFSET:		con 2 * WORDZ;
	RTTHISOFFSET:		con 3 * WORDZ;
	RTFIRSTRELOC:		con 4 * WORDZ;
	CLASSADTOFFSET:		con 1 * WORDZ;
	MAXUNENCODED:		con Sys->NAMEMAX - 7;
	ENCODEDLEN:		con 21;
	RDELTA:			con 16r80;

	T_BOOLEAN:		con 4;
	T_CHAR:			con 5;
	T_FLOAT:		con 6;
	T_DOUBLE:		con 7;
	T_BYTE:			con 8;
	T_SHORT:		con 9;
	T_INT:			con 10;
	T_LONG:			con 11;
	T_OBJECT:		con 12;
	T_ARRAY:		con 13;

	ACC_PUBLIC:		con 16r0001;
	ACC_PRIVATE:		con 16r0002;
	ACC_PROTECTED:		con 16r0004;
	ACC_STATIC:		con 16r0008;
	ACC_FINAL:		con 16r0010;
	ACC_SUPER:		con 16r0020;
	ACC_SYNCHRONIZED:	con 16r0020;
 	ACC_VOLATILE:		con 16r0040;
	ACC_TRANSIENT:		con 16r0080;
	ACC_NATIVE:		con 16r0100;
	ACC_INTERFACE:		con 16r0200;
 	ACC_ABSTRACT:		con 16r0400;

	JCL_INTEREXT:		con 16r4000;
	JCL_INTERWORK:		con 16r8000;

	MUSTCOMPILE:		con 16r10000;
	DONTCOMPILE:		con 16r20000;

	Rgetputfield:		con 16r1 << 16;
	Rgetputstatic:		con 16r2 << 16;
	Rinvokeinterface:	con 16r3 << 16;
	Rinvokespecial:		con 16r4 << 16;
	Rinvokestatic:		con 16r5 << 16;
	Rinvokevirtual:		con 16r6 << 16;
	Rmask:			con 16r7 << 16;

	Rstaticmp:		con 16r08 << 16;
	Rspecialmp:		con 16r10 << 16;

	POP:			con 16r3 << 2;		# operand
	PSRC:			con 16r1 << 2;		# patch source operand
	PDST:			con 16r2 << 2;		# destination
	PMID:			con 16r3 << 2;		# middle

	PTYPE:			con 16r3;		# Operand type
	PIMM:			con 16r0;		# patch immediate operand
	PSIND:			con 16r1;		# single indirect offset
	PDIND1:			con 16r2;		# first offset of double indirect
	PDIND2:			con 16r3;		# second offset of double indirect

	ISHIFT:			con 4;			# instr index shift

	jninil:			Nilmod;
	jnisig:			int;

	Extra: adt
	{
		what:		int;
		class:		cyclic ref Class;
	};

	Field: adt
	{
		field:		string;
		signature:	string;
		flags:		int;
		value:		int;
	};

	Method: adt
	{
		field:		ref Field;
		class:		cyclic ref Class;
	};

	Patch: adt
	{
		what:		int;
		value:		int;
	};

	Reloc: adt
	{
		field:		string;
		signature:	string;
		flags:		int;
		patch:		array of byte;
	};

	RTReloc: adt
	{
		field:		string;
		signature:	string;
		flags:		int;
	};

	Interface: adt
	{
		class:		cyclic ref Class;
		methods:	array of int;
	};

	Ldinfo: adt
	{
		links:		array of Loader->Link;
		nlinks:         array of Loader->Link;
		types:		array of Loader->Typedesc;
		extraoffset:	int;
		extrabase:	int;
		extras:		cyclic array of Extra;
		reloc:		array of Patch;
	};

	ClassObject: adt
	{
		mod:		ref Loader->Niladt;
		class:		cyclic ref Class;
		aryname:	string;
	};

	Object: adt
	{
		mod:		ref Loader->Niladt;

		class:		fn(o: self ref Object): ref Class;
	};

	Array: adt
	{
		mod:		ref Loader->Niladt;
		holder:		array of ref JavaString;
		dims:		int;
		class:		ref Class;
		primitive:	int;
	};

	JavaString: adt
	{
		mod:		ref Loader->Niladt;
		str:		string;
	};

	JavaThrowable: adt
	{
		mod:		ref Loader->Niladt;
		trace:		array of byte;
		msg:		ref JavaString;
	};

	ThreadData: adt
	{
		BLOCKED, SUSPENDED, ACKSUSP, WAITSUSP, WAITSTOP, INTERRUPTED, EXITED, DAEMON:
				con (1 << iota);
		SHUTDOWN, BLOCK, UNBLOCK, SUSPEND, RESUME, STOP:
				con iota;

		pid:		int;
		wchan:		chan of int;
		flags:		int;
		ctlfile:	string;
		control:	ref Sys->FD;
		culprit:	ref Object;
		this:		ref Object;
	};

	Class: adt
	{
		state:		int;
		name:		string;
		encoding:	string;
		ownname:	string;
		file:		string;
		version:	int;
		flags:		int;
		mod:		Nilmod;
		native:		Nilmod;
		super:		cyclic ref Class;
		this:		cyclic ref ClassObject;
		info:		cyclic ref Ldinfo;
		refs:		cyclic array of ref Class;
		staticdata:	array of ref Field;
		objectdata:	list of ref Field;
		privatemethods:	array of ref Field;
		staticmethods:	array of ref Field;
		virtualmethods:	cyclic array of Method;
		initmethods:	array of ref Field;
		classinit:	ref Field;
		cloneindex:	int;
		interfaces:	cyclic array of Interface;
		interindex:	int;
		intercache:	cyclic list of (ref Class, array of int);
		interextends:	cyclic list of ref Class;
		interdirect:	cyclic list of ref Class;
		objectsize:	int;
		staticoffset:	int;
		staticsize:	int;
		nextra:		int;
		dataoffset:	int;
		datasize:	int;
		datareloc:	int;
		moddata:	ref Loader->Niladt;
		modsize:	int;
		modmap:		array of byte;
		objmap:		array of byte;
		objtype:	int;
		mlinks:		int;

		loadclass:	fn(c: self ref Class);
		resolve:	fn(c: self ref Class);
		loadinterfaces:	fn(c: self ref Class);
		extinterfaces:	fn(c: self ref Class);
		linkinterfaces:	fn(c: self ref Class);
		makeobjtype:	fn(c: self ref Class);
		makevmtable:	fn(c: self ref Class, m: list of ref Field, z: int): array of Method;
		relocate:	fn(c: self ref Class);
		instrpatch:	fn(c: self ref Class, i: array of Loader->Inst);
		modpatch:	fn(c: self ref Class);
		getmethod:	fn(c: self ref Class, f, s: string, flag: int): int;
		override:	fn(c: self ref Class, f, s: string): int;
		findimethod:	fn(c: self ref Class, s: string): ref Field;
		findpmethod:	fn(c: self ref Class, f, s: string): ref Field;
		findsfield:	fn(c: self ref Class, f: string): ref Field;
		findsmethod:	fn(c: self ref Class, f, s: string): ref Field;
		findofield:	fn(c: self ref Class, f: string): ref Field;
		findvmethod:	fn(c: self ref Class, f, s: string): int;
		extra:		fn(c: self ref Class, w, n: int, r: ref Class);
		extras:		fn(c: self ref Class, a: array of Reloc, n: int, r: ref Class): int;
		special:	fn(c: self ref Class, f, s: string, flags: int, r: ref Class): (int, ref Class, int);
		copymap:	fn(c: self ref Class, m: array of byte, dr: int);
		copymd:		fn(c: self ref Class, md: ref Loader->Niladt, dr: int, om: Nilmod);
		relocref:	fn(c: self ref Class, t: ref Class, i: array of Loader->Inst, a: array of Reloc, x: int): int;
		resolvereloc:	fn(c: self ref Class, r, s: string, flags: int): (int, int);
		addinterface:	fn(c: self ref Class);
		getinterface:	fn(c: self ref Class, k: ref Class): array of int;
		interlook:	fn(c: self ref Class, a: array of Interface): array of int;
		initjni:	fn(c: self ref Class);
		loadnative:	fn(c: self ref Class);

		# runtime entry points
		run:		fn(c: self ref Class, args: list of string);
		new:		fn(c: self ref Class): ref Object;
		call:		fn(c: self ref Class, x: int, a: ref Object): ref Object;
		clone:		fn(c: self ref Class, o: ref Object): ref Object;
	};

	init:		fn(j: JavaClassLoader, ctxt: ref Draw->Context);
	shutdown:	fn();
	info:		fn(name: string);
	loader:		fn(name: string): ref Class;
	encodename:	fn(name: string): string;
	getclass:	fn(name: string): ref Class;
	getmodclass:	fn(mod: Nilmod): ref Class;
	runmain:        fn( j: JavaClassLoader, classname : string, argv : list of string );
	sysexception:   fn( ex : string ) : ref Object;
	setflags:       fn( flags : list of (string,int) );

	# runtime entry points
	compatclass:	fn(who, what: ref Class): int;
	checkcast:	fn(who: ref Object, what: ref Class);
	instanceof:	fn(who: ref Object, what: ref Class): int;
	acheckcast:	fn(who: ref Array, what: ref Class, dims: int);
	ainstanceof:	fn(who: ref Array, what: ref Class, dims: int): int;
	pcheckcast:	fn(who: ref Array, what, dims: int);
	pinstanceof:	fn(who: ref Array, what, dims: int): int;
	aastorecheck:	fn(who: ref Object, what: ref Array);
	arraycopy:	fn(src: ref Array, sx: int, dst: ref Array, dx: int, n: int);
	multianewarray:	fn(ndim: int, c: ref Class, etype: int, bounds: array of int): ref Array;
	error:		fn(s: string);
	delthreaddata:	fn();
	getthreaddata:	fn(): ref ThreadData;
	getcontext:	fn(): ref Draw->Context;
	daemonize:	fn();
	culprit:	fn(e: string): ref Object;
	throw:		fn(c: ref Object);
	rtload:		fn(addr: int);
	getinterface:	fn(c: ref Class, cookie: int): int;
	monitorenter:	fn(o: ref Object);
	monitorexit:	fn(o: ref Object);
	monitorwait:	fn(o: ref Object, l: int);
	monitornotify:	fn(o: ref Object, f: int);
	sleep:		fn(l: int);
	interrupt:	fn(t: ref ThreadData);
	suspend:	fn(t: ref ThreadData);
	resume:		fn(t: ref ThreadData);
	stop:		fn(t: ref ThreadData, o: ref Object);
	getclassclass:	fn(caller: string, class: string): ref Object;

	# math
	lcmp:		fn(x: big, y: big): int;

	d2i:		fn(x: real): int;
	d2l:		fn(x: real): big;
	dcmpg:		fn(x, y: real): int;
	dcmpl:		fn(x, y: real): int;
	drem:		fn(x, y: real): real;
};

JavaNative: module
{
	PATH:		con "/dis/java/javanative.dis";

	init:		fn(sys: Sys, ld: Loader, jldr: JavaClassLoader, jass: JavaAssist): string;
};

JavaAssist: module
{
	PATH:		con "/dis/java/javaassist.dis";

	getint:		fn(mod: Nilmod, index: int): int;
	getbytearray:	fn(mod: Nilmod, index: int): array of byte;
	getintarray:	fn(mod: Nilmod, index: int): array of int;
	getstrarray:	fn(mod: Nilmod, index: int): array of string;
	getptr:		fn(mod: Nilmod, index: int): ref Loader->Niladt;
	getreloc:	fn(mod: Nilmod, index: int): array of JavaClassLoader->Reloc;
	getrtreloc:	fn(data: ref Loader->Niladt, index: int): array of JavaClassLoader->RTReloc;
	getclassadt:	fn(data: ref Loader->Niladt, index: int): ref JavaClassLoader->Class;
	getabsint:	fn(addr: int): int;
	getadtstring:	fn(data: ref Loader->Niladt, index: int): string;
	getstring:	fn(mod: Nilmod, index: int): string;
	putclass:	fn(data: ref Loader->Niladt, index: int, value: ref JavaClassLoader->Class);
	putint:		fn(data: ref Loader->Niladt, index: int, value: int);
	putmod:		fn(data: ref Loader->Niladt, index: int, value: Nilmod);
	putobj:		fn(data: ref Loader->Niladt, index: int, value: ref JavaClassLoader->ClassObject);
	putptr:		fn(data: ref Loader->Niladt, index: int, value: ref Loader->Niladt);
	putstring:	fn(data: ref Loader->Niladt, index: int, value: string);
	little_endian:	fn(): int;
	jclnilmod:	fn(j: JavaClassLoader): Nilmod;
	sysnilmod:	fn(s: Sys): Nilmod;
	new:		fn(mod: Nilmod, index: int): ref JavaClassLoader->Object;
	getobjclass:	fn(j: ref JavaClassLoader->Object): ref JavaClassLoader->Class;
	modhash:	fn(mod: Nilmod): int;
	objhash:	fn(j: ref JavaClassLoader->Object): int;
	mcall0:		fn(mod: Nilmod, index: int): int;
	mcall1:		fn(mod: Nilmod, index: int, arg: ref JavaClassLoader->Object): ref JavaClassLoader->Object;
	mcalla:		fn(mod: Nilmod, index: int, arg: ref JavaClassLoader->Array): int;
	mcallm:		fn(mod: Nilmod, index: int, arg: Nilmod): int;
	getmd:		fn(mod: Nilmod): ref Loader->Niladt;
	arrayof:	fn(o: ref JavaClassLoader->Object): ref JavaClassLoader->Array;
	bytearraytoJS:	fn(a: array of byte): array of ref JavaClassLoader->JavaString;
	intarraytoJS:	fn(a: array of int): array of ref JavaClassLoader->JavaString;
	bigarraytoJS:	fn(a: array of big): array of ref JavaClassLoader->JavaString;
	realarraytoJS:	fn(a: array of real): array of ref JavaClassLoader->JavaString;
	ArraytoJS:	fn(a: ref JavaClassLoader->Array): ref JavaClassLoader->JavaString;
	JStoObject:	fn(j: ref JavaClassLoader->JavaString): ref JavaClassLoader->Object;
	ObjecttoJT: fn(o: ref JavaClassLoader->Object): ref JavaClassLoader->JavaThrowable;
	makeadt:	fn(addr: int): ref Loader->Niladt;
};

JavaTrace: module
{
	PATH:		con "/dis/java/javatrace.dis";

	JVERBOSE,
	JDEBUG:		con iota;

	init:		fn(a: JavaAssist);
	info:		fn(c: ref JavaClassLoader->Class);
	pr_reloc:	fn(r: JavaClassLoader->Reloc);
	pr_relocs:	fn(r: array of JavaClassLoader->Reloc);
	trace:		fn(c: int, s: string);

	level:		int;
	outfd:		ref Sys->FD;
};

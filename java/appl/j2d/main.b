bufio:	Bufio;
math:	Math;
sys:	Sys;
str:	String;

Iobuf: import bufio;
fprint, print, sprint: import sys;

gendis:		int = 1;	# generate .dis rather than .s (default)
fabort:		int;		# -f: cause broken thread on fatal error
emitcpool:	int;		# -p: emit constant pool (with -S only)
gensbl:		int;		# -g: generate .sbl file
compileflag:	int;		# -c (MUSTCOMPILE) & -C (DONTCOMPILE)
verbose:	int;		# -v: emit Java instructions (with -S only)
bout:		ref Bufio->Iobuf;
ofile:		string;

usage()
{
	print("usage: j2d [-cgpvCS] [-o outfile] file.class\n");
	exit;
}

#
# Translate .class file (in) into .s or .dis (out).
#

translate(in: string, out: string)
{
	ClassLoader(in);

	bout = bufio->create(out, Bufio->OWRITE, 8r644);
	if(bout == nil)
		fatal("can't open " + out + ": " + sprint("%r"));

	if(emitcpool != 0)
		dumpcpool();

	thisCreloc();
	xlate();
	mpdesc();
	# Patch frame/call for invokespecial/invokestatic.
	dofcpatch();
	# Patch instructions for run-time resolution.
	doRTpatch();

	if(gendis == 0) {	# generate .s file
		asminst();
		asmentry();
		asmdesc();
		asmvar();
		asmmod();
		asmlinks();
	} else
		disout();	# generate .dis file

	if(gensbl)		#  generate .sbl file
		sblout(out);

	bout.close();
}

MAXUNENCODED:	con Sys->NAMEMAX - 7;
ENCODEDLEN:	con 21;

encoding :=	array [] of {
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
	'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
	'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
	'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
	'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
	'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
	'w', 'x', 'y', 'z', '0', '1', '2', '3',
	'4', '5', '6', '7', '8', '9', '+', '-',
};

encodename(name: string): string
{
	d := array [Keyring->MD5dlen] of byte;
	kr := load Keyring Keyring->PATH;
	kr->md5(array of byte name, len name, d, nil);
	e := array[ENCODEDLEN] of byte;
	v := 0;
	n := 0;
	r := 0;
	for(i := 0; i < ENCODEDLEN; i++) {
		if(r < 6) {
			v |=  int d[n++] << r;
			r += 8;
		}
		e[i] = byte encoding[v & 16r3F];
		v >>= 6;
		r -= 6;
	}
	return string e;
}

#
# Construct output filename.
#

mkfileext(file: string, ext: string): string
{
	n := len file;
	if(n <= 6 || file[n-6:] != ".class")
		usage();
	else
		n -= 6;
	if(n > MAXUNENCODED) {
		file = encodename(file);
		n = ENCODEDLEN;
	}
	return file[:n] + ext;
}

init(nil: ref Draw->Context, argv: list of string)
{
	ext, s: string;

	sys = load Sys Sys->PATH;
	math = load Math Math->PATH;
	bufio = load Bufio Bufio->PATH;
	if(bufio == nil)
		fatal("can't load " + Bufio->PATH + ": " + sprint("%r"));
	str = load String String->PATH;
	if(str == nil)
		fatal("can't load " + String->PATH + ": " + sprint("%r"));

	arg := Arg.init(argv);
	while(c := arg.opt()) {
		case c {
		'C' =>
			compileflag |= _DONTCOMPILE;
		'S' =>
			gendis = 0;
		'c' =>
			compileflag |= _MUSTCOMPILE;
		'g' =>
			gensbl = 1;
		'f' =>
			fabort = 1;
		'p' =>
			emitcpool = 1;
		'o' =>
			ofile = arg.arg();
		'v' =>
			verbose = 1;
		* =>
			usage();
		}
	}
	argv = arg.argv;
	arg = nil;

	if(len argv != 1)
		usage();
	ifile := hd argv;
	if(compileflag == (_MUSTCOMPILE|_DONTCOMPILE)) {
		print("j2d: warning: -c and -C are mutually exclusive, ignoring\n");
		compileflag = 0;
	}
	if((verbose != 0 || emitcpool != 0) && gendis != 0) {
		print("j2d: warning: -p/-v only allowed with -S, ignoring\n");
		emitcpool = 0;
		verbose = 0;
	}
	if(ofile != nil)
		translate(ifile, ofile);
	else {
		if(gendis == 0)
			ext = ".s";
		else
			ext = ".dis";
		(nil, s) = str->splitr(ifile, "/");
		ofile = mkfileext(s, ext);
		translate(ifile, ofile);
	}
	reset();
}

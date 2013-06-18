#include "java.h"
//#include "libcrypt.h"
#include "reloc.h"

static	int	gendis;		/* generate .dis rather than .s (default) */
static	int	emitcpool;	/* -p: emit constant pool (with -S only) */
	int	gensbl;		/* -g: generate .sbl file */
	int	compileflag;	/* -c (MUSTCOMPILE) & -C (DONTCOMPILE) */
	int	verbose;	/* -v: emit Java instructions (with -S only) */
	Biobuf	*bout;
	char	*ofile;

static void
usage(void)
{
	print("usage: j2d [-cgpvCS] [-o outfile] file.class\n");
	exits("usage");
}

/*
 * Translate .class file (in) into .s or .dis (out).
 */

static void
translate(char *in, char *out)
{
	ClassLoader(in);

	bout = Bopen(out, OWRITE);
	if(bout == nil)
		fatal("can't open %s: %r\n", out);

	if(emitcpool != 0)
		dumpcpool();

	thisCreloc();
	crefseed();
	xlate();
	mpdesc();
	/* Patch frame/call for invokespecial/invokestatic. */
	dofcpatch();
	/* Patch instructions for run-time resolution. */
	doRTpatch();

	if(gendis == 0) {	/* generate .s file */
		asminst();
		asmentry();
		asmdesc();
		asmvar();
		asmmod();
		asmlinks();
	} else
		disout();	/* generate .dis file */

	if(gensbl)		/* generate .sbl file */
		sblout(out);

	Bterm(bout);
}

enum {
	MAXUNENCODED	= NAMELEN - 7,
	ENCODEDLEN	= 21
};

static char encoding[] = {
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
	'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
	'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
	'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
	'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
	'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
	'w', 'x', 'y', 'z', '0', '1', '2', '3',
	'4', '5', '6', '7', '8', '9', '+', '-',
};

static char*
encodename(char *name, int ln)
{
	char *e;
	int i, n, r, v;
	uchar d[MD5dlen];

	md5((uchar*)name, ln, d, nil);
	e = Malloc(ENCODEDLEN+1);
	n = 0;
	r = 0;
	v = 0;
	for(i = 0; i < ENCODEDLEN; i++) {
		if(r < 6) {
			v |= d[n++] << r;
			r += 8;
		}
		e[i] = encoding[v & 0x3F];
		v >>= 6;
		r -= 6;
	}
	e[ENCODEDLEN] = '\0';
	return e;
}

/*
 * Construct output filename.
 */

static char*
mkfileext(char *file, char *ext)
{
	char *s;
	int n;

	n = strlen(file);
	if(n <= 6 || strcmp(&file[n-6], ".class") != 0)
		usage();
	else
		n -= 6;
	if(n > MAXUNENCODED) {
		file = encodename(file, n);
		n = ENCODEDLEN;
	}
	s = Malloc(n + strlen(ext) + 1);
	memmove(s, file, n);
	strcpy(s+n, ext);
	print("%s\n", s);	/* print filename for [mk|make]file's */
	return s;
}

extern	int	gfltconv(va_list*, Fconv*);

void
main(int argc, char *argv[])
{
	char *ext, *s;

	fmtinstall('A', Aconv);
	fmtinstall('I', Iconv);
	fmtinstall('J', Jconv);
	fmtinstall('g', gfltconv);

	gendis = 1;

	ARGBEGIN{
	case 'C':
		compileflag |= _DONTCOMPILE;
		break;
	case 'S':
		gendis = 0;
		break;
	case 'c':
		compileflag |= _MUSTCOMPILE;
		break;
	case 'g':
		gensbl = 1;
		break;
	case 'p':
		emitcpool = 1;
		break;
	case 'o':
		ofile = ARGF();
		break;
	case 'v':
		verbose = 1;
		break;
	default:
		usage();
		break;
	}ARGEND

	if(argc != 1)
		usage();
	if(compileflag == (_MUSTCOMPILE|_DONTCOMPILE)) {
		print("j2d: warning: -c and -C are mutually exclusive, ignoring\n");
		compileflag = 0;
	}
	if((verbose != 0 || emitcpool != 0) && gendis != 0) {
		print("j2d: warning: -p/-v only allowed with -S, ignoring\n");
		emitcpool = 0;
		verbose = 0;
	}
	if(ofile)
		translate(argv[0], ofile);
	else {
		if(gendis == 0)
			ext = ".s";
		else
			ext = ".dis";
		s = strrchr(argv[0], '/');
		if(s == nil)
			s = argv[0];
		else
			s++;
		ofile = mkfileext(s, ext);
		translate(argv[0], ofile);
	}
	exits(nil);
}

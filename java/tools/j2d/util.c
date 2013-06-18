#include "java.h"

/*
 * Utility functions.
 */

static uchar *codeix;

void
uSet(uchar *x)
{
	codeix = x;
}

char*
uPtr(void)
{
	return (char*)codeix;
}

void
uN(int i)
{
	codeix += i;
}

uchar
u1(void)
{
	return *codeix++;
}

ushort
u2(void)
{
	ushort l;

	l = (codeix[0]<<8) | codeix[1];
	codeix += 2;
	return l;
}

uint
u4(void)
{
	uint l;

	l = (codeix[0]<<24) | (codeix[1]<<16) | (codeix[2]<<8) | codeix[3];
	codeix += 4;
	return l;
}

void
getattr(Attr *a)
{
	a->name = u2();
	verifycpindex(nil, a->name, 1 << CON_Utf8);
	a->ln = u4();
	a->info = Malloc(a->ln);
	memmove(a->info, codeix, a->ln);
	codeix += a->ln;
}

/*
 * Get the constantvalue_index of a ConstantValue attribute.
 */

int
CVattrindex(Field *fp)
{
	int i;
	Attr *a;

	for(i = 0, a = fp->attr_info; i < fp->attr_count; i++, a++) {
		if(strcmp(STRING(a->name), "ConstantValue") != 0)
			continue;
		if(a->ln != 2)
			verifyerrormess("ConstantValue attribute");
		return (a->info[0]<<8) | a->info[1];
	}
	return 0;
}

/*
 * Align 'off' on an 'align'-byte boundary ('align' is a power of 2).
 */

int
align(int off, int align)
{
	align--;
	return (off + align) & ~align;
}

/*
 * Set 'offset' bit in type descriptor 'map'.
 */

void
setbit(uchar *map, int offset)
{
	uchar *m;

	m = &map[offset / (8*IBY2WD)];
	*m |= 1 << (7 - (offset / IBY2WD % 8));
}

/*
 * Trivial hash function from asm.
 */

int
hashval(char *s)
{
	int h;

	h = 0;
	while(*s)
		h = h*3 + *s++;
	if(h < 0)
		h = -h;
	return h % Hashsize;
}

/*
 * Advance to the next Java type in a method descriptor.
 */

char*
nextjavatype(char *s)
{
	int nlb;

	nlb = 0;
	for(;;) {
		switch(s[0]) {
		case 'L':
			s = strchr(s, ';');
		case 'V':
		case 'Z':
		case 'B':
		case 'C':
		case 'S':
		case 'I':
		case 'J':
		case 'F':
		case 'D':
			return s+1;
		case '[':
			if(++nlb < 256) {
				s++;
				break;
			}
		default:
			verifyerrormess("field/method descriptor");
		}
	}
	return nil;	/* for compiler */
}

uchar
j2dtype(uchar jtype)
{
	uchar dtype;

	switch(jtype) {
	case 'Z':
	case 'B':
	case 'C':
	case 'S':
	case 'I':
		dtype = DIS_W;
		break;
	case 'J':
	case 'F':
	case 'D':
		dtype = DIS_L;
		break;
	case 'L':
	case '[':
		dtype = DIS_P;
		break;
	default:
		verifyerrormess("java data type");
		return -1;
	}
	return dtype;
}

/*
 * $i operands
 */

void
addrimm(Addr *a, int ival)
{
	a->mode = Aimm;
	a->u.ival = ival;
}

/*
 * Is an int too big to be an immediate operand?
 */

int
notimmable(int val)
{
	return val < 0 && ((val >> 29) & 7) != 7 || val > 0 && (val >> 29) != 0;
}

/*
 * i(fp) and i(mp) operands
 */

void
addrsind(Addr *a, uchar mode, int off)
{
	a->mode = mode;
	a->u.offset = off;
}

/*
 * i(j(fp)) and i(j(mp)) operands
 */

void
addrdind(Addr *a, uchar mode, uint fi, uint si)
{
	a->mode = mode;
	a->u.b.fi = fi;
	a->u.b.si = si;
}

/*
 * Assign a register to a destination operand if not already done so.
 */

void
dstreg(Addr *a, uchar dtype)
{
	if(a->mode == Afp && a->u.offset == -1)
		a->u.offset = getreg(dtype);
}

/*
 * Print a string.
 */

void
pstring(char *s)
{
	int slen;
	char *se;
	char c;

	slen = strlen(s);
	se = s + slen;
	for(; s < se; s++) {
		/* null char represented as 0xC080 in String literals */
		c = s[0];
		if(s+1 < se && (uchar)c == 0xC0 && (uchar)s[1] == 0x80) {
			c = '\0';
			s++;
		}
		if(c == '\n')
			Bwrite(bout, "\\n", 2);
		else if(c == '\t')
			Bwrite(bout, "\\t", 2);
		else if(c == '"')
			Bwrite(bout, "\\\"", 2);
		else if(c == '\\')
			Bwrite(bout, "\\\\", 2);
		else
			Bputc(bout, c);
	}
}

void*
Malloc(uint n)
{
	void *p;

	p = malloc(n);
	if(p == nil)
		fatal("out of memory\n");
	return p;
}

void*
Mallocz(uint n)
{
	void *p;

	p = Malloc(n);
	memset(p, 0, n);
	return p;
}

void*
Realloc(void *p, uint n)
{
	if(p == nil)
		p = malloc(n);
	else
		p = realloc(p, n);
	if(p == nil)
		fatal("out of memory\n");
	return p;
}

/*
 * Die.
 */

void
fatal(char *fmt, ...)
{
	va_list s;
	char buf[1024], *out;

	va_start(s, fmt);
	write(2, "fatal j2d error: ", 17);
	out = doprint(buf, buf+sizeof(buf), fmt, s);
	va_end(s);
	write(2, buf, (int)(out-buf));
	if(bout != nil)
		remove(ofile);
	exits("fatal");
}

/*
 * Bytecode verification.
 */

/*
 * Verify a constant pool index.
 */

void
verifycpindex(Jinst *j, int ix, int CON_bits)
{
	if(ix > 0 && ix < class->cp_count && ((1 << class->cts[ix]) & CON_bits))
		return;

	if(j != nil)
		verifyerror(j);
	else
		verifyerrormess("constant pool index");
}

void
verifyerror(Jinst *j)
{
	fatal("VerifyError: %J\n", j);
}

void
verifyerrormess(char *mess)
{
	fatal("VerifyError: %s\n", mess);
}

/*
 * Size of frame cell of given type.
 */

int cellsize[DIS_P+1] = {
	0,	/* DIS_X */
	IBY2WD,	/* DIS_W */
	IBY2LG,	/* DIS_L */
	IBY2WD,	/* DIS_P */
};

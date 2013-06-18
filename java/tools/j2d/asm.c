#include "java.h"

static char *instname[MAXDIS];

/*
 * %A format conversion.
 */

int
Aconv(va_list *addr, Fconv *f)
{
	Addr *a;
	char buf[512];

	a = va_arg(*addr, Addr*);

	switch(a->mode) {
	case Anone:
		sprint(buf, "none");
		break;
	case Aimm:
		sprint(buf, "$%d", a->u.ival);
		break;
	case Afp:
		sprint(buf, "%d(fp)", a->u.offset);
		break;
	case Amp:
		sprint(buf, "%d(mp)", a->u.offset);
		break;
	case Afpind:
		sprint(buf, "%d(%d(fp))", a->u.b.si, a->u.b.fi);
		break;
	case Ampind:
		sprint(buf, "%d(%d(mp))", a->u.b.si, a->u.b.fi);
		break;
	}
	strconv(buf, f);
	return sizeof(Addr*);
}

/*
 * %I format conversion.
 */

int
Iconv(va_list *inst, Fconv *f)
{
	int n;
	Inst *in;
	char buf[512], *p;
	char *op, *comma;

	in = va_arg(*inst, Inst*);
	if(in->op >= 0 && in->op < MAXDIS)
		op = instname[in->op];
	else
		op = "??";
	buf[0] = '\0';
	n = sprint(buf, "\t%s\t", op);
	p = buf+n;

	comma = "";
	if(in->s.mode != Anone) {
		n = sprint(p, "%A", &in->s);
		p += n;
		comma = ",";
	}
	if(in->m.mode != Anone) {
		n = sprint(p, "%s%A", comma, &in->m);
		p += n;
		comma = ",";
	}
	if(in->d.mode != Anone)
		sprint(p, "%s%A", comma, &in->d);

	strconv(buf, f);
	return sizeof(Inst*);
}

static void
ehtable(Code *c)
{
	int i;
	char *s;
	Handler *h;

	if(c->nex == 0)
		return;
	Bprint(bout, "#\tException Table\n");
	for(i = 0; i < c->nex; i++) {
		h = c->ex[i];
		if(h->catch_type == 0)
			s = "*";
		else
			s = CLASSNAME(h->catch_type);
		Bprint(bout, "#\t%d %d %d %s\n", h->start_pc, h->end_pc,
			h->handler_pc, s);
	}
}

static void
putinst(Inst *i)
{
	while(i) {
		if(i->pc % 10 == 0)
			Bprint(bout, "#%d\n", i->pc);
		Bprint(bout, "%I\n", i);
		i = i->next;
	}
}

Inst *clinitclone;	/* generated <clinit>, <clone> methods */

/*
 * Emit assembly instructions for a method.
 */

void
asminst(void)
{
	Inst *i;
	Jinst *j, *je;
	int n;

	if(verbose == 0) {
		putinst(ihead);
		return;
	}

	/* -v option */

	for(n = 0; n < class->methods_count; n++) {
		Bprint(bout, "#Method: %s%s\n", pcode[n].name, pcode[n].sig);
		if(pcode[n].code == nil)
			continue;
		ehtable(pcode[n].code);
		j = &pcode[n].code->j[0];
		je = j + pcode[n].code->code_length;
		while(j < je) {
			Bprint(bout, "#J%d\t%J\n", j->pc, j);
			for(i = j->dis; i && i->j == j; i = i->next) {
				if(i->pc % 10 == 0)
					Bprint(bout, "#%d\n", i->pc);
				Bprint(bout, "%I\n", i);
			}
			j += j->size;
		}
	}

	if(clinitclone) {
		Bprint(bout, "#Method: <clinit|clone>()V\n");
		putinst(clinitclone);
	}
}

void
sblinst(Biobuf *bsym)
{
	Inst *i;
	int curline, lastline, lastchar, blockid;

	Bprint(bsym, "%d\n", itail ? itail->pc + 1 : 0);
	curline = 1;
	lastline = -1;
	lastchar = 6;
	blockid = -1;
	for(i = ihead; i; i = i->next) {
		if(i->j)
			curline = i->j->line;
		if(curline != lastline) {
			lastline = curline;
			lastchar = 6;
			blockid++;
			Bprint(bsym, "%d.", curline);
		}
		Bprint(bsym, "1,%d %d\n", lastchar++, blockid);
	}
}

/*
 * Dis opcode mnemonics.  Keep in sync with interp/tab.h!
 */

static char *instname[MAXDIS] =
{
	"nop",
	"alt",
	"nbalt",
	"goto",
	"call",
	"frame",
	"spawn",
	"runt",
	"load",
	"mcall",
	"mspawn",
	"mframe",
	"ret",
	"jmp",
	"case",
	"exit",
	"new",
	"newa",
	"newcb",
	"newcw",
	"newcf",
	"newcp",
	"newcm",
	"newcmp",
	"send",
	"recv",
	"consb",
	"consw",
	"consp",
	"consf",
	"consm",
	"consmp",
	"headb",
	"headw",
	"headp",
	"headf",
	"headm",
	"headmp",
	"tail",
	"lea",
	"indx",
	"movp",
	"movm",
	"movmp",
	"movb",
	"movw",
	"movf",
	"cvtbw",
	"cvtwb",
	"cvtfw",
	"cvtwf",
	"cvtca",
	"cvtac",
	"cvtwc",
	"cvtcw",
	"cvtfc",
	"cvtcf",
	"addb",
	"addw",
	"addf",
	"subb",
	"subw",
	"subf",
	"mulb",
	"mulw",
	"mulf",
	"divb",
	"divw",
	"divf",
	"modw",
	"modb",
	"andb",
	"andw",
	"orb",
	"orw",
	"xorb",
	"xorw",
	"shlb",
	"shlw",
	"shrb",
	"shrw",
	"insc",
	"indc",
	"addc",
	"lenc",
	"lena",
	"lenl",
	"beqb",
	"bneb",
	"bltb",
	"bleb",
	"bgtb",
	"bgeb",
	"beqw",
	"bnew",
	"bltw",
	"blew",
	"bgtw",
	"bgew",
	"beqf",
	"bnef",
	"bltf",
	"blef",
	"bgtf",
	"bgef",
	"beqc",
	"bnec",
	"bltc",
	"blec",
	"bgtc",
	"bgec",
	"slicea",
	"slicela",
	"slicec",
	"indw",
	"indf",
	"indb",
	"negf",
	"movl",
	"addl",
	"subl",
	"divl",
	"modl",
	"mull",
	"andl",
	"orl",
	"xorl",
	"shll",
	"shrl",
	"bnel",
	"bltl",
	"blel",
	"bgtl",
	"bgel",
	"beql",
	"cvtlf",
	"cvtfl",
	"cvtlw",
	"cvtwl",
	"cvtlc",
	"cvtcl",
	"headl",
	"consl",
	"newcl",
	"casec",
	"indl",
	"movpc",
	"tcmp",
	"mnewz",
	"cvtrf",
	"cvtfr",
	"cvtws",
	"cvtsw",
	"lsrw",
	"lsrl",
	"eclr",
	"newz",
	"newaz",
};

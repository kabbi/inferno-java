#
# Dis opcode mnemonics.  Keep in sync with interp/tab.h!
#

#MAXDIS: con INEWAZ+1;

instname := array [MAXDIS] of {
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
	"raise",
};

#
# %A format conversion.
#

addrconv(a: ref Addr): string
{
	s := "";
	case int a.mode {
	int Aimm =>
		s = "$" + string a.ival;
	int Afp =>
		s = string a.offset + "(fp)";
	int Amp =>
		s = string a.offset + "(mp)";
	int Afpind =>
		s = string a.offset + "(" + string a.ival + "(fp))";
	int Ampind =>
		s = string a.offset + "(" + string a.ival + "(mp))";
	}
	return s;
}

#
# %I format conversion.
#

instconv(in: ref Inst): string
{
	op := "";
	if(in.op < byte MAXDIS)
		op = instname[int in.op];
	else
		op = "??";
	s := "\t" + op + "\t";
	comma := "";
	if(in.s.mode != Anone) {
		s += addrconv(in.s);
		comma = ",";
	}
	if(in.m.mode != Anone) {
		s += comma;
		s += addrconv(in.m);
		comma = ",";
	}
	if(in.d.mode != Anone)
		s += comma;
		s += addrconv(in.d);
	return s;
}

ehtable(c: ref Code)
{
	i: int;
	s: string;
	h: ref Handler;

	if(c.nex == 0)
		return;
	bout.puts("#\tException Table\n");
	for(i = 0; i < c.nex; i++) {
		h = c.ex[i];
		if(h.catch_type == 0)
			s = "*";
		else
			s = CLASSNAME(h.catch_type);
		bout.puts("#\t" + string h.start_pc + " " + string h.end_pc
			+ " " + string h.handler_pc + " " + s + "\n");
	}
}

putinst(i: ref Inst)
{
	while(i != nil) {
		if(i.pc % 10 == 0)
			bout.puts("#" + string i.pc + "\n");
		bout.puts(instconv(i) + "\n");
		i = i.next;
	}
}

clinitclone: ref Inst;	# generated <clinit>, <clone> methods

#
# Emit assembly instructions for a method.
#

asminst()
{
	i: ref Inst;
	j: ref Jinst;
	n, jix: int;
	c: ref Code;

	if(verbose == 0) {
		putinst(ihead);
		return;
	}

	# -v option

	for(n = 0; n < class.methods_count; n++) {
		bout.puts("#Method: " + pcode[n].name + pcode[n].sig + "\n");
		if(pcode[n].code == nil)
			continue;
		ehtable(pcode[n].code);
		c = pcode[n].code;
		jix = 0;
		while(jix < c.code_length) {
			j = c.j[jix];
			bout.puts("#J" + string j.pc + "\t" + jinstconv(j) + "\n");
			for(i = j.dis; i != nil && i.j == j; i = i.next) {
				if(i.pc % 10 == 0)
					bout.puts("#" + string i.pc + "\n");
				bout.puts(instconv(i) + "\n");
			}
			jix += j.size;
		}
	}

	if(clinitclone != nil) {
		bout.puts("#Method: <clinit|clone>()V\n");
		putinst(clinitclone);
	}
}

sblinst(bsym: ref Bufio->Iobuf)
{
	i: ref Inst;
	n, curline, lastline, lastchar, blockid: int;

	if(itail != nil)
		n = itail.pc + 1;
	else
		n = 0;
	bsym.puts(string n + "\n");
	curline = 1;
	lastline = -1;
	lastchar = 6;
	blockid = -1;
	for(i = ihead; i != nil; i = i.next) {
		if(i.j != nil)
			curline = i.j.line;
		if(curline != lastline) {
			lastline = curline;
			lastchar = 6;
			blockid++;
			bsym.puts(string curline + ".");
		}
		bsym.puts("1," + string lastchar++ + " " + string blockid + "\n");
	}
}

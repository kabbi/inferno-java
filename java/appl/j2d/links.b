#
# Manage .dis Link Section.
#

Link: adt {
	id:	int;		# dis type identifier
	pc:	int;		# method entry pc
	sig:	int;		# MD5 signature
	name:	string;		# method name
	next:	cyclic ref Link;
};

links:	ref Link;
last:	ref Link;
nlinks:	int;

#
# Create a Link entry; one for each method defined in the class.
#

xtrnlink(id: int, pc: int, name: string, sig: string)
{
	l: ref Link;

	l = ref Link(id, pc, 1247901281, name + sig, nil);
	if(name == "main")
		setentry(pc, id);
	if(links == nil)
		links = l;
	else
		last.next = l;
	last = l;
	nlinks += 1;
}

#
# Functions for patching frame & call instructions.
#

FCPatch: adt {
	frame:	ref Inst;
	call:	ref Inst;
	name:	string;
	sig:	string;
	next:	cyclic ref FCPatch;
};

fcplist:	ref FCPatch;

#
# Record a frame/call pair for later patching.
#

addfcpatch(frame: ref Inst, call: ref Inst, name: string, sig: string)
{
	fcp: ref FCPatch;

	fcp = ref FCPatch(frame, call, name, sig, fcplist);
	fcplist = fcp;
}

getLink(name: string, sig: string): ref Link
{
	l: ref Link;
	nlen: int;

	nlen = len name;
	l = links;
	while(l != nil) {
		if(len l.name == nlen + len sig
		&& l.name[0:nlen] == name && l.name[nlen:] == sig) {
			return l;
		}
		l = l.next;
	}
	fatal("getLink: " + name + ", " + sig);
	return nil;
}

#
# Patch frame/call pairs.
#

dofcpatch()
{
	fcp: ref FCPatch;
	l: ref Link;

	fcp = fcplist;
	while(fcp != nil) {
		l = getLink(fcp.name, fcp.sig);
		fcp.frame.s.ival = l.id;
		fcp.call.d.ival = l.pc;
		fcp = fcp.next;
	}
}

#
# Emit assembly 'link' directives.
#

asmlinks()
{
	l: ref Link;

	for(l = links; l != nil; l = l.next) {
		bout.puts("\tlink\t" + string l.id + "," + string l.pc
			+ ",0x" + hex(l.sig, 0) + ",\"" + l.name + "\"\n");
	}
}

sbllinks(bsym: ref Bufio->Iobuf)
{
	l: ref Link;

	bsym.puts(string nlinks + "\n");
	for(l = links; l != nil; l = l.next) {
		bsym.puts(string l.pc + ":" + l.name + "\n");
		bsym.puts("0\n");    # args
		bsym.puts("0\n");    # locals
		bsym.puts("n\n");    # return type
	}
}

disnlinks()
{
	discon(nlinks);
}

dislinks()
{
	l: ref Link;

	for(l = links; l != nil; l = l.next) {
		discon(l.pc);
		discon(l.id);
		disword(l.sig);
		bout.puts(l.name);
		bout.putb(byte 0);
	}
}

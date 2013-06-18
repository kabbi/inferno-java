roots:	array of ref BB;	# root basic blocks
nr:	int;			# number of root basic blocks
maxr:	int;			# maximum number of roots

setflags(pc: int, flags: byte)
{
	j: ref Jinst;

	j = code.j[pc];
	if(j.bb == nil) {
		j.bb = ref BB(j, nil, 0, nil, byte 0, byte BB_PRESIM, 0, nil, 0, nil);
		# record root basic blocks
		if(int (flags & (BB_ENTRY | BB_FINALLY | BB_HANDLER))) {
			if(nr >= maxr) {
				oldmaxr := maxr;
				maxr += ALLOCINCR;
				newroots := array [maxr] of ref BB;
				for(i := 0; i < oldmaxr; i++)
					newroots[i] = roots[i];
				roots = newroots;
			}
			roots[nr] = j.bb;
			nr += 1;
		}
	}
	j.bb.flags |= flags;
}

#
# Verify that the target of a jump is valid.
#

verifyjump(j: ref Jinst, offset: int)
{
	dst: int;

	dst = j.pc + offset;
	if(dst < 0 || dst >= code.code_length || code.j[dst] == nil)
		verifyerror(j);
}

#
# Mark the instructions of a method that are basic block leaders.
#

markldrs()
{
	j: ref Jinst;
	jpi: ref Jinst.Pi;
	jpt1: ref Jinst.Pt1;
	jpt2: ref Jinst.Pt2;
	jpw: ref Jinst.Pw;
	i: int;
	pc, pcnext: int;

	# first instruction is a leader
	setflags(0, BB_LDR | BB_ENTRY);

	# exception handler entry points are leaders
	for(i = 0; i < code.nex; i++)
		setflags(code.ex[i].handler_pc, BB_LDR | BB_HANDLER);

	pc = 0;
	while(pc < code.code_length) {
		j = code.j[pc];
		pcnext = pc+j.size;
		pick jp := j {
		Pi =>
			jpi = jp;
		Pt1 =>
			jpt1 = jp;
		Pt2 =>
			jpt2 = jp;
		Pw =>
			jpw = jp;
		}
		case int j.op {
		Jwide =>
			if(int jpw.w.op == Jret && pcnext < code.code_length)
				setflags(pcnext, BB_LDR);
		Jret or
		Jireturn or
		Jlreturn or
		Jfreturn or
		Jdreturn or
		Jareturn or
		Jreturn or
		Jathrow =>
			if(pcnext < code.code_length)
				setflags(pcnext, BB_LDR);
		Jifeq or
		Jifne or
		Jiflt or
		Jifge or
		Jifgt or
		Jifle or
		Jif_icmpeq or
		Jif_icmpne or
		Jif_icmplt or
		Jif_icmpge or
		Jif_icmpgt or
		Jif_icmple or
		Jif_acmpeq or
		Jif_acmpne or
		Jifnull or
		Jifnonnull =>
			verifyjump(j, jpi.i);
			setflags(pc+jpi.i, BB_LDR);
			setflags(pcnext, BB_LDR);
		Jgoto or
		Jgoto_w =>
			verifyjump(j, jpi.i);
			setflags(pc+jpi.i, BB_LDR);
			if(pcnext < code.code_length)
				setflags(pcnext, BB_LDR);
		Jjsr or
		Jjsr_w =>
			# target of jsr is leader, jsr successor isn't
			verifyjump(j, jpi.i);
			setflags(pc+jpi.i, BB_LDR | BB_FINALLY);
			finallyentry(pc+jpi.i);
		Jtableswitch =>
			for(i = 0; i < jpt1.t1.hb - jpt1.t1.lb + 1; i++) {
				verifyjump(j, jpt1.t1.tbl[i]);
				setflags(pc+jpt1.t1.tbl[i], BB_LDR);
			}
			verifyjump(j, jpt1.t1.dflt);
			setflags(pc+jpt1.t1.dflt, BB_LDR);
			if(pcnext < code.code_length)
				setflags(pcnext, BB_LDR);
		Jlookupswitch =>
			for(i = 0; i < jpt2.t2.np; i++) {
				verifyjump(j, jpt2.t2.tbl[2*i+1]);
				setflags(pc+jpt2.t2.tbl[2*i+1], BB_LDR);
			}
			verifyjump(j, jpt2.t2.dflt);
			setflags(pc+jpt2.t2.dflt, BB_LDR);
			if(pcnext < code.code_length)
				setflags(pcnext, BB_LDR);
		}
		pc = pcnext;
	}
}

#
# Link basic block bb to its successors.
#

linksucc(bb: ref BB)
{
	i: int;
	pc: int;
	je: ref Jinst;
	jpi: ref Jinst.Pi;
	jpt1: ref Jinst.Pt1;
	jpt2: ref Jinst.Pt2;
	jpw: ref Jinst.Pw;

	bb.nsucc = 0;
	bb.succ = nil;
	je = bb.je;
	pc = je.pc;

	pick jp := je {
	Pi =>
		jpi = jp;
	Pt1 =>
		jpt1 = jp;
	Pt2 =>
		jpt2 = jp;
	Pw =>
		jpw = jp;
	}

	case int je.op {
	Jwide =>
		if(int jpw.w.op != Jret && pc+je.size < code.code_length) {
			bb.nsucc = 1;
			bb.succ = array [1] of ref BB;
			bb.succ[0] = code.j[pc+je.size].bb;
		}
	* =>
		if(pc+je.size < code.code_length) {
			bb.nsucc = 1;
			bb.succ = array [1] of ref BB;
			bb.succ[0] = code.j[pc+je.size].bb;
		}
	Jret or
	Jireturn or
	Jlreturn or
	Jfreturn or
	Jdreturn or
	Jareturn or
	Jreturn or
	Jathrow =>
		;
	Jifeq or
	Jifne or
	Jiflt or
	Jifge or
	Jifgt or
	Jifle or
	Jif_icmpeq or
	Jif_icmpne or
	Jif_icmplt or
	Jif_icmpge or
	Jif_icmpgt or
	Jif_icmple or
	Jif_acmpeq or
	Jif_acmpne or
	Jifnull or
	Jifnonnull =>
		bb.nsucc = 2;
		bb.succ = array [2] of ref BB;
		bb.succ[0] = code.j[pc+jpi.i].bb;	# branch target
		bb.succ[1] = code.j[pc+je.size].bb;	# fall through
	Jgoto or
	Jgoto_w =>
		bb.nsucc = 1;
		bb.succ = array [1] of ref BB;
		bb.succ[0] = code.j[pc+jpi.i].bb;
	Jtableswitch =>
		bb.nsucc = jpt1.t1.hb - jpt1.t1.lb + 2;
		bb.succ = array [bb.nsucc] of ref BB;
		for(i = 0; i < bb.nsucc-1; i++)
			bb.succ[i] = code.j[pc+jpt1.t1.tbl[i]].bb;
		bb.succ[i] = code.j[pc+jpt1.t1.dflt].bb;
	Jlookupswitch =>
		bb.nsucc = jpt2.t2.np + 1;
		bb.succ = array [bb.nsucc] of ref BB;
		for(i = 0; i < bb.nsucc-1; i++)
			bb.succ[i] = code.j[pc+jpt2.t2.tbl[2*i+1]].bb;
		bb.succ[i] = code.j[pc+jpt2.t2.dflt].bb;
	}
}

#
# Build the basic block control flow graph.
#

flowgraph()
{
	js, je: ref Jinst;
	pc, pcnext: int;

	markldrs();

	pc = 0;
	while(pc < code.code_length) {
		js = code.j[pc];
		if(js.bb == nil)
			fatal("flowgraph: nil bb");
		# find last instruction in basic block
		je = js;
		while() {
			pcnext = je.pc + je.size;
			if(pcnext >= code.code_length
			|| code.j[pcnext].bb != nil)	# hence a leader
				break;
			je = code.j[pcnext];
			je.bb = js.bb;
		}
		js.bb.je = je;
		linksucc(js.bb);
		pc = pcnext;
	}
	finallyalloc();
}

#
# Free basic block structures after each method is translated.
#

bbfree()
{
	j: ref Jinst;
	jix: int;

	jix = 0;
	while(jix < code.code_length) {
		j = code.j[jix];
		if(j.bb.je == j) {
			j.bb.succ = nil;
			j.bb = nil;
		}
		jix += j.size;
	}
	roots = nil;
	nr = 0;
	maxr = 0;
}

#
# The following stuff is used during method simulation.
#

SSIZE:		con 128;
bbstack :=	array [SSIZE] of ref BB;
bbtos:		int;

bbput(bb: ref BB)
{
	if(bbtos == SSIZE)
		fatal("bbstack overflow");
	bb.state = BB_ACTIVE;
	bb.flags |= BB_REACHABLE;
	bbstack[bbtos++] = bb;
}

bbget(): ref BB
{
	ret: ref BB;

	if(bbtos != 0)
		ret = bbstack[--bbtos];
	return ret;
}

bbinit()
{
	i: int;

	bbtos = 0;
	for(i = 0; i < nr; i++)
		bbput(roots[i]);
}

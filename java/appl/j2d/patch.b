#
# Patch operands, etc. that reference pc offsets.
#

P_CASE,
P_OTHER:	con iota+1;

Patch: adt {
	kind:	byte;		# P_xxx
	i:	ref Inst;
	n:	int;		# number of cases in ...
	jmptbl:	array of int;	# ... case jump table
	next:	cyclic ref Patch;
};

plist:	ref Patch;

#
# Allocate a Patch structure.
#

newPatch(kind: int, i: ref Inst): ref Patch
{
	p: ref Patch;

	p = ref Patch(byte kind, i, 0, nil, plist);
	plist = p;
	return p;
}

#
# Record non-case branch instruction for later patching.
#

patchop(i: ref Inst)
{
	newPatch(P_OTHER, i);
}

#
# Record case jump table for later patching.
#

patchcase(i: ref Inst, n: int, jmptbl: array of int)
{
	p: ref Patch;

	p = newPatch(P_CASE, i);
	p.n = n;
	p.jmptbl = jmptbl;
}

#
# Calculate patch address; Java branches are relative.
#

patchaddr(i: ref Inst, pc: int): int
{
	j: ref Jinst;
	span, srcjpc, dstjpc: int;

	span = pc;
	srcjpc = i.j.pc;
	dstjpc = srcjpc + span;
	j = code.j[dstjpc];

	# account for no-op's (dup, swap, pop, etc.), elided loads/stores
	while(j.dis == nil) {
		dstjpc += j.size;
		j = code.j[dstjpc];
	}

	return j.dis.pc;
}

#
# Patch branch instructions and case jump tables of a method.
#

patchmethod(startpc: int)
{
	p: ref Patch;
	i: ref Inst;
	jt: array of int;
	n: int;

	for(p = plist; p != nil; p = p.next) {
		i = p.i;
		if(int p.kind == P_CASE) {
			jt = p.jmptbl;
			for(n = 0; n < p.n; n++)
				jt[n*3+2] = patchaddr(i, jt[n*3+2]);
			jt[p.n*3] = patchaddr(i, jt[p.n*3]);
		} else {	# P_OTHER
			i.d.ival = patchaddr(i, i.d.ival);
			#
			# jmp $start_of_method  ->  jmp $start_of_method+1
			# skip (re-)allocation of Sys->Exception object
			#
			# no more Sys->Exception objects, we killed them all
			#if(i.d.ival == startpc && int i.op == IJMP && code.nex != 0)
			#	i.d.ival += 1;
		}
	}
}

#
# Clear the patch list after each method.
#

patchfree()
{
	plist = nil;
}

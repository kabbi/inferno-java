#
# "Unify" results that are produced in one basic block and consumed
# in another.  I.e., ensure that producers and consumers access results
# through consistent fp offsets.
#

pushsucc(bb: ref BB)
{
	i: int;

	for(i = 0; i < bb.nsucc; i++) {
		if(bb.succ[i].state == BB_POSTSIM)
			bbput(bb.succ[i]);
	}
}

pass1(s: ref StkSnap): int
{
	j: ref Jinst;
	i: int;
	fpoff: int;

	fpoff = -1;
	for(i = 0; i < s.npc; i++) {
		j = code.j[s.pc[i]];
		if((isload(j) && j.movsrc.mode != byte Anone)
		|| (!isload(j) && j.dst.offset != -1)) {
			if(fpoff == -1)
				fpoff = j.dst.offset;
			else if(fpoff != j.dst.offset)
				fatal("pass1: can't");
		}
	}
	if(fpoff == -1)
		fpoff = getreg(j2dtype(s.jtype));
	return fpoff;
}

pass2(s: ref StkSnap, fpoff: int)
{
	j: ref Jinst;
	i: int;

	for(i = 0; i < s.npc; i++) {
		j = code.j[s.pc[i]];
		if(isload(j) && j.movsrc.mode == byte Anone) {
			*j.movsrc = *j.dst;
			j.dst.mode = byte Afp;
		}
		j.dst.offset = fpoff;
	}
}

unifybb(bb: ref BB)
{
	s: ref StkSnap;
	n, m: int;

	if(bb.state == BB_POSTUNIFY)
		fatal("unifybb: BB_POSTUNIFY");

	if(bb.entrystk == nil) {
		pushsucc(bb);
		return;
	}

	clearreg();
	reservereg(bb.entrystk, bb.entrysz);
	reservereg(bb.exitstk, bb.exitsz);

	for(n = 0; n < bb.entrysz; n++) {
		s = bb.entrystk[n];
		for(m = 0; m < s.npc; m++) {
			reservereg(code.j[s.pc[m]].bb.entrystk,
				code.j[s.pc[m]].bb.entrysz);
		}
	}

	for(n = 0; n < bb.entrysz; n++) {
		s = bb.entrystk[n];
		if(s.npc == 1)
			dstreg(code.j[s.pc[0]].dst, j2dtype(s.jtype));
		else
			pass2(s, pass1(s));
	}

	bb.state = BB_POSTUNIFY;
	pushsucc(bb);
}

unify()
{
	bb: ref BB;

	bbinit();
	while((bb = bbget()) != nil)
		unifybb(bb);
}

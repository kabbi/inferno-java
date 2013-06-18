#
# Generate symbol table file (.sbl).
#

SBLVERSION:	con "limbo .sbl 2.0";
EXT:		con ".sbl";

sblout(out: string)
{
	n: int;
	sym: string;
	bsym: ref Bufio->Iobuf;

	n = len out;
	if(n > 2 && out[n-1] == 's') {		# .s or .dis file ?
		if(out[n-2] == '.')
			n -= 2;
		else if(n > 4 && out[n-2] == 'i'
		&& out[n-3] == 'd' && out[n-4] == '.')
			n -= 4;
	}
	sym = out[0:n] + EXT;

	bsym = bufio->create(sym, Bufio->OWRITE, 8r644);
	if(bsym == nil)
		fatal("can't open " + sym + ": " + sprint("%r"));

	bsym.puts(SBLVERSION + "\n");
	bsym.puts(THISCLASS + "\n");
	bsym.puts("1\n");
	s: string;
	if(class.source_file)
		s = STRING(class.source_file) + "\n";
	else
		s = THISCLASS + ".java\n";
	bsym.puts(s);
	sblinst(bsym);			# Dis instructions
	bsym.puts("0\n");		# adts
	sbllinks(bsym);			# functions
	bsym.puts("0\n");		# globals

	bsym.close();
}

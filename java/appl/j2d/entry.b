#
# 'entry' assembly directive.
#

pc:	int = -1;
tid:	int = -1;

#
# Set the entry point; entry is the beginning of "main".
#

setentry(l: int, i: int)
{
	if(pc != -1)
		verifyerrormess("main overloaded");
	pc = l;
	tid = i;
}

#
# Emit 'entry' assembly directive.
#

asmentry()
{
	if(pc == -1)
		return;
	bout.puts("\tentry\t" + string pc + ", " + string tid + "\n");
}

disentry()
{
	discon(pc);
	discon(tid);
}

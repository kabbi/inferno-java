#
# Emit 'module' assembly directive.
#

asmmod()
{
	bout.puts("\tmodule\t" + THISCLASS + "\n");
}

dismod()
{
	name := array of byte THISCLASS;
	n := len name;
	if(n > Sys->NAMEMAX-1)
		n = Sys->NAMEMAX-1;
	bout.write(name, n);
	bout.putb(byte 0);
}

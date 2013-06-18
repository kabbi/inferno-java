#
# 'desc' assembly directives.
#

Desc: adt {
	id:	int;		# Dis type identifier
	ln:	int;		# length, in bytes, of mapped object
	map:	array of byte;	# bit map of pointers
	nmap:	int;		# number of bytes in map
	next:	cyclic ref Desc;
};

dlist:	ref Desc;
dtail:	ref Desc;
id:	int = 0;  # reserve id == 0 for Module Data type descriptor

#
# Allocate a Desc adt.
#

newDesc(id: int, ln: int, nmap: int, map: array of byte): ref Desc
{
	return ref Desc(id, ln, map, nmap, nil);
}

mapeq(a, b: array of byte, n: int): int
{
	while(n-- > 0) {
		if(a[n] != b[n])
			return 0;
	}
	return 1;
}

#
# Save a type descriptor; reuse existing descriptor if identical.
#

descid(ln: int, nmap: int, map: array of byte): int
{
	d: ref Desc;

	for(d = dlist; d != nil; d = d.next) {
		if(d.ln == ln && d.nmap == nmap && mapeq(d.map, map, nmap))
			return d.id;
	}

	id += 1;
	d = newDesc(id, ln, nmap, map);
	if(dlist == nil)
		dlist = d;
	else
		dtail.next = d;
	dtail = d;

	return d.id;
}

#
# Save type descriptor for module data.
#

mpdescid(ln: int, nmap: int, map: array of byte)
{
	d: ref Desc;

	d = newDesc(0, ln, nmap, map);
	d.next = dlist;
	dlist = d;
}

#
# Emit assembly 'desc' directives.
#

asmdesc()
{
	d: ref Desc;
	i: int;

	for(d = dlist; d != nil; d = d.next) {
		bout.puts("\tdesc\t$" + string d.id + "," + string d.ln + ",\"");
		for(i = 0; i < d.nmap; i++)
			bout.puts(hex(int d.map[i], 2));
		bout.puts("\"\n");
	}
}

disndesc()
{
	discon(id+1);
}

disdesc()
{
	d: ref Desc;

	for(d = dlist; d != nil; d = d.next) {
		discon(d.id);
		discon(d.ln);
		discon(d.nmap);
		bout.write(d.map, d.nmap);
	}
}

implement JavaTrace;

include "sys.m";
	sys:	Sys;

include "loader.m";
include "classloader.m";

Class, Reloc:		import JavaClassLoader;
RELOC, CLASSREF, WORDZ:	import JavaClassLoader;

jassist:	JavaAssist;

	getint, getintarray, getptr, getreloc, getstring:	import jassist;

init(a: JavaAssist)
{
	if (sys == nil)
		sys = load Sys Sys->PATH;
	jassist = a;
	level = -1;
	outfd = sys->fildes(2);
}

trace(c: int, s: string)
{
	if (c <= level)
		sys->fprint(outfd, "%s\n", s);
}

info(c: ref Class)
{
	sys->fprint(outfd, "Class: %s [%s]\n", c.name, c.file);
	sys->fprint(outfd, "--- Relocs ---\n");
	pr_relocs(getreloc(c.mod, RELOC));
	i := CLASSREF;
	while ((s := getstring(c.mod, i)) != nil) {
		sys->fprint(outfd, "--- %s ---\n", s);
		pr_relocs(getreloc(c.mod, i + WORDZ));
		i += 2 * WORDZ;
	}
}

flagstext(flags: int): string
{
	result := "";
	if(flags & JavaClassLoader->ACC_PUBLIC)
		result += "|public";
	if(flags & JavaClassLoader->ACC_PRIVATE)
		result += "|private";
	if(flags & JavaClassLoader->ACC_PROTECTED)
		result += "|protected";
	if(flags & JavaClassLoader->ACC_STATIC)
		result += "|static";
	if(flags & JavaClassLoader->ACC_FINAL)
		result += "|final";
	if(flags & JavaClassLoader->ACC_SUPER) # ACC_SYNCHRONIZED == ACC_SUPER
		result += "|super/synchronized";
	if(flags & JavaClassLoader->ACC_VOLATILE)
		result += "|volatile";
	if(flags & JavaClassLoader->ACC_TRANSIENT)
		result += "|transient";
	if(flags & JavaClassLoader->ACC_NATIVE)
		result += "|native";
	if(flags & JavaClassLoader->ACC_INTERFACE)
		result += "|interface";
	if(flags & JavaClassLoader->ACC_ABSTRACT)
		result += "|abstract";
	return result;
}

pr_reloc(r: Reloc)
{
	f := r.field;
	if (f == nil)
		f = "@";
	s := r.signature;
	if (s == nil)
		s = "@";
	n: int;
	if (r.patch == nil)
		n = -1;
	else
		n = len r.patch;

	sys->fprint(outfd, "%s %s %d (flags: %s) %d\n", f, s, r.flags, flagstext(r.flags), n);
}

pr_relocs(r: array of JavaClassLoader->Reloc)
{
	n := len r;
	for (i := 0; i < n; i++)
		pr_reloc(r[i]);
}


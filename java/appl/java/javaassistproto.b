implement	JavaAssist;

include "sys.m";

include "loader.m";
include "classloader.m";

i:	int = 23;
r:	array of JavaClassLoader->Reloc;
s:	string = "23";
c:	ref JavaClassLoader->Class;
p:	ref Loader->Niladt;
x:	int;
j:	JavaAssist;

plus(a, b: int): int
{
	return a + b;
}

getint(mod: Nilmod, index: int): int
{
	modref(mod);
	x = index;
	return plus(1, 3);
}

getbytearray(mod: Nilmod, index: int): array of byte
{
	modref(mod);
	x = index;
	return array[1] of byte;
}

getintarray(mod: Nilmod, index: int): array of int
{
	modref(mod);
	x = index;
	return array[1] of int;
}

getptr(mod: Nilmod, index: int): ref Loader->Niladt
{
	modref(mod);
	x = index;
	return p;
}

getreloc(mod: Nilmod, index: int): array of JavaClassLoader->Reloc
{
	modref(mod);
	x = index;
	return r;
}

getrtreloc(data: ref Loader->Niladt, index: int): array of JavaClassLoader->RTReloc
{
	p = data;
	x = index;
	return nil;
}

getclassadt(data: ref Loader->Niladt, index: int): ref JavaClassLoader->Class
{
	p = data;
	x = index;
	return nil;
}

getabsint(addr: int): int
{
	return 0;
}

getadtstring(data: ref Loader->Niladt, index: int): string
{
	p = data;
	x = index;
	return nil;
}

getstring(mod: Nilmod, index: int): string
{
	modref(mod);
	x = index;
	return s;
}

mnew(mod: Nilmod, index: int): ref Loader->Niladt
{
	modref(mod);
	x = index;
	return p;
}

putclass(data: ref Loader->Niladt, index: int, value: ref JavaClassLoader->Class)
{
	p = data;
	x = index;
	c = value;
}

putint(data: ref Loader->Niladt, index: int, value: int)
{
	p = data;
	x = index;
	x = value;
}

putmod(data: ref Loader->Niladt, index: int, value: Nilmod)
{
	p = data;
	x = index;
	modref(value);
}

putobj(data: ref Loader->Niladt, index: int, value: ref JavaClassLoader->ClassObject)
{
	p = data;
	x = index;
	o := value;
}

putptr(data: ref Loader->Niladt, index: int, value: ref Loader->Niladt)
{
	p = data;
	x = index;
	p = value;
}

putstring(data: ref Loader->Niladt, index: int, value: string)
{
	p = data;
	x = index;
	s = value;
}

modref(nil: Nilmod)
{
}

modref2(nil, nil: Nilmod)
{
}

little_endian(): int
{
	return 1;
}

jclnilmod(nil: JavaClassLoader): Nilmod
{
	return nil;
}

sysnilmod(nil: Sys): Nilmod
{
	return nil;
}

new(mod: Nilmod, index: int): ref JavaClassLoader->Object
{
	modref(mod);
	x = index;
	return nil;
}

getobjclass(j: ref JavaClassLoader->Object): ref JavaClassLoader->Class
{
	a := j.mod;
	return nil;
}

modhash(mod: Nilmod): int
{
	modref(mod);
	return i & 16r7FFFFFFF;
}

objhash(nil: ref JavaClassLoader->Object): int
{
	return 0;
}

mcall0(nil: Nilmod, nil: int): int
{
	return j->little_endian();
}

mcall1(nil: Nilmod, nil: int, nil: ref JavaClassLoader->Object): ref JavaClassLoader->Object
{
	return j->JStoObject(nil);
}

mcalla(nil: Nilmod, nil: int, nil: ref JavaClassLoader->Array): int
{
	return 0;
}

mcallm(nil: Nilmod, nil: int, arg: Nilmod): int
{
	return j->modhash(arg);
}

getstrarray(mod: Nilmod, index: int): array of string
{
	modref(mod);
	x = index;
	return array[1] of string;
}

arrayof(nil: ref JavaClassLoader->Object): ref JavaClassLoader->Array
{
	return nil;
}

bytearraytoJS(nil: array of byte): array of ref JavaClassLoader->JavaString
{
	return nil;
}

intarraytoJS(nil: array of int): array of ref JavaClassLoader->JavaString
{
	return nil;
}

bigarraytoJS(nil: array of big): array of ref JavaClassLoader->JavaString
{
	return nil;
}

realarraytoJS(nil: array of real): array of ref JavaClassLoader->JavaString
{
	return nil;
}

ArraytoJS(nil: ref JavaClassLoader->Array): ref JavaClassLoader->JavaString
{
	return nil;
}

JStoObject(nil: ref JavaClassLoader->JavaString): ref JavaClassLoader->Object
{
	return nil;
}

ObjecttoJT(nil: ref JavaClassLoader->Object): ref JavaClassLoader->JavaThrowable
{
	return nil;
}

getmd(nil: Nilmod): ref Loader->Niladt
{
	return nil;
}

makeadt(addr: int): ref Loader->Niladt
{
	x = addr;
	return nil;
}

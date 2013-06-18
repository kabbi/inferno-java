implement Dump;

include "sys.m";
include "draw.m";
include "loader.m";
include "classloader.m";

Context: import Draw;

Dump: module
{
	MP:                     con "@mp";
        ADT:                    con "@adt";

	JAVA:	con ('J'<<24)|('a'<<16)|('v'<<8)|'a';

	MAGIC, VERSION, NAME, SUPER, RELOC, DSIZE, DRELOC, CLASSREF:
        con (iota * 4);
	WORDZ:                  con 4;

	init:	fn(nil: ref Context, argv: list of string);

	Reloc: adt
        {
                field:          string;
                signature:      string;
                flags:          int;
                patch:          array of int;
        };

	Field: adt
        {
                field:          string;
                signature:      string;
                flags:          int;
                value:          int;
                class:          cyclic ref Class;
        };

	Class: adt
        {
		state:          int;
                name:           string;
                ownname:        string;
                file:           string;
                version:        int;
                mod:            Nilmod;
                super:          cyclic ref Class;
                refs:           cyclic array of ref Class;
                objectdata:     cyclic list of ref Field;
                virtualmethod:  cyclic list of ref Field;
                staticdata:     cyclic array of ref Field;
                staticmethod:   cyclic array of ref Field;
                objectsize:     int;
                staticsize:     int;
                nextra:         int;
                datasize:       int;
                datareloc:      int;
                modsize:        int;
                modmap:         array of byte;
                objmap:         array of byte;
                objtype:        int;
	};

};

sys: Sys;
jassist:        JavaAssist;
 
        getint, getptr, getreloc, getstring:    import jassist;
        putclass, putint, putmod, putptr:       import jassist;
        mnew:                                  	import jassist;

stderr: ref Sys->FD;

ident:          con "Dump";

mesg(s: string)
{
        sys->fprint(stderr, "%s: %s\n", ident, s);
}

error(s: string)
{
        mesg(s);
        exit;
}

init(nil: ref Context, argv: list of string)
{
	s := "";
	t: string;
	a: array of byte;

	sys = load Sys Sys->PATH;
	stderr = sys->fildes(2);

	jassist = load JavaAssist JavaAssist->PATH;
                if (jassist == nil)
                        error(sys->sprint(
			"could not load %s: %r", JavaAssist->PATH));
 
	argv = tl argv;

	if(argv == nil)
		exit;

	i := 0;
	junk := array[10] of Nilmod;
	while(argv != nil) {
		s = hd argv;
		t = "\n" + s + "\n";
		a = array of byte t;
		if(sys->write(sys->fildes(1), a, len a) != len a)
			sys->fprint(sys->fildes(2), "load: write error: %r\n");
		junk[i] = load Nilmod s;
		dump(junk[i]);
		if(junk == nil)
			sys->fprint(sys->fildes(2), "load: error: %r\n");
		argv = tl argv;
	}
}

nextra(a: array of Reloc): int
{
        n := 0;
        for (i := 0; i < len a; i++) {
                case a[i].field {
                MP or ADT =>
                        n++;
                }
        }
        return n;
}

dump(m: Nilmod)
{
	ld := load Loader Loader->PATH;
	if(ld == nil)
        	error(sys->sprint("could not load %s: %r", Loader->PATH));

	if (getint(m, MAGIC) != JAVA){
                sys->fprint(sys->fildes(2), "\tbad magic number\n");
		return;
	}
 
        version := getint(m, VERSION) & 16rFF;
	sys->fprint(sys->fildes(1),"\tversion: %d\n",version);
        ownname := getstring(m, NAME);
	a := array of byte ownname;
	sys->fprint(sys->fildes(1),"\townname: ");
	if(sys->write(sys->fildes(1), a, len a) != len a)
	        sys->fprint(sys->fildes(2), "load: write error: %r\n");

	super := getstring(m, SUPER);
	sys->fprint(sys->fildes(1),"\tsuper: %s\n",super);

	r := getreloc(m, RELOC);
	i := len r;
	sys->fprint(sys->fildes(1),"\tlen r: %d\n",i);
	for (j := 0; j < len r; j++) {
                t := r[j];
		sys->fprint(sys->fildes(1),"\t\t%s\t%s\n",t.field,t.signature);
	}

	datasize := getint(m, DSIZE);
	sys->fprint(sys->fildes(1),"\tdatasize: %d\n",datasize);
	dr := getint(m, DRELOC);
	sys->fprint(sys->fildes(1), "\treloc: %d\n",dr);
	i = CLASSREF;
	n := 0;

	sys->fprint(sys->fildes(1),"\tclassrefs:\n");
	while ((s := getstring(m, i)) != nil) {
		n += nextra(getreloc(m, i + WORDZ));
		sys->fprint(sys->fildes(1),"\t\t%s %d\n",s,n);
		i += 2 * WORDZ;
	}

#	td := ld->tdesc(m);
#	z :=  2 * WORDZ + n*WORDZ;
#	mod := array[z] of byte;
#	for (i = 1; i < z; i++)
#                mod[i] = byte 0;
#        # nil and ref Class
#        mod[0] = byte 16rC0;
#	md := ld->dnew(datasize,mod);
#	instructions := ld->ifetch(m);
	links := ld->link(m);

	R := ref Class;
	S := ref Class;
	classes: list of ref Class;
	classes  = S :: classes;
	classes  = R :: classes;

	refs := mkclarray(classes);

	sys->fprint(sys->fildes(1),"\n");
}

mkclarray(l: list of ref Class): array of ref Class 
{
        n := len l;
        sys->fprint(stderr, "mkclarray, len: %d\n",n);
        a := array[n] of ref Class;
        while (--n >= 0) {
                sys->fprint(stderr, "mkclarray, len: %d\n",n);
                a[n] = hd l;
                l = tl l;
        }
        sys->fprint(stderr, "mkclarray, exitting\n");
        return a;
}
 


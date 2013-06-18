implement jvm;

include "sys.m";
	FD:	import Sys;

include "loader.m";
include "classloader.m";
Context: import Draw;

jvm: module
{
        init:   fn(ctxt: ref Context, argv: list of string);
};

PJAVAVER : con "v1.0";  #javasoft pjava we are based on

sys:		Sys;
stderr:		ref FD;
classloader:	JavaClassLoader;
Class:		import classloader;

init(ctxt: ref Context, argv: list of string)
{
	sys = load Sys Sys->PATH;
	stderr = sys->fildes(2);

	# split args into classloader options and java app args
	(opts,args) := processargs(argv);

	classloader = load JavaClassLoader JavaClassLoader->PATH;
	if (classloader == nil) {
		sys->fprint(stderr, "could not load %s: %r\n", JavaClassLoader->PATH);
		exit;
	}
	s := classname(hd tl args);
	sys->pctl(sys->NEWPGRP, nil);

	classloader->init(classloader,ctxt);

	if ( opts != nil )
		classloader->setflags(opts);

	classloader->runmain(classloader, s, args);
}

classname(s: string): string
{
	d: string;
	n := len s;
	for (i := 0; i < n; i++) {
		c := s[i];
		if (c == '.')
			d[i] = '/';
		else
			d[i] = c;
	}
	return d;
}

#
# process the argv of 'jvm' and handle any 'jvm' flags here
# and return:
#    classloader options in the form of 'list of (string,val)'
#    java class args in the form of 'list of string'
# valid classloader options are:
#   ("debug",1|0) -- debug messages on==1
#   ("verbose",1|0) -- verbose messages on==1
#   ("warn",1|0)    -- warning messages on==1
# valid local jvm options are:
#   i == version information
#   h == jvm help
#
processargs( argv : list of string ) : (list of (string,int), list of string)
{
	if ( argv == nil )
	{
		mesg("error: invalid parameters");
		showhelp("jvm"); #exits
	}

	# cmd   ::= 'jvm' [flags] javastuff
	# flags ::= '-' CHAR+
	jvmcmd := hd argv;
	stuff  := tl argv;
	flags  : string;
	if ( (stuff != nil) && (hd stuff)[0] == '-' )
	{
		flags = hd stuff;
		stuff = tl stuff;
	}

	# process flags
	opts : list of (string,int);
	for(x:=1;x<len flags; x++)
	{
		case flags[x]
		{
			'v'  => opts = ("verbose",1)::opts;
			'd'  => opts = ("debug",1)::opts;
			'w'  => opts = ("warn",1)::opts;
			'i'  => showinfo();              #exits
			'h'  => showhelp(jvmcmd);           #exits
			*    => mesg(sys->sprint( "error: %c is an invalid option\n", flags[x] ));
			        showhelp(jvmcmd);

		}
	}

	if ( stuff == nil )
	{
		mesg("error: missing classname");
		showhelp(jvmcmd); #exits
	}

	return(opts,jvmcmd::stuff);
}


mesg(s:string)
{
	sys->fprint(stderr,"%s\n", s);
}
	
showinfo()
{
	mesg(sys->sprint("Inferno PJava v%c [PJava %s]\n", JavaClassLoader->SUXV, PJAVAVER ));
	exit;
}

showhelp(cmd:string)
{
	mesg(sys->sprint( "usage:\t%s [-vdwih] classname classargs", cmd ));
	mesg(sys->sprint( "\tv=verbose; d=debug; w=warnings; i=version; h=help" ));
	exit;
}

badopt(opt : int)
{
}


	

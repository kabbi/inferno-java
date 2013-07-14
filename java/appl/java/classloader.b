implement JavaClassLoader;

#
#	Java Class Loader.
#

include "sys.m";
	sys:	Sys;

stderr:	ref Sys->FD;

include "keyring.m";
	kr:	Keyring;

include "string.m";
	str:    String;

include "math.m";
	math:	Math;

include "hash.m";
	hash:	Hash;

include "loader.m";
include "classloader.m";
	ld:		Loader;
	Niladt:		import Loader;
	jassist:	JavaAssist;
	jtrace:		JavaTrace;

	JDEBUG, JVERBOSE:	import JavaTrace;

	getint, getintarray, getptr:		import jassist;
	getreloc, getrtreloc, getstring:	import jassist;
	getclassadt, getabsint, getadtstring:	import jassist;
	getbytearray, getstrarray, arrayof:	import jassist;
	getmd, putclass, putint, putmod:	import jassist;
	putobj, putptr, putstring, makeadt:	import jassist;
	bytearraytoJS, intarraytoJS:		import jassist;
	bigarraytoJS, realarraytoJS:		import jassist;
	ArraytoJS, JStoObject:			import jassist;

this:		JavaClassLoader;
thisnil:	Nilmod;
sysnil:		Nilmod;
loadlinks:	array of Loader->Link;
syslinks:	array of Loader->Link;
relocs:		list of ref Class;
relocd:		list of ref Class;
interf:		list of ref Class;
interfx:	list of ref Class;
initcl:		list of ref Class;
main:		ref Class;
arrayclass:	ref Class;
arraymd:	ref Loader->Niladt;
stringclass:	ref Class;
fsindir:	int;
cur:		string;

interfaces:	array of ref Class;
ninterfaces:	int = 0;
linterfaces:	int = 0;

INITINTER:	con 32;

acqchan:	chan of int;
relchan:	chan of int;
exitchan:	chan of int;

MSHUTDOWN, MENTER, MEXIT, MWAIT, MNOTIFY, MSLEEP, MINTERRUPT, MTIMER, MSYNC:
		con iota;

monitorctl:	chan of (int, ref ThreadData, ref Object, int);
threadctl:	chan of (ref ThreadData, int);

threadcount:	int = 0;
daemoncount:	int = 0;
stopped:	int = 0;

ident:		con "ClassLoader";
warn:		int = 1;
debug:		int = 0;
verbose:	int = 0;
errors:		int = 0;

# for generating ClassLoader exceptions use
# the following con's.  They will be turned
# into a corresponding Java Exception by 
# sysexcetion
# when thrown the format is:
# raise( ex +":"+detail );
# see loaderror();
#
# NOTE: the "raise" string has limited size
#       hence the "e"+<int>
#
JCLDREX       : con "JLD:";   #prefix
noclassdeffound,
classcircularity,
classformat,
nosuchmethod,
nosuchfield,
unsatisfiedlink,
linkageerr,
exceptionininitializer
	          : con "e" + (string iota);

badcallindex  : con "call index";
nocloneindex  : con "clone index";

encoding :=	array[] of
{
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
	'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
	'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
	'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
	'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
	'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
	'w', 'x', 'y', 'z', '0', '1', '2', '3',
	'4', '5', '6', '7', '8', '9', '+', '-',
};

bits :=		array[] of { 16r80, 16r40, 16r20, 16r10, 16r08, 16r04, 16r02, 16r01 };
mbits :=	array[] of { 16r80, 16r20, 16r08, 16r02 };

#
#	Diagnostics.
#

mesg(s: string)
{
	sys->fprint(stderr, "%s: %s\n", ident, s);
}

diag(s: string)
{
	if (cur != nil)
		s = cur + ": " + s;
	mesg(s);
	errors++;
}

loaderror( ex : string, msg : string )
{
	s := msg;

	# if prefix exists then just rethrow msg
	if ( str->prefix( JCLDREX+ex, msg ) == 0 )
	{
		if ( cur != nil )
			s = cur +": " + s;

		s = sys->sprint( "%s%s:%s", JCLDREX, ex, s );
	}

	trace(JDEBUG,s);

	raise s;
}

error(s: string)
{
	if ( s == nil )
		s = JCLDREX + "fatal error";
	else
	{
		# if prefix exists then just re-throw s
		if ( str->prefix(JCLDREX,s) == 0 )
		{
			# add prefix to tag as a Loader ex
			s = sys->sprint( "%s%s:%s", JCLDREX, s, cur );
		}
	}

	trace(JDEBUG,s);

	raise s;
}

warning(s: string)
{
	if (!warn)
		return;
	if (cur != nil)
		s = cur + ": " + s;
	sys->fprint(stderr, "%s: warning: %s\n", ident, s);
}

trace(c: int, s: string)
{
	if (jtrace != nil)
		jtrace->trace(c, s);
}

loadtrace()
{
	if (jtrace != nil)
		return;
	jtrace = load JavaTrace JavaTrace->PATH;
	if (jtrace == nil)
		error(sys->sprint("could not load %s: %r", JavaTrace->PATH));
	jtrace->init(jassist);
}

#
#	Load synchronization.  Allow only one thread to be loading at a time.
#

loadsync()
{
	for (;;) {
		alt {
		<- acqchan =>
			;
		<- exitchan =>
			return;
		}
		alt {
		<- relchan =>
			;
		<- exitchan =>
			return;
		}
	}
}

acquire()
{
	acqchan <-= 0;
}

release()
{
	relchan <-= 0;
}

context: ref Draw->Context;

#
#	Initialize loader.  Entry.
#
init(j: JavaClassLoader, ctxt: ref Draw->Context)
{
	sys = load Sys Sys->PATH;
	stderr = sys->fildes(2);
	context = ctxt;
	kr = load Keyring Keyring->PATH;
	if (kr == nil)
		error(sys->sprint("could not load %s: %r", Keyring->PATH));
	str = load String String->PATH;
	if (str == nil)
		error(sys->sprint("could not load %s: %r", String->PATH));
	math = load Math Math->PATH;
	if (math == nil)
		error(sys->sprint("could not load %s: %r", Math->PATH));
	math->FPcontrol(0, Math->INVAL|Math->ZDIV|Math->OVFL|Math->UNFL|Math->INEX);
	hash = load Hash Hash->PATH;
	if (hash == nil)
		error(sys->sprint("could not load %s: %r", Hash->PATH));
	ld = load Loader Loader->PATH;
	if (ld == nil)
		error(sys->sprint("could not load %s: %r", Loader->PATH));
	jassist = load JavaAssist JavaAssist->PATH;
	if (jassist == nil)
		error(sys->sprint("could not load %s: %r", JavaAssist->PATH));
	if (verbose) {
		loadtrace();
		if (debug)
			jtrace->level = JDEBUG;
		else
			jtrace->level = JVERBOSE;
	}
	fsindir = jassist->little_endian();
	this = j;
	thisnil = jassist->jclnilmod(j);
	sysnil = jassist->sysnilmod(sys);
	loadlinks = ld->link(thisnil);
	syslinks = ld->link(sysnil);
	if (loadlinks == nil || syslinks == nil)
		error(sys->sprint("Loader->link failed: %r"));
	initloadhash();
	acqchan = chan of int;
	relchan = chan of int;
	exitchan = chan of int;
	spawn loadsync();
	monitorctl = chan of (int, ref ThreadData, ref Object, int);
	spawn monitor();
	threadctl = chan of (ref ThreadData, int);
	spawn threadmanager();
	jniinit();
}

loadarrayclass()
{
	arrayclass = loader(ARRAYCLASS);
	arraymd = arrayclass.moddata;
}

loadstringclass()
{
	stringclass = loader(STRINGCLASS);
}

#
#	Native interface initialization.
#
jniinit()
{
	j := load JavaNative JavaNative->PATH;
	if (j == nil)
		error(sys->sprint("could not load %s: %r", JavaNative->PATH));
	e := j->init(sys, ld, this, jassist);
	if (e != nil)
		error(sys->sprint("JavaNative->init failed: %s", e));
}

#
#	Shutdown loader.  Entry.
#
shutdown()
{
	if (exitchan != nil) {
		exitchan <-= 0;
		exitchan = nil;
	}
	if (monitorctl != nil) {
		monitorctl <-= (MSHUTDOWN, nil, nil, 0);
		monitorctl = nil;
	}
	if (threadctl != nil) {
		threadctl <-= (nil, ThreadData.SHUTDOWN);
		threadctl = nil;
	}
}

#
#	Load a class and print information about it.
#	Does not resolve the class and should not be
#	called in the execution environment.  Entry.
#
info(name: string)
{
	c := getclass(name);
	if (c.state == NEW)
		c.loadclass();
	loadtrace();
	jtrace->info(c);
}

#
#	Perform outstanding relocation on loaded classes.
#
doreloc()
{
	#
	#	Load classes we need for relocation.
	#
	while (relocs != nil) {
		r: list of ref Class;
		r = nil;
		reloc := hd relocs;
		relocs = tl relocs;
		trace(JDEBUG, sys->sprint("reloc %s", reloc.name));
		i := CLASSREF;
		while ((s := getstring(reloc.mod, i)) != nil) {
			if (s != LOADER)
				r = loadhierarchy(s) :: r;
			else
				r = nil :: r;
			i += 2 * WORDZ;
		}
		reloc.refs = mkclarray(r);
		reloc.relocate();
		relocd = reloc :: relocd;
	}
	#
	#	Patch the module data of the relocated classes.
	#
	while (relocd != nil) {
		patch := hd relocd;
		relocd = tl relocd;
		trace(JDEBUG, sys->sprint("modpatch %s", patch.name));
		patch.modpatch();
		if (patch.native != nil || patch.classinit != nil) {
			initcl = patch :: initcl;
			patch.state = LOADED;
		} else
			patch.state = INITED;
	}
	#
	#	Extend interfaces.
	#
	while (interfx != nil) {
		extend := hd interfx;
		interfx = tl interfx;
		extend.interdirect = extend.interextends;
		extend.extinterfaces();
	}
	#
	#	Make interface linkage tables for classes that implement interfaces.
	#
	while (interf != nil) {
		inter := hd interf;
		interf = tl interf;
		inter.interdirect = inter.interextends;
		inter.linkinterfaces();
	}
	#
	#	Call class initializers.
	#
	initc : ref Class;
	t     : ref ThreadData;

	{
		while (initcl != nil) {
			initc = hd initcl;
			initcl = tl initcl;
			initc.state = INITED;
			trace(JVERBOSE, sys->sprint("Switching class %s state to INITED", initc.name));
			t = getthreaddata();
			release();
			unblock(t);
			if (initc.native != nil)
				initc.initjni();
			if (initc.classinit != nil) {
				trace(JVERBOSE, sys->sprint("%s-><clinit>()", initc.name));
				jassist->mcall0(initc.mod, initc.classinit.value);
				trace(JDEBUG, sys->sprint("clinit done"));
			}
			block(t);
			acquire();
		}
	}
	exception e
	{
		"*disabled" =>
			#NOTE: a raise is only expected from the init calls therefore
			#      when we reach here we need to block and acquire
			block(t);
			acquire();
			trace(JVERBOSE, sys->sprint("Some exception: %s", e));
			raise e;
			if ( str->prefix(JCLDREX+exceptionininitializer, e ) == 1 )
				loaderror(exceptionininitializer, e ); #rethrow
			else			
			{
				# clear any java exception; we are replacing it
				t.culprit = nil;
				loaderror(exceptionininitializer, sys->sprint("%s[unk]", initc.name));
			}
	}
}

#
#	Main "load class" routine.  Load a class hierarchy and
#	its dependencies and prepare it for use.  Entry.
#	No return on error.
#
loader(name: string): ref Class
{
	released := 0;
	t := getthreaddata();
	{
		trace(JDEBUG, sys->sprint("load class %s", name));
		block(t);
		acquire();
		c := loadhierarchy(name);
		if (relocs != nil)
			doreloc();
		release();
		unblock(t);
		released = 1;
		trace(JDEBUG, sys->sprint("loader() exit"));
#		if (errors)
#			error(nil);
		return c;
	}
	exception e
	{
		"*disabled" =>
			if(released == 0) {
				release();
				unblock(t);
			}
			if (e == nil)
				e = "exit";
			
			if ( str->prefix(JCLDREX, e) == 1 )
				error(e);
			
			error( sys->sprint( "%s", e) );
			
			#else if (e.name == noclassdeffound)
			#{		
			#	error(nil);
			#}
			#else
			#	error(sys->sprint("loader exception: %s: %s: %d", e.mod, e.name, e.pc));
	}
	return nil;
}

#
#	Recursively load a hierarchy.
#
loadhierarchy(name: string): ref Class
{
	c := getclass(name);
	case c.state {
	NEW =>
		trace(JVERBOSE, sys->sprint("[%s]", name));
		c.loadclass();
		relocs = c :: relocs;
		if ((s := getstring(c.mod, SUPER)) != nil) {
			c.state = HIER;
			trace(JVERBOSE, sys->sprint("Switching class %s state to HIER", name));
			c.super = loadhierarchy(s);
		} else
			c.super = nil;
		c.state = RESOLVE;
		trace(JVERBOSE, sys->sprint("Switching class %s state to RESOLVE", name));
		c.resolve();
		c.loadinterfaces();
	HIER =>
		loaderror( classcircularity, name );
	}
	return c;
}

#
#   Check if a string matches exception,
#   right aligned in string
#
matches(str, e: string): int
{
	if (len str >= len e && str[len str - len e:] == e)
		return 1;
	return 0;
}

#
#	Encode a class name path if its final component
#	will be too long.  Entry.
#
encodename(name: string): string
{
	(dir, base) := str->splitr(name, "/");
	b := array of byte base;
	if (len b <= MAXUNENCODED)
		return name;
	d := array[kr->MD5dlen] of byte;
	if (kr->md5(b, len b, d, nil) == nil)
		error(sys->sprint("md5 failed: %r"));
	e := array[ENCODEDLEN] of byte;
	v := 0;
	n := 0;
	r := 0;
	for (i := 0; i < ENCODEDLEN; i++) {
		if (r < 6) {
			v |= int d[n++] << r;
			r += 8;
		}
		e[i] = byte encoding[v & 16r3F];
		v >>= 6;
		r -= 6;
	}
	return dir + string e;
}

##
##	Runtime entries.
##

#
#	Runtime load.  Passed a pointer into a module's data of a rtload table.
#
rtload(addr: int)
{
	trace(JVERBOSE, sys->sprint("rtload start"));
	o := getabsint(addr + RTTHISOFFSET);
	r := getabsint(addr - (o + WORDZ));
	l := o + r;
	d := makeadt(addr - l);
	s := getadtstring(d, l + RTCLASSOFFSET);
	a := getrtreloc(d, l + RTRELOCOFFSET);
	t := getclassadt(d, CLASSADTOFFSET);
	trace(JVERBOSE, sys->sprint("rtload %s [%d -> %d] for %s", s, o, r, t.name));
	if (t.state != INITED)
		error("this not loaded");
	c := loader(s);
	cur = c.name;
	putmod(d, l, c.mod);
	putmod(d, l + RTCLASSOFFSET, c.native);
	putclass(d, l + RTRELOCOFFSET, c);
	putint(d, l + RTTHISOFFSET, c.objtype);
	o = l + RTFIRSTRELOC;
	n := len a;
	for (i := 0; i < n; i++) {
		if ((a[i].flags & Rmask) == Rinvokespecial) {
			(w, m, x) := t.special(a[i].field, a[i].signature, a[i].flags, c);
			if (a[i].flags & Rspecialmp) {
				if (w == CMP)
					putmod(d, o, m.mod);
				else if (w == CNP)
					putmod(d, o, m.native);
				else
					error("bad special");
			} else
				putint(d, o, x);
		} else {
			(w, v) := c.resolvereloc(a[i].field, a[i].signature, a[i].flags);
			case w {
			VVAL =>
				putint(d, o, v);
			VMP =>
				putmod(d, o, c.mod);
			VNP =>
				putmod(d, o, c.native);
			VOBJ =>
				putobj(d, o, c.this);
			* =>
				error("bad resolve");
			}
		}
		o += WORDZ;
	}
	cur = nil;
	trace(JVERBOSE, sys->sprint("rtload end"));
#	if (errors)
#		error("rtload failed");
}

#
#	Get a Class adt by name.  Used internally and made visible.
#	It does no loading so should only be called if you know
#	the class is loaded (or are loading it).
#

CHSZ:		con 31;
classhash :=	array[CHSZ] of list of ref Class;

getclass(name: string): ref Class
{
	h := classhash[hash->fun1(name, CHSZ):];
	for (l := h[0]; l != nil; l = tl l) {
		c := hd l;
		if (c.name == name)
			return c;
	}
	c := ref Class;
	c.state = NEW;
	trace(JVERBOSE, sys->sprint("Switching class %s state to NEW", name));
	c.name = name;
	c.flags = 0;
	c.info = ref Ldinfo;
	h[0] = c :: h[0];
	return c;
}

#
#	Map a module to its class.  This works for native modules too.
#

MHSZ:		con 31;
modhash :=	array[MHSZ] of list of (Nilmod, ref Class);

addmodclass(m: Nilmod, c: ref Class)
{
	h := modhash[jassist->modhash(m) % MHSZ:];
	h[0] = (m, c) :: h[0];
}

getmodclass(m: Nilmod): ref Class
{
	for (l := modhash[jassist->modhash(m) % MHSZ]; l != nil; l = tl l) {
		(t, c) := hd l;
		if (t == m)
			return c;
	}
	return nil;
}

#
#	Thread data.
#

THSZ:		con 31;
threadhash :=	array[THSZ] of list of ref ThreadData;

getpid(): int
{
	return sys->pctl(0, nil);
}

getcontext(): ref Draw->Context
{
	return context;
}

getthreaddata(): ref ThreadData
{
	p := getpid();
	for (l := threadhash[p % THSZ]; l != nil; l = tl l) {
		t := hd l;
		if (t.pid == p)
			return t;
	}
	acquire();
	h := threadhash[p % THSZ:];
	d := ref ThreadData;
	d.pid = p;
	d.wchan = chan of int;
	d.flags = 0;
	h[0] = d :: h[0];
	threadcount++;
	trace(JVERBOSE, sys->sprint("count = %d + %d", threadcount, daemoncount));
	release();
	return d;
}

delthreaddata()
{
	n: list of ref ThreadData;
	acquire();
	p := getpid();
	h := threadhash[p % THSZ:];
	for (l := h[0]; l != nil; l = tl l) {
		t := hd l;
		if (t.pid == p) {
			if (t.flags & ThreadData.DAEMON)
				daemoncount--;
			else
				threadcount--;
		} else
			n = t :: n;
	}
	h[0] = n;
	trace(JVERBOSE, sys->sprint("count = %d + %d", threadcount, daemoncount));
	if (threadcount == 0)
		nothreads(nil);
	else
		release();
}

#
#	Mark current thread a daemon.  Entry.
#
daemonize()
{
	t := getthreaddata();
	acquire();
	if ((t.flags & ThreadData.DAEMON) == 0) {
		t.flags |= ThreadData.DAEMON;
		daemoncount++;
		threadcount--;
	}
	trace(JVERBOSE, sys->sprint("count = %d + %d", threadcount, daemoncount));
	if (threadcount == 0)
		nothreads(t);
	else
		release();
}

#
#	Stop all threads.  When all are dead we will shutdown.
#
stopthreads(t: ref ThreadData)
{
	for (i := 0; i < THSZ; i++)
		for (l := threadhash[i]; l != nil; l = tl l) {
			s := hd l;
			if (s != t)
				stop(s, nil);
		}
	stopped = 1;
}

#
#	No non-daemon threads.  Maybe clean up, maybe shutdown.
#
nothreads(t: ref ThreadData)
{
	if (!stopped)
		stopthreads(t);
	if (daemoncount != 0) {
		release();
		if (t != nil) {
			t.culprit = threaddeath().new();
			raise JAVAEXCEPTION;
		}
		return;
	}
	release();
	shutdown();
}

#
#	Entry for system.exit().
#
system_exit()
{
	t := getthreaddata();
	acquire();
	stopthreads(t);
	release();
	t.culprit = threaddeath().new();
	raise JAVAEXCEPTION;
}

cmd_start:	array of byte;
cmd_stop:	array of byte;
cmd_kill:	array of byte;
cmd_failed:	int = 0;
tdclass:	ref Class;

ctlfile(t: ref ThreadData)
{
	if (t.ctlfile == nil)
		t.ctlfile = PROG + "/" + string t.pid + "/dbgctl";
}

threaddeath(): ref Class
{
	if (tdclass == nil)
		tdclass = loader(EXCEPTIONPATH + "ThreadDeath");
	return tdclass;
}

dosuspend(t: ref ThreadData)
{
	ctlfile(t);
	f := sys->open(t.ctlfile, Sys->ORDWR);
	monsync();
	t.flags |= ThreadData.SUSPENDED;
	if (f == nil) {
		if (!cmd_failed) {
			warning(sys->sprint("could not open %s: %r", t.ctlfile));
			cmd_failed = 1;
		}
	} else {
		sys->write(f, cmd_stop, len cmd_stop);
		t.control = f;
	}
}

doresume(t: ref ThreadData)
{
	if (t.control != nil) {
		sys->write(t.control, cmd_start, len cmd_start);
		t.control = nil;
	}
	monsync();
	t.flags &= ~ThreadData.SUSPENDED;
	if (t.flags & ThreadData.ACKSUSP) {
		t.wchan <-= MONOK;
		t.flags &= ~ThreadData.ACKSUSP;
	}
}

dostop(t: ref ThreadData)
{
	ctlfile(t);
	f := sys->open(t.ctlfile, Sys->ORDWR);
	if (f == nil) {
		if (!cmd_failed) {
			warning(sys->sprint("could not open %s: %r", t.ctlfile));
			cmd_failed = 1;
		}
	} else
		sys->write(f, cmd_kill, len cmd_kill);
}

#
#	The thread manager looks after suspend and resume.
#	A thread that cannot be suspended enters a block()/unblock()
#	pair for the duration of its critical region.
#

threadmanager()
{
	cmd_start = array of byte "start";
	cmd_stop = array of byte "stop";
	cmd_kill = array of byte "maim";
	for (;;) {
		(t, c) := <- threadctl;
		if (t != nil && (t.flags & ThreadData.EXITED)) {
			t = nil;
			continue;
		}
		case c {
		ThreadData.SHUTDOWN =>
			return;
		ThreadData.BLOCK =>
			t.flags |= ThreadData.BLOCKED;
		ThreadData.UNBLOCK =>
			if (t.flags & ThreadData.WAITSTOP)
				dostop(t);
			else if (t.flags & ThreadData.WAITSUSP)
				dosuspend(t);
			t.flags &= ~(ThreadData.BLOCKED | ThreadData.WAITSTOP | ThreadData.WAITSUSP);
		ThreadData.SUSPEND =>
			if ((t.flags & ThreadData.SUSPENDED) == 0) {
				if (t.flags & ThreadData.BLOCKED)
					t.flags |= ThreadData.WAITSUSP;
				else
					dosuspend(t);
			}
		ThreadData.RESUME =>
			if (t.flags & ThreadData.SUSPENDED)
				doresume(t);
			else
				t.flags &= ~ThreadData.WAITSUSP;
		ThreadData.STOP =>
			if (t.flags & ThreadData.BLOCKED)
				t.flags |= ThreadData.WAITSTOP;
			else
				dostop(t);
		* =>
			threadctl = nil;
			raise "bad threadctl command"; #error("bad threadctl command");
		}
		t = nil;
	}
}

block(t: ref ThreadData)
{
	threadctl <-= (t, ThreadData.BLOCK);
}

unblock(t: ref ThreadData)
{
	threadctl <-= (t, ThreadData.UNBLOCK);
}

suspend(t: ref ThreadData)
{
	threadctl <-= (t, ThreadData.SUSPEND);
}

resume(t: ref ThreadData)
{
	threadctl <-= (t, ThreadData.RESUME);
}

stop(t: ref ThreadData, o: ref Object)
{
	if (o == nil)
		o = threaddeath().new();
	t.culprit = o;
	threadctl <-= (t, ThreadData.STOP);
}

#
#	Exceptions.
#

mkexception( name : string ) : ref Object
{
	return(loader(EXCEPTIONPATH + name).new());
}

# convert an Inferno exception into a Java Exception
sysexception( e : string ) : ref Object
{
	s   : string;
	msg : string;


	if ( e == nil )
	{
		s   = "InternalError";
		msg = "unknown";
	}
	else if ( str->prefix(JCLDREX,e) == 1 )
	{
		trace(JDEBUG, sys->sprint("sysexception: / %s /", e));
		# try to convert JavaClassLoader exceptions first
		rest := e[len JCLDREX:];  #strip off prefix
		
		# pull the possible java ex name; save the rest as a message
		ex : string;
		(ex,msg) = str->splitl(rest, ":");

		# convert to coresponding Java Exception, if any
		case ex
		{
			noclassdeffound        => s = "NoClassDefFoundError";
			nosuchmethod           => s = "NoSuchMethodError";
			classcircularity       => s = "ClassCircularityError";
			classformat            => s = "ClassFormatError";
			unsatisfiedlink        => s = "UnsatisfiedLinkError";
			exceptionininitializer => s = "ExceptionInInitializerError";
			linkageerr             => s = "LinkageError";  #different then '*'

			# if none found then make into a generic LinkageError
			*                 => s   = "LinkageError";
			                     msg = rest;
		}
	}
	else 
	{	
		trace(JDEBUG, sys->sprint("sysexception: / %s /", e));
		case e
		{
			#
			# inferno system exceptions
			#
			"zero divide" or
			"invalid math argument" or
			"Floating point exception" or
			"Integer Overflow" or
			"Divide by Zero" or
			"Floating Point Divide by Zero" or
			"Inexact Floating Point" or
			"Invalid Floating Operation" or
			"Floating Point Result Overflow" or
			"Floating Point Stack Check" or 
			"Floating Point Result Underflow" =>
				s = "ArithmeticException";
			"heap full" or
			"no memory" =>
				s = "OutOfMemoryError";
			"array bounds error" or
			"Array Bounds Check" =>
				s = "ArrayIndexOutOfBoundsException";
			"negative array size" =>
				s = "NegativeArraySizeException";
			"dereference of nil" or
			"Segmentation violation" or
			"Bus error" =>
				s = "NullPointerException";
			"Stack Overflow" =>
				s = "StackOverflowError";
			* =>
				s = "InternalError";
		}

		# fill throwable object with information from inferno ex
		#msg = sys->sprint( "%s[%d]:%s", e.mod, e.pc, e.name );
	}

	obj := mkexception(s);   #create Java Ex object


	# set the detailed message
	throwable := jassist->ObjecttoJT(obj);
	if (stringclass == nil)
		loadstringclass();
	throwable.msg = ref JavaString(stringclass.moddata, msg);

	return( obj );
}

culprit(e: string): ref Object
{
	thd := getthreaddata();

	if ( thd.culprit == nil || e != JAVAEXCEPTION )
	{
		# no java exception -- turn an inferno
		# exception into a Java Exception
		thd.culprit = sysexception(e);
	}

	return( thd.culprit );
}

throw(c: ref Object)
{
	getthreaddata().culprit = c;
	raise JAVAEXCEPTION;
}

sthrow(s: string)
{
	throw(mkexception(s));
}

#
#	Monitors.
#

MONOK, MONILL, MONINT:
	con iota;

Synch: adt
{
	thread:	ref ThreadData;
	count:	int;
	status:	int;
	next:	cyclic ref Synch;
};

Monitor: adt
{
	thread:	ref ThreadData;
	object:	ref Object;
	count:	int;
	head:	ref Synch;
	tail:	ref Synch;
};

Waiter: adt
{
	thread:	ref ThreadData;
	object:	ref Object;
	count:	int;
	time:	int;
	next:	cyclic ref Waiter;
};

sleepers:	ref Waiter;
waiters:	ref Waiter;
timeout:	int;

MAXSLEEP:	con 1000;
SLEEPTOL:	con 50;

MONHSZ:		con 31;
monhash :=	array[MONHSZ] of list of ref Monitor;

getmonitor(o: ref Object): ref Monitor
{
	z: ref Monitor;
	h := monhash[jassist->objhash(o) % MONHSZ:];
	for (l := h[0]; l != nil; l = tl l) {
		m := hd l;
		if (m.object == o)
			return m;
		if (m.count == 0)
			z = m;
	}
	if (z == nil) {
		z = ref Monitor;
		z.count = 0;
		h[0] = z :: h[0];
	}
	z.object = o;
	return z;
}

#
#	Timer thread.
#
timer(t: int)
{
	s := t - sys->millisec();
	if (s > 0)
		sys->sleep(s);
	if(monitorctl != nil)
		monitorctl <-= (MTIMER, nil, nil, t);
}

#
#	Wait to be interrupted, notified or for timeout to expire.
#
waiter(w: ref Waiter)
{
	w.thread.flags &= ~ThreadData.INTERRUPTED;
	s := w.time;
	if (s == 0) {
		w.next = waiters.next;
		waiters.next = w;
	} else {
		t := sys->millisec();
		w.time += t;
		if (sleepers.next == nil) {
			sleepers.next = w;
			if (s > MAXSLEEP)
				s = MAXSLEEP;
			timeout = t + s;
			spawn timer(timeout);
		} else if (w.time >= sleepers.next.time) {
			h := sleepers.next;
			while (h.next != nil && w.time > h.next.time)
				h = h.next;
			w.next = h.next;
			h.next = w;
		} else {
			w.next = sleepers.next;
			sleepers.next = w;
			if (w.time < timeout - SLEEPTOL) {
				timeout = w.time;
				spawn timer(timeout);
			}
		}
	}
}

#
#	Respond to timer.
#
dotimer(t: int)
{
	c := sys->millisec();
	n := t;
	if (t < c)
		n = c;
	n += SLEEPTOL;
	w := sleepers;
	while ((l := w.next) != nil && l.time <= n) {
		w.next = l.next;
		mondone(l, MONOK);
	}
	if (t == timeout && l != nil) {
		timeout = l.time;
		if (timeout - c > MAXSLEEP)
			timeout = c + MAXSLEEP;
		spawn timer(timeout);
	}
}

#
#	Notify.
#

donotifyl(w: ref Waiter, o: ref Object): ref Waiter
{
	while ((l := w.next) != nil) {
		if (l.object == o) {
			w.next = l.next;
			return l;
		}
		else
			w = l;
	}
	return nil;
}

donotify(o: ref Object)
{
	if ((l := donotifyl(waiters, o)) != nil || (l = donotifyl(sleepers, o)) != nil)
		mondone(l, MONOK);
}

#
#	Notify all.
#

donotifyalll(w: ref Waiter, o: ref Object)
{
	while ((t := w.next) != nil) {
		if (t.object == o) {
			w.next = t.next;
			mondone(t, MONOK);
		} else
			w = t;
	}
}

donotifyall(o: ref Object)
{
	donotifyalll(waiters, o);
	donotifyalll(sleepers, o);
}

#
#	Interrupt.
#

dointerruptl(w: ref Waiter, t: ref ThreadData): ref Waiter
{
	while ((l := w.next) != nil) {
		if (l.thread == t) {
			w.next = l.next;
			return l;
		}
		else
			w = l;
	}
	return nil;
}

dointerrupt(t: ref ThreadData)
{
	if ((l := dointerruptl(waiters, t)) != nil || (l = dointerruptl(sleepers, t)) != nil) {
		l.thread.flags |= ThreadData.INTERRUPTED;
		mondone(l, MONINT);
	}
}

#
#	Enter or reenter a monitor.
#
doenter(t: ref ThreadData, o: ref Object, n: int, s: int)
{
	m := getmonitor(o);
	if (m.count == 0) {
		m.thread = t;
		m.count = n;
	} else if (m.thread == t)
		m.count += n;
	else {
		w := ref Synch;
		w.thread = t;
		w.count = n;
		w.status = s;
		if (m.tail == nil) {
			m.head = w;
			m.tail = w;
		} else {
			m.tail.next = w;
			m.tail = w;
		}
		return ;
	}
	for (;;) {
		alt {
		t.wchan <-= s =>
			return;
		* =>
			if (t.flags & ThreadData.SUSPENDED) {
				t.flags |= ThreadData.ACKSUSP;
				return;
			}
			sys->sleep(0);
		}
	}
}

#
#	A sleeper or waiter is done.
#
mondone(w: ref Waiter, s: int)
{
	if (w.object != nil)
		doenter(w.thread, w.object, w.count, s);
	else
		w.thread.wchan <-= s;
}

#
#	Concede monitor to next synchronizer.
#
monitornext(m: ref Monitor)
{
	h := m.head;
	if (h != nil) {
		x := h.next;
		m.head = x;
		if (x == nil)
			m.tail = nil;
		m.thread = h.thread;
		m.count = h.count;
		m.thread.wchan <-= h.status;
	} else {
		m.thread = nil;
		m.object = nil;
		m.count = 0;
	}
}

#
#	Monitor thread.
#
monitor()
{
	m: ref Monitor;
	sleepers = ref Waiter;
	waiters = ref Waiter;
	for (;;) {
		(c, t, o, n) := <- monitorctl;
		case c {
		MSHUTDOWN =>
			return;
		MSYNC =>
			sys->sleep(0);
		MENTER =>
			doenter(t, o, n, MONOK);
		MEXIT =>
			m = getmonitor(o);
			if (m.count == 0)
				raise "mexit inbalance"; #error("mexit inbalance");
			if (m.thread != t)
				raise "mexit mismatch"; #error("mexit mismatch");
			m.count--;
			if (m.count == 0)
				monitornext(m);
		MWAIT =>
			m = getmonitor(o);
			if (m.count == 0 || m.thread != t) {
				t.wchan <-= MONILL;
				break;
			}
			waiter(ref Waiter(t, o, m.count, n, nil));
			monitornext(m);
		MNOTIFY =>
			m = getmonitor(o);
			if (m.count == 0 || m.thread != t) {
				t.wchan <-= MONILL;
				break;
			}
			if (n)
				donotifyall(o);
			else
				donotify(o);
			t.wchan <-= MONOK;
		MSLEEP =>
			waiter(ref Waiter(t, nil, 0, n, nil));
		MINTERRUPT =>
			dointerrupt(t);
		MTIMER =>
			dotimer(n);
		* =>
			monitorctl = nil;
			raise "bad monitorctl command"; #error("bad monitorctl command");
		}
		t = nil;
		o = nil;
		m = nil;
	}
}

#
#	Common resume code.
#
monitorresume(d: ref ThreadData)
{
	case <- d.wchan {
	MONILL =>
		unblock(d);
		sthrow("IllegalMonitorStateException");
	MONINT =>
		unblock(d);
		sthrow("InterruptedException");
	}
	unblock(d);
}

#
#	Monitor / thread control entries.
#

monitorenter(o: ref Object)
{
	if ( o == nil )
		sthrow("NullPointerException");
	d := getthreaddata();
	if (monitorctl != nil) {
		monitorctl <-= (MENTER, d, o, 1);
		<- d.wchan;
	}
}

monitorexit(o: ref Object)
{
	if ( o == nil )
		sthrow("NullPointerException");
	d := getthreaddata();
	if (monitorctl != nil)
		monitorctl <-= (MEXIT, d, o, 0);
}

monitorwait(o: ref Object, l: int)
{
	if ( o == nil )
		sthrow("NullPointerException");
	d := getthreaddata();
	if (monitorctl != nil) {
		block(d);
		monitorctl <-= (MWAIT, d, o, l);
		monitorresume(d);
	}
}

monitornotify(o: ref Object, f: int)
{
	if ( o == nil )
		sthrow("NullPointerException");
	d := getthreaddata();
	if (monitorctl != nil) {
		block(d);
		monitorctl <-= (MNOTIFY, d, o, f);
		monitorresume(d);
	}
}

monsync()
{
	monitorctl <-= (MSYNC, nil, nil, 0);
}

sleep(l: int)
{
	if (l <= 100) {
		sys->sleep(l);
		return;
	}
	d := getthreaddata();
	if (monitorctl != nil) {
		block(d);
		monitorctl <-= (MSLEEP, d, nil, l);
		monitorresume(d);
	}
}

interrupt(t: ref ThreadData)
{
	d := getthreaddata();
	if (monitorctl != nil) {
		block(d);
		monitorctl <-= (MINTERRUPT, t, nil, 0);
		unblock(d);
	}
}

#
#	Get Class object for the class
#
getclassclass(caller: string, class: string): ref Object
{
	c := getclass(caller);
	if (c == nil)
		sthrow("NullPointerException");

	trace(JDEBUG, sys->sprint("Getclassclass called, %s asked for class %s", c.name, class));

	# TODO: put those strings in header
	# Prepare necessary classes
	if (stringclass == nil)
		loadstringclass();
	cc := getclass("java/lang/Class");
	if (cc == nil)
		sthrow("NullPointerException");
	f := cc.findsmethod("forName", "(Ljava/lang/String;)Ljava/lang/Class;");
	if (f == nil)
		error(sys->sprint("%s: %s: missing forName0 in Class", nosuchmethod, cc.name));
	result := cc.call(f.value, JStoObject(ref JavaString(stringclass.moddata, class)));

	trace(JDEBUG, sys->sprint("forName0 returned something, i think, %d", result != nil));

	return result;
}

#
#	Runtime hierarchy/type check routines.
#

compatclass(who, what: ref Class): int
{
	if ((what.flags & ACC_INTERFACE) && (who.flags & ACC_INTERFACE) == 0)
		return who.getinterface(what) != nil;
	do {
		if (who == what)
			return 1;
		who = who.super;
	} while (who != nil);
	return 0;
}

checkcast(who: ref Object, what: ref Class)
{
	if (who != nil && !instanceof(who, what))
		sthrow("ClassCastException");
}

instanceof(who: ref Object, what: ref Class): int
{
	if (who == nil)
		return 0;
	return compatclass(who.class(), what);
}

acheckcast(who: ref Array, what: ref Class, dims: int)
{
	if (who != nil && !ainstanceof(who, what, dims))
		sthrow("ClassCastException");
}

ainstanceof(who: ref Array, what: ref Class, dims: int): int
{
	if (who == nil)
		return 0;
	if (arrayclass == nil)
		loadarrayclass();
	if (who.mod != arraymd)
		return 0;
	# is 'what' Object[]... ?
	if (who.dims > dims && what.super == nil && (what.flags & ACC_INTERFACE) == 0)
		return 1;
	if (who.dims != dims || who.class == nil)
		return 0;
	return compatclass(who.class, what);
}

pcheckcast(who: ref Array, what, dims: int)
{
	if (who != nil && !pinstanceof(who, what, dims))
		sthrow("ClassCastException");
}

pinstanceof(who: ref Array, what, dims: int): int
{
	if (who == nil)
		return 0;
	if (arrayclass == nil)
		loadarrayclass();
	if (who.mod != arraymd || who.dims != dims || who.class != nil)
		return 0;
	return who.primitive == what;
}

aastoreinstanceof(who: ref Object, what: ref Array): int
{
	if (arrayclass == nil)
		loadarrayclass();
	if (what.mod != arraymd)
		return 0;
	if (what.dims == 1) {
		if (what.class == nil)
			return 0;
		if (who == nil)
			return 1;
		return compatclass(who.class(), what.class);
	} else {
		if (who == nil)
			return 1;
		if (who.class() != arrayclass)
			return 0;
		a := arrayof(who);
		if (a.dims != what.dims - 1)
			return 0;
		if (a.class == nil)
			return what.class == nil && a.primitive == what.primitive;
		if (what.class == nil)
			return 0;
		return compatclass(a.class, what.class);
	}
}

aastorecheck(who: ref Object, what: ref Array)
{
	if (what == nil)
		sthrow("NullPointerException");
	if (!aastoreinstanceof(who, what))
		sthrow("ArrayStoreException");
}

multianewarray(ndim: int, c: ref Class, etype: int, bounds: array of int): ref Array
{
	n := bounds[0];
	if (n < 0)
		sthrow("NegativeArraySizeException");
	if (arrayclass == nil)
		loadarrayclass();
	a := ref Array(arraymd, nil, ndim, c, etype);
	if (etype == 0 || ndim > 1)
		a.holder = array[n] of ref JavaString;
	else {
		case etype {
		T_BOOLEAN or T_BYTE =>
			a.holder = bytearraytoJS(array[n] of byte);
		T_CHAR or T_SHORT or T_INT =>
			a.holder = intarraytoJS(array[n] of int);
		T_LONG =>
			a.holder = bigarraytoJS(array[n] of big);
		T_FLOAT or T_DOUBLE =>
			a.holder = realarraytoJS(array[n] of real);
		}
	}
	if (len bounds > 1) {
		for (i := 0; i < n; i++)
			a.holder[i] = ArraytoJS(multianewarray(ndim - 1, c, etype, bounds[1:]));
	}
	return a;
}

arraycopy(src: ref Array, sx: int, dst: ref Array, dx: int, n: int)
{
	trace(JDEBUG, sys->sprint("Arraycopy called: src[%d], dst[%d], %d, %d, %d", len src.holder, len dst.holder, sx, dx, n));
	if (arrayclass == nil)
		loadarrayclass();
	if (src == nil || dst == nil)
		sthrow("NullPointerException");
	if (src.mod != arraymd || dst.mod != arraymd)
		sthrow("ArrayStoreException");
	sa := src.holder;
	if (src.dims == dst.dims) {
		if (src.class == nil) {
			if (dst.class != nil || src.primitive != dst.primitive)
				sthrow("ArrayStoreException");
		} else {
			if (dst.class == nil)
				sthrow("ArrayStoreException");
			if (src.class != dst.class && !compatclass(src.class, dst.class))
				for (i := 0; i < n; i++)
					if (!aastoreinstanceof(JStoObject(sa[sx + i]), dst))
						sthrow("ArrayStoreException");
		}
	} else if (dst.class == nil || dst.class.super != nil || dst.dims > src.dims)
		sthrow("ArrayStoreException");
	if (sx < 0 || dx < 0 || n < 0 || sx + n > len src.holder || dx + n > len dst.holder || sx > 2147483647 - n || dx > 2147483647 - n)
		sthrow("ArrayIndexOutOfBoundsException");
	dst.holder[dx:] = sa[sx:sx + n];
	trace(JDEBUG, "Arraycopy completed successfully");
}

#
#	Map a class and a interface cookie to a methodtable entry.
#
getinterface(c: ref Class, cookie: int) : int
{
	x := cookie >> 16;
	t := cookie & 16rFFFF;
	if (x >= ninterfaces)
		error("bad interface number");
	k := interfaces[x];
	m := c.getinterface(k);
	if (m == nil)
		error(sys->sprint("class %s does not implement interface %s", c.name, k.name));
	if (t >= len m)
		error("bad interface index");
	return m[t];
}

#
#	Math.
#

lcmp(x, y: big): int
{
	if(x < y)
		return -1;
	if(x == y)
		return 0;
	return 1;
}

truncate(x: real): real
{
	if (x < 0.0)
		x = math->ceil(x);
	else
		x = math->floor(x);
	return x;
}

d2i(x: real): int
{
	return int truncate(x);
}

d2l(x: real): big
{
	return big truncate(x);
}

dcmpg(x, y: real): int
{
	if (math->isnan(x) || math->isnan(y) || x > y)
		return 1;
	if (x == y)
		return 0;
	return -1;
}

dcmpl(x, y: real): int
{
	if (math->isnan(x) || math->isnan(y) || x < y)
		return -1;
	if (x == y)
		return 0;
	return 1;
}

drem(x, y: real): real
{
	if (math->isnan(x) || math->isnan(y) || !math->finite(x) || y == 0.0)
		return math->NaN;
	if ((math->finite(x) && !math->finite(y)) || (x == 0.0 && math->finite(y)))
		return x;
	return math->fmod(x, y);
}

#
#	Class entries.
#

Class.run(c: self ref Class, args: list of string)
{
	m := c.findsmethod(MAINFIELD, MAINSIGNATURE);
	if (m == nil)
		loaderror( nosuchmethod, sys->sprint("%s: missing static method main", c.name));
	main = c;
	if (arrayclass == nil)
		loadarrayclass();
	if (stringclass == nil)
		loadstringclass();
	n := len args;
	h := array[n] of ref JavaString;
	d := stringclass.moddata;
	for (i := 0; i < n; i++) {
		h[i] = ref JavaString(d, hd args);
		args = tl args;
	}
	getthreaddata();
	r := jassist->mcalla(c.mod, m.value, ref Array(arraymd, h, 1, stringclass, 0));
	delthreaddata();
}


Class.new(c: self ref Class): ref Object
{
	o := jassist->new(c.mod, c.objtype);
	o.mod = c.moddata;
	f := findasig(c.initmethods, VOIDSIGNATURE);
	if (f == nil)
		error(sys->sprint("%s: %s: missing constructor", nosuchmethod, c.name));
	c.call(f.value, o);
	return o;
}

Class.call(c: self ref Class, x: int, a: ref Object): ref Object
{
	if (x < 0 || x >= c.mlinks)
		raise badcallindex;
	return jassist->mcall1(c.mod, x, a);
}

Class.clone(c: self ref Class, o: ref Object): ref Object
{
	if (c.cloneindex < 0)
		raise nocloneindex;
	return jassist->mcall1(c.mod, c.cloneindex, o);
}

#
#	Class private methods.
#

#
#	Load a class file.
#
Class.loadclass(c: self ref Class)
{
	c.encoding = encodename(c.name);
	f := c.encoding + ".dis";
	m := load Nilmod f;
	if (m == nil) {
		e := sys->sprint("%r");
		if (!matches(e, EXIST))
			error(f + ": " + e);
		f = ROOT + f;
		m = load Nilmod f;
		if (m == nil) {
			e = sys->sprint("%r");
			m : string;
			if (!matches(e, EXIST))
				m = f + ": " + e;
			else
				m = c.name + ": class not found";
			loaderror(noclassdeffound, m);
		}
	}
	trace(JDEBUG, sys->sprint("\"%s\"", f));
	c.file = f;
	c.mod = m;
	if (getint(m, MAGIC) != JAVA)
		loaderror(classformat, f + ": bad magic number");
	c.version = getint(m, VERSION) & 16rFF;
	if (c.version != SUXV)
		loaderror(classformat, f + ": incompatible version (rerun j2d)");
	c.ownname = getstring(m, NAME);
	if (c.ownname != c.name && encodename(c.ownname) != c.name)
		warning("class file " + f + ": inconsistent classname: " + c.ownname);
}

#
#	The bulk of the work for loading a class is done here.
#	This is the essentially the first (resolution) pass.
#
Class.resolve(c: self ref Class)
{
	od, vm, pm, sd, sm, im: list of ref Field;
	oz, vz, sz: int;
	cur = c.name;
	c.info.links = ld->link(c.mod);
	if (c.info.links == nil)
		error(sys->sprint("link failed: %r"));
	c.mlinks = len c.info.links;
	c.info.types = ld->tdesc(c.mod);
	if (c.info.types == nil)
		error(sys->sprint("tdesc failed: %r"));
	c.objtype = len c.info.types;
	c.cloneindex = -1;
	if (c.super != nil) {
		od = c.super.objectdata;
		vz = len c.super.virtualmethods;
		oz = c.super.objectsize;
	} else {
		od = nil;
		vz = 0;
		oz = WORDZ;
	}
	vm = nil;
	pm = nil;
	sd = nil;
	sm = nil;
	im = nil;
	sz = 0;
	r := getreloc(c.mod, RELOC);
	n := len r;
	p := array[n] of Patch;
	e := 0;
	for (i := 0; i < n; i++) {
		s := r[i].field;
		if (s[0] != '@')
			break;
		case s {
		CLASS =>
			p[i].what = PVALUE;
			p[i].value = c.objtype;
			c.flags = r[i].flags;
		MP or NP or ADT or OBJ =>
			p[i].what = PEXTRA;
			p[i].value = e++;
		JEX =>
			error("@jex not in @Loader");
		SYS =>
			error("@sys not in @Loader");
		}
	}
	for (; i < n; i++) {
		t := r[i];
		if (isdata(t.signature)) {
			if (isspecial(t.field))
				error(sys->sprint("unknown special data: %s", t.field));
			else if (isstatic(t.flags)) {
				trace(JDEBUG, sys->sprint("%s: static data", t.field));
				sz = alignto(sz, t.signature);
				p[i].what = PSTATIC;
				p[i].value = sz;
				f := ref Field(t.field, t.signature, t.flags, sz);
				sz += sizeof(t.signature);
				sd = f :: sd;
			} else {
				superfield: ref Field;
				if (c.super != nil)
					superfield = c.super.findofield(t.field);
				if (superfield != nil) {
					trace(JDEBUG, sys->sprint("%s: superclass data", t.field));
					p[i].what = PVALUE;
					p[i].value = superfield.value;
					continue;
				}
				trace(JDEBUG, sys->sprint("%s: new data", t.field));
				oz = alignto(oz, t.signature);
				p[i].what = PVALUE;
				p[i].value = oz;
				f := ref Field(t.field, t.signature, t.flags, oz);
				od = f :: od;
				oz += sizeof(t.signature);
			}
		} else {
			if (isspecial(t.field)) {
				s := t.field;
				case s {
				SPECIALINIT =>
					if (isstatic(t.flags))
						error("<init> static");
					x := c.getmethod(s, t.signature, t.flags);
					if (t.flags & Rspecialmp) {
						p[i].what = PEXTRA;
						p[i].value = e++;
					} else {
						p[i].what = PVALUE;
						p[i].value = x;
					}
					if (findsig(im, t.signature) == nil)
						im = ref Field(s, t.signature, t.flags, x) :: im;
				SPECIALCLINIT or SPECIALCLONE =>
					if (!isstatic(t.flags))
						error(s + " not static");
					if (t.patch != nil)
						error(s + " patches");
					if (t.signature != VOIDSIGNATURE)
						error(s + " bad signature");
					if (isnative(t.flags))
						error(s + " is native");
					x := c.getmethod(s, t.signature, t.flags);
					if (s == SPECIALCLINIT)
						c.classinit = ref Field(s, t.signature, t.flags, x);
					else
						c.cloneindex = x;
					p[i].what = PVALUE;
					p[i].value = x;
				* =>
					error(sys->sprint("unknown special: %s", s));
				}
			} else if (isvirtual(t.flags)) {
				f := findfs(vm, t.field, t.signature);
				if (f == nil) {
					x := c.override(t.field, t.signature);
					if (x < 0) {
						trace(JDEBUG, sys->sprint("%s: new method", t.field));
						x = vz++;
					} else {
						trace(JDEBUG, sys->sprint("%s: overriden method", t.field));
					}
					f = ref Field(t.field, t.signature, t.flags, x);
					vm = f :: vm;
				}
				if (t.flags & Rspecialmp) {
					p[i].what = PVALUE;
					p[i].value = e++;
				} else {
					p[i].what = PMETHOD;
					p[i].value = f.value;
				}
			} else {
				trace(JDEBUG, sys->sprint("%s: static method", t.field));
				x := c.getmethod(t.field, t.signature, t.flags);
				f := ref Field(t.field, t.signature, t.flags, x);
				p[i].what = PVALUE;
				p[i].value = x;
				if (isstatic(t.flags)) {
					trace(JDEBUG, sys->sprint("%s: static method", t.field));
					sm = f :: sm;
				} else {
					trace(JDEBUG, sys->sprint("%s: private method", t.field));
					pm = f :: pm;
				}
			}
		}
	}
	if (c.flags & ACC_INTERFACE)
		c.addinterface();
	c.info.reloc = p;
	c.objectdata = od;
	c.virtualmethods = c.makevmtable(vm, vz);
	c.staticdata = mkfdarray(sd);
	c.staticmethods = mkfdarray(sm);
	c.privatemethods = mkfdarray(pm);
	c.initmethods = mkfdarray(im);
	c.objectsize = alignto(oz, nil);
	c.staticsize = alignto(sz, nil);
	c.info.extrabase = e;
	cur = nil;
}

#
#	Make a type for a class object.
#
Class.makeobjtype(c: self ref Class)
{
	z := ((c.objectsize / WORDZ) + 7) / 8;
	m := array[z] of byte;
	m[0] = byte 16r80;
	for (i := 1; i < z; i++)
		m[i] = byte 0;
	for (l := c.objectdata; l != nil; l = tl l) {
		f := hd l;
		if (ispointer(f.signature)) {
			v := f.value / WORDZ;
			x := v / 8;
			m[x] = byte ((int m[x]) | bits[v & 7]);
		}
	}
	c.objmap = m;
	if (ld->tnew(c.mod, c.objectsize, c.objmap) != c.objtype)
		error("objtype mismatch");
}

#
#	Make a virtual method table from that of the superclass
#	and the overriden and new entries.
#
Class.makevmtable(c: self ref Class, m: list of ref Field, z: int): array of Method
{
	trace(JDEBUG, sys->sprint("Makevmtable for %s, %d", c.name, z));
	t := array[z] of Method;
	if (c.super != nil) {
		s := c.super.virtualmethods;
		n := len s;
		for (i := 0; i < n; i++) {
			trace(JDEBUG, sys->sprint("Makevmtable adding super method %s", s[i].field.field + s[i].field.signature));
			t[i] = s[i];
		}
	}
	while (m != nil) {
		f := hd m;
		n := f.value;
		trace(JDEBUG, sys->sprint("Makevmtable checking %s %d %d", f.field + f.signature, n, f.flags));
		{
			f.value = c.getmethod(f.field, f.signature, f.flags);
		}
		exception e {
			JCLDREX + nosuchmethod + "*" =>
				# TODO: check if we really have it in superclass vmtable
				m = tl m;
				continue;
		}
		t[n].field = f;
		t[n].class = c;
		m = tl m;
	}
	return t;
}

#
#	Load the interfaces implemented by a class.
#
Class.loadinterfaces(c: self ref Class)
{
	s := getstrarray(c.mod, INTERFACES);
	if (s == nil)
		return;
	n := len s;
	trace(JDEBUG, sys->sprint("inter %s %d", c.name, n));
	l: list of ref Class;
	for (i := 0; i < n; i++)
		l = loadhierarchy(s[i]) :: l;
	c.interextends = l;
	if (c.flags & ACC_INTERFACE) {
		c.flags |= JCL_INTEREXT;
		interfx = c :: interfx;
	} else
		interf = c :: interf;
}

#
#	Add a class to a list.
#
addclass(c: ref Class, n: list of ref Class): list of ref Class
{
	for (l := n; l != nil; l = tl l)
		if (hd l == c)
			return n;
	return c :: n;
}

#
#	Extend list of interfaces.
#
interext(l: list of ref Class): list of ref Class
{
	n: list of ref Class;
	while (l != nil) {
		c := hd l;
		n = addclass(c, n);
		for (x := c.interextends; x != nil; x = tl x)
			n = addclass(hd x, n);
		l = tl l;
	}
	return n;
}

#
#	Extend (transitively) an interface.
#
intertrans(c: ref Class, n: list of ref Class): list of ref Class
{
	if (c.flags & JCL_INTERWORK)
		error("circular interface extension"); #ClassCircularityError ??
	n = addclass(c, n);
	c.extinterfaces();
	for (l := c.interextends; l != nil; l = tl l)
		n = addclass(hd l, n);
	return n;
}

#
#	Extend interfaces.
#
Class.extinterfaces(c: self ref Class)
{
	if ((c.flags & JCL_INTEREXT) == 0)
		return;
	c.flags |= JCL_INTERWORK;
	n: list of ref Class;
	for (l := c.interextends; l != nil; l = tl l)
		n = intertrans(hd l, n);
	c.interextends = n;
	c.flags &= ~(JCL_INTEREXT | JCL_INTERWORK);
}

#
#	Resolve the implementation of a class' interfaces.
#
Class.linkinterfaces(c: self ref Class)
{
	cur = c.name;
	l := interext(c.interextends);
	n := len l;
	a := array[n] of Interface;
	c.interfaces = a;
	for (i := 0; i < n; i++) {
		s := hd l;
		l = tl l;
		a[i].class = s;
		if ((s.flags & ACC_INTERFACE) == 0)
			loaderror(linkageerr, sys->sprint("%s not an interface", s.name));
		v := s.virtualmethods;
		m := len v;
		o := array[m] of int;
		a[i].methods = o;
		for (j := 0; j < m; j++) {
			f := v[j].field;
			x := findmfsx(c.virtualmethods, f.field, f.signature);
			if (x < 0)
				loaderror( nosuchmethod, sys->sprint("method %s'%s' of interface %s not implemented", 
				                                   f.field, f.signature, s.name));
			else
				o[j] = (METHODOFFSET + x * 2) * WORDZ;
		}
	}
	cur = nil;
}

#
#	This is the second pass of class loading.  All classes needed for
#	relocation have been resolved.
#
Class.relocate(c: self ref Class)
{
	cur = c.name;
	trace(JDEBUG, sys->sprint("relocate(%s) enter", c.name));
	#
	#	Count extra entries (e.g. @mp and @adt).
	#
	n := nextra(getreloc(c.mod, RELOC));
	i := CLASSREF;
	while ((s := getstring(c.mod, i)) != nil) {
		n += nextra(getreloc(c.mod, i + WORDZ));
		i += 2 * WORDZ;
	}
	c.dataoffset = (i + 4 + 31) & ~31;
	c.nextra = n;
	#
	#	Record extras.
	#
	c.info.extras = array[n] of Extra;
	n = c.extras(getreloc(c.mod, RELOC), 0, c);
	j := 0;
	i = CLASSREF;
	while ((s = getstring(c.mod, i)) != nil) {
		n = c.extras(getreloc(c.mod, i + WORDZ), n, c.refs[j]);
		i += 2 * WORDZ;
		j++;
	}
	#
	#	Determine size of new module data.
	#
	v := len c.virtualmethods;
	z := METHODOFFSET * WORDZ + v * 2 * WORDZ + c.staticsize + c.nextra * WORDZ + WORDZ;
	c.datareloc = (z + 31) & ~31;
	c.datasize = getint(c.mod, DSIZE);
	c.modsize = c.datareloc + c.datasize;
	z = ((c.modsize / WORDZ) + 7) / 8;
	m := array[z] of byte;
	#
	#	Create type map for module.
	#
	c.modmap = m;
	#
	#	First two entries are nil and ref Class adt.
	#
	m[0] = byte 16rC0;
	for (i = 1; i < z; i++)
		m[i] = byte 0;
	#
	#	Method table.
	#
	for (i = 1; i <= v; i++) {
		x := i / 4;
		m[x] = byte ((int m[x]) | mbits[i & 3]);
	}
	o := METHODOFFSET + v * 2;
	#
	#	Static data.
	#
	c.staticoffset = o * WORDZ;
	d := c.staticdata;
	for (i = 0; i < len d; i++) {
		f := d[i];
		if (ispointer(f.signature)) {
			w := o + (f.value / WORDZ);
			x := w / 8;
			m[x] = byte ((int m[x]) | bits[w & 7]);
		}
	}
	o += c.staticsize / WORDZ;
	#
	#	Extra data.
	#
	c.info.extraoffset = o * WORDZ;
	for (i = 0; i < c.nextra; i++) {
		x := o / 8;
		m[x] = byte ((int m[x]) | bits[o & 7]);
		o++;
	}
	#
	#	Copy class module data and its map.
	#
	if (c.datasize > 0) {
		if (c.datasize + c.dataoffset > c.info.types[0].size) {
			error("bad data size/offset");
			c.datasize = 0;
		} else
			c.copymap(c.info.types[0].map, c.dataoffset);
	}
	trace(JDEBUG, sys->sprint("%s data %d reloc %d", c.name, c.modsize, c.datareloc));
	trace(JDEBUG, sys->sprint("\t%d bytes at %d", c.datasize, c.dataoffset));
	md := ld->dnew(c.modsize, c.modmap);
	if (md == nil)
		error(sys->sprint("dnew failed: %r"));
	c.moddata = md;
	c.this = ref ClassObject(nil, c, nil);
	#
	#	Fetch the instruction stream and patch it.
	#
	instructions := ld->ifetch(c.mod);
	if (instructions == nil)
		error(sys->sprint("ifetch failed: %r"));
	c.instrpatch(instructions);
	trace(JDEBUG, sys->sprint("\t%d instrs", len instructions));
	#
	#	Make the new module.
	#
	links := c.info.links;
	oldmod := c.mod;
	c.mod = ld->newmod(c.name, STACKSIZE, len links, instructions, md);
	if (c.mod == nil)
		error(sys->sprint("newmod failed: %r"));
	addmodclass(c.mod, c);
	#
	#	Install the new types.
	#
	types := c.info.types;
	for (i = 1; i < len types; i++) {
		if (ld->tnew(c.mod, types[i].size, types[i].map) != i)
			error(sys->sprint("tnew failed: %r"));
	}
	#
	#	Install the links.
	#
	for (i = 0; i < len links; i++) {
		trace(JDEBUG, sys->sprint("link %d pc %d tdesc %d name %s",
			i, links[i].pc, links[i].tdesc, links[i].name));
		if (ld->ext(c.mod, i, links[i].pc, links[i].tdesc) < 0) 
			error(sys->sprint("ext failed: %r"));
	}
	#
	#	This word is used by rtload.
	#
	putint(md, c.datareloc - WORDZ, c.datareloc);
	if (c.datasize > 0)
		c.copymd(md, c.dataoffset, oldmod);
	c.makeobjtype();
	trace(JDEBUG, sys->sprint("relocate(%s) exit", c.name));
	cur = nil;
}

#
#	Instruction patching.
#
Class.instrpatch(c: self ref Class, inst: array of Loader->Inst)
{
	#
	#	A class' own relocations were determined in resolve.
	#
	r := getreloc(c.mod, RELOC);
	p := c.info.reloc;
	x := c.info.extraoffset;
	n := len r;
	for (i := 0; i < n; i++) {
		v: int;
		case p[i].what {
		PVALUE =>
			v = p[i].value;
		PEXTRA =>
			v = x + p[i].value * WORDZ;
		PMETHOD =>
			v = (METHODOFFSET + p[i].value * 2) * WORDZ;
		PSTATIC =>
			v = c.staticoffset + p[i].value;
		* =>
			error("bad Patch");
		}
		ipatch(inst, r[i].patch, v);
	}
	x += c.info.extrabase * WORDZ;
	#
	#	Data relocation.
	#
	ipatch(inst, getbytearray(c.mod, DRELOC), c.datareloc);
	#
	#	Patching for referenced classes (and @Loader).
	#
	j := 0;
	i = CLASSREF;
	while ((s := getstring(c.mod, i)) != nil) {
		k := c.refs[j];
		if (k != nil)
			x = k.relocref(c, inst, getreloc(c.mod, i + WORDZ), x);
		else
			x = relocloader(inst, getreloc(c.mod, i + WORDZ), x);
		i += 2 * WORDZ;
		j++;
	}
}

#
#	Third pass of class loader.  All referenced classes
#	have had new modules allocated.
#
Class.modpatch(c: self ref Class)
{
	cur = c.name;
	d := c.moddata;
	putclass(d, CLASSADTOFFSET, c);
	v := c.virtualmethods;
	n := len v;
	o := METHODOFFSET * WORDZ;
	for (i := 0; i < n; i++) {
		m := v[i];
		if (isnative(m.field.flags))
			putmod(d, o, m.class.native);
		else
			putmod(d, o, m.class.mod);
		putint(d, o + WORDZ, m.field.value);
		o += 2 * WORDZ;
	}
	x := c.info.extras;
	n = len x;
	o = c.info.extraoffset;
	for (i = 0; i < n; i++) {
		e := x[i];
		case e.what {
		CMP =>
			if (e.class == nil)
				putmod(d, o, thisnil);
			else
				putmod(d, o, e.class.mod);
		CADT =>
			putclass(d, o, e.class);
		CNP =>
			putmod(d, o, e.class.native);
		COBJ =>
			putobj(d, o, e.class.this);
		CJEX =>
			putstring(d, o, JAVAEXCEPTION);
		CSYS =>
			putmod(d, o, sysnil);
		* =>
			error("bad extra what");
		}
		o += WORDZ;
	}
	trace(JDEBUG, sys->sprint("compile %s", c.name));
	if ((c.flags & DONTCOMPILE) == 0) {
		if (ld->compile(c.mod, c.flags & MUSTCOMPILE) < 0)
			error(sys->sprint("compile %s failed: %r", c.name));
		if (c.native != nil) {
			trace(JDEBUG, sys->sprint("compile native %s", c.name));
			if (ld->compile(c.native, c.flags & MUSTCOMPILE) < 0)
				error(sys->sprint("compile native %s failed: %r", c.name));
		}
	}
	cur = nil;
}

#
#	Resolution routines.
#

#
#	Check for method override.
#
Class.override(c: self ref Class, f, s: string): int
{
	if (c.super == nil)
		return -1;
	m := c.super.virtualmethods;
	n := len m;
	for (i := 0; i < n; i++) {
		t := m[i].field;
		if (t.field == f && t.signature == s)
			return i;
	}
	return -1;
}

#
#	Find init method.
#
Class.findimethod(c: self ref Class, s: string): ref Field
{
	return findasig(c.initmethods, s);
}

#
#	Find private method.
#
Class.findpmethod(c: self ref Class, f, s: string): ref Field
{
	return findafs(c.privatemethods, f, s);
}

#
#	Find static field.
#
Class.findsfield(c: self ref Class, f: string): ref Field
{
	return findafield(c.staticdata, f);
}

#
#	Find static method.
#
Class.findsmethod(c: self ref Class, f, s: string): ref Field
{
	return findafs(c.staticmethods, f, s);
}

#
#	Find object field.
#
Class.findofield(c: self ref Class, f: string): ref Field
{
	return findfield(c.objectdata, f);
}

#
#	Find virtual method.
#
Class.findvmethod(c: self ref Class, f, s: string): int
{
	a := c.virtualmethods;
	n := len a;
	for (i := 0; i < n; i++) {
		t := a[i].field;
		if (t.field == f && t.signature == s)
			return i;
	}
	trace(JDEBUG, "returned fail");
	return -1;
}

Class.loadnative(c: self ref Class)
{
	native := ROOT + c.encoding + "_L.dis";
	mod := load Nilmod native;
	if (mod == nil) {
		trace(JVERBOSE, sys->sprint("Load native failed: %r"));
		return;
	}
	trace(JDEBUG, sys->sprint("\"%s\"", native));
	links := ld->link(mod);
	if (links == nil)
		error(sys->sprint("%s: native Loader->link failed: %r", unsatisfiedlink));
	c.info.nlinks = links;
	types := ld->tdesc(mod);
	if (types == nil)
		error(sys->sprint("%s: native tdesc failed: %r",unsatisfiedlink));
	instrs := ld->ifetch(mod);
	if (instrs == nil)
		error(sys->sprint("%s: native ifetch failed: %r",unsatisfiedlink));
	imports := ld->imports(mod);

	nm := ld->newmod("N-" + c.name, STACKSIZE, len links, instrs, getmd(mod));
	if (nm == nil)
		error(sys->sprint("%s: native newmod failed: %r",unsatisfiedlink));

	n := len types;
	for (i := 1; i < n; i++) {
		if (ld->tnew(nm, types[i].size, types[i].map) != i)
			error(sys->sprint("%s: native tnew failed: %r",unsatisfiedlink));
	}
	n = len links;
	for (i = 0; i < n; i++) {
		if (ld->ext(nm, i, links[i].pc, links[i].tdesc) < 0)
			error(sys->sprint("%s: native ext failed: %r",unsatisfiedlink));
	}
	if (ld->setimports(nm, imports) < 0)
		error(sys->sprint("%s: native setimports failed: %r",unsatisfiedlink));
	addmodclass(nm, c);
	c.native = nm;
}

#
#	Search the links for a method.  Maybe load the native module.
#
Class.getmethod(c: self ref Class, f, s: string, flags: int): int
{
	trace(JDEBUG, sys->sprint("Getmethod of %s: %s, %s, %d", c.name, f, s, flags));
	l: array of Loader->Link;
	m: string;
	if (isnative(flags)) {
		if (c.native == nil)
			c.loadnative();
		l = c.info.nlinks;
		m = mangle(f, s);
		trace(JDEBUG, sys->sprint("Mangled native name: %s", m));
	} else {
		l = c.info.links;
		m = f + s;
	}
	n := len l;
	for (i := 0; i < n; i++) {
		if (l[i].name == m)
			return i;
	}
	if (flags & ACC_NATIVE)
		trace(JDEBUG, sys->sprint("Native method %s not found in %s", m, c.name));
	if (!(flags & (ACC_ABSTRACT | ACC_NATIVE)))
	{
		loaderror( nosuchmethod, sys->sprint("method %x %s '%s' %s not found", flags, f, s, m) );
	}
	return -1;
}

#
#	Find method called with invokespecial.
#
Class.special(c: self ref Class, f, s: string, flags: int, r: ref Class): (int, ref Class, int)
{
	if (f == SPECIALINIT) {
		i := findasig(r.initmethods, s);
		if (i == nil)
			error(sys->sprint("%s: <init> '%s' not found in class %s", nosuchmethod, s, r.name));
		return (CMP, r, i.value);
	} else if (isprivate(flags)) {
		p := findafs(r.privatemethods, f, s);
		if (p == nil)
			error("invokespecial private botch");
		if (isnative(p.flags))
			return (CNP, r, p.value);
		else
			return (CMP, r, p.value);
	} else {
		r = c.super;
		if (r == nil)
			error("invokespecial super botch");
		i := r.findvmethod(f, s);
		if (i < 0)
			error("invokespecial botch");
		m := r.virtualmethods[i];
		if (isnative(m.field.flags))
			return (CNP, m.class, m.field.value);
		else
			return (CMP, m.class, m.field.value);
	}
}

#
#	Record info for an extra.
#
Class.extra(c: self ref Class, w, n: int, r: ref Class)
{
	c.info.extras[n].what = w;
	c.info.extras[n].class = r;
}

#
#	Record info for extras.
#
Class.extras(c: self ref Class, a: array of Reloc, n: int, r: ref Class): int
{
	l := len a;
	for (i := 0; i < l; i++) {
		f := a[i].field;
		if (f[0] != '@')
			break;
		case f {
		MP =>
			c.extra(CMP, n, r);
		ADT =>
			c.extra(CADT, n, r);
		NP =>
			c.extra(CNP, n, r);
		OBJ =>
			c.extra(COBJ, n, r);
		JEX =>
			if (r != nil)
				error("@jex not in @Loader");
			c.extra(CJEX, n, nil);
		SYS =>
			if (r != nil)
				error("@sys not in @Loader");
			c.extra(CSYS, n, nil);
		CLASS =>
			n--;
		* =>
			error(sys->sprint("unknown reloc: %s", f));
		}
		n++;
	}
	for (; i < l; i++) {
		if (a[i].flags & Rspecialmp) {
			if ((a[i].flags & Rmask) != Rinvokespecial)
				error("bad Rspecialmp");
			(v, s, nil) := c.special(a[i].field, a[i].signature, a[i].flags, r);
			c.extra(v, n, s);
			n++;
		}
	}
	return n;
}

#
#	Count the extra data fields need for a Reloc.
#
nextra(a: array of Reloc): int
{
	n := 0;
	l := len a;
	for (i := 0; i < l; i++) {
		f := a[i].field;
		if (f[0] != '@')
			break;
		case f {
		MP or NP or ADT or OBJ or JEX or SYS =>
			n++;
		}
	}
	for (; i < l; i++) {
		if (a[i].flags & Rspecialmp)
			n++;
	}
	return n;
}

#
#	Copy old module map corresponding to module data to new map.
#
Class.copymap(c: self ref Class, om: array of byte, dr: int)
{
	nm := c.modmap;
	s := dr / MAPZ;
	d := c.datareloc / MAPZ;
	while (d < len nm) {
		if (s < len om)
			nm[d] = om[s];
		else
			nm[d] = byte 0;
		s++;
		d++;
	}
}

#
#	Copy old module data to new module data.
#
Class.copymd(c: self ref Class, md: ref Niladt, dr: int, om: Nilmod)
{
	m := c.modmap;
	s := dr;
	d := c.datareloc;
	for (i := 0; i <  c.datasize; i+= WORDZ) {
		w := d  / WORDZ;
		if ((int m[w / 8] & bits[w & 7]) != 0)
			putptr(md, d, getptr(om, s));
		else
			putint(md, d, getint(om, s));
		d += WORDZ;
		s += WORDZ;
	}
}

#
#	Resolve a relocation for a referenced class.
#
Class.resolvereloc(c: self ref Class, r, s: string, flags: int): (int, int)
{
	v: int;
	f: ref Field;
	case flags & Rmask {
	Rgetputfield =>
		f = c.findofield(r);
		if (f == nil)
			loaderror(nosuchfield, sys->sprint("%s not resolved in class %s", r, c.name));
		else {
			if (f.signature != s) {
				loaderror(nosuchfield, sys->sprint("%s type mismatch in class %s:%s vs %s", r, c.name, f.signature, s));
			}
			v = f.value;
		}
	Rgetputstatic =>
		f = c.findsfield(r);
		if (f == nil)
			loaderror( nosuchfield, sys->sprint("static %s not found in class %s", r, c.name));
		else {
			if (f.signature != s) {
				loaderror(nosuchfield, sys->sprint("%s static type mismatch in class %s:%s vs %s", r, c.name, f.signature, s));
			}
			v = c.staticoffset + f.value;
		}
	Rinvokeinterface =>
		if ((c.flags & ACC_INTERFACE) == 0) {
			loaderror(linkageerr, sys->sprint("%s is not an interface", c.name));
			break;
		}
		v = findmfsx(c.virtualmethods, r, s);
		if (v < 0)
			loaderror( nosuchmethod, sys->sprint("interface method %s '%s' not found in class %s", r, s, c.name));
		v |= c.interindex << 16;
	Rinvokespecial =>
		error("Rinvokespecial botch");
	Rinvokestatic =>
		f = c.findsmethod(r, s);
		if (f == nil)
			loaderror( nosuchmethod, sys->sprint("static method %s '%s' not found in class %s", r, s, c.name));
		else if (flags & Rstaticmp) {
			if (f.flags & ACC_NATIVE)
				return (VNP, 0);
			else
				return (VMP, 0);
		} else
			v = f.value;
	Rinvokevirtual =>
		v = c.findvmethod(r, s);
		if (v < 0)
			loaderror( nosuchmethod, sys->sprint("method %s '%s' not resolved in class %s", r, s, c.name));
		v = (METHODOFFSET + v * 2) * WORDZ;
	* =>
		if (r == OBJ)
			return (VOBJ, 0);
		error(sys->sprint("%s: bad Rmask", c.name));
	}
	return (VVAL, v);
}

#
#	Perform relocation for a referenced class.
#
Class.relocref(c: self ref Class, t: ref Class, inst: array of Loader->Inst, a: array of Reloc, x: int): int
{
	v, w: int;
	mp := -1;
	np := -1;
	n := len a;
	for (i := 0; i < n; i++) {
		f := a[i].field;
		if (f[0] != '@')
			break;
		case f {
		MP =>
			if (mp >= 0)
				error("repeat @mp");
			mp = x;
			v = x;
			x += WORDZ;
		NP =>
			if (np >= 0)
				error("repeat @np");
			np = x;
			v = x;
			x += WORDZ;
		ADT =>
			v = x;
			x += WORDZ;
		OBJ =>
			v = x;
			x += WORDZ;
		JEX =>
			error("@jex not in @Loader");
		SYS =>
			error("@sys not in @Loader");
		CLASS =>
			v = c.objtype;
		* =>
			error("@botch");
		}
		ipatch(inst, a[i].patch, v);
	}
	for (; i < n; i++) {
		if ((a[i].flags & Rmask) == Rinvokespecial) {
			if (a[i].flags & Rspecialmp) {
				v = x;
				x += WORDZ;
			} else
				(nil, nil, v) = t.special(a[i].field, a[i].signature, a[i].flags, c);
		} else {
			(w, v) = c.resolvereloc(a[i].field, a[i].signature, a[i].flags);
			if (w == VMP) {
				if (mp < 0)
					error("no @mp for Rstaticmp");
				v = mp;
			} else if (w == VNP) {
				if (np < 0)
					error("no @np for Rstaticmp");
				v = np;
			}
		}
		ipatch(inst, a[i].patch, v);
	}
	return x;
}

#
#	Record an interface and assign it an ordinal.
#
Class.addinterface(c: self ref Class)
{
	if (ninterfaces == linterfaces) {
		if (ninterfaces == 0) {
			linterfaces = INITINTER;
			interfaces = array[INITINTER] of ref Class;
		} else {
			n := linterfaces * 3 / 2;
			a := array[n] of ref Class;
			for (i := 0; i < linterfaces; i++)
				a[i] = interfaces[i];
			linterfaces = n;
			interfaces = a;
		}
	}
	c.interindex = ninterfaces;
	interfaces[ninterfaces++] = c;
}

#
#	Search for an interface implementation.
#
Class.interlook(c: self ref Class, a: array of Interface): array of int
{
	if (a == nil)
		return nil;
	n := len a;
	for (i := 0; i < n; i++) {
		d := a[i].class;
		do {
			if (d == c)
				return a[i].methods;
			d = d.super;
		} while (d != nil);
	}
	return nil;
}

#
#	Fetch interface table, possibly cached.
#
Class.getinterface(c: self ref Class, k: ref Class): array of int
{
	for (l := c.intercache; l != nil; l = tl l) {
		(d, m) := hd l;
		if (d == k)
			return m;
	}
	m: array of int;
	d := c;
	do {
		m = k.interlook(d.interfaces);
		d = d.super;
	} while (m == nil && d != nil);
	if (m != nil) {
		c.intercache = (k, m) :: c.intercache;
		return m;
	}
	return nil;
}

#
#	Call native module init function.
#
Class.initjni(c: self ref Class)
{
	trace(JVERBOSE, sys->sprint("%s->init()", c.name));
	l := c.info.nlinks;
	n := len l;
	for (i := 0; i < n; i++) {
		if (l[i].name == "init") {
			if (l[i].sig != jnisig)
				error(sys->sprint("init typecheck in class %s native", c.name));
			jassist->mcallm(c.native, i, jninil);
			trace(JDEBUG, "done");
			return;
		}
	}
	error(sys->sprint("no init function in class %s native", c.name));
}

#
#	@Loader relocation.
#
relocloader(inst: array of Loader->Inst, a: array of Reloc, x: int): int
{
	v: int;
	n := len a;
	for (i := 0; i < n; i++) {
		r := a[i].field;
		case r {
		MP or JEX or SYS =>
			v = x;
			x += WORDZ;
		CLASS =>
			error("@Loader @Class");
		ADT =>
			error("@Loader @adt");
		NP =>
			error("@Loader @np");
		OBJ =>
			error("@Loader @obj");
		* =>
			v = getloader(r);
			if (v < 0)
				error(sys->sprint("no ClassLoader/Sys entry %s", r));
		}
		ipatch(inst, a[i].patch, v);
	}
	return x;
}

#
#	@Loader and @Sys entries.
#	This uses a magic hash which maps each loadkey to a unique index.
#	If you add a loadkey you will need new magic.
#

LDHASH: con 38;

LoadMap: adt
{
	name:	string;
	value:	int;
};

loadtable := array[LDHASH] of LoadMap;

loadkeys := array[] of
{
	"aastorecheck",
	"acheckcast",
	"ainstanceof",
	"checkcast",
	"culprit",
	"d2i",
	"d2l",
	"dcmpg",
	"dcmpl",
	"drem",
	"getinterface",
	"instanceof",
	"lcmp",
	"monitorenter",
	"monitorexit",
	"multianewarray",
	"pcheckcast",
	"pinstanceof",
	"raise",
	"rescue",
	"rtload",
	"throw",
	"unrescue",
	"getclassclass",
};

#
#	This function maps the above 23 strings to unique integers from 0 to 37.
#
loadhash(s: string): int
{
	# TODO: fix
	if (s == "getclassclass")
		return 1;
	return ((s[len s - 1] + 49) * len s + 19 * s[0]) % LDHASH;
}

loadenter(s: string, x: int)
{
	n := loadhash(s);
	if (loadtable[n].name == s)
		loadtable[n].value = x;
}

initloadhash()
{
	n := len loadkeys;
	for (i := 0; i < n; i++) {
		s := loadkeys[i];
		loadtable[loadhash(s)].name = s;
	}
	a := loadlinks;
	n = len a;
	for (i = 0; i < n; i++)
		loadenter(a[i].name, i);
	a = syslinks;
	n = len a;
	for (i = 0; i < n; i++)
		loadenter(a[i].name, i);
}

#
#	Map a string to a @Loader or @Sys index.
#
getloader(s: string): int
{
	n := loadhash(s);
	if (loadtable[n].name != s)
		error("getloader botch");
	return loadtable[n].value;
}

#
#	Get Class adt from an object.
#
Object.class(o: self ref Object): ref Class
{
	return getclassadt(o.mod, CLASSADTOFFSET);
}

#
#	Categorizers.
#
isdata(sig: string): int
{
	return sig[0] != '(';
}

isspecial(field: string): int
{
	return field[0] == '<';
}

ispointer(sig: string): int
{
	case sig[0] {
	'L' or '[' =>
		return 1;
	}
	return 0;
}

isprivate(flags: int): int
{
	return flags & ACC_PRIVATE;
}

isstatic(flags: int): int
{
	return flags & ACC_STATIC;
}

isnative(flags: int): int
{
	return flags & ACC_NATIVE;
}

isvirtual(flags: int): int
{
	return (flags & (ACC_PRIVATE | ACC_STATIC)) == 0;
}

isabstract(flags: int): int
{
	return flags & ACC_ABSTRACT;
}

#
#	Type alignment.
#
alignto(sz: int, sig: string): int
{
	a: int;
	if (sig == nil)
		a = WORDZ;
	else {
		a = sizeof(sig);
		if (a == 1)
			return sz;
	}
	a--;
	return (sz + a) & ~a;
}

#
#	Type size.
#
sizeof(sig: string): int
{
	case sig[0] {
	'Z' or 'B' =>
		return 1;
	'D' or 'J' or 'F' =>
		return 2 * WORDZ;
	'C' or 'S' or 'I' or 'L' or '[' =>
		return WORDZ;
	}
	warning("unknown size: " + sig);
	return WORDZ;
}

#
#	Utilities.
#

mkclarray(l: list of ref Class): array of ref Class
{
	n := len l;
	a := array[n] of ref Class;
	while (--n >= 0) {
		a[n] = hd l;
		l = tl l;
	}
	return a;
}

mkfdarray(l: list of ref Field): array of ref Field
{
	n := len l;
	a := array[n] of ref Field;
	while (--n >= 0) {
		a[n] = hd l;
		l = tl l;
	}
	return a;
}

findfield(l: list of ref Field, f: string): ref Field
{
	while (l != nil) {
		h := hd l;
		if (h.field == f)
			return h;
		l = tl l;
	}
	return nil;
}

findsig(l: list of ref Field, s: string): ref Field
{
	while (l != nil) {
		h := hd l;
		if (h.signature == s)
			return h;
		l = tl l;
	}
	return nil;
}

findfs(l: list of ref Field, f, s: string): ref Field
{
	while (l != nil) {
		h := hd l;
		if (h.field == f && h.signature == s)
			return h;
		l = tl l;
	}
	return nil;
}

findafield(a: array of ref Field, f: string): ref Field
{
	n := len a;
	for (i := 0; i < n; i++) {
		if (a[i].field == f)
			return a[i];
	}
	return nil;
}

findasig(a: array of ref Field, s: string): ref Field
{
	n := len a;
	for (i := 0; i < n; i++) {
		if (a[i].signature == s)
			return a[i];
	}
	return nil;
}

findafs(a: array of ref Field, f, s: string): ref Field
{
	n := len a;
	for (i := 0; i < n; i++) {
		if (a[i].field == f && a[i].signature == s)
			return a[i];
	}
	return nil;
}

findmfsx(a: array of Method, f, s: string): int
{
	n := len a;
	for (i := 0; i < n; i++) {
		t := a[i].field;
		if (t.field == f && t.signature == s)
			return i;
	}
	return -1;
}

#
#	Patch an instruction.
#
ipatch(inst: array of Loader->Inst, p: array of byte, d: int)
{
	v: int;
	l := len inst;
	n := len p;
	x := 0;
	if (fsindir) {
		for (i := 0; i < n; i++) {
			t := int p[i];
			if (t & RDELTA) {
				x += (256 - t) << 3;
				continue;
			}
			x += t >> ISHIFT;
			if (x < 0 || x >= l)
				error("bad inst index");
			debugs := sys->sprint("ipatch inst[%d](%d, %d, %d)->", x, inst[x].src, inst[x].mid, inst[x].dst);
			case t & (POP | PTYPE) {
			PSRC | PIMM or PSRC | PSIND =>
				inst[x].src += d;
			PSRC | PDIND1 =>
				v = inst[x].src;
				inst[x].src = (v & int 16rFFFF0000) | ((v & 16rFFFF) + d);
			PSRC | PDIND2 =>
				v = inst[x].src;
				inst[x].src = (v & 16rFFFF) | ((v & int 16rFFFF0000) + (d << 16));
			PMID | PIMM or PMID | PSIND =>
				inst[x].mid += d;
			PDST | PIMM or PDST | PSIND =>
				inst[x].dst += d;
			PDST | PDIND1 =>
				v = inst[x].dst;
				inst[x].dst = (v & int 16rFFFF0000) | ((v & 16rFFFF) + d);
			PDST | PDIND2 =>
				v = inst[x].dst;
				inst[x].dst = (v & 16rFFFF) | ((v & int 16rFFFF0000) + (d << 16));
			* =>
				error("bad reloc");
			}
			#trace(JDEBUG, sys->sprint("%sinst[%d](%d, %d, %d)", debugs, x, inst[x].src, inst[x].mid, inst[x].dst));
		}
	} else {
		for (i := 0; i < n; i++) {
			t := int p[i];
			if (t & RDELTA) {
				x += (256 - t) << 3;
				continue;
			}
			x += t >> ISHIFT;
			if (x < 0 || x >= l)
				error("bad inst index");
			case t & (POP | PTYPE) {
			PSRC | PIMM or PSRC | PSIND =>
				inst[x].src += d;
			PSRC | PDIND1 =>
				v = inst[x].src;
				inst[x].src = (v & 16rFFFF) | ((v & int 16rFFFF0000) + (d << 16));
			PSRC | PDIND2 =>
				v = inst[x].src;
				inst[x].src = (v & int 16rFFFF0000) | ((v & 16rFFFF) + d);
			PMID | PIMM or PMID | PSIND =>
				inst[x].mid += d;
			PDST | PIMM or PDST | PSIND =>
				inst[x].dst += d;
			PDST | PDIND1 =>
				v = inst[x].dst;
				inst[x].dst = (v & 16rFFFF) | ((v & int 16rFFFF0000) + (d << 16));
			PDST | PDIND2 =>
				v = inst[x].dst;
				inst[x].dst = (v & int 16rFFFF0000) | ((v & 16rFFFF) + d);
			* =>
				error("bad POP");
			}
		}
	}
}

#
#	String concatenation.
#
concat(l: list of string, r: int): string
{
	n := len l;
	do {
		t: list of string;
		t = nil;
		do {
			if (n > 1) {
				s0, s1: string;
				if (r) {
					s1 = hd l;
					l = tl l;
					s0 = hd l;
					l = tl l;
				} else {
					s0 = hd l;
					l = tl l;
					s1 = hd l;
					l = tl l;
				}
				t = (s0 + s1) :: t;
				n -= 2;
			} else {
				t = (hd l) :: t;
				break;
			}
		} while (l != nil);
		l = t;
		n = len l;
		r = 1 - r;
	} while (n > 1);
	return hd l;
}

#
#	Native name mangling.
#
mangle(f, s: string): string
{
	l := f :: nil;
	_ := 1;
	a := 0;
	while (s != nil) {
		n := len s;
		i := 0;
	scan:	for (;;) {
			if (i == n) {
				s = nil;
				break;
			}
			if (_)
				l = "_" :: l;
			case s[i] {
			'(' or ')' =>
				_ = 0;
			'[' =>
				l = "a" :: l;
				_ = 0;
				a = 1;
			'L' =>
				(c, r) := str->splitl(s[i + 1:], ";)");
				(nil, b) := str->splitr(c, "/");
				if (a)
					l = b :: l;
				else
					l = b :: "r" :: l;
				if (r == nil)
					s = nil;
				else
					s = r[1:];
				_ = 1;
				a = 0;
				break scan;
			* =>
				l = s[i:i + 1] :: l;
				_ = 1;
				a = 0;
			}
			i++;
		}
	}
	return concat(l, 1);
}

handlejavaex(nil: string, obj: ref Object)
{
	class := obj.class();
	if (class != tdclass) {
		throwable := jassist->ObjecttoJT(obj);
		msg : string = nil;
		if ( throwable.msg != nil )
			msg = throwable.msg.str;
		sys->fprint(stderr, "%s: %s\n", class.name, msg);
		if (throwable.trace != nil)
			sys->fprint(stderr, "%s\n", string throwable.trace);
	}
	delthreaddata();
	exit;
}

setflags( flags : list of (string,int) )
{
	if ( flags == nil ) return;

	for((f,v):=hd flags; flags != nil; flags = tl flags )
	{
		case (f)
		{
			"debug"   => loadtrace();
						 jtrace->level = JDEBUG;
			"verbose" => loadtrace();
						 jtrace->level = JVERBOSE;
			"warn"    => warn    = v;
		}
	}
}

runmain( classloader : JavaClassLoader, classname : string, argv : list of string )
{
	{
		classloader->loader(classname).run(tl tl argv);
	}
	exception e
	{
		"*disabled" =>
			m := sys->sprint("uncaught exception: %s", e);
			mesg(m);
			if ( (obj := culprit(e)) != nil) 
				handlejavaex(e, obj);
			else {
				raise m; #just giveup
			}
			classloader->shutdown();
	}
}

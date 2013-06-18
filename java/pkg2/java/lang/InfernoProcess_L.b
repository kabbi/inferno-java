implement InfernoProcess_L;

# javal v1.3 generated file: edit with care

include "jni.m";
    jni : JNI;
        ClassModule,
        JString,
        JArray,
        JArrayI,
        JArrayC,
        JArrayB,
        JArrayS,
        JArrayJ,
        JArrayF,
        JArrayD,
        JArrayZ,
        JArrayJObject,
        JArrayJClass,
        JArrayJString,
        JClass,
        JThread,
        JObject : import jni;

#>> extra pre includes here

include "java/io/FileDescriptor_L.m";
    FileDescriptor_obj : import FileDescriptor_L;

#<<

include "InfernoProcess_L.m";

#>> extra post includes here

include "sh.m";

ioexception := "";

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    #<<
}

initProc_aString_aString_V( this : ref InfernoProcess_obj, p0 : JArrayJString,p1 : JArrayJString)
{#>>
    #
    # p0 : command and arguments
    # p1 : environment in for var=value; does not apply in Inferno
    #
    dummy := this;
    jstrs := p0.ary;
    args : list of string;
    l := len jstrs;
    for ( i := l-1; i >= 0; i--)
	args = jstrs[i].str :: args;

    sync := chan of int;
    spawn exec(this, args, sync);
    pid := <- sync;
    if ( pid == 0 )
	jni->ThrowException("java.io.IOException", ioexception);
}#<<

waitFor_I( this : ref InfernoProcess_obj) : int
{#>>
    if ( this.waitfd.fd == nil )
	this.terminated = JNI->TRUE;
    while ( this.terminated == JNI->FALSE ) {
	(ok, nil) := jni->sys->fstat(this.waitfd.fd);
	if ( ok < 0 )
	    this.terminated = JNI->TRUE;
	else
	    jni->sys->sleep(1000);
    }
    this.waitfd.fd = nil;
    return 0;
}#<<

destroy_V( this : ref InfernoProcess_obj)
{#>>
    if ( this.pid == 0 || isTerminated_Z(this) == JNI->TRUE )
	return;

    fd := jni->sys->open("/prog/"+string this.pid+"/ctl", jni->sys->OWRITE);
    if ( fd != nil )
	jni->sys->fprint(fd, "killgrp");
    this.pid = 0;
    this.terminated = JNI->TRUE;
}#<<

isTerminated_Z( this : ref InfernoProcess_obj) : int
{#>>
    #	If the file descriptor being used to wait for the process to terminate
    #	is still good, the process hasn't terminated yet.
    #
    if ( this.waitfd.fd == nil )
	return this.terminated = JNI->TRUE;
    (ok, nil) := jni->sys->fstat(this.waitfd.fd);
    if ( ok < 0 )
	this.terminated = JNI->TRUE;
    return this.terminated;
}#<<



exec(this : ref InfernoProcess_obj, args : list of string,
							waitpid : chan of int)
{
    # find and load module corresponding to hd args.
    cmd := hd args;
    file := cmd;
    if ( len file < 4 || file[len file - 4:] != ".dis" )
	file += ".dis";

    c := load Command file;
    if ( c == nil ) {
	err := jni->sys->sprint("%r");
	if ( err == "file does not exist" && file[0] != '/' &&
							file[0:2] != "./" ) {
	    c = load Command "/dis/" + file;
	    if ( c == nil )
		err = jni->sys->sprint("%r");
	}
	if ( c == nil ) {
	    ioexception = jni->sys->sprint("%s: %r", cmd);
	    waitpid <- = 0;
	    return;
	}
    }
    #
    # Get pid (via pctl) and save; We save the pid of the PARENT of the
    # thread that will actually execute the command.  Then if someone
    # calls destroy, the whole group is killed.
    #
    this.pid = jni->sys->pctl(Sys->FORKNS | Sys->NEWPGRP, nil);
    #
    # Note: have to open the /prog/n/wait file of parent before doing the spawn.
    #
    waitfd : ref Sys->FD;;
    if ( this.pid > 0 )
	waitfd = jni->sys->open("#p/" + string this.pid + "/wait", Sys->OREAD);
    this.waitfd.fd = waitfd;

    # arrange for new input/output to the command.  Save in stdin & stdout.
    si := array[2] of ref Sys->FD;
    so := array[2] of ref Sys->FD;
    se := array[2] of ref Sys->FD;
    if ( jni->sys->pipe(si) < 0 ) {
	ioexception = "pipe failure";
	waitpid <- = 0;
	return;
    }
    if ( jni->sys->pipe(so) < 0 ) {
	ioexception = "pipe failure";
	waitpid <- = 0;
	return;
    }
    if ( jni->sys->pipe(se) < 0 ) {
	ioexception = "pipe failure";
	waitpid <- = 0;
	return;
    }
    this.stdin.fd = si[1];
    this.stdout.fd = so[0];
    this.stderr.fd = se[0];
    spawn exec1(c, si[0], so[1], se[1], args, waitpid);
    si[0] = si[1] = so[0] = so[1] = se[0] = se[1] = nil;
    #
    # We can't just exit this thread, or we could never detect completion
    # of the child.  So we wait here for the wait notification.
    # Note that we nil the 'this' reference, so that it will be
    # possible for it to be garbage collected when not referenced elsewhere.
    # That means we can't set the terminated flag, so that anyone who
    # really needs to know whether the process has terminated has to check
    # to see if this.waitfd.fd is still a valid FD.
    #
    this = nil;
    buf := array[64] of byte;
    if ( waitfd != nil && jni->sys->read(waitfd, buf, len buf) < 0 )
	jni->sys->print("read error on wait file: %r\n")
	;	# even if this is an error, how do we report it?
}

exec1(cmd : Command, in, out, err : ref Sys->FD, args : list of string,
							c : chan of int)
{
    newfds := in.fd :: out.fd :: err.fd :: nil;
    pid := jni->sys->pctl(Sys->NEWFD, newfds);
    jni->sys->dup(in.fd, 0);
    jni->sys->dup(out.fd, 1);
    jni->sys->dup(err.fd, 2);
    in = out = err = nil;
    pid = jni->sys->pctl(Sys->NEWFD, 0 :: 1 :: 2 :: nil);
    #
    #	Eventually there has to be a way to get the Draw->Context.
    #
    #	ctxt := jni->GetContext();
    c <- = pid;
    cmd->init(nil, args);
}


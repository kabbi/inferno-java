implement Runtime_L;

# javal v1.2 generated file: edit with care

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
        JObject : import jni;

#>> extra pre includes here

#<<

include "Runtime_L.m";

#>> extra post includes here

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    #<<
}

killgrp()
{
	# kill this process group
	msg := array of byte "killgrp";
	pid := string jni->sys->pctl(0,nil);  #my pid

	fd := jni->sys->open("#p/"+pid+"/ctl", Sys->OWRITE);
	if(fd != nil) 
		jni->sys->write(fd, msg, len msg);

	#note: we silently fail if we could not open
	#'#p' (i.e. because of NODEVS) or if the
	#write fails
}

exitInternal_I_V( this : ref Runtime_obj, p0 : int)
{#>>
	# can't kill self, so spawn thread to kill group
	spawn killgrp();
	# send nowhere until killed
	chan of int <-= 666;
	junk := (this,p0); #inferno does not have an exit code
}#<<

runFinalizersOnExit0_Z_V( p0 : int)
{#>>
	junk := (p0);
}#<<

freeMemory_J( this : ref Runtime_obj) : big
{#>>
	# open; read; parase; memory device
	mfd := jni->sys->open("#c/memory", Sys->OREAD);
	if ( mfd == nil )
		return(big 0);
	buf := array[300] of byte;
	n   := jni->sys->read(mfd, buf, len buf);
	if(n <= 0)
		return(big 0);
	(nil, arena) := jni->sys->tokenize(string buf[0:n], "\n");
	(used,limit) := (0,0);
	# walk list of arena's looking for "heap"
	while(arena != nil) 
	{
		# break line into tokens
		(nil,tok) := jni->sys->tokenize( hd arena, " " );
		used  = int (hd tok);  #first tok is amount used
		tok = tl tok;
		limit = int (hd tok);  #second tok is total
		name : string;
		for(tok= tl tok; tok != nil; tok = tl tok)
			name = hd tok;

		if ( name == "heap" )
			break;
		arena = tl arena;
	}
	
	# return the amount free
	return( big (limit-used) );
	junk := (this);
}#<<

totalMemory_J( this : ref Runtime_obj) : big
{#>>
	# open; read; parase; memory device
	mfd := jni->sys->open("#c/memory", Sys->OREAD);
	if ( mfd == nil )
		return( big 0 );
	buf := array[300] of byte;
	n   := jni->sys->read(mfd, buf, len buf);
	if(n <= 0)
		return(big 0);
	(nil, arena) := jni->sys->tokenize(string buf[0:n], "\n");
	limit := 0;
	while(arena != nil) 
	{
		# break line into tokens
		(nil,tok) := jni->sys->tokenize( hd arena, " " );
		tok = tl tok;
		limit = int (hd tok);  #second tok is total
		name : string;
		for(tok= tl tok; tok != nil; tok = tl tok)
			name = hd tok;

		if ( name == "heap" ) 
			break;
		arena = tl arena;
	}
	
	# return the total amount
	return( big limit );
	junk := (this);
}#<<

gc_V( this : ref Runtime_obj)
{#>>
	# do nothing
	junk := this;
}#<<

runFinalization_V( this : ref Runtime_obj)
{#>>
	# do nothing
	junk := this;
}#<<

traceInstructions_Z_V( this : ref Runtime_obj, p0 : int)
{#>>
	# do nothing
	return;
	junk := (this,p0);
}#<<

traceMethodCalls_Z_V( this : ref Runtime_obj, p0 : int)
{#>>
	# doing nothing is a valid implementation
	return;
	junk := (this,p0);
}#<<

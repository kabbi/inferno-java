implement Throwable_L;

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

include "Throwable_L.m";

#>> extra post includes here

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    #<<
}

printStackTrace0_rObject_V( this : ref Throwable_obj, p0 : JObject)
{#>>
	Value : import jni;
	jldr := jni->jldr;
	Object : import jldr;

	if ( this.backtrace != nil )
	{
		args := array[] of 
		{
			ref Value.TObject( jni->NewStringObject( string this.backtrace ) )
		};
		(nil,nil):=jni->CallMethod( p0, "println", "(Ljava/lang/String;)V", args );
		# ignore any erros
	}

}#<<

fillInStackTrace_rThrowable( this : ref Throwable_obj) : ref Throwable_obj
{#>>
	# attempt to open the local "prog" device (i.e. '#p')
	# and read the call stack into an array of bytes
	pid      := jni->sys->pctl(0,nil);
	progfile := "#p/"+ (string pid) +"/stack";
	fd       := jni->sys->open( progfile, Sys->OREAD );
	if ( fd != nil )
	{
		# must spin a thread to read my own call-stack
		result := chan of array of byte;    # channel for thd results
		spawn ReadCallStack( fd, result );
		this.backtrace = <- result;          # wait for results

	}
	else
		this.backtrace = array of byte jni->sys->sprint("could not open %s:%r\n", progfile );

	return( this );
}#<<

####### private functions


ReadCallStack( fd : ref Sys->FD, result : chan of array of byte )
{
	buf := array[8000] of byte; #about 10 frames 
	n   := jni->sys->read(fd, buf, len buf - 1);
	fd  = nil; 
	if(n < 0)
		buf = array of byte jni->sys->sprint("could not read call-stack:%r\n");
	else
		buf[n] = byte 0;

	result <- = buf[:n+1];
}


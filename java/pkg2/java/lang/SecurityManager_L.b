implement SecurityManager_L;

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

include "SecurityManager_L.m";

#>> extra post includes here

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    #<<
}

getClassContext_aClass( this : ref SecurityManager_obj) : JArrayJClass
{#>>
	#
	# return an array of classes that represent the classes of
	# each method on the current call stack (presumably ignoring
	# any native funtions).
	#
	jni->FatalError( "getClassContext() not implemented" );
	junk := this;
	return(nil);
}#<<

currentClassLoader_rClassLoader( this : ref SecurityManager_obj) : JObject
{#>>
	#
	# this returns the most recent class loader on the current call
	# stack. Traditionally the call stack is walked and the class of
	# each "active" method is checked to obtain its class loader (if
	# any; null==root loader).  The first such class loader we find
	# is returned.
	#
	return(nil);  #for now we don't walk back
	junk := this;
}#<<

classDepth_rString_I( this : ref SecurityManager_obj, p0 : JString) : int
{#>>
	# 
	# walk the call stack looking for a method that resides in
	# the class specified.
	#
	if ( p0 != nil )
	{
		clname := p0.str;  
		# change any '.' to '/'
		l := len clname;
		for(x:=0;x<l; x++)
			if ( clname[x] == '.' ) clname[x] = '/';

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
			callstack := <- result;          # wait for results

			(cnt,frame) := jni->sys->tokenize( string callstack, "\n" );
			if ( cnt > 0 )
			{
				# walk frames looking for module-name/class-name match
				depth := 0;
				for( ; frame!=nil; frame=tl frame )
				{
					# parse each line
					(a,tok) := jni->sys->tokenize(hd frame, " ");
					if ( a > 0 )
					{
						#module name is last token
						for( b:=0; b<a-1; b-- )
							tok = tl tok;
						if ( (hd tok) == clname )
							return( depth );
					}
					depth++;
				}
			}
		}

	}

	return(-1);  #if we are here we can't find the class
	junk := (this);
}#<<

classLoaderDepth_I( this : ref SecurityManager_obj) : int
{#>>
	#
	# return the number of frames back to the first class
	# loader on the call stack.  Return -1 if no classloaders.
	#
	return(-1);    #for now we don't walk back
	junk := this;
}#<<

currentLoadedClass0_rClass( this : ref SecurityManager_obj) : JClass
{#>>
	#
	# return the first class on the call stack that was loaded
	# with a class loader.  
	#
	return( nil );
	junk := this;
}#<<




ReadCallStack( fd : ref Sys->FD, result : chan of array of byte )
{
	# read until eof
	buf := array[8000] of byte; #about 10 frames 
	(n,ptr) := (0,0);
	do
	{
		cur := len buf-ptr;
		n = jni->sys->read(fd, buf[ptr:], cur);
		ptr += n;
		if ( n == cur )				
		{
			# need to read more
			buf = ExtendBuf(buf);
		}

	} while ( n != 0 );

	result <- = buf[:ptr];
}

ExtendBuf( buf : array of byte ) : array of byte
{
	curlen := len buf;
	newbuf := array[curlen + 8000] of byte;

	# copy old contents
	for(x:=0; x<curlen; x++ )
		newbuf[x] = buf[x];

	return( newbuf ); 
}
implement System_L;

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

include "System_L.m";

#>> extra post includes here
include "workdir.m";

cast         : Cast;
system_class : JNI->ClassData;  # java.lang.System class data

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
	system_class = jni->FindClass( "java/lang/System" );
	if ( system_class == nil )
		jni->InitError( "System_L.init(): failed to find System class" );

	# we Cast in this module
	cast = jni->CastMod();
	#<<
}

setIn0_rInputStream_V( p0 : JObject)
{#>>
	Value : import JNI;
	val := ref Value.TObject(p0);
	jni->SetStaticField( system_class, "in", val );
}#<<

setOut0_rPrintStream_V( p0 : JObject)
{#>>
	Value : import JNI;
	val := ref Value.TObject(p0);
	jni->SetStaticField( system_class, "out", val );
}#<<

setErr0_rPrintStream_V( p0 : JObject)
{#>>
	Value : import JNI;
	val := ref Value.TObject(p0);
	jni->SetStaticField( system_class, "err", val );
}#<<

currentTimeMillis_J( ) : big
{#>>
	fd := jni->sys->open("#c/time", jni->sys->OREAD);
	if(fd == nil)
		return big 0;
	buf := array[128] of byte;
	n := jni->sys->read(fd, buf, len buf);
	if(n < 0)
		return big 0;

	return ( (big string buf[:n]) / big 1000 );
}#<<

arraycopy_rObject_I_rObject_I_I_V( p0 : JObject,p1 : int,p2 : JObject,p3 : int,p4 : int)
{#>>
	jni->jldr->arraycopy( cast->ToJArray(p0), p1, cast->ToJArray(p2), p3, p4 );
}#<<

identityHashCode_rObject_I( p0 : JObject) : int
{#>>
	return( jni->IdentityHash(p0) );
}#<<

GetUserName_rString( ) : JString
{#>>
	# return the current inferno user
	# name as a Java String
	#
	user_name : string;

	fd := jni->sys->open("#c/user", jni->sys->OREAD);
	if(fd == nil)
		user_name = "unknown";
	else {
		buf := array[128] of byte;
		n := jni->sys->read(fd, buf, len buf);
		if(n < 0)
			user_name = "unknown";
		else
			user_name = string buf[:n];
	}

	# make java string from user name
	return( jni->NewString( user_name ) );
}#<<

GetCWD_rString( ) : JString
{#>>
	# return the current working directory
	# as a Java String
	#
	# this fct is really only called once so
	# just load Workdir right here
	wdir := load Workdir Workdir->PATH;
	if ( wdir == nil )
		jni->InitError( jni->sys->sprint( "java.lang.System: could not load %s: %r", Workdir->PATH ) );

	return( jni->NewString( wdir->init() ) );
}#<<



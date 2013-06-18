implement Object_L;

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
        JArrayJString,
        JClass,
        JObject : import jni;

#>> extra pre includes here

#<<

include "Object_L.m";

#>> extra post includes here

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    #<<
}

getClass_rClass( this : JObject) : JClass
{#>>
	return( jni->GetObjectClass(this) );
}#<<

hashCode_I( this : JObject ) : int
{#>>
	return( jni->IdentityHash( this ) );
}#<<

clone_rObject( this : JObject ) : JObject
{#>>
	return( jni->DupObject( this ) );
}#<<

notify_V( this : JObject )
{#>>
	jni->jldr->monitornotify( this, 0 );
}#<<

notifyAll_V( this : JObject )
{#>>
	jni->jldr->monitornotify( this, 1 );
}#<<

wait_J_V( this : JObject, p0 : big)
{#>>
	if ( p0 < big 0 )
		jni->ThrowException( "java.lang.IllegalArgumentException", "negative timeout value" );
	# limit to 30 bits of millisecond time.
	duration := (int p0) & 16r3FFFFFFF;
	jni->jldr->monitorwait( this, duration );
}#<<

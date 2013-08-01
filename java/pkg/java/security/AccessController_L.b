implement AccessController_L;

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

include "AccessController_L.m";

#>> extra post includes here

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    #<<
}

# TODO: provide implementation

doPrivileged_rPrivilegedAction_rObject( p0 : JObject) : JObject
{#>>
	return nil;
}#<<

doPrivileged_rPrivilegedExceptionAction_rObject( p0 : JObject) : JObject
{#>>
	return nil;
}#<<

doPrivileged_rPrivilegedAction_rAccessControlContext_rObject( p0 : JObject,p1 : JObject) : JObject
{#>>
	return nil;
}#<<

doPrivileged_rPrivilegedExceptionAction_rAccessControlContext_rObject( p0 : JObject,p1 : JObject) : JObject
{#>>
	return nil;
}#<<

getInheritedAccessControlContext_rAccessControlContext( ) : JObject
{#>>
	return nil;
}#<<

getStackAccessControlContext_rAccessControlContext( ) : JObject
{#>>
	return nil;
}#<<



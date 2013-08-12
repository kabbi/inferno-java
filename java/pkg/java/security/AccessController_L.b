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
        JObject,
        Value : import jni;

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
	if (p0 == nil)
		jni->ThrowException("java.lang.NullPointerException", "action arg is null");

	(obj, result) := jni->CallMethod(p0, ACTION_RUN_METHOD,
		ACTION_RUN_SIGNATURE, array [0] of ref Value);
	if (result != jni->OK)
		jni->FatalError("run() method execute failed");

	return obj.Object();
}#<<

doPrivileged_rPrivilegedExceptionAction_rObject( p0 : JObject) : JObject
{#>>
	return doPrivileged_rPrivilegedAction_rObject(p0);
}#<<

doPrivileged_rPrivilegedAction_rAccessControlContext_rObject( p0 : JObject,p1 : JObject) : JObject
{#>>
	return doPrivileged_rPrivilegedAction_rObject(p0);
}#<<

doPrivileged_rPrivilegedExceptionAction_rAccessControlContext_rObject( p0 : JObject,p1 : JObject) : JObject
{#>>
	return doPrivileged_rPrivilegedAction_rObject(p0);
}#<<

getInheritedAccessControlContext_rAccessControlContext( ) : JObject
{#>>
	return nil;
}#<<

getStackAccessControlContext_rAccessControlContext( ) : JObject
{#>>
	return nil;
}#<<



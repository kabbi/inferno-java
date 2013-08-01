# generated file edit with care

AccessController_L : module
{
    AccessController_obj : adt
    {
        cl_mod : ClassModule;
    };

    init : fn( jni_p : JNI );
    doPrivileged_rPrivilegedAction_rObject : fn( p0 : JObject) : JObject;
    doPrivileged_rPrivilegedExceptionAction_rObject : fn( p0 : JObject) : JObject;
    doPrivileged_rPrivilegedAction_rAccessControlContext_rObject : fn( p0 : JObject,p1 : JObject) : JObject;
    doPrivileged_rPrivilegedExceptionAction_rAccessControlContext_rObject : fn( p0 : JObject,p1 : JObject) : JObject;
    getInheritedAccessControlContext_rAccessControlContext : fn( ) : JObject;
    getStackAccessControlContext_rAccessControlContext : fn( ) : JObject;

};

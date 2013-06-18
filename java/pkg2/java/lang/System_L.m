# javal v1.2 generated file: edit with care

System_L : module
{
    System_obj : adt
    {
        cl_mod : ClassModule;
    };

    init : fn( jni_p : JNI );
    setIn0_rInputStream_V : fn( p0 : JObject);
    setOut0_rPrintStream_V : fn( p0 : JObject);
    setErr0_rPrintStream_V : fn( p0 : JObject);
    currentTimeMillis_J : fn( ) : big;
    arraycopy_rObject_I_rObject_I_I_V : fn( p0 : JObject,p1 : int,p2 : JObject,p3 : int,p4 : int);
    identityHashCode_rObject_I : fn( p0 : JObject) : int;
    GetUserName_rString : fn( ) : JString;
    GetCWD_rString : fn( ) : JString;

};

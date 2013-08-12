# generated file edit with care

Version_L : module
{
    Version_obj : adt
    {
        cl_mod : ClassModule;
    };

    init : fn( jni_p : JNI );
    getJvmSpecialVersion_rString : fn( ) : JString;
    getJdkSpecialVersion_rString : fn( ) : JString;
    getJvmVersionInfo_Z : fn( ) : int;
    getJdkVersionInfo_V : fn( );

};

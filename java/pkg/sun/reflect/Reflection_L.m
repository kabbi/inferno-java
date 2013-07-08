# generated file edit with care

Reflection_L : module
{
    Reflection_obj : adt
    {
        cl_mod : ClassModule;
    };

    init : fn( jni_p : JNI );
    getClassAccessFlags_rClass_I : fn( p0 : JClass) : int;
    getCallerClass_I_rClass : fn( p0 : int) : JClass;

};

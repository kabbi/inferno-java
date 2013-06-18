# javal v1.2 generated file: edit with care

ClassLoader_L : module
{
    ClassLoader_obj : adt
    {
        cl_mod : ClassModule;
        initialized : int;
        classes : JObject;
    };

    init : fn( jni_p : JNI );
    init_V : fn( this : ref ClassLoader_obj);
    defineClass0_rString_aB_I_I_rClass : fn( this : ref ClassLoader_obj, p0 : JString,p1 : JArrayB,p2 : int,p3 : int) : JClass;
    resolveClass0_rClass_V : fn( this : ref ClassLoader_obj, p0 : JClass);
    findSystemClass0_rString_rClass : fn( this : ref ClassLoader_obj, p0 : JString) : JClass;
    getSystemResourceAsStream0_rString_rInputStream : fn( p0 : JString) : JObject;
    getSystemResourceAsName0_rString_rString : fn( p0 : JString) : JString;

};

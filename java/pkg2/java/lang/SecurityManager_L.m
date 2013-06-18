# javal v1.2 generated file: edit with care

SecurityManager_L : module
{
    SecurityManager_obj : adt
    {
        cl_mod : ClassModule;
        inCheck : int;
        initialized : int;
    };

    init : fn( jni_p : JNI );
    getClassContext_aClass : fn( this : ref SecurityManager_obj) : JArrayJClass;
    currentClassLoader_rClassLoader : fn( this : ref SecurityManager_obj) : JObject;
    classDepth_rString_I : fn( this : ref SecurityManager_obj, p0 : JString) : int;
    classLoaderDepth_I : fn( this : ref SecurityManager_obj) : int;
    currentLoadedClass0_rClass : fn( this : ref SecurityManager_obj) : JClass;

};

# generated file edit with care

Constructor_L : module
{
    Constructor_obj : adt
    {
        cl_mod : ClassModule;
        clazz : JClass;
        slot : int;
        parameterTypes : JArrayJClass;
        exceptionTypes : JArrayJClass;
    };

    init : fn( jni_p : JNI );
    getModifiers_I : fn( this : ref Constructor_obj) : int;
    newInstance_aObject_rObject : fn( this : ref Constructor_obj, p0 : JArrayJObject) : JObject;

};

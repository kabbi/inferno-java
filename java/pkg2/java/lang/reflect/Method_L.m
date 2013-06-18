# generated file edit with care

Method_L : module
{
    Method_obj : adt
    {
        cl_mod : ClassModule;
        clazz : JClass;
        slot : int;
        name : JString;
        returnType : JClass;
        parameterTypes : JArrayJClass;
        exceptionTypes : JArrayJClass;
    };

    init : fn( jni_p : JNI );
    getModifiers_I : fn( this : ref Method_obj) : int;
    invoke_rObject_aObject_rObject : fn( this : ref Method_obj, p0 : JObject,p1 : JArrayJObject) : JObject;

};

# generated file edit with care

ConstantPool_L : module
{
    ConstantPool_obj : adt
    {
        cl_mod : ClassModule;
        constantPoolOop : JObject;
    };

    init : fn( jni_p : JNI );
    getSize0_rObject_I : fn( this : ref ConstantPool_obj, p0 : JObject) : int;
    getClassAt0_rObject_I_rClass : fn( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : JClass;
    getClassAtIfLoaded0_rObject_I_rClass : fn( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : JClass;
    getMethodAt0_rObject_I_rMember : fn( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : JObject;
    getMethodAtIfLoaded0_rObject_I_rMember : fn( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : JObject;
    getFieldAt0_rObject_I_rField : fn( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : JObject;
    getFieldAtIfLoaded0_rObject_I_rField : fn( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : JObject;
    getMemberRefInfoAt0_rObject_I_aString : fn( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : JArrayJString;
    getIntAt0_rObject_I_I : fn( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : int;
    getLongAt0_rObject_I_J : fn( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : big;
    getFloatAt0_rObject_I_F : fn( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : real;
    getDoubleAt0_rObject_I_D : fn( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : real;
    getStringAt0_rObject_I_rString : fn( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : JString;
    getUTF8At0_rObject_I_rString : fn( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : JString;

};

# javal v1.2 generated file: edit with care

Class_L : module
{

    init : fn( jni_p : JNI );
    forName_rString_rClass : fn( p0 : JString) : JClass;
    newInstance_rObject : fn( this : JClass) : JObject;
    isInstance_rObject_Z : fn( this : JClass, p0 : JObject) : int;
    isAssignableFrom_rClass_Z : fn( this : JClass, p0 : JClass) : int;
    isInterface_Z : fn( this : JClass) : int;
    isArray_Z : fn( this : JClass) : int;
    isPrimitive_Z : fn( this : JClass) : int;
    getName_rString : fn( this : JClass) : JString;
    getClassLoader_rClassLoader : fn( this : JClass) : JObject;
    getSuperclass_rClass : fn( this : JClass) : JClass;
    getInterfaces_aClass : fn( this : JClass) : JArrayJClass;
    getComponentType_rClass : fn( this : JClass) : JClass;
    getModifiers_I : fn( this : JClass) : int;
    getSigners_aObject : fn( this : JClass) : JArrayJObject;
    setSigners_aObject_V : fn( this : JClass, p0 : JArrayJObject);
    getPrimitiveClass_rString_rClass : fn( p0 : JString) : JClass;
    getFields0_I_aField : fn( this : JClass, p0 : int) : JArrayJObject;
    getMethods0_I_aMethod : fn( this : JClass, p0 : int) : JArrayJObject;
    getConstructors0_I_aConstructor : fn( this : JClass, p0 : int) : JArrayJObject;
    getField0_rString_I_rField : fn( this : JClass, p0 : JString,p1 : int) : JObject;
    getMethod0_rString_aClass_I_rMethod : fn( this : JClass, p0 : JString,p1 : JArrayJClass,p2 : int) : JObject;
    getConstructor0_aClass_I_rConstructor : fn( this : JClass, p0 : JArrayJClass,p1 : int) : JObject;

};

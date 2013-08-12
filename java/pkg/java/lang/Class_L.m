# generated file edit with care

Class_L : module
{

    init : fn( jni_p : JNI );
    forName0_rString_Z_rClassLoader_rClass : fn( p0 : JString,p1 : int,p2 : JObject) : JClass;
    isAssignableFrom_rClass_Z : fn( this : JClass, p0 : JClass) : int;
    isInstance_rObject_Z : fn( this : JClass, p0 : JObject) : int;
    getModifiers_I : fn( this : JClass) : int;
    isInterface_Z : fn( this : JClass) : int;
    isArray_Z : fn( this : JClass) : int;
    isPrimitive_Z : fn( this : JClass) : int;
    getSuperclass_rClass : fn( this : JClass) : JClass;
    getComponentType_rClass : fn( this : JClass) : JClass;
    registerNatives_V : fn( );
    getName0_rString : fn( this : JClass) : JString;
    getClassLoader0_rClassLoader : fn( this : JClass) : JObject;
    getInterfaces_aClass : fn( this : JClass) : JArrayJClass;
    getSigners_aObject : fn( this : JClass) : JArrayJObject;
    setSigners_aObject_V : fn( this : JClass, p0 : JArrayJObject);
    getEnclosingMethod0_aObject : fn( this : JClass) : JArrayJObject;
    getDeclaringClass_rClass : fn( this : JClass) : JClass;
    getProtectionDomain0_rProtectionDomain : fn( this : JClass) : JObject;
    setProtectionDomain0_rProtectionDomain_V : fn( this : JClass, p0 : JObject);
    getPrimitiveClass_rString_rClass : fn( p0 : JString) : JClass;
    getGenericSignature_rString : fn( this : JClass) : JString;
    getRawAnnotations_aB : fn( this : JClass) : JArrayB;
    getConstantPool_rConstantPool : fn( this : JClass) : JObject;
    getDeclaredFields0_Z_aField : fn( this : JClass, p0 : int) : JArrayJObject;
    getDeclaredMethods0_Z_aMethod : fn( this : JClass, p0 : int) : JArrayJObject;
    getDeclaredConstructors0_Z_aConstructor : fn( this : JClass, p0 : int) : JArrayJObject;
    getDeclaredClasses0_aClass : fn( this : JClass) : JArrayJClass;
    desiredAssertionStatus0_rClass_Z : fn( p0 : JClass) : int;
    newInstance0_rObject : fn( this : JClass) : JObject;

};

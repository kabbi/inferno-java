# generated file edit with care

ObjectInputStream_L : module
{
    ObjectInputStream_obj : adt
    {
        cl_mod : ClassModule;
        in : JObject;
        count : int;
        blockDataMode : byte;
        dis : JObject;
        abortIOException : JObject;
        abortClassNotFoundException : JObject;
        currentObject : JObject;
        currentClassDesc : JObject;
        currentClass : JClass;
        classdesc : JArrayJObject;
#       classes : JArrayJClass;
        spClass : int;
        wireHandle2Object : JObject;
        nextWireOffset : int;
        callbacks : JObject;
        recursionDepth : int;
        currCode : byte;
        enableResolve : byte;
    };

    init : fn( jni_p : JNI );
    loadClass0_rClass_rString_rClass : fn( this : ref ObjectInputStream_obj, p0 : JClass,p1 : JString) : JClass;
    inputClassFields_rObject_rClass_aI_V : fn( this : JObject, p0 : JObject,p1 : JClass,p2 : JArrayI);
    inputArrayValues_rObject_rClass_V : fn( this : JObject, p0 : JObject,p1 : JClass);
    allocateNewObject_rClass_rClass_rObject : fn( p0 : JClass,p1 : JClass) : JObject;
    allocateNewArray_rClass_I_rObject : fn( p0 : JClass,p1 : int) : JObject;
    invokeObjectReader_rObject_rClass_Z : fn( this : JObject, p0 : JObject,p1 : JClass) : int;

};

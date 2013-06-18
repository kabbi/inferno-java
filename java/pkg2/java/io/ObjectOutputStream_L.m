# generated file edit with care

ObjectOutputStream_L : module
{
    ObjectOutputStream_obj : adt
    {
        cl_mod : ClassModule;
        blockDataMode : byte;
        buf : JArrayB;
        count : int;
        out : JObject;
        dos : JObject;
        abortIOException : JObject;
        wireHandle2Object : JArrayJObject;
        wireNextHandle : JArrayI;
        wireHash2Handle : JArrayI;
        nextWireOffset : int;
        currentObject : JObject;
        currentClassDesc : JObject;
        classDescStack : JObject;
        enableReplace : byte;
        replaceObjects : JArrayJObject;
        nextReplaceOffset : int;
        recursionDepth : int;
    };

    init : fn( jni_p : JNI );
    outputClassFields_rObject_rClass_aI_V : fn( this : JObject, p0 : JObject,p1 : JClass,p2 : JArrayI);
    outputArrayValues_rObject_rClass_V : fn( this : JObject, p0 : JObject,p1 : JClass);
    invokeObjectWriter_rObject_rClass_Z : fn( this : JObject, p0 : JObject,p1 : JClass) : int;
    getRefHashCode_rObject_I : fn( p0 : JObject) : int;

};

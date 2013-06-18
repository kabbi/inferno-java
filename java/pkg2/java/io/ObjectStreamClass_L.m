# generated file edit with care

ObjectStreamClass_L : module
{
    ObjectStreamClass_obj : adt
    {
        cl_mod : ClassModule;
        name : JString;
        superclass : ref ObjectStreamClass_obj;
        serializable : byte;
        externalizable : byte;
        fields : JArrayJObject;
        ofClass : JClass;
        suid : big;
        fieldSequence : JArrayI;
        hasWriteObjectMethod : byte;
        localClassDesc : ref ObjectStreamClass_obj;
    };

    init : fn( jni_p : JNI );
    getClassAccess_rClass_I : fn( p0 : JClass) : int;
    getMethodSignatures_rClass_aString : fn( p0 : JClass) : JArrayJString;
    getMethodAccess_rClass_rString_I : fn( p0 : JClass,p1 : JString) : int;
    getFieldSignatures_rClass_aString : fn( p0 : JClass) : JArrayJString;
    getFieldAccess_rClass_rString_I : fn( p0 : JClass,p1 : JString) : int;
    getFields0_rClass_aObjectStreamField : fn( this : ref ObjectStreamClass_obj, p0 : JClass) : JArrayJObject;
    getSerialVersionUID_rClass_J : fn( p0 : JClass) : big;
    hasWriteObject_rClass_Z : fn( p0 : JClass) : int;

};

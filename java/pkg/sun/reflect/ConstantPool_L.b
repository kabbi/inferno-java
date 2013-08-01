implement ConstantPool_L;

include "jni.m";
    jni : JNI;
        ClassModule,
        JString,
        JArray,
        JArrayI,
        JArrayC,
        JArrayB,
        JArrayS,
        JArrayJ,
        JArrayF,
        JArrayD,
        JArrayZ,
        JArrayJObject,
        JArrayJClass,
        JArrayJString,
        JClass,
        JObject : import jni;

#>> extra pre includes here

#<<

include "ConstantPool_L.m";

#>> extra post includes here

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    #<<
}

getSize0_rObject_I( this : ref ConstantPool_obj, p0 : JObject) : int
{#>>
    return 0;
}#<<

getClassAt0_rObject_I_rClass( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : JClass
{#>>
    return nil;
}#<<

getClassAtIfLoaded0_rObject_I_rClass( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : JClass
{#>>
    return nil;
}#<<

getMethodAt0_rObject_I_rMember( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : JObject
{#>>
    return nil;
}#<<

getMethodAtIfLoaded0_rObject_I_rMember( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : JObject
{#>>
    return nil;
}#<<

getFieldAt0_rObject_I_rField( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : JObject
{#>>
    return nil;
}#<<

getFieldAtIfLoaded0_rObject_I_rField( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : JObject
{#>>
    return nil;
}#<<

getMemberRefInfoAt0_rObject_I_aString( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : JArrayJString
{#>>
    return nil;
}#<<

getIntAt0_rObject_I_I( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : int
{#>>
    return 0;
}#<<

getLongAt0_rObject_I_J( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : big
{#>>
    return big 0;
}#<<

getFloatAt0_rObject_I_F( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : real
{#>>
    return 0.0;
}#<<

getDoubleAt0_rObject_I_D( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : real
{#>>
    return 0.0;
}#<<

getStringAt0_rObject_I_rString( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : JString
{#>>
    return nil;
}#<<

getUTF8At0_rObject_I_rString( this : ref ConstantPool_obj, p0 : JObject,p1 : int) : JString
{#>>
    return nil;
}#<<


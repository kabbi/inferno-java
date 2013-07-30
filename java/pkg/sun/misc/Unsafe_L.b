implement Unsafe_L;

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

include "Unsafe_L.m";

#>> extra post includes here

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    #<<
}

allocateInstance_rClass_rObject( this : ref Unsafe_obj, p0 : JClass) : JObject
{#>>
	return nil;
}#<<

copyMemory_rObject_J_rObject_J_J_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : JObject,p3 : big,p4 : big)
{#>>
}#<<

park_Z_J_V( this : ref Unsafe_obj, p0 : byte,p1 : big)
{#>>
}#<<

unpark_rObject_V( this : ref Unsafe_obj, p0 : JObject)
{#>>
}#<<

getObject_rObject_J_rObject( this : ref Unsafe_obj, p0 : JObject,p1 : big) : JObject
{#>>
	return nil;
}#<<

putObject_rObject_J_rObject_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : JObject)
{#>>
}#<<

getBoolean_rObject_J_Z( this : ref Unsafe_obj, p0 : JObject,p1 : big) : byte
{#>>
	return byte 0;
}#<<

putBoolean_rObject_J_Z_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : byte)
{#>>
}#<<

getByte_J_B( this : ref Unsafe_obj, p0 : big) : byte
{#>>
	return byte 0;
}#<<

getByte_rObject_J_B( this : ref Unsafe_obj, p0 : JObject,p1 : big) : byte
{#>>
	return byte 0;
}#<<

putByte_J_B_V( this : ref Unsafe_obj, p0 : big,p1 : byte)
{#>>
}#<<

putByte_rObject_J_B_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : byte)
{#>>
}#<<

getShort_rObject_J_S( this : ref Unsafe_obj, p0 : JObject,p1 : big) : int
{#>>
	return 0;
}#<<

getShort_J_S( this : ref Unsafe_obj, p0 : big) : int
{#>>
	return 0;
}#<<

putShort_rObject_J_S_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : int)
{#>>
}#<<

putShort_J_S_V( this : ref Unsafe_obj, p0 : big,p1 : int)
{#>>
}#<<

getChar_J_C( this : ref Unsafe_obj, p0 : big) : int
{#>>
	return 0;
}#<<

getChar_rObject_J_C( this : ref Unsafe_obj, p0 : JObject,p1 : big) : int
{#>>
	return 0;
}#<<

putChar_J_C_V( this : ref Unsafe_obj, p0 : big,p1 : int)
{#>>
}#<<

putChar_rObject_J_C_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : int)
{#>>
}#<<

getInt_rObject_J_I( this : ref Unsafe_obj, p0 : JObject,p1 : big) : int
{#>>
	return 0;
}#<<

getInt_J_I( this : ref Unsafe_obj, p0 : big) : int
{#>>
	return 0;
}#<<

putInt_J_I_V( this : ref Unsafe_obj, p0 : big,p1 : int)
{#>>
}#<<

putInt_rObject_J_I_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : int)
{#>>
}#<<

getLong_rObject_J_J( this : ref Unsafe_obj, p0 : JObject,p1 : big) : big
{#>>
	return big 0;
}#<<

getLong_J_J( this : ref Unsafe_obj, p0 : big) : big
{#>>
	return big 0;
}#<<

putLong_J_J_V( this : ref Unsafe_obj, p0 : big,p1 : big)
{#>>
}#<<

putLong_rObject_J_J_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : big)
{#>>
}#<<

getFloat_J_F( this : ref Unsafe_obj, p0 : big) : real
{#>>
	return 0.0;
}#<<

getFloat_rObject_J_F( this : ref Unsafe_obj, p0 : JObject,p1 : big) : real
{#>>
	return 0.0;
}#<<

putFloat_J_F_V( this : ref Unsafe_obj, p0 : big,p1 : real)
{#>>
}#<<

putFloat_rObject_J_F_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : real)
{#>>
}#<<

getDouble_J_D( this : ref Unsafe_obj, p0 : big) : real
{#>>
	return 0.0;
}#<<

getDouble_rObject_J_D( this : ref Unsafe_obj, p0 : JObject,p1 : big) : real
{#>>
	return 0.0;
}#<<

putDouble_J_D_V( this : ref Unsafe_obj, p0 : big,p1 : real)
{#>>
}#<<

putDouble_rObject_J_D_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : real)
{#>>
}#<<

getObjectVolatile_rObject_J_rObject( this : ref Unsafe_obj, p0 : JObject,p1 : big) : JObject
{#>>
	return nil;
}#<<

putObjectVolatile_rObject_J_rObject_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : JObject)
{#>>
}#<<

getBooleanVolatile_rObject_J_Z( this : ref Unsafe_obj, p0 : JObject,p1 : big) : byte
{#>>
	return byte 0;
}#<<

putBooleanVolatile_rObject_J_Z_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : byte)
{#>>
}#<<

getByteVolatile_rObject_J_B( this : ref Unsafe_obj, p0 : JObject,p1 : big) : byte
{#>>
	return byte 0;
}#<<

putByteVolatile_rObject_J_B_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : byte)
{#>>
}#<<

getShortVolatile_rObject_J_S( this : ref Unsafe_obj, p0 : JObject,p1 : big) : int
{#>>
	return 0;
}#<<

putShortVolatile_rObject_J_S_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : int)
{#>>
}#<<

getCharVolatile_rObject_J_C( this : ref Unsafe_obj, p0 : JObject,p1 : big) : int
{#>>
	return 0;
}#<<

putCharVolatile_rObject_J_C_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : int)
{#>>
}#<<

getIntVolatile_rObject_J_I( this : ref Unsafe_obj, p0 : JObject,p1 : big) : int
{#>>
	return 0;
}#<<

putIntVolatile_rObject_J_I_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : int)
{#>>
}#<<

getLongVolatile_rObject_J_J( this : ref Unsafe_obj, p0 : JObject,p1 : big) : big
{#>>
	return big 0;
}#<<

putLongVolatile_rObject_J_J_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : big)
{#>>
}#<<

getFloatVolatile_rObject_J_F( this : ref Unsafe_obj, p0 : JObject,p1 : big) : real
{#>>
	return 0.0;
}#<<

putFloatVolatile_rObject_J_F_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : real)
{#>>
}#<<

getDoubleVolatile_rObject_J_D( this : ref Unsafe_obj, p0 : JObject,p1 : big) : real
{#>>
	return 0.0;
}#<<

putDoubleVolatile_rObject_J_D_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : real)
{#>>
}#<<

getAddress_J_J( this : ref Unsafe_obj, p0 : big) : big
{#>>
	return big 0;
}#<<

putAddress_J_J_V( this : ref Unsafe_obj, p0 : big,p1 : big)
{#>>
}#<<

compareAndSwapObject_rObject_J_rObject_rObject_Z( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : JObject,p3 : JObject) : byte
{#>>
	return byte 0;
}#<<

compareAndSwapLong_rObject_J_J_J_Z( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : big,p3 : big) : byte
{#>>
	return byte 0;
}#<<

compareAndSwapInt_rObject_J_I_I_Z( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : int,p3 : int) : byte
{#>>
	return byte 0;
}#<<

putOrderedObject_rObject_J_rObject_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : JObject)
{#>>
}#<<

putOrderedLong_rObject_J_J_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : big)
{#>>
}#<<

putOrderedInt_rObject_J_I_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : int)
{#>>
}#<<

registerNatives_V( )
{#>>
}#<<

throwException_rThrowable_V( this : ref Unsafe_obj, p0 : JObject)
{#>>
}#<<

defineClass_rString_aB_I_I_rClassLoader_rProtectionDomain_rClass( this : ref Unsafe_obj, p0 : JString,p1 : JArrayB,p2 : int,p3 : int,p4 : JObject,p5 : JObject) : JClass
{#>>
	return nil;
}#<<

defineClass_rString_aB_I_I_rClass( this : ref Unsafe_obj, p0 : JString,p1 : JArrayB,p2 : int,p3 : int) : JClass
{#>>
	return nil;
}#<<

objectFieldOffset_rField_J( this : ref Unsafe_obj, p0 : JObject) : big
{#>>
	return big 0;
}#<<

staticFieldBase_rField_rObject( this : ref Unsafe_obj, p0 : JObject) : JObject
{#>>
	return nil;
}#<<

allocateMemory_J_J( this : ref Unsafe_obj, p0 : big) : big
{#>>
	return big 0;
}#<<

reallocateMemory_J_J_J( this : ref Unsafe_obj, p0 : big,p1 : big) : big
{#>>
	return big 0;
}#<<

setMemory_rObject_J_J_B_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : big,p3 : byte)
{#>>
}#<<

freeMemory_J_V( this : ref Unsafe_obj, p0 : big)
{#>>
}#<<

staticFieldOffset_rField_J( this : ref Unsafe_obj, p0 : JObject) : big
{#>>
	return big 0;
}#<<

ensureClassInitialized_rClass_V( this : ref Unsafe_obj, p0 : JClass)
{#>>
}#<<

arrayBaseOffset_rClass_I( this : ref Unsafe_obj, p0 : JClass) : int
{#>>
	return 0;
}#<<

arrayIndexScale_rClass_I( this : ref Unsafe_obj, p0 : JClass) : int
{#>>
	return 0;
}#<<

addressSize_I( this : ref Unsafe_obj) : int
{#>>
	return 0;
}#<<

pageSize_I( this : ref Unsafe_obj) : int
{#>>
	return 0;
}#<<

defineAnonymousClass_rClass_aB_aObject_rClass( this : ref Unsafe_obj, p0 : JClass,p1 : JArrayB,p2 : JArrayJObject) : JClass
{#>>
	return nil;
}#<<

monitorEnter_rObject_V( this : ref Unsafe_obj, p0 : JObject)
{#>>
}#<<

monitorExit_rObject_V( this : ref Unsafe_obj, p0 : JObject)
{#>>
}#<<

tryMonitorEnter_rObject_Z( this : ref Unsafe_obj, p0 : JObject) : byte
{#>>
	return byte 0;
}#<<

getLoadAverage_aD_I_I( this : ref Unsafe_obj, p0 : JArrayD,p1 : int) : int
{#>>
	return 0;
}#<<


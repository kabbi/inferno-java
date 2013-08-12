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
	low: Low;
#<<

include "Unsafe_L.m";

#>> extra post includes here

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    low = jni->LowMod();
    #<<
}

allocateInstance_rClass_rObject( this : ref Unsafe_obj, p0 : JClass) : JObject
{#>>
	# FIXME
	return nil;
}#<<

copyMemory_rObject_J_rObject_J_J_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : JObject,p3 : big,p4 : big)
{#>>
	# FIXME
}#<<

park_Z_J_V( this : ref Unsafe_obj, p0 : byte,p1 : big)
{#>>
	# FIXME
}#<<

unpark_rObject_V( this : ref Unsafe_obj, p0 : JObject)
{#>>
	# FIXME
}#<<

getObject_rObject_J_rObject( this : ref Unsafe_obj, p0 : JObject,p1 : big) : JObject
{#>>
	return low->GetObj(p0.mod, int p1);
}#<<

putObject_rObject_J_rObject_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : JObject)
{#>>
	low->SetObj(p0.mod, int p1, p2);
}#<<

getBoolean_rObject_J_Z( this : ref Unsafe_obj, p0 : JObject,p1 : big) : int
{#>>
	return low->GetInt(p0.mod, int p1);
}#<<

putBoolean_rObject_J_Z_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : int)
{#>>
	low->SetInt(p0.mod, int p1, p2);
}#<<

getByte_J_B( this : ref Unsafe_obj, p0 : big) : byte
{#>>
	# FIXME
	return byte 0;
}#<<

getByte_rObject_J_B( this : ref Unsafe_obj, p0 : JObject,p1 : big) : byte
{#>>
	return low->GetByte(p0.mod, int p1);
}#<<

putByte_J_B_V( this : ref Unsafe_obj, p0 : big,p1 : byte)
{#>>
	# FIXME
}#<<

putByte_rObject_J_B_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : byte)
{#>>
	low->SetByte(p0.mod, int p1, p2);
}#<<

getShort_rObject_J_S( this : ref Unsafe_obj, p0 : JObject,p1 : big) : int
{#>>
	return low->GetInt(p0.mod, int p1);
}#<<

getShort_J_S( this : ref Unsafe_obj, p0 : big) : int
{#>>
	# FIXME
	return 0;
}#<<

putShort_rObject_J_S_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : int)
{#>>
	low->SetInt(p0.mod, int p1, p2);
}#<<

putShort_J_S_V( this : ref Unsafe_obj, p0 : big,p1 : int)
{#>>
	# FIXME
}#<<

getChar_J_C( this : ref Unsafe_obj, p0 : big) : int
{#>>
	# FIXME
	return 0;
}#<<

getChar_rObject_J_C( this : ref Unsafe_obj, p0 : JObject,p1 : big) : int
{#>>
	return low->GetInt(p0.mod, int p1);
}#<<

putChar_J_C_V( this : ref Unsafe_obj, p0 : big,p1 : int)
{#>>
	# FIXME
}#<<

putChar_rObject_J_C_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : int)
{#>>
	low->SetInt(p0.mod, int p1, p2);
}#<<

getInt_rObject_J_I( this : ref Unsafe_obj, p0 : JObject,p1 : big) : int
{#>>
	return low->GetInt(p0.mod, int p1);
}#<<

getInt_J_I( this : ref Unsafe_obj, p0 : big) : int
{#>>
	# FIXME
	return 0;
}#<<

putInt_J_I_V( this : ref Unsafe_obj, p0 : big,p1 : int)
{#>>
	# FIXME
}#<<

putInt_rObject_J_I_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : int)
{#>>
	low->SetInt(p0.mod, int p1, p2);
}#<<

getLong_rObject_J_J( this : ref Unsafe_obj, p0 : JObject,p1 : big) : big
{#>>
	return low->GetBig(p0.mod, int p1);
}#<<

getLong_J_J( this : ref Unsafe_obj, p0 : big) : big
{#>>
	# FIXME
	return big 0;
}#<<

putLong_J_J_V( this : ref Unsafe_obj, p0 : big,p1 : big)
{#>>
	# FIXME
}#<<

putLong_rObject_J_J_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : big)
{#>>
	low->SetBig(p0.mod, int p1, p2);
}#<<

getFloat_J_F( this : ref Unsafe_obj, p0 : big) : real
{#>>
	# FIXME
	return 0.0;
}#<<

getFloat_rObject_J_F( this : ref Unsafe_obj, p0 : JObject,p1 : big) : real
{#>>
	return low->GetReal(p0.mod, int p1);
}#<<

putFloat_J_F_V( this : ref Unsafe_obj, p0 : big,p1 : real)
{#>>
	# FIXME
}#<<

putFloat_rObject_J_F_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : real)
{#>>
	low->SetReal(p0.mod, int p1, p2);
}#<<

getDouble_J_D( this : ref Unsafe_obj, p0 : big) : real
{#>>
	# FIXME
	return 0.0;
}#<<

getDouble_rObject_J_D( this : ref Unsafe_obj, p0 : JObject,p1 : big) : real
{#>>
	return low->GetReal(p0.mod, int p1);
}#<<

putDouble_J_D_V( this : ref Unsafe_obj, p0 : big,p1 : real)
{#>>
	# FIXME
}#<<

putDouble_rObject_J_D_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : real)
{#>>
	low->SetReal(p0.mod, int p1, p2);
}#<<

getObjectVolatile_rObject_J_rObject( this : ref Unsafe_obj, p0 : JObject,p1 : big) : JObject
{#>>
	return getObject_rObject_J_rObject(this, p0, p1);
}#<<

putObjectVolatile_rObject_J_rObject_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : JObject)
{#>>
	putObject_rObject_J_rObject_V(this, p0, p1, p2);
}#<<

getBooleanVolatile_rObject_J_Z( this : ref Unsafe_obj, p0 : JObject,p1 : big) : int
{#>>
	return getBoolean_rObject_J_Z(this, p0, p1);
}#<<

putBooleanVolatile_rObject_J_Z_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : int)
{#>>
	putBoolean_rObject_J_Z_V(this, p0, p1, p2);
}#<<

getByteVolatile_rObject_J_B( this : ref Unsafe_obj, p0 : JObject,p1 : big) : byte
{#>>
	return getByte_rObject_J_B(this, p0, p1);
}#<<

putByteVolatile_rObject_J_B_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : byte)
{#>>
	putByte_rObject_J_B_V(this, p0, p1, p2);
}#<<

getShortVolatile_rObject_J_S( this : ref Unsafe_obj, p0 : JObject,p1 : big) : int
{#>>
	return getShort_rObject_J_S(this, p0, p1);
}#<<

putShortVolatile_rObject_J_S_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : int)
{#>>
	putShort_rObject_J_S_V(this, p0, p1, p2);
}#<<

getCharVolatile_rObject_J_C( this : ref Unsafe_obj, p0 : JObject,p1 : big) : int
{#>>
	return getChar_rObject_J_C(this, p0, p1);
}#<<

putCharVolatile_rObject_J_C_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : int)
{#>>
	putChar_rObject_J_C_V(this, p0, p1, p2);
}#<<

getIntVolatile_rObject_J_I( this : ref Unsafe_obj, p0 : JObject,p1 : big) : int
{#>>
	return getInt_rObject_J_I(this, p0, p1);
}#<<

putIntVolatile_rObject_J_I_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : int)
{#>>
	putInt_rObject_J_I_V(this, p0, p1, p2);
}#<<

getLongVolatile_rObject_J_J( this : ref Unsafe_obj, p0 : JObject,p1 : big) : big
{#>>
	return getLong_rObject_J_J(this, p0, p1);
}#<<

putLongVolatile_rObject_J_J_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : big)
{#>>
	putLong_rObject_J_J_V(this, p0, p1, p2);
}#<<

getFloatVolatile_rObject_J_F( this : ref Unsafe_obj, p0 : JObject,p1 : big) : real
{#>>
	return getFloat_rObject_J_F(this, p0, p1);
}#<<

putFloatVolatile_rObject_J_F_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : real)
{#>>
	putFloat_rObject_J_F_V(this, p0, p1, p2);
}#<<

getDoubleVolatile_rObject_J_D( this : ref Unsafe_obj, p0 : JObject,p1 : big) : real
{#>>
	return getDouble_rObject_J_D(this, p0, p1);
}#<<

putDoubleVolatile_rObject_J_D_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : real)
{#>>
	putDouble_rObject_J_D_V(this, p0, p1, p2);
}#<<

getAddress_J_J( this : ref Unsafe_obj, p0 : big) : big
{#>>
	# FIXME
	return big 0;
}#<<

putAddress_J_J_V( this : ref Unsafe_obj, p0 : big,p1 : big)
{#>>
	# FIXME
}#<<

compareAndSwapObject_rObject_J_rObject_rObject_Z( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : JObject,p3 : JObject) : byte
{#>>
	# FIXME
	return byte 0;
}#<<

compareAndSwapLong_rObject_J_J_J_Z( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : big,p3 : big) : byte
{#>>
	# FIXME
	return byte 0;
}#<<

compareAndSwapInt_rObject_J_I_I_Z( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : int,p3 : int) : byte
{#>>
	# FIXME
	return byte 0;
}#<<

putOrderedObject_rObject_J_rObject_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : JObject)
{#>>
	putObject_rObject_J_rObject_V(this, p0, p1, p2);
}#<<

putOrderedLong_rObject_J_J_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : big)
{#>>
	putOrderedLong_rObject_J_J_V(this, p0, p1, p2);
}#<<

putOrderedInt_rObject_J_I_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : int)
{#>>
	putOrderedInt_rObject_J_I_V(this, p0, p1, p2);
}#<<

registerNatives_V( )
{#>>
}#<<

throwException_rThrowable_V( this : ref Unsafe_obj, p0 : JObject)
{#>>
	jni->Throw(p0);
}#<<

defineClass_rString_aB_I_I_rClassLoader_rProtectionDomain_rClass( this : ref Unsafe_obj, p0 : JString,p1 : JArrayB,p2 : int,p3 : int,p4 : JObject,p5 : JObject) : JClass
{#>>
	jni->FatalError("defineAnonymousClass is not implemented");
	return nil;
}#<<

defineClass_rString_aB_I_I_rClass( this : ref Unsafe_obj, p0 : JString,p1 : JArrayB,p2 : int,p3 : int) : JClass
{#>>
	jni->FatalError("defineAnonymousClass is not implemented");
	return nil;
}#<<

objectFieldOffset_rField_J( this : ref Unsafe_obj, p0 : JObject) : big
{#>>
	# FIXME
	return big 0;
}#<<

staticFieldBase_rField_rObject( this : ref Unsafe_obj, p0 : JObject) : JObject
{#>>
	# FIXME
	return nil;
}#<<

allocateMemory_J_J( this : ref Unsafe_obj, p0 : big) : big
{#>>
	# FIXME
	return big 0;
}#<<

reallocateMemory_J_J_J( this : ref Unsafe_obj, p0 : big,p1 : big) : big
{#>>
	# FIXME
	return big 0;
}#<<

setMemory_rObject_J_J_B_V( this : ref Unsafe_obj, p0 : JObject,p1 : big,p2 : big,p3 : byte)
{#>>
	# FIXME
}#<<

freeMemory_J_V( this : ref Unsafe_obj, p0 : big)
{#>>
	# FIXME
}#<<

staticFieldOffset_rField_J( this : ref Unsafe_obj, p0 : JObject) : big
{#>>
	# FIXME
	return big 0;
}#<<

ensureClassInitialized_rClass_V( this : ref Unsafe_obj, p0 : JClass)
{#>>
	jni->FindClass(p0.class.name);
}#<<

arrayBaseOffset_rClass_I( this : ref Unsafe_obj, p0 : JClass) : int
{#>>
	# FIXME
	return 0;
}#<<

arrayIndexScale_rClass_I( this : ref Unsafe_obj, p0 : JClass) : int
{#>>
	# FIXME
	return 0;
}#<<

addressSize_I( this : ref Unsafe_obj) : int
{#>>
	# TODO: obtain that value somehow?
	return 4;
}#<<

pageSize_I( this : ref Unsafe_obj) : int
{#>>
	# FIXME
	return 0;
}#<<

defineAnonymousClass_rClass_aB_aObject_rClass( this : ref Unsafe_obj, p0 : JClass,p1 : JArrayB,p2 : JArrayJObject) : JClass
{#>>
	jni->FatalError("defineAnonymousClass is not implemented");
	return nil;
}#<<

monitorEnter_rObject_V( this : ref Unsafe_obj, p0 : JObject)
{#>>
	jni->MonitorEnter(p0);
}#<<

monitorExit_rObject_V( this : ref Unsafe_obj, p0 : JObject)
{#>>
	jni->MonitorExit(p0);
}#<<

tryMonitorEnter_rObject_Z( this : ref Unsafe_obj, p0 : JObject) : int
{#>>
	jni->MonitorEnter(p0);
	return 1; # TODO: check something
}#<<

getLoadAverage_aD_I_I( this : ref Unsafe_obj, p0 : JArrayD,p1 : int) : int
{#>>
	# FIXME
	return 0;
}#<<


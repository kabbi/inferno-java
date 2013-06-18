# javal v1.5 generated file: edit with care

Array_L : module
{
    Array_obj : adt
    {
        cl_mod : ClassModule;
    };

    init : fn( jni_p : JNI );
    getLength_rObject_I : fn( p0 : JObject) : int;
    get_rObject_I_rObject : fn( p0 : JObject,p1 : int) : JObject;
    getBoolean_rObject_I_Z : fn( p0 : JObject,p1 : int) : int;
    getByte_rObject_I_B : fn( p0 : JObject,p1 : int) : int;
    getChar_rObject_I_C : fn( p0 : JObject,p1 : int) : int;
    getShort_rObject_I_S : fn( p0 : JObject,p1 : int) : int;
    getInt_rObject_I_I : fn( p0 : JObject,p1 : int) : int;
    getLong_rObject_I_J : fn( p0 : JObject,p1 : int) : big;
    getFloat_rObject_I_F : fn( p0 : JObject,p1 : int) : real;
    getDouble_rObject_I_D : fn( p0 : JObject,p1 : int) : real;
    set_rObject_I_rObject_V : fn( p0 : JObject,p1 : int,p2 : JObject);
    setBoolean_rObject_I_Z_V : fn( p0 : JObject,p1 : int,p2 : int);
    setByte_rObject_I_B_V : fn( p0 : JObject,p1 : int,p2 : int);
    setChar_rObject_I_C_V : fn( p0 : JObject,p1 : int,p2 : int);
    setShort_rObject_I_S_V : fn( p0 : JObject,p1 : int,p2 : int);
    setInt_rObject_I_I_V : fn( p0 : JObject,p1 : int,p2 : int);
    setLong_rObject_I_J_V : fn( p0 : JObject,p1 : int,p2 : big);
    setFloat_rObject_I_F_V : fn( p0 : JObject,p1 : int,p2 : real);
    setDouble_rObject_I_D_V : fn( p0 : JObject,p1 : int,p2 : real);
    newArray_rClass_I_rObject : fn( p0 : JClass,p1 : int) : JObject;
    multiNewArray_rClass_aI_rObject : fn( p0 : JClass,p1 : JArrayI) : JObject;

};

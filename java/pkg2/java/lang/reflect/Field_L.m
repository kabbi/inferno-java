# javal v1.5 generated file: edit with care

Field_L : module
{
    Field_obj : adt
    {
        cl_mod : ClassModule;
        clazz : JClass;
        slot : int;
        name : JString;
        type_j : JClass;
    };

    init : fn( jni_p : JNI );
    getModifiers_I : fn( this : ref Field_obj) : int;
    get_rObject_rObject : fn( this : ref Field_obj, p0 : JObject) : JObject;
    getBoolean_rObject_Z : fn( this : ref Field_obj, p0 : JObject) : int;
    getByte_rObject_B : fn( this : ref Field_obj, p0 : JObject) : int;
    getChar_rObject_C : fn( this : ref Field_obj, p0 : JObject) : int;
    getShort_rObject_S : fn( this : ref Field_obj, p0 : JObject) : int;
    getInt_rObject_I : fn( this : ref Field_obj, p0 : JObject) : int;
    getLong_rObject_J : fn( this : ref Field_obj, p0 : JObject) : big;
    getFloat_rObject_F : fn( this : ref Field_obj, p0 : JObject) : real;
    getDouble_rObject_D : fn( this : ref Field_obj, p0 : JObject) : real;
    set_rObject_rObject_V : fn( this : ref Field_obj, p0 : JObject,p1 : JObject);
    setBoolean_rObject_Z_V : fn( this : ref Field_obj, p0 : JObject,p1 : int);
    setByte_rObject_B_V : fn( this : ref Field_obj, p0 : JObject,p1 : int);
    setChar_rObject_C_V : fn( this : ref Field_obj, p0 : JObject,p1 : int);
    setShort_rObject_S_V : fn( this : ref Field_obj, p0 : JObject,p1 : int);
    setInt_rObject_I_V : fn( this : ref Field_obj, p0 : JObject,p1 : int);
    setLong_rObject_J_V : fn( this : ref Field_obj, p0 : JObject,p1 : big);
    setFloat_rObject_F_V : fn( this : ref Field_obj, p0 : JObject,p1 : real);
    setDouble_rObject_D_V : fn( this : ref Field_obj, p0 : JObject,p1 : real);

};

# javal v1.4 generated file: edit with care

##EDITED

StringBuffer_L : module
{
    StringBuffer_obj : adt
    {
        cl_mod : ClassModule;
        Ivalue : string;
        buf_capacity : int;
        value : array of int;
        count : int;
        shared : byte;
    };

    init : fn( jni_p : JNI );
    setLength0_I_V : fn( this : ref StringBuffer_obj, p0 : int);
    charAt0_I_C : fn( this : ref StringBuffer_obj, p0 : int) : int;
    getChars0_I_I_aC_I_V : fn( this : ref StringBuffer_obj, p0 : int,p1 : int,p2 : JArrayC,p3 : int);
    setCharAt0_I_C_V : fn( this : ref StringBuffer_obj, p0 : int,p1 : int);
    reverse0_V : fn( this : ref StringBuffer_obj);
    append_int_I_V : fn( this : ref StringBuffer_obj, p0 : int);
    append_long_J_V : fn( this : ref StringBuffer_obj, p0 : big);
    append_str_rString_V : fn( this : ref StringBuffer_obj, p0 : JString);
    append_chars_aC_I_I_V : fn( this : ref StringBuffer_obj, p0 : JArrayC,p1 : int,p2 : int);
    append_ch_C_V : fn( this : ref StringBuffer_obj, p0 : int);
    append_float_F_V : fn( this : ref StringBuffer_obj, p0 : real);
    append_double_D_V : fn( this : ref StringBuffer_obj, p0 : real);
    insert_int_I_I_V : fn( this : ref StringBuffer_obj, p0 : int,p1 : int);
    insert_long_I_J_V : fn( this : ref StringBuffer_obj, p0 : int,p1 : big);
    insert_str_I_rString_V : fn( this : ref StringBuffer_obj, p0 : int,p1 : JString);
    insert_chars_I_aC_V : fn( this : ref StringBuffer_obj, p0 : int,p1 : JArrayC);
    insert_ch_I_C_V : fn( this : ref StringBuffer_obj, p0 : int,p1 : int);
    insert_float_I_F_V : fn( this : ref StringBuffer_obj, p0 : int,p1 : real);
    insert_double_I_D_V : fn( this : ref StringBuffer_obj, p0 : int,p1 : real);
    get_string_rString : fn( this : ref StringBuffer_obj) : JString;
    get_chars_aC : fn( this : ref StringBuffer_obj) : JArrayC;

    writeObject0_rObjectOutputStream_V : fn(this : ref StringBuffer_obj, p0 : JObject);
    readObject0_rObjectInputStream_V : fn(this : ref StringBuffer_obj, p0 : JObject);
};

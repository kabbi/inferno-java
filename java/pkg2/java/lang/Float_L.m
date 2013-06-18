# javal v1.3 generated file: edit with care

Float_L : module
{
    Float_obj : adt
    {
        cl_mod : ClassModule;
        value : real;
    };

    init : fn( jni_p : JNI );
    floatToIntBits_F_I : fn( p0 : real) : int;
    intBitsToFloat_I_F : fn( p0 : int) : real;
    mkstring_F_rString : fn( p0 : real) : JString;

};

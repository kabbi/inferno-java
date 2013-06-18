# javal v1.3 generated file: edit with care

Double_L : module
{
    Double_obj : adt
    {
        cl_mod : ClassModule;
        value : real;
    };

    init : fn( jni_p : JNI );
    doubleToLongBits_D_J : fn( p0 : real) : big;
    longBitsToDouble_J_D : fn( p0 : big) : real;
    valueOf0_rString_D : fn( p0 : JString) : real;
    mkstring_D_rString : fn( p0 : real) : JString;

};

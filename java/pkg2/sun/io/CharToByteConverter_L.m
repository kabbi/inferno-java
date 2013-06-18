# javal v1.3 generated file: edit with care

CharToByteConverter_L : module
{
    CharToByteConverter_obj : adt
    {
        cl_mod : ClassModule;
        convert : Converter;
    };

    init : fn( jni_p : JNI );
    Init_rString_V : fn( this : ref CharToByteConverter_obj, p0 : JString);
    convert_aC_I_I_aB_I_I_I : fn( this : ref CharToByteConverter_obj, p0 : JArrayC,p1 : int,p2 : int,p3 : JArrayB,p4 : int,p5 : int) : int;
    convertAll_aC_aB : fn( this : ref CharToByteConverter_obj, p0 : JArrayC) : JArrayB;
    flush_aB_I_I_I : fn( this : ref CharToByteConverter_obj, p0 : JArrayB,p1 : int,p2 : int) : int;
    reset_V : fn( this : ref CharToByteConverter_obj);
    canConvert_C_Z : fn( this : ref CharToByteConverter_obj, p0 : int) : int;
    getMaxBytesPerChar_I : fn( this : ref CharToByteConverter_obj) : int;
    getBadInputLength_I : fn( this : ref CharToByteConverter_obj) : int;
    nextCharIndex_I : fn( this : ref CharToByteConverter_obj) : int;
    nextByteIndex_I : fn( this : ref CharToByteConverter_obj) : int;
    setSubstitutionMode_Z_V : fn( this : ref CharToByteConverter_obj, p0 : int);
    setSubstitutionBytes_aB_V : fn( this : ref CharToByteConverter_obj, p0 : JArrayB);
    getCharacterEncoding_rString : fn( this : ref CharToByteConverter_obj) : JString;

};

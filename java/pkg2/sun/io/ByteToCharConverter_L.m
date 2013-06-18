# javal v1.3 generated file: edit with care

ByteToCharConverter_L : module
{
    ByteToCharConverter_obj : adt
    {
        cl_mod : ClassModule;
        convert : Converter;
    };

    init : fn( jni_p : JNI );
    Init_rString_V : fn( this : ref ByteToCharConverter_obj, p0 : JString);
    convert_aB_I_I_aC_I_I_I : fn( this : ref ByteToCharConverter_obj, p0 : JArrayB,p1 : int,p2 : int,p3 : JArrayC,p4 : int,p5 : int) : int;
    convertAll_aB_aC : fn( this : ref ByteToCharConverter_obj, p0 : JArrayB) : JArrayC;
    flush_aC_I_I_I : fn( this : ref ByteToCharConverter_obj, p0 : JArrayC,p1 : int,p2 : int) : int;
    reset_V : fn( this : ref ByteToCharConverter_obj);
    getMaxCharsPerByte_I : fn( this : ref ByteToCharConverter_obj) : int;
    getBadInputLength_I : fn( this : ref ByteToCharConverter_obj) : int;
    nextCharIndex_I : fn( this : ref ByteToCharConverter_obj) : int;
    nextByteIndex_I : fn( this : ref ByteToCharConverter_obj) : int;
    setSubstitutionMode_Z_V : fn( this : ref ByteToCharConverter_obj, p0 : int);
    setSubstitutionChars_aC_V : fn( this : ref ByteToCharConverter_obj, p0 : JArrayC);
    getCharacterEncoding_rString : fn( this : ref ByteToCharConverter_obj) : JString;

};

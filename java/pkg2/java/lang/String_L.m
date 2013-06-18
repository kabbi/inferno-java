# javal v1.6 generated file: edit with care

String_L : module
{

    init : fn( jni_p : JNI );
    length_I : fn( this : JString) : int;
    charAt_I_C : fn( this : JString, p0 : int) : int;
    getChars_I_I_aC_I_V : fn( this : JString, p0 : int,p1 : int,p2 : JArrayC,p3 : int);
    equality_rString_Z_Z : fn( this : JString, p0 : JString,p1 : int) : int;
    compareTo_rString_I : fn( this : JString, p0 : JString) : int;
    regionMatches_Z_I_rString_I_I_Z : fn( this : JString, p0 : int,p1 : int,p2 : JString,p3 : int,p4 : int) : int;
    hashCode_I : fn( this : JString) : int;
    substring_I_I_rString : fn( this : JString, p0 : int,p1 : int) : JString;
    concat_rString_rString : fn( this : JString, p0 : JString) : JString;
    replace_C_C_rString : fn( this : JString, p0 : int,p1 : int) : JString;
    trim_rString : fn( this : JString) : JString;
    intern_rString : fn( this : JString) : JString;
    utfLength_I : fn( this : JString) : int;
    fill_aC_I_I_V : fn( this : JString, p0 : JArrayC,p1 : int,p2 : int);
    isPrefix_rString_I_Z : fn( this : JString, p0 : JString,p1 : int) : int;
    isSuffix_rString_Z : fn( this : JString, p0 : JString) : int;
    uppercase_rString : fn( this : JString) : JString;
    lowercase_rString : fn( this : JString) : JString;
    index_rString_I_I : fn( this : JString, p0 : JString,p1 : int) : int;
    index_I_I_I : fn( this : JString, p0 : int,p1 : int) : int;
    rindex_rString_I_Z_I : fn( this : JString, p0 : JString,p1 : int,p2 : int) : int;
    rindex_I_I_Z_I : fn( this : JString, p0 : int,p1 : int,p2 : int) : int;

};

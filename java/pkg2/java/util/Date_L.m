# javal v1.3 generated file: edit with care

Date_L : module
{
    Date_obj : adt
    {
        cl_mod : ClassModule;
        value : big;
        valueValid :  byte;
        expanded :  byte;
        tm_millis : int;
        tm_sec : byte;
        tm_min : byte;
        tm_hour : byte;
        tm_mday : byte;
        tm_mon : byte;
        tm_wday : byte;
        tm_yday : int;
        tm_year : int;
        tm_isdst : int;
    };

    init : fn( jni_p : JNI );
    toString_rString : fn( this : ref Date_obj) : JString;
    toLocaleString_rString : fn( this : ref Date_obj) : JString;
    toGMTString_rString : fn( this : ref Date_obj) : JString;
    expand_V : fn( this : ref Date_obj);
    computeValue_V : fn( this : ref Date_obj);

};

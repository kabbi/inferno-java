# javal v1.5 generated file: edit with care

iFontMetrics_L : module
{
    iFontMetrics_obj : adt
    {
        cl_mod : ClassModule;
        font : JObject;
        widths : JArrayI;
        ascent : int;
        descent : int;
        leading : int;
        height : int;
        maxAscent : int;
        maxDescent : int;
        maxHeight : int;
        maxAdvance : int;
        needWidths : byte;
        ifontpeer : ref iFontPeer_obj; # javal generates JObject;
    };

    init : fn( jni_p : JNI );
    iStringWidth_rString_I : fn( this : ref iFontMetrics_obj, p0 : JString) : int;
    iBytesWidth_aB_I : fn( this : ref iFontMetrics_obj, p0 : JArrayB) : int;
    iInitWidths_aI_I : fn( this : ref iFontMetrics_obj, p0 : JArrayI) : int;

};

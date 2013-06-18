# javal v1.5 generated file: edit with care

iFontPeer_L : module
{
    PATH : con "/dis/java/inferno/awt/iFontPeer_L.dis";

    iFontPeer_obj : adt
    {
        cl_mod : ClassModule;
        iFontRef : ref Font; # javal generates JObject;
        iAscent : int;
        iHeight : int;
        fLeading : int;
        iName : JString;
    };

    init : fn( jni_p : JNI );
    initFontPeer_rString_V : fn( this : ref iFontPeer_obj, p0 : JString);

};

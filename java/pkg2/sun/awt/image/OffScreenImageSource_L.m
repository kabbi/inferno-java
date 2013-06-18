# javal v1.5 generated file: edit with care

OffScreenImageSource_L : module
{
    OffScreenImageSource_obj : adt
    {
        cl_mod : ClassModule;
        target : JObject;
        width : int;
        height : int;
        baseIR : JObject;
        theConsumer : JObject;
    };

    init : fn( jni_p : JNI );
    sendPixels_V : fn( this : ref OffScreenImageSource_obj);

};

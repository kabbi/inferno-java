# javal v1.5 generated file: edit with care

JPEGImageDecoder_L : module
{
    JPEGImageDecoder_obj : adt
    {
        cl_mod : ClassModule;
        source : JObject;
        input : JObject;
        feeder : JThread;
        aborted : byte;
        finished : byte;
        queue : JObject;
        next : JObject;
        store : JObject;
        props : JObject;
    };

    init : fn( jni_p : JNI );
    readImage_rInputStream_aB_V : fn( this : ref JPEGImageDecoder_obj, p0 : JObject,p1 : JArrayB);

};

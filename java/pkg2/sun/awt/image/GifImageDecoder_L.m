# javal v1.5 generated file: edit with care

GifImageDecoder_L : module
{
    GifImageDecoder_obj : adt
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
        cancatchup : byte;
        num_global_colors : int;
        global_colormap : JArrayB;
        trans_pixel : int;
        global_model : JObject;
        props : JObject;
        saved_image : JArrayB;
        saved_model : JObject;
        global_width : int;
        global_height : int;
        global_bgpixel : int;
        curframe : JObject;
        prefix : JArrayS;
        suffix : JArrayB;
        outCode : JArrayB;
    };

    init : fn( jni_p : JNI );
    parseImage_I_I_I_I_Z_I_aB_aB_rIndexColorModel_Z : fn( this : ref GifImageDecoder_obj, p0 : int,p1 : int,p2 : int,p3 : int,p4 : int,p5 : int,p6 : JArrayB,p7 : JArrayB,p8 : JObject) : int;

};

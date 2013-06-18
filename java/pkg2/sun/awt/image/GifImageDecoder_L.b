implement GifImageDecoder_L;

# javal v1.5 generated file: edit with care

include "jni.m";
    jni : JNI;
        ClassModule,
        JString,
        JArray,
        JArrayI,
        JArrayC,
        JArrayB,
        JArrayS,
        JArrayJ,
        JArrayF,
        JArrayD,
        JArrayZ,
        JArrayJObject,
        JArrayJClass,
        JArrayJString,
        JClass,
        JThread,
        JObject : import jni;

#>> extra pre includes here
    sys : Sys;
    draw : Draw;
    FALSE : import jni;
    TRUE : import jni;
#<<

include "GifImageDecoder_L.m";

#>> extra post includes here

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    sys = jni->sys;
    #<<
}

parseImage_I_I_I_I_Z_I_aB_aB_rIndexColorModel_Z( this : ref GifImageDecoder_obj, p0 : int,p1 : int,p2 : int,p3 : int,p4 : int,p5 : int,p6 : JArrayB,p7 : JArrayB,p8 : JObject) : int
{#>>
    # not yet implemented so just keep the type system happy by returning
    # false
    sys->print("GifImageDecoder_L.parseImage() - NYI!\n");
    return(FALSE);
}#<<


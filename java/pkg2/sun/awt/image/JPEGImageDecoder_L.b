implement JPEGImageDecoder_L;

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
#<<

include "JPEGImageDecoder_L.m";

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

readImage_rInputStream_aB_V( this : ref JPEGImageDecoder_obj, p0 : JObject,p1 : JArrayB)
{#>>
    sys->print("JPGEImageDecoder_L.readImage() - NYI!\n");
}#<<


implement CRC32_L;

# javal v1.4 generated file: edit with care

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

#<<

include "CRC32_L.m";

#>> extra post includes here

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    #<<
}

update_aB_I_I_V( this : ref CRC32_obj, p0 : JArrayB,p1 : int,p2 : int)
{#>>
}#<<

update1_I_V( this : ref CRC32_obj, p0 : int)
{#>>
}#<<



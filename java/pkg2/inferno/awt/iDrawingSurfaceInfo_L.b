implement iDrawingSurfaceInfo_L;

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

include "iDrawingSurfaceInfo_L.m";

#>> extra post includes here

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    #<<
}

lock_I( this : ref iDrawingSurfaceInfo_obj) : int
{#>>
}#<<

unlock_V( this : ref iDrawingSurfaceInfo_obj)
{#>>
}#<<

getDrawable_rObject( this : ref iDrawingSurfaceInfo_obj) : JObject
{#>>
}#<<

getDepth_I( this : ref iDrawingSurfaceInfo_obj) : int
{#>>
}#<<


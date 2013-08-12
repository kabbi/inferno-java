implement Bits_L;

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
        JObject : import jni;

#>> extra pre includes here

#<<

include "Bits_L.m";

#>> extra post includes here

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    #<<
}

# TODO: implement this

copyFromShortArray_rObject_J_J_J_V( p0 : JObject,p1 : big,p2 : big,p3 : big)
{#>>
}#<<

copyToShortArray_J_rObject_J_J_V( p0 : big,p1 : JObject,p2 : big,p3 : big)
{#>>
}#<<

copyFromIntArray_rObject_J_J_J_V( p0 : JObject,p1 : big,p2 : big,p3 : big)
{#>>
}#<<

copyToIntArray_J_rObject_J_J_V( p0 : big,p1 : JObject,p2 : big,p3 : big)
{#>>
}#<<

copyFromLongArray_rObject_J_J_J_V( p0 : JObject,p1 : big,p2 : big,p3 : big)
{#>>
}#<<

copyToLongArray_J_rObject_J_J_V( p0 : big,p1 : JObject,p2 : big,p3 : big)
{#>>
}#<<


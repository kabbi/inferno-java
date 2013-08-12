implement Version_L;

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

include "Version_L.m";

#>> extra post includes here

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    #<<
}

getJvmSpecialVersion_rString( ) : JString
{#>>
    # official jvm returns empty string here,
    # and I have no idea what should really be returned
    return jni->NewString("");
}#<<

getJdkSpecialVersion_rString( ) : JString
{#>>
    # official jvm returns empty string here,
    # and I have no idea what should really be returned
    return jni->NewString("");
}#<<

getJvmVersionInfo_Z( ) : int
{#>>
    # TODO: implement
    # returning false means that Version
    # will parse info from java.vm.version prop
    return 0;
}#<<

getJdkVersionInfo_V( )
{#>>
    # TODO: implement
}#<<


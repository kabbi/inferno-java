implement FileSystem_L;

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

include "FileSystem_L.m";

#>> extra post includes here

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    #<<
}

getFileSystem_rFileSystem( ) : JObject
{#>>
    nativefs := jni->FindClass("java/io/NativeFileSystem");
    if (nativefs == nil)
        jni->FatalError("could not obtain NativeFileSystem class");
    return jni->NewObject(nativefs);
}#<<


implement NativeFileSystem_L;

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

include "NativeFileSystem_L.m";

#>> extra post includes here

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    #<<
}

prefixLength_rString_I( this : ref NativeFileSystem_obj, p0 : JString) : int
{#>>
    # no prefixes in Inferno
    return 0;
}#<<

listRoots_aFile( this : ref NativeFileSystem_obj) : JArrayJObject
{#>>
    # TODO: implement
    return nil;
}#<<

normalize_rString_rString( this : ref NativeFileSystem_obj, p0 : JString) : JString
{#>>
    # TODO: implement
    return p0;
}#<<

getDefaultParent_rString( this : ref NativeFileSystem_obj) : JString
{#>>
    # TODO: is it really so?
    return jni->NewString("/");
}#<<

fromURIPath_rString_rString( this : ref NativeFileSystem_obj, p0 : JString) : JString
{#>>
    # TODO: is it really so?
    return p0;
}#<<

getBooleanAttributes_rFile_I( this : ref NativeFileSystem_obj, p0 : File_obj) : int
{#>>
    return 0;
}#<<

getLastModifiedTime_rFile_J( this : ref NativeFileSystem_obj, p0 : File_obj) : big
{#>>
    return big 0;
}#<<

createFileExclusively_rString_Z( this : ref NativeFileSystem_obj, p0 : JString) : int
{#>>
    return 0;
}#<<

createDirectory_rFile_Z( this : ref NativeFileSystem_obj, p0 : File_obj) : int
{#>>
    return 0;
}#<<

rename_rFile_rFile_Z( this : ref NativeFileSystem_obj, p0 : File_obj,p1 : File_obj) : int
{#>>
    return 0;
}#<<

setLastModifiedTime_rFile_J_Z( this : ref NativeFileSystem_obj, p0 : File_obj,p1 : big) : int
{#>>
    return 0;
}#<<

setPermission_rFile_I_Z_Z_Z( this : ref NativeFileSystem_obj, p0 : File_obj,p1 : int,p2 : int,p3 : int) : int
{#>>
    return 0;
}#<<

getSpace_rFile_I_J( this : ref NativeFileSystem_obj, p0 : File_obj,p1 : int) : big
{#>>
    return big 0;
}#<<

getSeparator_C( this : ref NativeFileSystem_obj) : int
{#>>
    return '/';
}#<<

getPathSeparator_C( this : ref NativeFileSystem_obj) : int
{#>>
    return ':';
}#<<

hashCode_rFile_I( this : ref NativeFileSystem_obj, p0 : File_obj) : int
{#>>
    return 0;
}#<<

getLength_rFile_J( this : ref NativeFileSystem_obj, p0 : File_obj) : big
{#>>
    return big 0;
}#<<

compare_rFile_rFile_I( this : ref NativeFileSystem_obj, p0 : File_obj,p1 : File_obj) : int
{#>>
    return 0;
}#<<

isAbsolute_rFile_Z( this : ref NativeFileSystem_obj, p0 : File_obj) : int
{#>>
    return 0;
}#<<

setReadOnly_rFile_Z( this : ref NativeFileSystem_obj, p0 : File_obj) : int
{#>>
    return 0;
}#<<

checkAccess_rFile_I_Z( this : ref NativeFileSystem_obj, p0 : File_obj,p1 : int) : int
{#>>
    return 0;
}#<<

list_rFile_aString( this : ref NativeFileSystem_obj, p0 : File_obj) : JArrayJString
{#>>
    return nil;
}#<<

resolve_rFile_rString( this : ref NativeFileSystem_obj, p0 : File_obj) : JString
{#>>
    return nil;
}#<<

resolve_rString_rString_rString( this : ref NativeFileSystem_obj, p0 : JString,p1 : JString) : JString
{#>>
    return nil;
}#<<

canonicalize_rString_rString( this : ref NativeFileSystem_obj, p0 : JString) : JString
{#>>
    return nil;
}#<<

delete_rFile_Z( this : ref NativeFileSystem_obj, p0 : File_obj) : int
{#>>
    return 0;
}#<<


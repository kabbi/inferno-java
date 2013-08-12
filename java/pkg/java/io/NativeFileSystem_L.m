# generated file edit with care

NativeFileSystem_L : module
{
    NativeFileSystem_obj : adt
    {
        cl_mod : ClassModule;
    };
    File_obj : adt
    {
        cl_mod : ClassModule;
        path: JString;
    };

    init : fn( jni_p : JNI );
    prefixLength_rString_I : fn( this : ref NativeFileSystem_obj, p0 : JString) : int;
    listRoots_aFile : fn( this : ref NativeFileSystem_obj) : JArrayJObject;
    normalize_rString_rString : fn( this : ref NativeFileSystem_obj, p0 : JString) : JString;
    getDefaultParent_rString : fn( this : ref NativeFileSystem_obj) : JString;
    fromURIPath_rString_rString : fn( this : ref NativeFileSystem_obj, p0 : JString) : JString;
    getBooleanAttributes_rFile_I : fn( this : ref NativeFileSystem_obj, p0 : File_obj) : int;
    getLastModifiedTime_rFile_J : fn( this : ref NativeFileSystem_obj, p0 : File_obj) : big;
    createFileExclusively_rString_Z : fn( this : ref NativeFileSystem_obj, p0 : JString) : int;
    createDirectory_rFile_Z : fn( this : ref NativeFileSystem_obj, p0 : File_obj) : int;
    rename_rFile_rFile_Z : fn( this : ref NativeFileSystem_obj, p0 : File_obj,p1 : File_obj) : int;
    setLastModifiedTime_rFile_J_Z : fn( this : ref NativeFileSystem_obj, p0 : File_obj,p1 : big) : int;
    setPermission_rFile_I_Z_Z_Z : fn( this : ref NativeFileSystem_obj, p0 : File_obj,p1 : int,p2 : int,p3 : int) : int;
    getSpace_rFile_I_J : fn( this : ref NativeFileSystem_obj, p0 : File_obj,p1 : int) : big;
    getSeparator_C : fn( this : ref NativeFileSystem_obj) : int;
    getPathSeparator_C : fn( this : ref NativeFileSystem_obj) : int;
    hashCode_rFile_I : fn( this : ref NativeFileSystem_obj, p0 : File_obj) : int;
    getLength_rFile_J : fn( this : ref NativeFileSystem_obj, p0 : File_obj) : big;
    compare_rFile_rFile_I : fn( this : ref NativeFileSystem_obj, p0 : File_obj,p1 : File_obj) : int;
    isAbsolute_rFile_Z : fn( this : ref NativeFileSystem_obj, p0 : File_obj) : int;
    setReadOnly_rFile_Z : fn( this : ref NativeFileSystem_obj, p0 : File_obj) : int;
    checkAccess_rFile_I_Z : fn( this : ref NativeFileSystem_obj, p0 : File_obj,p1 : int) : int;
    list_rFile_aString : fn( this : ref NativeFileSystem_obj, p0 : File_obj) : JArrayJString;
    resolve_rFile_rString : fn( this : ref NativeFileSystem_obj, p0 : File_obj) : JString;
    resolve_rString_rString_rString : fn( this : ref NativeFileSystem_obj, p0 : JString,p1 : JString) : JString;
    canonicalize_rString_rString : fn( this : ref NativeFileSystem_obj, p0 : JString) : JString;
    delete_rFile_Z : fn( this : ref NativeFileSystem_obj, p0 : File_obj) : int;

};

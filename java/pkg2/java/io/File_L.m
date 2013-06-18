# javal v1.3 generated file: edit with care

File_L : module
{
    File_obj : adt
    {
        cl_mod : ClassModule;
        path : JString;
    };

    init : fn( jni_p : JNI );
    exists0_Z : fn( this : ref File_obj) : int;
    canWrite0_Z : fn( this : ref File_obj) : int;
    canRead0_Z : fn( this : ref File_obj) : int;
    isFile0_Z : fn( this : ref File_obj) : int;
    isDirectory0_Z : fn( this : ref File_obj) : int;
    lastModified0_J : fn( this : ref File_obj) : big;
    length0_J : fn( this : ref File_obj) : big;
    mkdir0_Z : fn( this : ref File_obj) : int;
    renameTo0_rFile_Z : fn( this : ref File_obj, p0 : ref File_obj) : int;
    delete0_Z : fn( this : ref File_obj) : int;
    rmdir0_Z : fn( this : ref File_obj) : int;
    list0_aString : fn( this : ref File_obj) : JArrayJString;
    canonPath_rString_rString : fn( this : ref File_obj, p0 : JString) : JString;
    isAbsolute_Z : fn( this : ref File_obj) : int;

};

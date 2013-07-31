# javal v1.3 generated file: edit with care

FileOutputStream_L : module
{
    FileOutputStream_obj : adt
    {
        cl_mod : ClassModule;
        fd : ref FileDescriptor_obj;
    };

    init : fn( jni_p : JNI );
    open_rString_Z_V : fn( this : ref FileOutputStream_obj, p0 : JString, p1 : int);
    write_I_Z_V : fn( this : ref FileOutputStream_obj, p0 : int, p1 : int);
    writeBytes_aB_I_I_Z_V : fn( this : ref FileOutputStream_obj, p0 : JArrayB,p1 : int,p2 : int, p3 : int);
    close0_V : fn( this : ref FileOutputStream_obj);
    initIDs_V: fn( );

};

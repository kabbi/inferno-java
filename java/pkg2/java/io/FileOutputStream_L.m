# javal v1.3 generated file: edit with care

FileOutputStream_L : module
{
    FileOutputStream_obj : adt
    {
        cl_mod : ClassModule;
        fd : ref FileDescriptor_obj;
    };

    init : fn( jni_p : JNI );
    open_rString_V : fn( this : ref FileOutputStream_obj, p0 : JString);
    openAppend_rString_V : fn( this : ref FileOutputStream_obj, p0 : JString);
    write_I_V : fn( this : ref FileOutputStream_obj, p0 : int);
    writeBytes_aB_I_I_V : fn( this : ref FileOutputStream_obj, p0 : JArrayB,p1 : int,p2 : int);
    close_V : fn( this : ref FileOutputStream_obj);

};

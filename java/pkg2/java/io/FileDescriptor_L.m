# javal v1.3 generated file: edit with care

FileDescriptor_L : module
{
    FileDescriptor_obj : adt
    {
        cl_mod : ClassModule;
        fd : ref Sys->FD;
    };

    init : fn( jni_p : JNI );
    valid_Z : fn( this : ref FileDescriptor_obj) : int;
    sync_V : fn( this : ref FileDescriptor_obj);
    initSystemFD_rFileDescriptor_I_rFileDescriptor : fn( p0 : ref FileDescriptor_obj,p1 : int) : ref FileDescriptor_obj;

};

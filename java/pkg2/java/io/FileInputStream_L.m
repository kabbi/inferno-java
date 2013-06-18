# javal v1.3 generated file: edit with care

FileInputStream_L : module
{
    FileInputStream_obj : adt
    {
        cl_mod : ClassModule;
        fd : ref FileDescriptor_obj;
    };

    init : fn( jni_p : JNI );
    open_rString_V : fn( this : ref FileInputStream_obj, p0 : JString);
    read_I : fn( this : ref FileInputStream_obj) : int;
    readBytes_aB_I_I_I : fn( this : ref FileInputStream_obj, p0 : JArrayB,p1 : int,p2 : int) : int;
    skip_J_J : fn( this : ref FileInputStream_obj, p0 : big) : big;
    available_I : fn( this : ref FileInputStream_obj) : int;
    close_V : fn( this : ref FileInputStream_obj);

};

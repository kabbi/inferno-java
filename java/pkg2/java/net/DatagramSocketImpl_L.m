# generated file edit with care

DatagramSocketImpl_L : module
{
    DatagramSocketImpl_obj : adt
    {
        cl_mod : ClassModule;
        localPort : int;
        fd : ref FileDescriptor_obj;
    };

    init : fn( jni_p : JNI );

};

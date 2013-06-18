# generated file edit with care

SocketOutputStream_L : module
{
    SocketOutputStream_obj : adt
    {
        cl_mod : ClassModule;
        fd : ref FileDescriptor_obj;
        impl : JObject;
        temp : JArrayB;
    };

    init : fn( jni_p : JNI );
    socketWrite_aB_I_I_V : fn( this : ref SocketOutputStream_obj, p0 : JArrayB,p1 : int,p2 : int);

};

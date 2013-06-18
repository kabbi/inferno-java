# generated file edit with care

SocketInputStream_L : module
{
    SocketInputStream_obj : adt
    {
        cl_mod : ClassModule;
        fd : ref FileDescriptor_obj;
        eof : int;
        impl : ref PlainSocketImpl_obj;
        temp : JArrayB;
    };

    init : fn( jni_p : JNI );
    socketRead_aB_I_I_I : fn( this : ref SocketInputStream_obj, p0 : JArrayB,p1 : int,p2 : int) : int;

};

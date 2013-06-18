# generated file edit with care

SocketImpl_L : module
{
    SocketImpl_obj : adt
    {
        cl_mod : ClassModule;
 	cfd : ref FileDescriptor_obj;
	ctype: int;
	connection: int;
        fd : ref FileDescriptor_obj;
        address : ref InetAddress_obj;
        port : int;
        localport : int;
    };

    init : fn( jni_p : JNI );

};

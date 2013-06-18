# generated file edit with care

PlainSocketImpl_L : module
{
    PlainSocketImpl_obj : adt
    {
        cl_mod : ClassModule;
        cfd : ref FileDescriptor_obj;
        ctype : int;
        connection : int;
        fd : ref FileDescriptor_obj;
        address : ref InetAddress_obj;
        port : int;
        localport : int;
        timeout : int;
    };

    init : fn( jni_p : JNI );
    socketCreate_Z_V : fn( this : ref PlainSocketImpl_obj, p0 : int);
    socketConnect_rInetAddress_I_V : fn( this : ref PlainSocketImpl_obj, p0 : ref InetAddress_obj,p1 : int);
    socketBind_rInetAddress_I_V : fn( this : ref PlainSocketImpl_obj, p0 : ref InetAddress_obj,p1 : int);
    socketListen_I_V : fn( this : ref PlainSocketImpl_obj, p0 : int);
    socketAccept_rSocketImpl_V : fn( this : ref PlainSocketImpl_obj, p0 : ref SocketImpl_obj);
    socketAvailable_I : fn( this : ref PlainSocketImpl_obj) : int;
    socketClose_V : fn( this : ref PlainSocketImpl_obj);
    initProto_V : fn( );
    socketSetOption_I_Z_rObject_V : fn( this : ref PlainSocketImpl_obj, p0 : int,p1 : int,p2 : JObject);
    socketGetOption_I_I : fn( this : ref PlainSocketImpl_obj, p0 : int) : int;

};

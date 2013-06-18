# javal v1.5 generated file: edit with care

PlainDatagramSocketImpl_L : module
{
    PlainDatagramSocketImpl_obj : adt
    {
        cl_mod : ClassModule;
        localPort : int;
        fd : ref FileDescriptor_obj;
        cfd : ref FileDescriptor_obj;
        connection : int;
        timeout : int;
    };

    init : fn( jni_p : JNI );
    bind_I_rInetAddress_V : fn( this : ref PlainDatagramSocketImpl_obj, p0 : int,p1 : JObject);
    send_rDatagramPacket_V : fn( this : ref PlainDatagramSocketImpl_obj, p0 : JObject);
    peek_rInetAddress_I : fn( this : ref PlainDatagramSocketImpl_obj, p0 : JObject) : int;
    receive_rDatagramPacket_V : fn( this : ref PlainDatagramSocketImpl_obj, p0 : JObject);
    setTTL_B_V : fn( this : ref PlainDatagramSocketImpl_obj, p0 : int);
    getTTL_B : fn( this : ref PlainDatagramSocketImpl_obj) : int;
    join_rInetAddress_V : fn( this : ref PlainDatagramSocketImpl_obj, p0 : JObject);
    leave_rInetAddress_V : fn( this : ref PlainDatagramSocketImpl_obj, p0 : JObject);
    datagramSocketCreate_V : fn( this : ref PlainDatagramSocketImpl_obj);
    datagramSocketClose_V : fn( this : ref PlainDatagramSocketImpl_obj);
    socketSetOption_I_rObject_V : fn( this : ref PlainDatagramSocketImpl_obj, p0 : int,p1 : JObject);
    socketGetOption_I_I : fn( this : ref PlainDatagramSocketImpl_obj, p0 : int) : int;

};

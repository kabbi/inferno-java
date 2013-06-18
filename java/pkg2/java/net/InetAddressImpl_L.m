# javal v1.5 generated file: edit with care

InetAddressImpl_L : module
{
    InetAddressImpl_obj : adt
    {
        cl_mod : ClassModule;
    };

    init : fn( jni_p : JNI );
    getLocalHostName_rString : fn( this : ref InetAddressImpl_obj) : JString;
    makeAnyLocalAddress_rInetAddress_V : fn( this : ref InetAddressImpl_obj, p0 : JObject);
    lookupAllHostAddr_rString_aaB : fn( this : ref InetAddressImpl_obj, p0 : JString) : JArray;
    getHostByAddr_I_rString : fn( this : ref InetAddressImpl_obj, p0 : int) : JString;
    getInetFamily_I : fn( this : ref InetAddressImpl_obj) : int;

};

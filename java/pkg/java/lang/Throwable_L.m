# javal v1.2 generated file: edit with care

Throwable_L : module
{
    Throwable_obj : adt
    {
        cl_mod : ClassModule;
        backtrace : array of byte;
        detailMessage : JString;
    };

    init : fn( jni_p : JNI );
    printStackTrace0_rObject_V : fn( this : ref Throwable_obj, p0 : JObject);
    fillInStackTrace_rThrowable : fn( this : ref Throwable_obj) : ref Throwable_obj;

};

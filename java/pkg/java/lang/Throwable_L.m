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
    fillInStackTrace_I_rThrowable : fn( this : ref Throwable_obj, p0 : int) : ref Throwable_obj;
    getStackTraceDepth_I : fn( this : ref Throwable_obj) : int;
    getStackTraceElement_I_rStackTraceElement : fn( this : ref Throwable_obj, p0 : int) : JObject;
};

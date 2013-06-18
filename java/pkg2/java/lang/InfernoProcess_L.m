# javal v1.3 generated file: edit with care

InfernoProcess_L : module
{
    InfernoProcess_obj : adt
    {
        cl_mod : ClassModule;
        stdin : ref FileDescriptor_obj;
        stdout : ref FileDescriptor_obj;
        stderr : ref FileDescriptor_obj;
        pid : int;
        waitfd : ref FileDescriptor_obj;
        terminated : int;
    };

    init : fn( jni_p : JNI );
    initProc_aString_aString_V : fn( this : ref InfernoProcess_obj, p0 : JArrayJString,p1 : JArrayJString);
    waitFor_I : fn( this : ref InfernoProcess_obj) : int;
    destroy_V : fn( this : ref InfernoProcess_obj);
    isTerminated_Z : fn( this : ref InfernoProcess_obj) : int;

};

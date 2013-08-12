# generated file edit with care

Thread_L : module
{

    init : fn( jni_p : JNI );
    isInterrupted_Z_Z : fn( this : JThread, p0 : int) : int;
    currentThread_rThread : fn( ) : JThread;
    registerNatives_V : fn( );
    holdsLock_rObject_Z : fn( p0 : JObject) : int;
    yield_V : fn( );
    sleep_J_V : fn( p0 : big);
    start0_V : fn( this : JThread);
    isAlive_Z : fn( this : JThread) : int;
    countStackFrames_I : fn( this : JThread) : int;
    dumpThreads_aThread_aaStackTraceElement : fn( p0 : JArrayJObject) : JArray;
    getThreads_aThread : fn( ) : JArrayJObject;
    setPriority0_I_V : fn( this : JThread, p0 : int);
    stop0_rObject_V : fn( this : JThread, p0 : JObject);
    suspend0_V : fn( this : JThread);
    resume0_V : fn( this : JThread);
    interrupt0_V : fn( this : JThread);
    lowinit_rThread_V : fn( p0 : JThread);

};

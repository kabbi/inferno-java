# javal v1.3 generated file: edit with care

Thread_L : module
{

    init : fn( jni_p : JNI );
    currentThread_rThread : fn( ) : JThread;
    yield_V : fn( );
    sleep_J_V : fn( p0 : big);
    start_V : fn( this : JThread);
    isInterrupted_Z_Z : fn( this : JThread, p0 : int) : int;
    isAlive_Z : fn( this : JThread) : int;
    countStackFrames_I : fn( this : JThread) : int;
    setPriority0_I_V : fn( this : JThread, p0 : int);
    stop0_rObject_V : fn( this : JThread, p0 : JObject);
    suspend0_V : fn( this : JThread);
    resume0_V : fn( this : JThread);
    interrupt0_V : fn( this : JThread);
    lowinit_rThread_V : fn( p0 : JThread);

};

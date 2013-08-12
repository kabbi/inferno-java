# generated file edit with care

Runtime_L : module
{
    Runtime_obj : adt
    {
        cl_mod : ClassModule;
    };

    init : fn( jni_p : JNI );
    freeMemory_J : fn( this : ref Runtime_obj) : big;
    maxMemory_J : fn( this : ref Runtime_obj) : big;
    availableProcessors_I : fn( this : ref Runtime_obj) : int;
    totalMemory_J : fn( this : ref Runtime_obj) : big;
    runFinalization0_V : fn( );
    traceInstructions_Z_V : fn( this : ref Runtime_obj, p0 : byte);
    traceMethodCalls_Z_V : fn( this : ref Runtime_obj, p0 : byte);
    gc_V : fn( this : ref Runtime_obj);

};

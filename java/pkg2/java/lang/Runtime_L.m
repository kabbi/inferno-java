# javal v1.2 generated file: edit with care

Runtime_L : module
{
    Runtime_obj : adt
    {
        cl_mod : ClassModule;
    };

    init : fn( jni_p : JNI );
    exitInternal_I_V : fn( this : ref Runtime_obj, p0 : int);
    runFinalizersOnExit0_Z_V : fn( p0 : int);
    freeMemory_J : fn( this : ref Runtime_obj) : big;
    totalMemory_J : fn( this : ref Runtime_obj) : big;
    gc_V : fn( this : ref Runtime_obj);
    runFinalization_V : fn( this : ref Runtime_obj);
    traceInstructions_Z_V : fn( this : ref Runtime_obj, p0 : int);
    traceMethodCalls_Z_V : fn( this : ref Runtime_obj, p0 : int);

};

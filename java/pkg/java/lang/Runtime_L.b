implement Runtime_L;

include "jni.m";
    jni : JNI;
        ClassModule,
        JString,
        JArray,
        JArrayI,
        JArrayC,
        JArrayB,
        JArrayS,
        JArrayJ,
        JArrayF,
        JArrayD,
        JArrayZ,
        JArrayJObject,
        JArrayJClass,
        JArrayJString,
        JClass,
        JObject : import jni;

#>> extra pre includes here

#<<

include "Runtime_L.m";

#>> extra post includes here

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    #<<
}

freeMemory_J( this : ref Runtime_obj) : big
{#>>
    # TODO: parse /dev/memory
    return big (42*1024);
}#<<

maxMemory_J( this : ref Runtime_obj) : big
{#>>
    # TODO: parse /dev/memory
    return big (42*1024);
}#<<

availableProcessors_I( this : ref Runtime_obj) : int
{#>>
    # TODO: is there a way to determine this value?
    return 1;
}#<<

totalMemory_J( this : ref Runtime_obj) : big
{#>>
    # TODO: parse /dev/memory
    return big (42*1024);
}#<<

runFinalization0_V( )
{#>>
    # TODO: what should we do here?
}#<<

traceInstructions_Z_V( this : ref Runtime_obj, p0 : byte)
{#>>
    # as says javadoc, we can ignore this if we do not
    # support that feature. and so we do
}#<<

traceMethodCalls_Z_V( this : ref Runtime_obj, p0 : byte)
{#>>
    # as says javadoc, we can ignore this if we do not
    # support that feature. and so we do
}#<<

gc_V( this : ref Runtime_obj)
{#>>
    # there is no way to force Limbo gc
    # so this function is nop
}#<<


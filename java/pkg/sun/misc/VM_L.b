implement VM_L;

# javal v1.2 generated file: edit with care

include "jni.m";
    jni : JNI;
        ClassModule,
        JObject: import jni;

#>> extra pre includes here

#<<

include "VM_L.m";

#>> extra post includes here
#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
	#<<
}

initialize_V()
{#>>
	# Just a no-op, we have nothing to initialize currently
}#<<

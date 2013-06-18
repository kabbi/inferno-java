implement FileDescriptor_L;

# javal v1.3 generated file: edit with care

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
        JThread,
        JObject : import jni;

#>> extra pre includes here
    sys : import jni;
    FALSE : import jni;
    TRUE : import jni;
#<<

include "FileDescriptor_L.m";

#>> extra post includes here
#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    sys = jni->sys;
    #<<
}

valid_Z( this : ref FileDescriptor_obj) : int
{#>>
	if (this.fd != nil)
		return TRUE;
	else
		return FALSE;
}#<<

sync_V( this : ref FileDescriptor_obj)
{#>>
        # this routine has no meaning in the limbo world because there is
        # nothing to sync or flush. It may have meaning to each underlying
        # file system (device driver) but at the present there is no devtab
        # interface to the device driver for sync. As such, this routine is
        # a noop.
	jni->ThrowException("java.io.SyncFailedException", "sync not gauranteed");
}#<<

initSystemFD_rFileDescriptor_I_rFileDescriptor( p0 : ref FileDescriptor_obj,p1 : int) : ref FileDescriptor_obj
{#>>
        p0.fd = sys->fildes(p1);
        return (p0);
}#<<






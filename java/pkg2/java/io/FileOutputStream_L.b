implement FileOutputStream_L;

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
include "FileDescriptor_L.m";
    FileDescriptor_obj : import FileDescriptor_L;
#<<

include "FileOutputStream_L.m";

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

open_rString_V( this : ref FileOutputStream_obj, p0 : JString)
{#>>
	# open file pointed to by p0. If it does not exists, create it and 
	# and open it with mode of 644.

        if ((p0 == nil) || (p0.str == nil))
                jni->ThrowException("java.lang.NullPointerException", "null file name");

        this.fd.fd = sys->create(p0.str, sys->OWRITE, 8r666);
        if(this.fd.fd == nil)
                jni->ThrowException("java.io.IOException", sys->sprint("%r"));
}#<<

openAppend_rString_V( this : ref FileOutputStream_obj, p0 : JString)
{#>>
        if ((p0 == nil) || (p0.str == nil))
                jni->ThrowException("java.lang.NullPointerException", "null filename");

        this.fd.fd = sys->open(p0.str, sys->OWRITE);
        if(this.fd.fd == nil)
                jni->ThrowException("java.io.IOException", sys->sprint("%r"));
        sys->seek(this.fd.fd, 0, sys->SEEKEND);
}#<<

write_I_V( this : ref FileOutputStream_obj, p0 : int)
{#>>
	# p0 == character to write
	c := array[1] of byte;
	c[0] = byte p0;

        if ((this.fd == nil) || (this.fd.fd == nil))
                jni->ThrowException("java.lang.NullPointerException", "null FileDescriptor");

        if (sys->write(this.fd.fd, c, 1) != 1)
                jni->ThrowException("java.io.IOException", sys->sprint("%r"));
}#<<

writeBytes_aB_I_I_V( this : ref FileOutputStream_obj, p0 : JArrayB,p1 : int,p2 : int)
{#>>
	# p0 == buffer array to write from
	# p1 == offset in buffer
	# p2 == length to write out

        if ((this.fd == nil) || (this.fd.fd == nil))
                jni->ThrowException("java.lang.NullPointerException", "null FileDescriptor");
        if ((p0 == nil) || (p0.ary == nil))
                jni->ThrowException("java.lang.NullPointerException", nil);
        if ((p1 < 0) || (p2 < 0) || (p1 > (len p0.ary)))
                jni->ThrowException("java.lang.ArrayIndexOutOfBoundsException", nil);

        n := 0;
        while (p2 > 0) {
		# you can also write the following line as.....
                # n = sys->write(this.fd.fd, p0.ary[p1:], p2);
                n = sys->write(this.fd.fd, p0.ary[p1:len p0.ary], p2);
                if (n == -1) {
                        jni->ThrowException("java.io.IOException", sys->sprint("%r"));
                        break;
                }
                p1 += n;
                p2 -= n;
        }
}#<<

close_V( this : ref FileOutputStream_obj)
{#>>
	if (this.fd != nil)
		this.fd.fd = nil;
}#<<


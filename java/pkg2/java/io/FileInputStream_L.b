implement FileInputStream_L;

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

include "FileInputStream_L.m";

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

open_rString_V( this : ref FileInputStream_obj, p0 : JString)
{#>>
	# p0 == file name

        if ((p0 == nil) || (p0.str == nil))
                jni->ThrowException("java.lang.NullPointerException", "str is nil");

        this.fd.fd = sys->open(p0.str, sys->OREAD);
        if(this.fd.fd == nil)
		jni->ThrowException("java.io.IOException", "open error");
}#<<

read_I( this : ref FileInputStream_obj) : int
{#>>
        buf := array[1] of byte;

        if (this.fd.fd == nil)
                jni->ThrowException("java.lang.NullPointerException", "null FileDescriptor");
        readin := sys->read(this.fd.fd, buf, 1);
        if (readin == 0)    # EOF
                return -1;

		if (readin < 0)
			jni->ThrowException("java.io.IOException", sys->sprint("%r"));
        return (int buf[0]);

}#<<

readBytes_aB_I_I_I( this : ref FileInputStream_obj, p0 : JArrayB,p1 : int,p2 : int) : int
{#>>
	# p0 == input buffer (array of bytes)
	# p1 == offset
	# p2 == length
	# read p2 bytes from the file and place them at location (p0 + p1)

        if (this.fd == nil)
                jni->ThrowException("java.lang.NullPointerException", "null FileDescriptor");
        if ((p0 == nil) || (p0.ary == nil))
                jni->ThrowException("java.lang.NullPointerException", "nil buffer pointer");
        if ((p1 < 0) || (p1 > len p0.ary))
                jni->ThrowException("java.lang.ArrayIndexOutOfBoundsException",
			jni->sys->sprint( "offset=%d len buf array=%d", p1, len p0.ary));

        if ((p1 + p2) > len p0.ary)
                p2 = (len p0.ary) - p1;
        if (p2 <= 0)
                return 0;

        n := sys->read(this.fd.fd, p0.ary[p1: len p0.ary], p2);
        if (n == 0)    # EOF
                return -1;

        if (n < 0)
                jni->ThrowException("java.io.IOException", sys->sprint("%r"));
        return n;
}#<<

skip_J_J( this : ref FileInputStream_obj, p0 : big) : big
{#>>
	# skip the next p0 bytes from the Input stream. First find out where you are in
	# the stream. Next skip the bytes then return the "actual" bytes skipped.

        if (this.fd.fd == nil)
                jni->ThrowException("java.lang.NullPointerException", "null FileDescriptor");
        cur := sys->seek(this.fd.fd, 0, sys->SEEKRELA);
	end := sys->seek(this.fd.fd, (int p0), sys->SEEKRELA);
        return big (end - cur);
}#<<

available_I( this : ref FileInputStream_obj) : int
{#>>
        if (this.fd.fd == nil)
                jni->ThrowException("java.lang.NullPointerException", "null FileDescriptor");
        cur := sys->seek(this.fd.fd, 0, Sys->SEEKRELA);
        end := sys->seek(this.fd.fd, 0, Sys->SEEKEND);
        sys->seek(this.fd.fd, cur, Sys->SEEKSTART);

        return (end - cur);
}#<<

close_V( this : ref FileInputStream_obj)
{#>>
	if (this.fd != nil)
		this.fd.fd = nil;
}#<<





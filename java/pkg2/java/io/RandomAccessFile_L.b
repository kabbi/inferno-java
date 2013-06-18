implement RandomAccessFile_L;

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

include "RandomAccessFile_L.m";

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

open_rString_Z_V( this : ref RandomAccessFile_obj, p0 : JString,p1 : int)
{#>>
	# p0 == file name
	# p1 == writable flag

        if ((this.fd == nil) || (p0 == nil) || (p0.str == nil))
                jni->ThrowException("java.lang.NullPointerException", "null path name");

        if (p1 == TRUE){
                this.fd.fd = sys->open(p0.str, sys->ORDWR);
		if(this.fd.fd == nil)
                	this.fd.fd = sys->create(p0.str, Sys->ORDWR, 8r640);
	}
        else
                this.fd.fd = sys->open(p0.str, sys->OREAD);

        if(this.fd.fd == nil)
                jni->ThrowException("java.io.IOException", sys->sprint("%r"));
}#<<

read_I( this : ref RandomAccessFile_obj) : int
{#>>
        buf := array[1] of byte;

        if ((this.fd == nil) || (this.fd.fd == nil))
                jni->ThrowException("java.lang.NullPointerException", "null FileDescriptor");

        readin := sys->read(this.fd.fd, buf, 1);
        if (readin == 0)    # EOF
                return -1;

        if (readin < 0)
                jni->ThrowException("java.io.IOException", sys->sprint("%r"));
        return (int buf[0]);
}#<<

FD:     import Sys;
stderr: ref FD;
readBytes_aB_I_I_I( this : ref RandomAccessFile_obj, p0 : JArrayB,p1 : int,p2 : int) : int
{#>>
	# p0 == buffer for read in data
	# p1 == offset in buffer to start to place data
	# p2 == amount of data to read in

        if ((this.fd == nil) || (this.fd.fd == nil))
                jni->ThrowException("java.lang.NullPointerException", "null FileDescriptor");

        if ((p0 == nil) || (p0.ary == nil))
                jni->ThrowException("java.lang.NullPointerException", "null array");

        if ((p1 < 0) || (p1 > len p0.ary))
                jni->ThrowException("java.lang.ArrayIndexOutOfBoundsException", nil);

        if ((p1 + p2) > len p0.ary)
                p2 = (len p0.ary) - p1;

        if (p2 <= 0)
		jni->ThrowException("java.lang.ArrayIndexOutOfBoundsException",
nil);

        n := sys->read(this.fd.fd, p0.ary[p1:len p0.ary], p2);
        if (n == 0)    # EOF
                return -1;

        if (n < 0)
                jni->ThrowException("java.io.IOException", sys->sprint("%r"));
        return n;
}#<<

write_I_V( this : ref RandomAccessFile_obj, p0 : int)
{#>>
	c := array[1] of byte;
	c[0] = byte p0;

        if ((this.fd == nil) || (this.fd.fd == nil))
                jni->ThrowException("java.lang.NullPointerException", "null FileDescriptor");

        if (sys->write(this.fd.fd, c, 1) != 1)
                jni->ThrowException("java.io.IOException", sys->sprint("%r"));
}#<<

writeBytes_aB_I_I_V( this : ref RandomAccessFile_obj, p0 : JArrayB,p1 : int,p2 : int)
{#>>
	# p0 == buffer array to write from
	# p1 == offset in buffer
	# p2 == amount to write out

        if ((this.fd == nil) || (this.fd.fd == nil))
                jni->ThrowException("java.lang.NullPointerException", "null FileDescriptor");
        if ((p0 == nil) || (p0.ary == nil))
                jni->ThrowException("java.lang.NullPointerException", nil);
        if ((p1 < 0) || (p2 < 0) || (p1 + p2 > (len p0.ary)))
                jni->ThrowException("java.lang.ArrayIndexOutOfBoundsException", nil);

        n := 0;
        while (p2 > 0) {
                n = sys->write(this.fd.fd, p0.ary[p1:len p0.ary], p2);
                if (n == -1) {
                        jni->ThrowException("java.io.IOException", sys->sprint("%r"));
                        break;
                }
                p1 += n;
                p2 -= n;
        }
}#<<

getFilePointer_J( this : ref RandomAccessFile_obj) : big
{#>>
	if (this.fd == nil)
		jni->ThrowException("java.io.IOException", "this.fd nil");
	cur := sys->seek(this.fd.fd, 0, sys->SEEKRELA);
	if (cur < 0)
		jni->ThrowException("java.io.IOException", sys->sprint("%r"));
	return (big cur);
}#<<

seek_J_V( this : ref RandomAccessFile_obj, p0 : big)
{#>>
	if (this.fd == nil)
		jni->ThrowException("java.io.IOException", "this.fd nil");
	sys->seek(this.fd.fd, (int p0), sys->SEEKSTART);
}#<<

length_J( this : ref RandomAccessFile_obj) : big
{#>>
	if (this.fd == nil)
		jni->ThrowException("java.io.IOException", "this.fd nil");
        cur := sys->seek(this.fd.fd, 0, sys->SEEKRELA);
        end := sys->seek(this.fd.fd, 0, sys->SEEKEND);
        sys->seek(this.fd.fd, cur, sys->SEEKSTART);

        return (big end);
}#<<

close_V( this : ref RandomAccessFile_obj)
{#>>
	if (this.fd != nil)
		this.fd.fd = nil;
}#<<






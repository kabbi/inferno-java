implement SocketInputStream_L;

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
        JArrayJString,
        JClass,
        JObject : import jni;

#>> extra pre includes here

#<<

include "SocketInputStream_L.m";

#>> extra post includes here

include "jnet.m";
        jnet: JNET;

include "java/io/FileDescriptor_L.m";
        fildes: FileDescriptor_L;

include "InetAddress_L.m";
	inet: InetAddress_L;

FileDescriptor_obj: import fildes;
InetAddress_obj: import inet;

include "SocketImpl_L.m";
	sock: SocketImpl_L;

SocketImpl_obj: import sock;

include "PlainSocketImpl_L.m";
	psock: PlainSocketImpl_L;

sys: Sys;
strp: String;
DEBUG: import jnet;
FD:    import sys;

PlainSocketImpl_obj: import psock;

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here

	sys = jni->sys;
	strp = jni->str;

    #<<
}

socketRead_aB_I_I_I( this : ref SocketInputStream_obj, p0 : JArrayB,p1 : int,p2 : int) : int
{#>>


	st: list of string;
	str: string;
	m: int;

	# p1 =  offset
	# p2 =  length

	if (p0 == nil ) {
		if ( DEBUG ) 
			sys->print( "socketRead:  p0 ptr to JArrayB is nil\n");
		jni->ThrowException( "java.lang.NullPointerException", "");
	}
 
	if (this.fd == nil ) {
		if ( DEBUG )
			sys->print( "socketRead: this.fd == 0, socket must be closed\n");
		jni->ThrowException( "java.net.SocketException", "Socket was closed");
	}

	if ( p2 <0 || p1 < 0 || p1 + p2 > len p0.ary ) {
		if ( DEBUG ) 
			sys->print( "socketRead:  offset: %d/length: %d wrong in byte array\n",p1,p2);
		jni->ThrowException( "java.lang.ArrayIndexOutOfBoundsException", "");
	}
	

	if (this.impl == nil ) {
		if ( DEBUG ) 
			sys->print( "socketRead:  p0 ptr to SocketImpl is nil\n");
		jni->ThrowException( "java.lang.NullPointerException", "null SocketImpl ref");
	}


	# The TIMEOUT logic... Note modifications to SocketInputStream_L.m 
	# had to be made to support impl ptr as a ref to PlainSocketImpl_obj instead
	# of JOBJECT...
 
        if( this.impl.timeout != 0 ) {
                temp:= jnet->timeout + " " + string this.impl.timeout;
                rc := sys->write(this.impl.cfd.fd, array of byte temp, len temp);
                if (DEBUG)
                        sys->print("socketRead: fixing timeout value %s\n", string this.impl.timeout);
                if ( rc <= 0 ) 
                        jni->ThrowException("java.net.SocketException",
                                "socketRead: Unable to set timeout");
        }

	# Do Read of data file into buffer...
	if (DEBUG)
		sys->print("Reading into JArrayB for %d bytes\n",p2);

        n := sys->read(this.fd.fd, array of byte p0.ary[p1: ], p2);

	if (DEBUG)
		sys->print("SocketInputStream: read of socket: %s\n", string p0.ary[p1:n]);

        # Check status file to for timeout...

        if (this.impl.ctype == jnet->SOCK_STREAM)
                ctype:= "tcp";
        else
                ctype = "udp";

	buf:= array[256] of byte;

        dir := "/net/" + ctype + "/" + string this.impl.connection + "/status";
        sfd := sys->open( dir, sys->OREAD );
        if (sfd == nil ) {
                if (DEBUG)
                        sys->print( "socketInputStreamRead: Open of status file %s returned nil fd\n", dir);
                jni->ThrowException( "java.net.SocketException",
                         "socketInputStreamRead: Read failed");
        }

        k := sys->read(sfd, buf, len buf);
        if (DEBUG)
                sys->print("socketInputStreamRead: status file has: %s\n", string buf[0:k]);
        if ( k > 0 ) {
                (m, st) = sys->tokenize( string buf, " \t\n");
                for(i:=0;i<m;i++) {
                        str = hd st;
                        if ( strp->prefix( str, "timed-out" )) {
                                if (DEBUG)
                                        sys->print( "socketAccept: timeout\n");
                                jni->ThrowException("java.io.InterruptedIOException",
                                "socketInputStreamRead: Read timed out.");
                        }
                        st = tl st;
                }
        }


	if ( n < 0 ) {
		if ( DEBUG ) 
			sys->print( "socketRead:  Read failed with code %d\n", n);
		jni->ThrowException( "java.net.SocketException", "Read failed");
	}
	return n;

}#<<

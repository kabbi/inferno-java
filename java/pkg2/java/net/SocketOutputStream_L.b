implement SocketOutputStream_L;

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

include "SocketOutputStream_L.m";

#>> extra post includes here


include "jnet.m";
        jnet: JNET;

include "java/io/FileDescriptor_L.m";
        fildes: FileDescriptor_L;

include "InetAddress_L.m";
	inet: InetAddress_L;

sys: Sys;

DEBUG: import jnet;
FD:    import sys;
FileDescriptor_obj: import fildes;
InetAddress_obj: import inet;

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here

	sys = jni->sys;

	if (DEBUG)
		sys->print("socketOutputStream: init()\n");
    #<<
}

socketWrite_aB_I_I_V( this : ref SocketOutputStream_obj, p0 : JArrayB,p1 : int,p2 : int)
{#>>


        if (this.fd == nil ) {
                if ( DEBUG )
                        sys->print( "socketWrite: this.fd == 0, socket must be closed\n");
                jni->ThrowException( "java.net.SocketException", "Socket was closed");
        }

        if ( p2 <0 || p1 < 0 || p1 + p2 > len p0.ary ) {
                if ( DEBUG )
                        sys->print( "socketWrite:  offset: %d/length: %d wrong in byte array\n",p1,p2);
                jni->ThrowException( "java.lang.ArrayIndexOutOfBoundsException", "");
        }

        if (p0 == nil ) {
                if ( DEBUG )
                        sys->print( "socketWrite:  p0 ptr to JArrayB is nil\n");
                jni->ThrowException( "java.lang.NullPointerException", "");
        }

        # Write into buffer...
        if (DEBUG)
                sys->print("Writing into JArrayB for %d bytes\n",p2);
        n := sys->write(this.fd.fd, p0.ary[p1: ], p2);
        if ( n < 0 ) {
                if ( DEBUG )
                        sys->print( "socketWrite:  Read failed with code %d\n", n);
                jni->ThrowException( "java.net.SocketException", "Write failed");
        }
        return;

}#<<


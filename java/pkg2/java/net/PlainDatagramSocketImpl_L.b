implement PlainDatagramSocketImpl_L;

# javal v1.5 generated file: edit with care

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
#<<

include "PlainDatagramSocketImpl_L.m";

#>> extra post includes here

include "jnet.m";
        jnet: JNET;

include "java/io/FileDescriptor_L.m";
        fildes: FileDescriptor_L;

include "InetAddress_L.m";
        inet: InetAddress_L;

InetAddress_obj: import inet;  #make sure p0 ref works properly

include "DatagramPacket_L.m";
        pkt: DatagramPacket_L;

include "srv.m";
        srv: Srv;

sys:  Sys;

strp: String;

c: Cast;


DEBUG, AF_INET: import jnet;
FD: 		import sys;
DatagramPacket_obj: import pkt;  #make sure p0 ref works properly
FileDescriptor_obj: import fildes;
Value: import jni;



#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here

	sys = jni->sys;
	strp = jni->str;
	c = jni->CastMod();
	if((srv = load Srv Srv->BUILTINPATH) == nil
	&& (srv = load Srv Srv->PATH) == nil)
		jni->InitError( jni->sys->sprint( "java.net.PlainDatagramSocketImpl: could not load Srv: %r" ) );

    #<<
}

bind_I_rInetAddress_V( this : ref PlainDatagramSocketImpl_obj, p0 : int,p1 : JObject)
{#>>

        fd: ref FD;
        buf:= array[50] of byte;
	byteary:= array[6] of byte;
	i,n: int;
	str: string;
	arg: list of string;

        # Create the localaddress/localport assoc to a socket......

        # p1 is a ref to InetAddress_obj
        # p0 is the localport

        if (DEBUG)
                sys->print("PlainDgramBind: Entering....\n");

        if( this.cfd == nil ) {
                if (DEBUG)
                        sys->print("Attempt to Bind using cfd = nil\n");
                jni->ThrowException("java.net.SocketException",
			 "Socket closed");
        }

        # Check for address presence...
	if (p1 == nil) {
		if( DEBUG )
			sys->print("PlainDgramSocketImplBind: No address given\n");
		jni->ThrowException("java.lang.NullPointerException", "null Address" );
	}

	# assume IPv4...

        v := jni->GetObjField( p1, "address", "I");

	if (DEBUG && v == nil)
		sys->print("DGrambind: GetObjField returned nil\n");
	if (DEBUG)
		sys->print("DGrambind: GetObjField done\n");
        vl := v.Int();
	
	b := array[jnet->IPADDRLEN] of byte;
	b[0] = byte (vl >> 24 );
	b[1] = byte (vl >> 16 );
	b[2] = byte (vl >> 8 );
	b[3] = byte vl;  

        if (p0) 
                str = "announce " + string b[0] + "." + string b[1] + "." +
			string b[2] + "." + string b[3] + "!" +
			string p0;   
	else
                str = "announce " +  string b[0] + "." + string b[1] +
                + "." + string b[2] + "." + string b[3] ;


        n = sys->write( this.cfd.fd, array of byte str, len str );

        if( n <= 0 ) {
                if (DEBUG)
                        sys->print( "Datagram %s to  ctl file failed\n", str);
                jni->ThrowException( "java.net.SocketException",
			 "Bind error");
         }

       	str = "/net/" + "udp/" + string this.connection + "/local";
       	if (DEBUG)
                sys->print( "PlainDatagramSocketBind: opening file %s to get local port\n", str);
        fd = sys->open( str, sys->OREAD );
        if ( fd == nil ) {
                  if (DEBUG)
                         sys->print( "PlainDatagramSocketBind: Open of local file returned nil fd\n");
                  jni->ThrowException( "java.net.SocketException",
                         "Bind local file open error");
        }
        n = sys->read( fd, buf, len buf);


        if ( n <= 0 ) {
                  if (DEBUG)
                          sys->print( "PlainDatagramSocketBind: Read of local file returned %d\n", n);
                  jni->ThrowException( "java.net.SocketException",
                         "Bind local file read error");
         }

        ( i, arg) = sys->tokenize(string buf[0:n], "!");
	arg = tl arg;

        if (DEBUG)
                sys->print( "PlainDatagramSocketBind: Returning port # %d\n", int hd arg);
	this.localPort = int hd arg;

        if (DEBUG)
                sys->print("PlainDgramBind: Leaving....\n");

}#<<

send_rDatagramPacket_V( this : ref PlainDatagramSocketImpl_obj, p0 : JObject)
{#>>
	#p0 - Datagram Packet obj ref

	b:= array[jnet->IPADDRLEN] of byte;
	str: string;

        if (DEBUG)
                sys->print("PlainDgramsend: Entering....\n");

	if (this.cfd == nil ) {
		if (DEBUG)
			sys->print( "PlainDatagramSocketSend: ref FileDescriptor_obj for cfd is nil\n");
		jni->ThrowException( "java.net.SocketException",
			 "Socket closed");
	}
	
	if ( p0 == nil ) {
		if (DEBUG)
                        sys->print( "PlainDatagramSocketSend: ref DatagramPacket_obj is nil\n");
                jni->ThrowException( "java.lang.NullPointerException",
			 "Null DatagramPacket arg");
        }

	#Check buf field...
        Pb := jni->GetObjField( p0, "buf", "[B");
	if ( Pb == nil ) {
		if (DEBUG)
                        sys->print( "PlainDatagramSocketSend: ref DatagramPacket_obj buf is nil\n");
                jni->ThrowException( "java.lang.NullPointerException",
			 "Null DatagramPacket_obj buffer ref");
	}
	if (DEBUG)
		sys->print("Dgramsend: GetObjField returned %x\n", Pb);

        Pbvl := Pb.Object();
	if (DEBUG)
		sys->print("Dgramsend: GetObjField returned %x\n", Pbvl);


	#Check address field....
	if (DEBUG)
		sys->print("DGramsend: Doing GetObjField Packet.address\n");
        I := jni->GetObjField( p0, "address", "Ljava.net.InetAddress;");
	if ( I == nil ) {
		if (DEBUG)
                        sys->print( "PlainDatagramSocketSend: ref DatagramPacket_obj address is nil\n");
                jni->ThrowException( "java.lang.NullPointerException",
			 "Null DatagramPacket_obj address ref");
        }

	#address is an InetAddress ref
        Ivl := I.Object();
	if (DEBUG)
		sys->print("Dgramsend: GetObjField returned %x\n", Ivl);

	if (DEBUG)
		sys->print("DGramsend: Doing GetObjField Packet.address.address\n");
        v := jni->GetObjField( Ivl, "address", "I");

	if (DEBUG && v == nil)
		sys->print("DGramsend: GetObjField returned nil\n");
        vl := v.Int();

	if (DEBUG)
		sys->print("Dgramsend: GetObjField returned %d\n", vl);

	b[0] = byte (vl >> 24);
	b[1] = byte (vl >> 16);
	b[2] = byte (vl >> 8);
	b[3] = byte (vl);
	
	a := string b[0]+"."+string b[1]+"."+string b[2]+
		"."+string b[3];

	# Check port....
	if (DEBUG)
		sys->print("DGramsend: Doing GetObjField Packet.port\n");
        v = jni->GetObjField( p0, "port", "I");

	if (DEBUG && v == nil)
		sys->print("DGramsend: GetObjField returned nil\n");

        vl = v.Int();
	if (DEBUG)
		sys->print("Dgramsend: GetObjField returned %d\n", vl);
	if ( vl <= 0 )
		str = "connect " + a;
	else
		str = "connect " + a + "!" + string vl;	
	
        if( DEBUG )
                sys->print( "DGramsend: connect str = %s\n", str);

	n := sys->write( this.cfd.fd, array of byte str, len array of byte str ); 
        if( n <= 0 ) {
		if (DEBUG)
			sys->print( "DGramsend: connect cmd failed %d\n", n);
                jni->ThrowException( "java.net.SocketException",
                         "Datagram send ctl file error");
        }

	#Get buf.ary field....
        ar := c->ToJArrayB( Pbvl );
        n = sys->write( this.fd.fd, ar.ary, len ar.ary);
	if ( n <= 0 ) {
		# set length to zero...
		val := ref Value.TInt(0);    
		jni->SetObjField( p0, "length", val ); 
                if (DEBUG)
                        sys->print( "PlainDatagramSocketSend: write of data file returned %d\n", n);
		jni->ThrowException( "java.net.SocketException",
			 "Send: data file write error");
	}
	
	val := ref Value.TInt(n);    
	jni->SetObjField( p0, "length", val ); 

        if (DEBUG)
                sys->print("PlainDgramsend: Leaving...\n");

}#<<

peek_rInetAddress_I( this : ref PlainDatagramSocketImpl_obj, p0 : JObject) : int
{#>>
        if (DEBUG)
                sys->print( "PlainDatagramSocketPeek: Unsupported entry.\n");
        jni->ThrowException( "java.net.SocketException",
			 "Peek: Unsupported option");
	return -1;
}#<<

receive_rDatagramPacket_V( this : ref PlainDatagramSocketImpl_obj, p0 : JObject)
{#>>
	
	# p0 = ref DatagramPacket

	str,temp: string;
	st: list of string;
	m: int;



        if (DEBUG)
                sys->print("PlainDgramreceive: Entering...\n");

	if (this.cfd == nil ) {
		if (DEBUG)
			sys->print( "PlainDatagramSocketRead: ref FileDescriptor_obj for cfd is nil\n");
		jni->ThrowException( "java.net.SocketException",
			 "Socket closed");
	}
	
	if ( p0 == nil ) {
		if (DEBUG)
                        sys->print( "PlainDatagramSocketRead: ref DatagramPacket_obj is nil\n");
                jni->ThrowException( "java.lang.NullPointerException",
			 "Null DatagramPacket_obj ref");
        }

	#Check buf field...
        Pb := jni->GetObjField( p0, "buf", "[B");
	if ( Pb == nil ) {
		if (DEBUG)
                        sys->print( "PlainDatagramSocketRecv: ref DatagramPacket_obj buf is nil\n");
                jni->ThrowException( "java.lang.NullPointerException",
			 "Null DatagramPacket_obj buffer ref");
	}
	if (DEBUG)
		sys->print("DgramRecv: GetObjField returned %x\n", Pb);

        Pbvl := Pb.Object();
	if (DEBUG)
		sys->print("DgramRecv: GetObjField returned %x\n", Pbvl);

	#Get buf.ary field....
        ar := c->ToJArrayB( Pbvl );

        n := sys->read( this.fd.fd, ar.ary, len ar.ary);
	val := ref Value.TInt(n);    
	jni->SetObjField( p0, "length", val ); 

	if ( n < 0 ) {
                if (DEBUG)
                        sys->print( "PlainDatagramSocketRead: read of data file returned %d\n", n);
		jni->ThrowException( "java.net.SocketException", 
			"PlainDatagramSocketReceive: data file read error");
	}

        if (DEBUG)
               sys->print( "PlainDatagramSocketReceive: read of data file: %s\n", string ar.ary[0:n]);

	# Timeout logic...
        if( this.timeout != 0 ) {
                temp = jnet->timeout + " " + string this.timeout;
                rc := sys->write(this.cfd.fd, array of byte temp, 
			len array of byte temp);
                if (DEBUG)
                        sys->print("DatagramSocketImplReceive: fixing timeout value %s\n", string this.timeout);
                if ( rc <= 0 ) 
                        jni->ThrowException("java.net.SocketException",
                                "DatagramSocketImplReceive: Unable to set timeout");
        }
	
        # Check status file for timeout...

        buf:= array[256] of byte;

        temp  = "/net/udp/" + string this.connection + "/status";
        sfd := sys->open( temp, sys->OREAD );
        if (sfd == nil ) {
                if (DEBUG)
                        sys->print( "DatagramSocketImplReceive: Open of status file %s returned nil fd\n", temp);
                jni->ThrowException( "java.net.SocketException",
                         "DatagramSocketImplReceive: Read failed");
        }

        k := sys->read(sfd, buf, len buf);

        if ( k <= 0 ) {
                if (DEBUG)
                        sys->print("DgramReceive: status file read: %d\n", n);
                jni->ThrowException( "java.net.SocketException",
                         "DatagramSocketImplReceive: status file read failed");
        }


       	if (DEBUG)
		sys->print("DgramSocketreceive: Got status: %s\n", string buf[0:k]);
	
        (m, st) = sys->tokenize( string buf[:k], " \n\t");

	if ( m != 0 ) 
        	for(i:=0;i<m;i++) {
               		str = hd st;
               		if ( strp->prefix( str, "timed-out" )) {
                        	if (DEBUG)
                                	sys->print( "DatagramSocketImplReceive: timeout\n");
                        	jni->ThrowException("java.io.InterruptedIOException",
                                	"DatagramSocketImplReceive: Read timed out.");
               		}
                	st = tl st;
        	}
	else
            if (DEBUG)
                    sys->print( "DatagramSocketImplReceive: Can't tokenize\n");


        if (DEBUG)
                sys->print( "DatagramSocketImplReceive: Doing NewObject\n");
	# Default constructor...
	I_obj  := jni->NewObject( jni->FindClass( "java/net/InetAddress" ));
	
        if (DEBUG)
                sys->print( "DatagramSocketImplReceive: NewObject Done\n");
        str = "/net/" + "udp/" + string this.connection + "/remote";
	fd := sys->open(str, sys->OREAD);
	
	if ( fd == nil ) {
		if (DEBUG)
			sys->print("Dgramreceive: Can't open %s\n", str);
		jni->ThrowException( "java.net.SocketException", 
			"DatagramSocketImplreceive: Unable to obtain remote fd\n");
	}

	n = sys->read(fd, buf, len buf);

	if (n <= 0) {
		if (DEBUG)
			sys->print("DgramSocketreceive: Can't read %s\n", str);
		jni->ThrowException( "java.net.SocketException", 
			"DatagramSocketImplreceive: Unable to obtain remote addr\n");
	}

	if (DEBUG) 
		sys->print("DgramSocketreceive: Remote file read has %s\n", string buf[0:n]);

        (m, st) = sys->tokenize( string buf[:n], "!");
	if ( m == 0 ) {
                if (DEBUG)
                        sys->print("DgramSocketReceive: Can't tokenize %s\n", str);
                jni->ThrowException( "java.net.SocketException",
			"DatagramSocketImplReceive: Unable to tokenize remote\n");
	}
		
	str = hd st;
	st = tl st;

	iplist: list of string;
	( i, iplist ) = sys->tokenize( str, ".");
	if (DEBUG)
		sys->print("DgramSocketreceive: tokenize iplist i = %d\n", i);
        b:= array[len iplist] of byte;
        for (j:=0; j<i; j++) {
                  temp = hd iplist;
                  iplist = tl iplist;
                  b[j] = byte temp;
        }
	
	i = 0;
	i |= int b[0] <<24;
	i |= int b[1] <<16;
	i |= int b[2] <<8;
	i |= int b[3];
        if (DEBUG )
                 sys->print("DgramSocketreceive: shifted remote addr = %d\n",i);

	val = ref Value.TInt( int hd st );
	n = jni->SetObjField( p0, "port", val );
        if (DEBUG )
                 sys->print("DgramSocketRecv: Return from SetObjField port %d\n",n );

	nval := ref Value.TObject( I_obj );
	n = jni->SetObjField( p0, "address", nval );
        if (DEBUG )
                 sys->print("DgramSocketRecv: Return from SetObjField addr %d\n",n );

        if (DEBUG )
                 sys->print("DgramSocketRecv: Finished setting InetAddr ref\n" );

	val = ref Value.TInt( i );
	n = jni->SetObjField( I_obj, "address", val ); 
        if (DEBUG )
                 sys->print("DgramSocketRecv: Return from Inetaddr addr SetObjField %d\n",n );

	val = ref Value.TInt( jnet->AF_INET );
	n = jni->SetObjField( I_obj, "family", val ); 
        if (DEBUG )
                 sys->print("DgramSocketRecv: Return from family SetObjField %d\n",n );

        if (DEBUG)
                sys->print("PlainDgramRecv: Leaving...\n");

}#<<

setTTL_B_V( this : ref PlainDatagramSocketImpl_obj, p0 : int)
{#>>
        if (DEBUG)
                sys->print( "PlainDatagramSocketSetTTL: Unsupported.\n");
        jni->ThrowException( "java.net.SocketException",
			 "setTTL: Unsupported option");
}#<<

getTTL_B( this : ref PlainDatagramSocketImpl_obj) : int
{#>>
        if (DEBUG)
                sys->print( "PlainDatagramSocketGetTTL: Unsupported.\n");
        jni->ThrowException( "java.net.SocketException",
			 "getTTL: Unsupported option");
	return -1;
}#<<

join_rInetAddress_V( this : ref PlainDatagramSocketImpl_obj, p0 : JObject)
{#>>
        if (DEBUG)
                sys->print( "PlainDatagramSocketJoin: Unsupported.\n");
        jni->ThrowException( "java.net.SocketException",
			 "Join: Unsupported option");
}#<<

leave_rInetAddress_V( this : ref PlainDatagramSocketImpl_obj, p0 : JObject)
{#>>
        if (DEBUG)
                sys->print( "PlainDatagramSocketLeave: Unsupported.\n");
        jni->ThrowException( "java.net.SocketException",
			 "Leave: Unsupported option");
}#<<

datagramSocketCreate_V( this : ref PlainDatagramSocketImpl_obj)
{#>>

	dir: string;
        cfd: ref FD;

	if (DEBUG)
		sys->print("DgramCreate: Entering...\n");

        #Open clone device and allocate a connection
        dir = "/net/udp/clone";
        cfd = sys->open(dir, sys->ORDWR);
        if (cfd == nil) {
                if( DEBUG )
                        sys->print( "DgramCreate: Unable to open clone device\n");
                jni->ThrowException( "java.net.SocketException",
                         "Unable to create socket");
        }

        #The following gets a connection number string
        buf := array[10] of byte;
        n := sys->read(cfd, buf, len buf);
        if (n < 0) {
                if (DEBUG)
                        sys->print("DgramCreate: Ctl file read returned no connection num!\n");
                jni->ThrowException( "java.net.SocketException",
                         "Unable to create socket");
        }

        if (DEBUG)
                sys->print("DgramCreate: ctl read connection #: %s\n", 
		string buf[:n]);

        if (DEBUG)
                sys->print("DgramCreate: Storing cfd #\n");
        this.cfd.fd = cfd;
        r := string buf[:n];
        if (DEBUG)
                sys->print("DgramCreate: Storing conn #\n");
        this.connection = int r;

        #Open data file and get a handle...
        dir = "/net/" + "udp/" + string this.connection + "/data";
        cfd = sys->open(dir, sys->ORDWR);
        if (cfd == nil) {
                if( DEBUG )
                        sys->print( "DatagramCreate: Unable to open %s\n", dir);
                jni->ThrowException( "java.net.SocketException",
                         "Unable to create socket");
        }
        if (DEBUG)
                sys->print("DgramCreate: Storing fd #\n");
        this.fd.fd = cfd;
}#<<

datagramSocketClose_V( this : ref PlainDatagramSocketImpl_obj)
{#>>

        if (DEBUG)
                sys->print( "In socket close routine");
        this.fd = nil;
        this.cfd = nil;


}#<<

socketSetOption_I_rObject_V( this : ref PlainDatagramSocketImpl_obj, p0 : int,p1 : JObject)
{#>>

        if( p0 == jnet->IP_MULTICAST_IF ){
                if (DEBUG)
                        sys->print("PlainDatagramSocketImplSetOption: MULTICAST");
                jni->ThrowException("java.net.SocketException",
                        "invalid DatagramSocket Option");
	}
}#<<

socketGetOption_I_I( this : ref PlainDatagramSocketImpl_obj, p0 : int) : int
{#>>

	# p0 = option

	buf := array[256] of byte;
	temp, str: string;
	iplist, st: list of string;
	m,i : int;

	ctype := "udp";
        if (DEBUG)
                sys->print("PlainDatagramSocketImplGetOption: Entering...\n");

        if ( this.fd == nil ) {
                if (DEBUG)
                        sys->print("PlainDatagramSocketImplGetOption: Null this.fd\n");
                jni->ThrowException("java.net.SocketException", "Socket Closed");
        }

	if( p0 == jnet->IP_MULTICAST_IF ) {
                if (DEBUG)
                        sys->print("PlainDatagramSocketImplGetOption: MULTICAST");
                jni->ThrowException("java.net.SocketException", "invalid DatagramSocket Option");
	} else if ( p0 == jnet->SO_BINADDR ) {
                if (DEBUG)
                        sys->print("PlainDatagramSocketImplGetOption: BINADDR");
                sfd := sys->open("/dev/sysname", sys->OREAD);
                if(( m = sys->read(sfd, buf, len buf)) < 0 ) {
                        if (DEBUG)
                                sys->print("DatagramSocketGetOpt: SO_BINADDR: /dev/sysna me read failed\n");
                        return -1;
                }
                st = srv->iph2a(string buf[0:m]);
                if (st == nil) {
                        if (DEBUG)
                          sys->print("DsockGetOpt: iph2a returned nil list\n");
                        jni->ThrowException( "java.net.SocketException",
                        "socketGetOption: SO_BINADDR: Unable to get local addres s");
                }
                str = hd st;
                if (DEBUG)
                        sys->print("socketGetOption: st hd = %s\n", str);
                # insure net byte ordered byte[]
                ( i, iplist ) = sys->tokenize( str, ".");
                if (DEBUG)
                        sys->print("socketGetOption: iplist tokenize i = %d\n", i);
                b:= array[len iplist] of byte;
                for (j:=0; j<i; j++) {
                        temp = hd iplist;
                        iplist = tl iplist;
                        b[j] = byte temp;
                }
                i=0;
                i |= int ( b[0] << 24) ;
                i |= int ( b[1] << 16 );
                i |= int ( b[2] << 8 );
                i |= int ( b[3] );
                if (DEBUG )
                        sys->print("DgramSocketGetOpt: BINADDR = %d\n", i);
                return i;
        } else
                jni->ThrowException( "java.net.SocketException",
                "DatagramSocketGetOption: Unsupported Option.");
        if (DEBUG)
                sys->print("PlainDatagramSocketImplGetOption: Leaving...\n");

	return -1;
}#<<



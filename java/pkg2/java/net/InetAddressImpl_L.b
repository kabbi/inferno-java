implement InetAddressImpl_L;

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

include "InetAddressImpl_L.m";

#>> extra post includes here

include "InetAddress_L.m";
	inet: InetAddress_L;   # declare pointer to module name
	
include "srv.m";
        srv: Srv;

sys:  Sys;

include "jnet.m";
	jnet: JNET;

DEBUG, AF_INET: import jnet;
FD: import sys;
InetAddress_obj: import inet;  # import adt object for p0 ref
Value: import jni;

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here

	sys = jni->sys;
	if((srv = load Srv Srv->BUILTINPATH) == nil
	&& (srv = load Srv Srv->PATH) == nil)
		jni->InitError( jni->sys->sprint( "java.net.InetAddressImpl: could not load Srv: %r" ) );

    #<<
}

getLocalHostName_rString( this : ref InetAddressImpl_obj) : JString
{#>>

	fd: ref FD;
        buf:= array[256] of byte;

	if (DEBUG)
                sys->print("Entering getLocalHostName\n");

        fd = sys->open("/dev/sysname", sys->OREAD);

	if (fd != nil )
        	n := sys->read(fd, buf, 256);
	else
 		return jni->NewString("localhost");
	
        if (n <= 0) {
                return jni->NewString("localhost");
		if (DEBUG) 
			sys->print(" Bad return from /dev/sysname\n");
	}
	if (DEBUG) 
		sys->print(" Name from dev/sysname: %s\n",  string buf[0:n]);
        return jni->NewString(string buf[0:n]);

}
#<<

makeAnyLocalAddress_rInetAddress_V( this : ref InetAddressImpl_obj, p0 : JObject)
{#>>

	# p0 must be changed to a type InetAddress_obj in arg list
	# Must include InetAddress_L.m also in this file.

	if (DEBUG)
                sys->print("Entering makeAnyLocalAddress\n");


        #p0.address = jnet->INADDR_ANY;

        val := ref Value.TInt( jnet->INADDR_ANY );
        n := jni->SetObjField( p0, "address", val );
        if (DEBUG )
                 sys->print("makeAnyLocalAddr: Return from SetObjField %d\n",n);

        #p0.family  = jnet->AF_INET;
        val = ref Value.TInt( jnet->AF_INET );
        n = jni->SetObjField( p0, "family", val );
        if (DEBUG )
                 sys->print("makeAnyLocalAddr: Return from SetObjField %d\n",n);
}#<<

lookupAllHostAddr_rString_aaB( this : ref InetAddressImpl_obj, p0 : JString) : JArray
{#>>

	if (DEBUG)
                sys->print("Entering lookupAllHostAddr\n");

	iplist,AddrList: list of string;
	hostname,str,temp: string;
	j: int;

        hostname = p0.str;
	if (DEBUG)
                sys->print("hostname is %s \n", p0.str);
        AddrList = srv->iph2a(hostname);
	if (DEBUG)
                sys->print("InetAddressImpl:Got AddrList\n");


	b:= array[len AddrList] of { array[jnet->IPADDRLEN] of byte };

        if (AddrList != nil) {
		for(i:=0;i<len AddrList;i++) {
			str = hd AddrList;
			if (DEBUG)
				sys->print(" Addrlist hd = %s\n", str);
			AddrList = tl AddrList;

			# insure net byte ordered byte[][]
			( j, iplist ) = sys->tokenize( str, ".");
			for (k:=0; k<j; k++) {
				temp = hd iplist;
				if (DEBUG)
					sys->print("iplist hd = %s\n", temp);
				iplist = tl iplist;
				if (DEBUG)
					sys->print("b[%d][%d]\n", i,k);
				b[i][k] = byte temp;
				if (DEBUG)
					sys->print("InetAddressGetHostByName: tokenize b[%d][%d]  = %d\n", i, k, int b[i][k]);
			}
		}
		return jni->MkAAByte( b );
        } else {
		jni->ThrowException( "java.net.UnknownHostException", "Host unknown" );
		return nil;
        }

}#<<

getHostByAddr_I_rString( this : ref InetAddressImpl_obj, p0 : int) : JString
{#>>

	address: string;
	
	# p0 is the address
	# IPV4 only....


	if (DEBUG)
                sys->print("Entering getHostByAddr\n");

	if( !p0 )
	     jni->ThrowException( "java.net.UnknownHostException", 
			"Gethostbyaddr Bad Address" );

	if (DEBUG)
		sys->print("GetHostByAddr: p0 = %d\n", p0);

	b:= array[jnet->IPADDRLEN] of byte;

	b[0] = byte ( p0 >> 24 );
	b[1] = byte ( p0 >> 16 );
	b[2] = byte ( p0 >> 8 );
	b[3] = byte p0;

	address = string b[0] + "." + string b[1] + "." + string b[2] + "." + 
		 string b[3];	

        HostList := srv->ipa2h(address);

	if ( len HostList == 0 ) {
		      if (DEBUG)
			  sys->print("GetHostByAddr: ipa2h returned nil on %s\n",
				address);
		      jni->ThrowException( "java.net.UnknownHostException", 
				"Gethostbyaddr Bad Address" );
		     return nil;
	}

	return jni->NewString( string hd HostList );

}#<<

getInetFamily_I( this : ref InetAddressImpl_obj) : int
{#>>

	if (DEBUG)
                sys->print("Entering getInetFamily\n");
 	#This is a nasty piece of work here...
        return AF_INET;

}#<<


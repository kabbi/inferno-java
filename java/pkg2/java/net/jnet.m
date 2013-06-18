JNET: module
{
    # These are taken from solaris

    AF_INET:      con 2;
    INADDR_ANY:   con 0;

    SOCK_STREAM:  con 2;
    SOCK_DGRAM:   con 1;
    SO_LINGER:    con  16r80;
    SO_REUSEADDR: con  16r04;
    TCP_NODELAY:  con  16r01;

    SO_BINADDR:   con  16r0F;
    IP_MULTICAST_IF: con  16r10;

    timeout:      con "rcvtimeo";
    linger:       con "linger";
    nodelay:      con "nodelay";

    IPADDRLEN:    con 4;
    DEBUG:	  con 0;
};

implement Date_L;

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
include "daytime.m";
	localtime : ref Daytime->Tm;
	gmttime : ref Daytime->Tm;
	daytime : Daytime;
	sys : import jni;
	FALSE : import jni;
	TRUE : import jni;
month := array[] of {
	"Jan", "Feb", "Mar", "Apr", "May", "Jun",
	"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
};

#<<

include "Date_L.m";

#>> extra post includes here

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
	sys = jni->sys;
	daytime = load Daytime Daytime->PATH;
	if(daytime == nil)
		jni->InitError( sys->sprint( "java.util.Date: could not load %s: %r", Daytime->PATH ) );
    #<<
}

toString_rString( this : ref Date_obj) : JString
{#>>
	if (this.expanded != byte TRUE)
		expand_V(this);
	if (this.expanded != byte TRUE)
		jni->ThrowException("java.lang.IllegalArgumentException", "could not expand time");
	s := daytime->text(localtime);
	return (jni->NewString( s));
}#<<

toLocaleString_rString( this : ref Date_obj) : JString
{#>>
	s : string;
	#
	# put the date in the following format 
	#	09-Sep-97 9:15:24 PM
	#
	if (this.expanded != byte TRUE)
		expand_V(this);
	if (this.expanded != byte TRUE)
		jni->ThrowException("java.lang.IllegalArgumentException", "could not expand time");

	if ((int this.tm_hour) >= 12) {
		s = sys->sprint( "%.2d-%s-%.2d %d:%.2d:%.2d PM",
			int this.tm_mday,
			month[int this.tm_mon],
			this.tm_year,
			(int this.tm_hour) - 12,
			int this.tm_min,
			int this.tm_sec);
	} else {
		s = sys->sprint( "%.2d-%s-%.2d %d:%.2d:%.2d AM",
			int this.tm_mday,
			month[int this.tm_mon],
			this.tm_year,
			int this.tm_hour,
			int this.tm_min,
			int this.tm_sec);
	}
	return (jni->NewString( s));
}#<<

toGMTString_rString( this : ref Date_obj) : JString
{#>>
	s : string;
	if (this.valueValid != byte TRUE)
		computeValue_V( this);
	if (this.valueValid != byte TRUE)
		jni->ThrowException("java.lang.IllegalArgumentException", "could not compute time");
        t := (big this.value) / big 1000;
	#10 Sep 1997 02:15:24 GMT
	s = sys->sprint( "%.2d %s %d %.2d:%.2d:%.2d GMT",
			int this.tm_mday,
			month[int this.tm_mon],
			this.tm_year + 1900,
			int this.tm_hour,
			int this.tm_min,
			int this.tm_sec);

        gmttime = daytime->gmt(int t);
	return (jni->NewString( s));
}#<<

expand_V( this : ref Date_obj)
{#>>
	#
	# this routine assumes there is a valid date stored
	# in this.value. If not, return error.
	#
	if (this.value <= (big 0)) {
		this.expanded = byte FALSE;
		this.tm_millis = 0;
		this.tm_sec = byte 0;
		this.tm_min = byte 0;
		this.tm_hour = byte 0;
		this.tm_mday = byte 0;
		this.tm_mon = byte 0;
		this.tm_wday = byte 0;
		this.tm_yday = 0;
		this.tm_year = 0;
		this.tm_isdst = 0;
		return;
	}
        t := (big this.value) / big 1000;
        localtime = daytime->local(int t);
	#
	# set the following to 0 since java code is not using them.
	#
        this.tm_millis  = 0;
        this.tm_isdst = 0;	# flag for alternate daylight savings time
	#
	# these values come from calculations done by local().
	#
        this.tm_sec = byte localtime.sec;
        this.tm_min = byte localtime.min;
        this.tm_hour = byte localtime.hour;
        this.tm_mday = byte localtime.mday;     # day of the month - [1, 31]
        this.tm_mon = byte localtime.mon;	# months since January - [0, 11]
        this.tm_wday = byte localtime.wday;	# days since Sunday - [0, 6]
        this.tm_yday = localtime.yday;		# days since January 1 - [0, 365]
        this.tm_year = localtime.year;		# years since 1900
	this.expanded = byte TRUE;
}#<<

computeValue_V( this : ref Date_obj)
{#>>
        now := daytime->now();
        localtime = daytime->local(now);
	localtime.sec = int this.tm_sec;
	localtime.min = int this.tm_min;
	localtime.hour = int this.tm_hour;
	localtime.mday = int this.tm_mday;
	localtime.mon = int this.tm_mon;
	localtime.year = int this.tm_year;
	localtime.wday = int this.tm_wday;
	localtime.yday = int this.tm_yday;

	t := daytime->tm2epoch(localtime);
	this.value = (big t) * big 1000;
	this.valueValid = byte TRUE;
}#<<



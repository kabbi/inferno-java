implement iFontMetrics_L;

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
#
#  %W% - %E%
#

Value: import jni;
sys : import jni;  # std inferno Sys modoule
# str : import jni;  # std inferno String module
# jldr : import jni; # primary java class loader, JavaClassLoader

# draw.m is included by something included by jni.m
draw : Draw;
Font : import Draw;

include "iFontPeer_L.m";
ifontpeerm : iFontPeer_L;
iFontPeer_obj : import ifontpeerm;
#<<

include "iFontMetrics_L.m";

#>> extra post includes here

cast : Cast;
ctxt : ref Draw->Context; # for ref to Display

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here

	sys = jni->sys;

    # should not I share draw with at least the rest of the AWT
    # graphics world ?
    draw = load Draw Draw->PATH;

	#ifontpeerm = load iFontPeer_L iFontPeer_L->PATH;

	ctxt = jni->getContext();
	if (ctxt == nil) {
		# Eventually the print can be removed, throwing the
		# Exception will suffice.
    	sys->print("iFontMetrics_L.init: ctxt == nil, can't get Draw Context!\n");
		jni->ThrowException("java.awt.AWTError", "can't get Draw Context");
    }
#<<
}

iStringWidth_rString_I( this : ref iFontMetrics_obj, p0 : JString) : int
{#>>

    # sys->print("iFontMetrics_L: fontref=%#x\n", p0);
    return (draw->(this.ifontpeer.iFontRef).width(p0.str));
    #return (draw->(this.iFontRef).width(p0.str));
}#<<

iBytesWidth_aB_I( this : ref iFontMetrics_obj, p0 : JArrayB) : int
{#>>
    # convert to string performing UT8 to Unicode translation
	cdata := string p0.ary; 
	return (draw->(this.ifontpeer.iFontRef).width(cdata));
}#<<

iInitWidths_aI_I( this : ref iFontMetrics_obj, p0 : JArrayI) : int
{#>>
	# p0 is widths[256] in java land
	maxw := 0;   	# maximum width
	cs : string;
	n := len p0.ary;
	cw : int;      # width of current char
	cb := array[1] of byte;  

	for (i := 0; i < n; i++) {
		cb[0] = byte i; # cast i to string
		cs = string cb;

		cw = (draw->(this.ifontpeer.iFontRef).width(cs));

	    if (maxw < cw) {
		    maxw = cw;
	    }

		p0.ary[i] = cw;
	}
	return maxw;
}#<<










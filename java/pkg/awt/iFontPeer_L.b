implement iFontPeer_L;

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

Value : import jni;
sys : import jni;  # std inferno Sys modoule
str : import jni;  # std inferno String module
# jldr : import jni; # primary java class loader, JavaClassLoader

# draw.m is included by something included by jni.m
draw : Draw;
Font : import Draw;

#<<

include "iFontPeer_L.m";

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
    # sys->print("iFontPeer_L: draw=%x\n",draw);

    # Why is getting Cast module handle from jni different 
    # than getting  Sys, Math, and String modules handles from jni?
    # cast = jni->CastMod();
    ctxt = jni->getContext();
    if (ctxt == nil) {
	# Eventually the print can be removed, throwing the
	# Exception will suffice.
    	sys->print("iFontPeer_L.init: ctxt == nil, can't get Draw Context!\n");
	jni->ThrowException("java.awt.AWTError", "can't get Draw Context");
    }
    #<<
}

initFontPeer_rString_V( this : ref iFontPeer_obj, p0 : JString)
{#>>

    ifp := p0.str;
    #sys->print("initFontPeer_V: this.ifpathname=%s\n",ifp);

    this.iFontRef = draw->Font.open(ctxt.display, ifp);
    fontref := this.iFontRef;
    
    if (nil == fontref) {
    	sys->print("iFontPeer_L: can't open font %s - %r\n",ifp);
    	jni->ThrowException("java.io.FileNotFoundException", ifp);
    }
    
    # sys->print("iFontPeer_L: this=%#x\n",this);
    # sys->print("iFontPeer_L: this.iFontRef=%#x, draw=%#x\n",this.iFontRef, draw);
    
    
    # make native Font information visible in javaland
    
    #this.iName.str = fontref.name;
    this.iName = jni->NewString(fontref.name);
    
    this.iAscent = fontref.ascent;
    this.iHeight = fontref.height;
    
    
    ## if there is some height to spare, fudge a pixel of leading
    # if ((fontref.height - fontref.ascent) > 2) {
    # 	this.fLeading = 1;
    # }
    this.fLeading = 0;
    
    # sys->print("this.iFontRef=%x\n",this.iFontRef);
    # sys->print("this.iAscent=%x\n",this.iAscent);
    # sys->print("this.iHeight=%x\n",this.iHeight);
    # sys->print("this.fLeading=%x\n",this.fLeading);
}#<<


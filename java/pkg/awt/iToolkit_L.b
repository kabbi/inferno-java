implement iToolkit_L;

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
    draw: Draw;
        Context, Display, Image: import draw;

include "java/lang/ClassLoader_L.m";
include "awt_Color.m";
	awt : AwtColor;

sys : import jni;
ctxt : ref Context;

#<<

include "iToolkit_L.m";

#>> extra post includes here

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    	sys = jni->sys;
    	ctxt = jni->getContext();
        awt = load AwtColor AwtColor->PATH;
        if (awt == nil) {
                sys->print("could not load %s: %r\n", AwtColor->PATH);
                return;
        }
    #<<
}

makeColorModel_rColorModel( this : ref iToolkit_obj ) : JObject
{#>>
	if (ctxt == nil) {
		sys->print("iToolkit_L: Can't makeColorModel - nil context\n");
		return nil;
	}

	junk := this;
        ldepth := ctxt.display.image.ldepth;
        bits := 1<<ldepth;
        jobj := awt->makeColorModel(jni, bits);
	return jobj;
}#<<

## nwk+
loadSystemColors_aI_V( this : ref iToolkit_obj, p0 : JArrayI)
{#>>
        junk := this;

	awt->loadSystemColors(jni, p0);
	return;
}#<<
## -nwk

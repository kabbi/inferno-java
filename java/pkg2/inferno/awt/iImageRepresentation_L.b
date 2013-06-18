implement iImageRepresentation_L;

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

include "iImageRepresentation_L.m";

#>> extra post includes here
    sys : import jni;  # std Inferno Sys module
    str : import jni;  # std Inferno String module

    FALSE : import jni;
    TRUE : import jni;

    # draw.m in included by something included by jni.m
    draw : Draw;
    Context, Screen, Display, Rect, Point, Image : import draw;
    ctxt: ref Context;

include "awt_Image.m";

    awtIm : AwtImage;
    
    # Some constants that aggregate status state.
    IM_SIZEINFO: con (awtIm->ImO_WIDTH | awtIm->ImO_HEIGHT);
    IM_DRAWINFO: con (awtIm->ImO_WIDTH | awtIm->ImO_HEIGHT | 
                      awtIm->ImO_SOMEBITS);
    IM_FULLDRAWINFO: con (awtIm->ImO_FRAMEBITS | awtIm->ImO_ALLBITS);
    IM_OFFSCREENINFO: con (awtIm->ImO_WIDTH | awtIm->ImO_HEIGHT | 
                           awtIm->ImO_SOMEBITS | awtIm->ImO_ALLBITS);

    # Some constants that aggregate hints state
    HINT_OFFSCREENSEND: con (awtIm->ImC_TOPDOWNLEFTRIGHT | 
                             awtIm->ImC_COMPLETESCANLINES | 
                             awtIm->ImC_SINGLEPASS);

include "awt_Color.m";
    awtColor : AwtColor;

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    sys = jni->sys;
    draw = load Draw Draw->PATH;
    if (draw == nil) {
        jni->InitError(sys->sprint(
              "inferno.awt.iImageRepresentation: could not load %s: %r",
              Draw->PATH));
    }
    awtColor = load AwtColor AwtColor->PATH;
    if (awtColor == nil) {
        jni->InitError(sys->sprint(
              "inferno.awt.iImageRepresentation: could not load %s: %r",
              AwtColor->PATH));
    }
    ctxt = jni->getContext();
    #<<
}

offscreenInit_rColor_V( this : ref iImageRepresentation_obj, p0 : JObject)
{#>>
    # Type(p0) is java.awt.Color
    # bgcolorim := ctxt.display.color(Draw->White);  # default
    bgcoloridx := Draw->White;
    if (p0 == nil) {
        sys->print("iImageRepresentation_L.offscreenInit(): p0 == nil!\n");
    } else {
        # get the colormap index for this Java Color
        bgcoloridx = awtColor->getColorIndex(jni, p0);
    }    
    bgcoloridx = Draw->White; # for testing... - jfs
    if (this.width <= 0 || this.height <=0) {
        jni->ThrowException("java.lang.IllegalArgumentException", "offscreen w and h < 0");
    }
    # create an Inferno Image for double buffer store.
    ldeep := ctxt.display.image.ldepth; 
    this.piImage = ctxt.display.newimage(Draw->Rect(
                        (0,0),(this.width,this.height)),
                       ldeep, 0, bgcoloridx);
    sys->print("iImageRepresentation_L.offscreenInit(): - this=%x, piImage=%x!\n",
               this, this.piImage);
}#<<

setBytePixels_I_I_I_I_rColorModel_aB_I_I_Z( this : ref iImageRepresentation_obj, p0 : int,p1 : int,p2 : int,p3 : int,p4 : JObject,p5 : JArrayB,p6 : int,p7 : int) : int
{#>>
    # not yet implemented, so keep the type system happy by returning
    # FALSE as nothing was done
    sys->print("iImageRepresentation_L.setBytePixels(): - NYI!\n");
    return(FALSE);
}#<<

setIntPixels_I_I_I_I_rColorModel_aI_I_I_Z( this : ref iImageRepresentation_obj, p0 : int,p1 : int,p2 : int,p3 : int,p4 : JObject,p5 : JArrayI,p6 : int,p7 : int) : int
{#>>
    # not yet implemented, so keep the type system happy by returning
    # FALSE as nothing was done
    sys->print("iImageRepresentation_L.setIntPixels(): - NYI!\n");
    return(FALSE);
}#<<

finish_Z_Z( this : ref iImageRepresentation_obj, p0 : int) : int
{#>>
    # not yet implemented, so just return false so the calling code
    # wont try a resend in TopDownLeftRight order...
    sys->print("iImageRepresentation_L.finish(): - NYI!\n");
    return(FALSE);
}#<<

imageDraw_rGraphics_I_I_rColor_V( this : ref iImageRepresentation_obj, p0 : JObject,p1 : int,p2 : int,p3 : JObject)
{#>>
    sys->print("iImageRepresentation_L.imageDraw(): - NYI!\n");
}#<<

imageStretch_rGraphics_I_I_I_I_I_I_I_I_rColor_V( this : ref iImageRepresentation_obj, p0 : JObject,p1 : int,p2 : int,p3 : int,p4 : int,p5 : int,p6 : int,p7 : int,p8 : int,p9 : JObject)
{#>>
    sys->print("iImageRepresentation_L.imageStretch(): - NYI!\n");
}#<<

disposeImage_V( this : ref iImageRepresentation_obj)
{#>>
    this.piImage = nil;
    sys->print("iImageRepresentation_L.disposeImage(): - NYI!\n");
}#<<




#
#  %W% - %E%
#
# generated file edit with care

iGraphics_L : module
{
    iGraphics_obj : adt
    {
        cl_mod : ClassModule;
        refImage : ref Draw->Image;
        refOffScreenImage : ref Draw->Image;
	target : JObject;
        foreground : JObject;
        font : JObject;
        ifontpeer : ref iFontPeer_obj;
        originX : int;
        originY : int;
        clipRect : JObject;
        initialClipRect : JObject;
        dirty : int;
        image : JObject;
	awt : AwtGraphics;
    };

    init : fn( jni_p : JNI );
    pSetForeground_I_I_I_V : fn( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int);
    createGraphics_V : fn( this : ref iGraphics_obj);
    pDispose_V : fn( this : ref iGraphics_obj);
    setPaintMode_V : fn( this : ref iGraphics_obj);
    setXORMode_rColor_V : fn( this : ref iGraphics_obj, p0 : JObject);
    changeClip_I_I_I_I_Z_V : fn( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int,p4 : int);
    pClearRect_I_I_I_I_V : fn( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int);
    pFillRect_I_I_I_I_V : fn( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int);
    pDrawRect_I_I_I_I_V : fn( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int);
    pDrawStringWidth_rString_I_I_I : fn( this : ref iGraphics_obj, p0 : JString,p1 : int,p2 : int) : int;
    pDrawLine_I_I_I_I_V : fn( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int);
    pGenDraw_I_I_I_I_aB_V : fn( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int,p4 : JArrayB);
    copyArea_I_I_I_I_I_I_V : fn( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int,p4 : int,p5 : int);
    pDrawRoundRect_I_I_I_I_I_I_V : fn( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int,p4 : int,p5 : int);
    pFillRoundRect_I_I_I_I_I_I_V : fn( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int,p4 : int,p5 : int);
    pDrawPolygon_aI_aI_I_V : fn( this : ref iGraphics_obj, p0 : JArrayI,p1 : JArrayI,p2 : int);
    pDrawPolyline_aI_aI_I_V : fn( this : ref iGraphics_obj, p0 : JArrayI,p1 : JArrayI,p2 : int);
    pFillPolygon_aI_aI_I_V : fn( this : ref iGraphics_obj, p0 : JArrayI,p1 : JArrayI,p2 : int);
    pDrawOval_I_I_I_I_V : fn( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int);
    pFillOval_I_I_I_I_V : fn( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int);
    pDrawArc_I_I_I_I_I_I_V : fn( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int,p4 : int,p5 : int);
    pFillArc_I_I_I_I_I_I_V : fn( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int,p4 : int,p5 : int);
    copyOffscreenImage_I_I_I_I_V :	fn( this : ref iGraphics_obj, p0 : int, p1: int, p2: int, p3: int);
};

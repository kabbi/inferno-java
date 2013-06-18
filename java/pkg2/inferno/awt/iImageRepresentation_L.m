# javal v1.5 generated file: edit with care

iImageRepresentation_L : module
{
    iImageRepresentation_obj : adt
    {
        cl_mod : ClassModule;
        watchers : JObject;     # type java.lang.Vector;
        pData : int;
        src : JObject;          # type sun.awt.image.InputStreamImageSource
        image : JObject;        # type sun.awt.image.Image
        tag : int;
        srcW : int;
        srcH : int;
        width : int;
        height : int;
        hints : int;
        availinfo : int;
        offscreen : byte;
        newbits : JObject;      # type java.awt.Rectangle
        consuming : byte;
        numWaiters : int;
        finalnext : JObject;	# type sun.awt.AWTFinalizeable
        piImage : ref Draw->Image;
    };

    init : fn( jni_p : JNI );
    offscreenInit_rColor_V : fn( this : ref iImageRepresentation_obj, p0 : JObject);
    setBytePixels_I_I_I_I_rColorModel_aB_I_I_Z : fn( this : ref iImageRepresentation_obj, p0 : int,p1 : int,p2 : int,p3 : int,p4 : JObject,p5 : JArrayB,p6 : int,p7 : int) : int;
    setIntPixels_I_I_I_I_rColorModel_aI_I_I_Z : fn( this : ref iImageRepresentation_obj, p0 : int,p1 : int,p2 : int,p3 : int,p4 : JObject,p5 : JArrayI,p6 : int,p7 : int) : int;
    finish_Z_Z : fn( this : ref iImageRepresentation_obj, p0 : int) : int;
    imageDraw_rGraphics_I_I_rColor_V : fn( this : ref iImageRepresentation_obj, p0 : JObject,p1 : int,p2 : int,p3 : JObject);
    imageStretch_rGraphics_I_I_I_I_I_I_I_I_rColor_V : fn( this : ref iImageRepresentation_obj, p0 : JObject,p1 : int,p2 : int,p3 : int,p4 : int,p5 : int,p6 : int,p7 : int,p8 : int,p9 : JObject);
    disposeImage_V : fn( this : ref iImageRepresentation_obj);

};

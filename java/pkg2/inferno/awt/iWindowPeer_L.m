#
#  %W% - %E%
#
# generated file edit with care

iWindowPeer_L : module
{
    iWindowPeer_obj : adt
    {
        cl_mod : ClassModule;
        pCanvas : ref Canvas;
        target : JObject;
        leftInset : int;
        rightInset : int;
        topInset : int;
        bottomInset : int;
        left : int;
        top : int;
        oldMousePoint : JObject;
        buttonState : JArrayZ;
    };

    init : fn( jni_p : JNI );
    getRefImage_rObject : fn( this : ref iWindowPeer_obj) : ref Draw->Image;
    getRefOffScreenImage_rObject : fn( this : ref iWindowPeer_obj) : ref Draw->Image;
    pReshape_I_I_I_I_V : fn( this : ref iWindowPeer_obj, p0 : int,p1 : int,p2 : int,p3 : int);
    pHide_V : fn( this : ref iWindowPeer_obj);
    pShow_riWindowPeer_V : fn( this : ref iWindowPeer_obj, p0 : JObject);
    getXYLoc_I_I : fn( this : ref iWindowPeer_obj, p0 : int) : int;
    create_riWindowPeer_V : fn( this : ref iWindowPeer_obj, p0 : JObject);
    pDispose_V : fn( this : ref iWindowPeer_obj);
    setCursor_I_V : fn( this : ref iWindowPeer_obj, p0 : int);
    toFront_V : fn( this : ref iWindowPeer_obj);
    toBack_V : fn( this : ref iWindowPeer_obj);

};

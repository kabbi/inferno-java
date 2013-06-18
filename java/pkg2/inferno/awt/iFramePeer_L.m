# javal v1.5 generated file: edit with care

iFramePeer_L : module
{
    iFramePeer_obj : adt
    {
        cl_mod : ClassModule;
        pCanvas : ref Canvas;		#JObject;
	thisAsJObject : JObject;
        target : JObject;
        leftInset : int;
        rightInset : int;
        topInset : int;
        bottomInset : int;
        left : int;
        top : int;
	buttonState : JArrayZ;
        oldMousePoint : JObject;
	resizable : int;
    };

    init : fn( jni_p : JNI );
    getRefImage_rObject : fn( this : ref iFramePeer_obj) : ref Draw->Image;
    getRefOffScreenImage_rObject : fn(this :ref iFramePeer_obj) : ref Draw->Image; 
    pReshape_I_I_I_I_V : fn( this : ref iFramePeer_obj, p0 : int,p1 : int,p2 : int,p3 : int);
    pHide_V : fn( this : ref iFramePeer_obj);
    pShow_riFramePeer_V : fn( this : ref iFramePeer_obj, p0 : JObject);
    getXYLoc_I_I : fn( this : ref iFramePeer_obj, p0 : int) : int;
    create_riFramePeer_V : fn( this : ref iFramePeer_obj, p0 : JObject);
    pDispose_V : fn( this : ref iFramePeer_obj);
    setCursor_I_V : fn( this : ref iFramePeer_obj, p0 : int);
    setTitle_rString_V : fn( this : ref iFramePeer_obj, p0 : JString);
    toFront_V : fn( this : ref iFramePeer_obj);
    toBack_V : fn( this : ref iFramePeer_obj);

};

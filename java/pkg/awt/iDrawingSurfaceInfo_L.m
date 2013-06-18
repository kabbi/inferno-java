# javal v1.5 generated file: edit with care

iDrawingSurfaceInfo_L : module
{
    iDrawingSurfaceInfo_obj : adt
    {
        cl_mod : ClassModule;
        state : int;
        w : int;
        h : int;
        peer : JObject;
        imgrep : JObject;
    };

    init : fn( jni_p : JNI );
    lock_I : fn( this : ref iDrawingSurfaceInfo_obj) : int;
    unlock_V : fn( this : ref iDrawingSurfaceInfo_obj);
    getDrawable_rObject : fn( this : ref iDrawingSurfaceInfo_obj) : JObject;
    getDepth_I : fn( this : ref iDrawingSurfaceInfo_obj) : int;

};

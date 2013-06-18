# javal v1.6 generated file: edit with care

Inflater_L : module
{
    Inflater_obj : adt
    {
        cl_mod : ClassModule;
        strm : int;
        buf : JArrayB;
        off : int;
        len_j : int;
        finished : byte;
        needsDictionary : byte;
    };

    init : fn( jni_p : JNI );
    inflate_aB_I_I_I : fn( this : ref Inflater_obj, p0 : JArrayB,p1 : int,p2 : int) : int;
    getTotalIn_I : fn( this : ref Inflater_obj) : int;
    getTotalOut_I : fn( this : ref Inflater_obj) : int;
    reset_V : fn( this : ref Inflater_obj);
    end_V : fn( this : ref Inflater_obj);
    init_Z_V : fn( this : ref Inflater_obj, p0 : int);

};

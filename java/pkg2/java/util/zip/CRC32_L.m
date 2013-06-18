# javal v1.4 generated file: edit with care

CRC32_L : module
{
    CRC32_obj : adt
    {
        cl_mod : ClassModule;
        crc : int;
    };

    init : fn( jni_p : JNI );
    update_aB_I_I_V : fn( this : ref CRC32_obj, p0 : JArrayB,p1 : int,p2 : int);
    update1_I_V : fn( this : ref CRC32_obj, p0 : int);

};

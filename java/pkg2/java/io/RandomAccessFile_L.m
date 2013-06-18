# javal v1.3 generated file: edit with care

RandomAccessFile_L : module
{
    RandomAccessFile_obj : adt
    {
        cl_mod : ClassModule;
        fd : ref FileDescriptor_obj;
    };

    init : fn( jni_p : JNI );
    open_rString_Z_V : fn( this : ref RandomAccessFile_obj, p0 : JString,p1 : int);
    read_I : fn( this : ref RandomAccessFile_obj) : int;
    readBytes_aB_I_I_I : fn( this : ref RandomAccessFile_obj, p0 : JArrayB,p1 : int,p2 : int) : int;
    write_I_V : fn( this : ref RandomAccessFile_obj, p0 : int);
    writeBytes_aB_I_I_V : fn( this : ref RandomAccessFile_obj, p0 : JArrayB,p1 : int,p2 : int);
    getFilePointer_J : fn( this : ref RandomAccessFile_obj) : big;
    seek_J_V : fn( this : ref RandomAccessFile_obj, p0 : big);
    length_J : fn( this : ref RandomAccessFile_obj) : big;
    close_V : fn( this : ref RandomAccessFile_obj);

};

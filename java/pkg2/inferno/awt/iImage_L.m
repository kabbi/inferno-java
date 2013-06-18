#
#  %W% - %E%
#

# javal v1.5 generated file: edit with care

iImage_L : module
{
    iImage_obj : adt
    {
        cl_mod : ClassModule;
        width : int;
        height : int;
        file : JString;
        url : JObject;
        imgbytes : JArrayB;
        properties : JObject;
        q : JObject;
        consumers : JObject;
        fd : ref Sys->FD;
    };

    init : fn( jni_p : JNI );
    getImage_V : fn( this : ref iImage_obj);

};

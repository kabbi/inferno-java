# generated file edit with care

Bits_L : module
{
    Bits_obj : adt
    {
        cl_mod : ClassModule;
    };

    init : fn( jni_p : JNI );
    copyFromShortArray_rObject_J_J_J_V : fn( p0 : JObject,p1 : big,p2 : big,p3 : big);
    copyToShortArray_J_rObject_J_J_V : fn( p0 : big,p1 : JObject,p2 : big,p3 : big);
    copyFromIntArray_rObject_J_J_J_V : fn( p0 : JObject,p1 : big,p2 : big,p3 : big);
    copyToIntArray_J_rObject_J_J_V : fn( p0 : big,p1 : JObject,p2 : big,p3 : big);
    copyFromLongArray_rObject_J_J_J_V : fn( p0 : JObject,p1 : big,p2 : big,p3 : big);
    copyToLongArray_J_rObject_J_J_V : fn( p0 : big,p1 : JObject,p2 : big,p3 : big);

};

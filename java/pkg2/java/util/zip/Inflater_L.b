implement Inflater_L;

# javal v1.4 generated file: edit with care

include "jni.m";
    jni : JNI;
        ClassModule,
        JString,
        JArray,
        JArrayI,
        JArrayC,
        JArrayB,
        JArrayS,
        JArrayJ,
        JArrayF,
        JArrayD,
        JArrayZ,
        JArrayJObject,
        JArrayJClass,
        JArrayJString,
        JClass,
        JThread,
        JObject : import jni;

#>> extra pre includes here

#<<

include "Inflater_L.m";

#>> extra post includes here

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    #<<
}

inflate_aB_I_I_I( this : ref Inflater_obj, p0 : JArrayB,p1 : int,p2 : int) : int
{#>>
	junk1 := (this, p0);
	junk2 := (p1, p2);
	return 0;
}#<<

getTotalIn_I( this : ref Inflater_obj) : int
{#>>
	junk := this;
	return 0;
}#<<

getTotalOut_I( this : ref Inflater_obj) : int
{#>>
	junk := this;
	return 0;
}#<<

reset_V( this : ref Inflater_obj)
{#>>
	junk := this;
}#<<

end_V( this : ref Inflater_obj)
{#>>
	junk := this;
}#<<

init_Z_V( this : ref Inflater_obj, p0 : int)
{#>>
	junk := (this, p0);
}#<<



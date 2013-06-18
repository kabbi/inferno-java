implement Float_L;

# javal v1.3 generated file: edit with care

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

include "Float_L.m";

#>> extra post includes here
math : Math;
#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
	math = jni->math;
    #<<
}

floatToIntBits_F_I( p0 : real) : int
{#>>
	return( math->realbits32(p0) );
}#<<

intBitsToFloat_I_F( p0 : int) : real
{#>>
	return( math->bits32real(p0) );
}#<<

mkstring_F_rString( p0 : real) : JString
{#>>
	s := string p0;
	if(p0 == 0.0)
		s += ".0";
	return( jni->NewString( s ) );
}#<<

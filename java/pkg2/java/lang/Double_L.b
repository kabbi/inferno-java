implement Double_L;

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

include "Double_L.m";

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

doubleToLongBits_D_J( p0 : real) : big
{#>>
	return( math->realbits64(p0) );
}#<<

longBitsToDouble_J_D( p0 : big) : real
{#>>
	return( math->bits64real( p0 ) );
}#<<

valueOf0_rString_D( p0 : JString) : real
{#>>
	return( real p0.str );
}#<<

mkstring_D_rString( p0 : real) : JString
{#>>
	s := string p0;
	if(p0 == 0.0)
		s += ".0";
	return( jni->NewString( s ) );
}#<<


implement Math_L;

# javal v1.2 generated file: edit with care

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
        JObject : import jni;

#>> extra pre includes here

#<<

include "Math_L.m";

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

sin_D_D( p0 : real) : real
{#>>
	return( math->sin(p0) );
}#<<

cos_D_D( p0 : real) : real
{#>>
	return( math->cos(p0) );
}#<<

tan_D_D( p0 : real) : real
{#>>
	return( math->tan(p0) );
}#<<

asin_D_D( p0 : real) : real
{#>>
	return( math->asin(p0) );
}#<<

acos_D_D( p0 : real) : real
{#>>
	return( math->acos(p0) );
}#<<

atan_D_D( p0 : real) : real
{#>>
	return( math->atan(p0) );
}#<<

exp_D_D( p0 : real) : real
{#>>
	return( math->exp(p0) );
}#<<

log_D_D( p0 : real) : real
{#>>
	return( math->log(p0) );
}#<<

sqrt_D_D( p0 : real) : real
{#>>
	return( math->sqrt(p0) );
}#<<

IEEEremainder_D_D_D( p0 : real,p1 : real) : real
{#>>
	return( math->remainder(p0,p1) );
}#<<

ceil_D_D( p0 : real) : real
{#>>
	return( math->ceil(p0) );
}#<<

floor_D_D( p0 : real) : real
{#>>
	return( math->floor(p0) );
}#<<

rint_D_D( p0 : real) : real
{#>>
	return( math->rint(p0) );
}#<<

atan2_D_D_D( p0 : real,p1 : real) : real
{#>>
	return( math->atan2(p0,p1) );
}#<<

pow_D_D_D( p0 : real,p1 : real) : real
{#>>
	return( math->pow(p0,p1) );
}#<<




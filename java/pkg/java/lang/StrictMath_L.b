implement StrictMath_L;

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
    math: Math;
#<<

include "StrictMath_L.m";

#>> extra post includes here

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
    return math->sin(p0);
}#<<

cos_D_D( p0 : real) : real
{#>>
    return math->cos(p0);
}#<<

tan_D_D( p0 : real) : real
{#>>
    return math->tan(p0);
}#<<

atan2_D_D_D( p0 : real,p1 : real) : real
{#>>
    return math->atan2(p0, p1);
}#<<

sqrt_D_D( p0 : real) : real
{#>>
    return math->sqrt(p0);
}#<<

log_D_D( p0 : real) : real
{#>>
    return math->log(p0);
}#<<

log10_D_D( p0 : real) : real
{#>>
    return math->log10(p0);
}#<<

pow_D_D_D( p0 : real,p1 : real) : real
{#>>
    return math->pow(p0, p1);
}#<<

exp_D_D( p0 : real) : real
{#>>
    return math->exp(p0);
}#<<

asin_D_D( p0 : real) : real
{#>>
    return math->asin(p0);
}#<<

acos_D_D( p0 : real) : real
{#>>
    return math->acos(p0);
}#<<

atan_D_D( p0 : real) : real
{#>>
    return math->atan(p0);
}#<<

cbrt_D_D( p0 : real) : real
{#>>
    return math->cbrt(p0);
}#<<

IEEEremainder_D_D_D( p0 : real,p1 : real) : real
{#>>
    return math->remainder(p0, p1);
}#<<

sinh_D_D( p0 : real) : real
{#>>
    return math->sinh(p0);
}#<<

cosh_D_D( p0 : real) : real
{#>>
    return math->cosh(p0);
}#<<

tanh_D_D( p0 : real) : real
{#>>
    return math->tanh(p0);
}#<<

hypot_D_D_D( p0 : real,p1 : real) : real
{#>>
    return math->hypot(p0, p1);
}#<<

expm1_D_D( p0 : real) : real
{#>>
    return math->expm1(p0);
}#<<

log1p_D_D( p0 : real) : real
{#>>
    return math->log1p(p0);
}#<<


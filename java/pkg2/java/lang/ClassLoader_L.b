implement ClassLoader_L;

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

include "ClassLoader_L.m";

#>> extra post includes here

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    #<<
}

init_V( this : ref ClassLoader_obj)
{#>>
	junk := this;
}#<<

defineClass0_rString_aB_I_I_rClass( this : ref ClassLoader_obj, p0 : JString,p1 : JArrayB,p2 : int,p3 : int) : JClass
{#>>
	junk := (this,p0,p1,p2,p3);
	jni->ThrowException( "java.lang.ClassNotFoundException", "not implemented" );
	return( nil );
}#<<

resolveClass0_rClass_V( this : ref ClassLoader_obj, p0 : JClass)
{#>>
	junk := (this,p0);
	jni->FatalError( "resolveClass() not implemented" );
}#<<

findSystemClass0_rString_rClass( this : ref ClassLoader_obj, p0 : JString) : JClass
{#>>
	junk := (this,p0);
	jni->FatalError( "findSystemClass() not implemented" );
	return( nil );
}#<<

getSystemResourceAsStream0_rString_rInputStream( p0 : JString) : JObject
{#>>
	junk := p0;
	jni->FatalError( "getSystemResourceAsStream() not implemented" );
	return( nil );
}#<<

getSystemResourceAsName0_rString_rString( p0 : JString) : JString
{#>>
	junk := p0;
	jni->FatalError( "getSystemResourceAsName() not implemented" );
	return( nil );
}#<<




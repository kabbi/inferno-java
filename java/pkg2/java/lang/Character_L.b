implement Character_L;

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

include "Character_L.m";

#>> extra post includes here

include "unicode_table.m";

unicode_table : UnicodeTable;
	A,
	Y,
	X   : import unicode_table;

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    #<<
}

lookup_C_I( p0 : int) : int
{#>>
	if ( unicode_table == nil )
		loadtable();

	return( A[Y[(X[p0>>6]<<6)|(p0& 16r3F)]] );
}#<<

loadtable()
{
	unicode_table = load UnicodeTable UnicodeTable->PATH;
	if ( unicode_table == nil )
		jni->InitError( jni->sys->sprint( "java.lang.Character: could not load %s: %r", UnicodeTable->PATH ) );
}

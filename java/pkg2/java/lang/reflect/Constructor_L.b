implement Constructor_L;

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

    Value,
    ClassData,
    jldr : import jni;

    Object : import jldr;

#<<

include "Constructor_L.m";

#>> extra post includes here

illegalarg := "java.lang.IllegalArgumentException";
nullptr    := "java.lang.NullPointerException";

include "reflect.m";
    refl : Reflect;
    widen : import refl;

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    refl = load Reflect Reflect->PATH;
    if ( refl == nil )
	jni->InitError( jni->sys->sprint( "java.lang.reflect.Constructor: could not load %s: %r", Reflect->PATH ) );
    else
	refl->init(jni);
    #<<
}

getModifiers_I( this : ref Constructor_obj) : int
{#>>
    #
    #	Assume that lower part of slot has modifier bits.
    #
    return this.slot & 16rffff;
}#<<

newInstance_aObject_rObject( this : ref Constructor_obj, p0 : JArrayJObject) : JObject
{#>>
    #	this - a Constructor object representing a constructor of some class
    #	p0   - a Java array of Objects, containing argument values for the
    #	       the constructor
    #	Returns a new instance, constructed by the 'this' constructor.
    #
    #	Check inputs and build the argument list.
    #
    args := refl->BuildArgList(this.parameterTypes, p0);
    #
    #	Allocate a new object, then do the call.
    #
    newobj := jni->AllocObject(this.clazz.class);

    # Eventually may be able to do something like
    # (result, ok) = jni->CallConstruct(newobj, this.slot, args);

    fld := this.clazz.class.initmethods[this.slot >> 16];
    (nil, ok) := jni->CallMethod(newobj, fld.field, fld.signature, args);

    if ( ok == JNI->OK )
	return newobj;
    return nil;
}#<<

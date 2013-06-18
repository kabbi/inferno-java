implement Method_L;

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

include "Method_L.m";

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
	jni->InitError( jni->sys->sprint( "java.lang.reflect.Method: could not load %s: %r", Reflect->PATH ) );
    else
	refl->init(jni);
    #<<
}

getModifiers_I( this : ref Method_obj) : int
{#>>
    #
    #	Assume that lower part of slot has modifier bits.
    #
    return this.slot & 16rffff;
}#<<

invoke_rObject_aObject_rObject( this : ref Method_obj, p0 : JObject,p1 : JArrayJObject) : JObject
{#>>
    #	this - a Method object.  The corresponding method should be invoked for
    #	p0   - an Object which should contain that method, with
    #	p1   - a Java array of Objects that are the arguments to the method.
    #	       Can be null if the method has no arguments.
    #   Returns an object reflecting the value returned by the method call.
    #
    #	First do some checking.  If 'this' is a static method, p0 is ignored,
    #	otherwise it must an instance of the class in which the method is
    #	declared.
    #
    if ( (this.slot & JNI->ACC_STATIC) == 0 ) {	# not static
	if ( p0 == nil )
	    jni->ThrowException(nullptr, "Must supply an instance");
	if ( jni->IsInstanceOf(p0, this.clazz.class) == JNI->FALSE )
	    jni->ThrowException(illegalarg, "Method not in object");
    }
    #
    #	Check inputs and build the argument list.
    #
    args := refl->BuildArgList(this.parameterTypes, p1);
    #
    #	Do the call.
    #
    result : ref Value;
    ok : int;
    if ( this.slot & JNI->ACC_STATIC ) {
	fld := this.clazz.class.staticmethods[this.slot >> 16];
	(result, ok) = jni->CallStatic(this.clazz.class, fld.field,
							fld.signature, args);
    }
    else {
	fld : ref JavaClassLoader->Field;
	if ( (this.slot & JNI->ACC_PRIVATE) != 0 )
	    fld = p0.class().privatemethods[this.slot >> 16];
	else
	    fld = p0.class().virtualmethods[this.slot >> 16].field;
	(result, ok) = jni->CallMethod(p0, fld.field, fld.signature, args);
    }
    #
    #	If necessary, wrap the answer up as an Object.
    #
    if ( ok == JNI->OK && result != nil ) {
	typ := refl->ValType(result);
	if ( typ >= JNI->T_BOOLEAN && typ <= JNI->T_LONG )
	    return refl->ValueToObject(result);
	else
	    return result.Object();
    }
    return nil;
}#<<

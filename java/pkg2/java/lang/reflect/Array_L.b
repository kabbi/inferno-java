implement Array_L;

# javal v1.5 generated file: edit with care

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

	ClassData,
	Value	: import jni;

	jldr    : JavaClassLoader;

#<<

include "Array_L.m";

#>> extra post includes here

include "reflect.m";
    refl : Reflect;
    widen : import refl;

array_class : ClassData;

badindex   := "java.lang.ArrayIndexOutOfBoundsException";
illegalarg := "java.lang.IllegalArgumentException";
nullptr    := "java.lang.NullPointerException";

    cast : Cast;

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    array_class = jni->FindClass("inferno/vm/Array");

    jldr = jni->jldr;
    cast = jni->CastMod();
    refl = load Reflect Reflect->PATH;
    if ( refl == nil )
	jni->InitError( jni->sys->sprint( "java.lang.reflect.Array: could not load %s: %r", Reflect->PATH ) );
    else
	refl->init(jni);

    #<<
}

getLength_rObject_I( p0 : JObject) : int
{#>>
    #	p0 - must be a Java array; if not, exceptions are thrown
    #	Returns the integer length of the array.

    if ( p0 == nil )
	jni->ThrowException(nullptr, "");
    if ( jni->IsArray(p0) == JNI->FALSE)
	jni->ThrowException(illegalarg, "Not an array");
    return jni->GetArrayLength(cast->ToJArray(p0));
}#<<

get_rObject_I_rObject( p0 : JObject,p1 : int) : JObject
{#>>
    #	p0 - a Java object, which must be an array, else exception occurs.
    #	p1 - an index into the array, >= 0 and < length of array
    #	Returns the element at that index.  If the array is of a primitive
    #	type, it is put in an appropriate wrapper class instance.

    checksOK(p0, p1);

    #
    #	Need to figure out what kind of an array this is, then get the
    #	requested element and convert it to an appropriate JObject.
    #
    (typ, elem) := GetArrayElement(p0, p1);
    #(typ, elem) := jni->GetArrayElement(p0, p1);

    if ( typ == 0 )	# array of Objects.  good.
	return elem.Object();

    if ( typ >= JNI->T_BOOLEAN && typ <= JNI->T_LONG )
	return refl->ValueToObject(elem);

    return nil;
}#<<

getBoolean_rObject_I_Z( p0 : JObject,p1 : int) : int
{#>>
    #	p0 - a Java object, which must be an array, else exception occurs.
    #	p1 - an index into the array, >= 0 and < length of array
    #	Returns the element at that index as a boolean value.  If the array
    #	is not an array of something that can be converted to a boolean by
    #	widening (and for boolean that's nothing), then getprim will throw
    #	an exception.

    return getprim(p0, p1, JNI->T_BOOLEAN, "boolean").Boolean();
}#<<

getByte_rObject_I_B( p0 : JObject,p1 : int) : int
{#>>
    #	See comments in getBoolean_rObject_I_Z, above

    return getprim(p0, p1, JNI->T_BYTE, "byte").Byte();
}#<<

getChar_rObject_I_C( p0 : JObject,p1 : int) : int
{#>>
    #	See comments in getBoolean_rObject_I_Z, above

    return getprim(p0, p1, JNI->T_CHAR, "char").Char();
}#<<

getShort_rObject_I_S( p0 : JObject,p1 : int) : int
{#>>
    #	See comments in getBoolean_rObject_I_Z, above

    return getprim(p0, p1, JNI->T_SHORT, "short").Short();
}#<<

getInt_rObject_I_I( p0 : JObject,p1 : int) : int
{#>>
    #	See comments in getBoolean_rObject_I_Z, above

    return getprim(p0, p1, JNI->T_INT, "int").Int();
}#<<

getLong_rObject_I_J( p0 : JObject,p1 : int) : big
{#>>
    #	See comments in getBoolean_rObject_I_Z, above

    return getprim(p0, p1, JNI->T_LONG, "long").Long();
}#<<

getFloat_rObject_I_F( p0 : JObject,p1 : int) : real
{#>>
    #	See comments in getBoolean_rObject_I_Z, above

    return getprim(p0, p1, JNI->T_FLOAT, "float").Float();
}#<<

getDouble_rObject_I_D( p0 : JObject,p1 : int) : real
{#>>
    #	See comments in getBoolean_rObject_I_Z, above

    return getprim(p0, p1, JNI->T_DOUBLE, "double").Double();
}#<<

set_rObject_I_rObject_V( p0 : JObject,p1 : int,p2 : JObject)
{#>>
    #	p0 - a Java array.  If null or not an array, exception.
    #	p1 - index into the array.  If < 0 or >= length of array, exception.
    #	p2 - a value to put into the array at the specified index.  If p0 is
    #	     an array of JObject, p2 must be an instance of the appropriate
    #	     class.  If p0 is an array of a primitive Java type, then p2 must
    #	     be a wrapper of a primitive type that can be converted to the
    #	     the array's type by widening.

    checksOK(p0, p1);

    objarray := cast->ToJArray(p0);
    typ := objarray.primitive;
    if ( typ == 0 ) {		# an Object array
	if ( jni->IsInstanceOf(p2, objarray.class) == JNI->TRUE ) {
	    cast->JArrayToObject(objarray).ary[p1] = p2;
	    return;
	}
    }
    else if ( typ >= JNI->T_BOOLEAN && typ <= JNI->T_LONG ) {
	(stype, val) := refl->GetVal(p2);
	if ( stype != 0 && (val = widen(stype, typ, val)) != nil ) {
	    SetArrayElement(p0, p1, val);
	    return;
	}
    }
    jni->ThrowException(illegalarg, "Argument can't be cast to array element");
}#<<

setBoolean_rObject_I_Z_V( p0 : JObject,p1 : int,p2 : int)
{#>>
    #	p0[p1] = p2
    #	where p2 is a boolean value, and it must be possible to convert it by
    #	widening to the type array p0.

    putprim(p0, p1, JNI->T_BOOLEAN, "boolean", ref Value.TBoolean(p2));
}#<<

setByte_rObject_I_B_V( p0 : JObject,p1 : int,p2 : int)
{#>>
    #	see comments for setBoolean_rObject_I_Z_V, above.

    putprim(p0, p1, JNI->T_BYTE, "byte", ref Value.TByte(p2));
}#<<

setChar_rObject_I_C_V( p0 : JObject,p1 : int,p2 : int)
{#>>
    #	see comments for setBoolean_rObject_I_Z_V, above.

    putprim(p0, p1, JNI->T_CHAR, "char", ref Value.TChar(p2));
}#<<

setShort_rObject_I_S_V( p0 : JObject,p1 : int,p2 : int)
{#>>
    #	see comments for setBoolean_rObject_I_Z_V, above.

    putprim(p0, p1, JNI->T_SHORT, "short", ref Value.TShort(p2));
}#<<

setInt_rObject_I_I_V( p0 : JObject,p1 : int,p2 : int)
{#>>
    #	see comments for setBoolean_rObject_I_Z_V, above.

    putprim(p0, p1, JNI->T_INT, "int", ref Value.TInt(p2));
}#<<

setLong_rObject_I_J_V( p0 : JObject,p1 : int,p2 : big)
{#>>
    #	see comments for setBoolean_rObject_I_Z_V, above.

    putprim(p0, p1, JNI->T_LONG, "long", ref Value.TLong(p2));
}#<<

setFloat_rObject_I_F_V( p0 : JObject,p1 : int,p2 : real)
{#>>
    #	see comments for setBoolean_rObject_I_Z_V, above.

    putprim(p0, p1, JNI->T_FLOAT, "float", ref Value.TFloat(p2));
}#<<

setDouble_rObject_I_D_V( p0 : JObject,p1 : int,p2 : real)
{#>>
    #	see comments for setBoolean_rObject_I_Z_V, above.

    putprim(p0, p1, JNI->T_DOUBLE, "double", ref Value.TDouble(p2));
}#<<

newArray(jclass: JClass, bounds: array of int): JObject
{
    #	Create a Java array whose components belong to class jclass.
    #	jclass may be a class object representing a primitive type.
    #	bounds gives the length of each dimension.

    dims := len bounds;
    cldata: ClassData;

    #	See if the class represents a primitive type.
    typ := jni->PrimitiveIndex(jclass, 1);

    #	If jclass represents an array, then component type of array
    #	being created is component type of jclass.
    s := jclass.aryname;
    if(s != nil) {
	# count [s in aryname
	n := 1;
	while(s[n] == '[')
	    n++;
	dims += n;
	typ = refl->SigToType(s[n:]);
	if(typ == 0)
	    cldata = jni->FindClass(s[n+1:len s - 1]);
    } else if(typ == 0) {	# jclass is not array and not primitive
	cldata = jclass.class;
    }

    return cast->FromJArray(jldr->multianewarray(dims, cldata, typ, bounds));
}

newArray_rClass_I_rObject( p0 : JClass,p1 : int) : JObject
{#>>
    if ( p0 == nil )
	jni->ThrowException(nullptr, "");

    return newArray(p0, array [1] of { p1 });
}#<<

multiNewArray_rClass_aI_rObject( p0 : JClass,p1 : JArrayI) : JObject
{#>>
    if ( p0 == nil || p1 == nil )
	jni->ThrowException(nullptr, "");

    ln := len p1.ary;

    if ( ln < 1 || ln > 255 )
	jni->ThrowException(illegalarg, "dimensions out of range [1,255]");

    return newArray(p0, p1.ary);
}#<<

#	An argument verification routine for use by native methods.  The
#	first argument must be non-null, and a Java array.  (These conditions
#	are actually check by calling getLength_rObject.)  The second
#	argument must be a valid index into that array.  There is no return
#	value: if the conditions above are not met, an exception is thrown;
#	hence the routine does not return in this case.  A successful return
#	indicates the arguments are O.K.
#
checksOK(o : JObject, ix : int)
{
    if ( ix >= getLength_rObject_I(o) || ix < 0 )
	jni->ThrowException(badindex, "Illegal index");
    return;
}
#
#	Gets element 'index' of Java array 'o' and returns it as a ref Value
#	of the type corresponding to Java type index 'want'.  String 's'
#	is used only in creating the exception message, and should correspond
#	to 'want'.  o must be non-null and refer to a Java array, index must
#	within range, and the array must be of a primitive type that can
#	be made into the requested type by a widening conversion.  If any of
#	these conditions are not met, an exception is thrown.
#
getprim( o : JObject, index : int, want : int, s : string) : ref Value
{
    checksOK(o, index);

    (typ, elem) := GetArrayElement(o, index);
    if ( (wider := widen(typ, want, elem)) == nil ) {
	if ( s != nil )
    	    jni->ThrowException(illegalarg, "Can't cast array element to " + s);
	else
	    jni->ThrowException(illegalarg, "Can't cast array element");
    }
    return wider;
}
#
#	Sets element 'index' of Java array 'o' to the ref Value 'val'
#	of the type corresponding to Java type index 'have'.  String 's'
#	is used only in creating the exception message, and should correspond
#	to 'have'.  o must be non-null and refer to a Java array, index must
#	within range, and the array must be of a primitive type that can
#	be made from the provided type by a widening conversion.  If any of
#	these conditions are not met, an exception is thrown.
#
putprim( o : JObject, index : int, have : int, s : string, val : ref Value)
{
    checksOK(o, index);

    typ := cast->ToJArray(o).primitive;
    if ( (val = widen(have, typ, val)) == nil ) {
	if ( s != nil )
    	    jni->ThrowException(illegalarg,
				"Can't put input value into " + s + " array");
	else
    	    jni->ThrowException(illegalarg,
				"Can't put input value into array");
    }
    SetArrayElement(o, index, val);
    #jni->SetArrayElement(o, index, val);
}
#
#	Get the element at index from the Java array o and return it in
#	in an appropriate member of the Value union.
#	The arguments should have been verified before calling this function.
#
GetArrayElement( o : JObject, index : int ) : (int, ref Value)
{
    a := cast->ToJArray(o);
    val : ref Value;
    case a.primitive {
      0 =>
	val = ref Value.TObject(cast->JArrayToObject(a).ary[index]);
      JNI->T_BOOLEAN =>
	val = ref Value.TBoolean(int cast->JArrayToByte(a).ary[index]);
      JNI->T_BYTE =>
	val = ref Value.TByte(int cast->JArrayToByte(a).ary[index]);
      JNI->T_CHAR =>
	val = ref Value.TChar(cast->JArrayToInt(a).ary[index]);
      JNI->T_SHORT =>
	val = ref Value.TShort(cast->JArrayToInt(a).ary[index]);
      JNI->T_INT =>
	val = ref Value.TInt(cast->JArrayToInt(a).ary[index]);
      JNI->T_LONG =>
	val = ref Value.TLong(cast->JArrayToBig(a).ary[index]);
      JNI->T_FLOAT =>
	val = ref Value.TFloat(cast->JArrayToReal(a).ary[index]);
      JNI->T_DOUBLE =>
	val = ref Value.TDouble(cast->JArrayToReal(a).ary[index]);
    }
    return (a.primitive, val);
}
#
#	Set the element at index from the Java array o to 'val',
#	The arguments should have been verified before calling this function.
#
SetArrayElement( o : JObject, index : int, val : ref Value)
{
    a := cast->ToJArray(o);
    pick sw := val {
      TBoolean	=> cast->JArrayToByte(a).ary[index] = byte sw.jboolean;
      TByte	=> cast->JArrayToByte(a).ary[index] = byte sw.jbyte;
      TChar	=> cast->JArrayToInt(a).ary[index] = sw.jchar;
      TShort	=> cast->JArrayToInt(a).ary[index] = sw.jshort;
      TInt	=> cast->JArrayToInt(a).ary[index] = sw.jint;
      TLong	=> cast->JArrayToBig(a).ary[index] = sw.jlong;
      TFloat	=> cast->JArrayToReal(a).ary[index] = sw.jfloat;
      TDouble	=> cast->JArrayToReal(a).ary[index] = sw.jdouble;
    }
}

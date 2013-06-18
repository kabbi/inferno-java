implement Reflect;

include "jni.m";
    jni : JNI;
    cast : Cast;

    JObject,
    JClass,
    JArrayJClass,
    JArrayJObject,
    Value 	: import jni;
    OK,
    ERR,
    TRUE,
    FALSE,
    #T_OBJECT, T_ARRAY,
    T_BOOLEAN,
    T_BYTE,
    T_CHAR,
    T_SHORT,
    T_INT,
    T_LONG,
    T_FLOAT,
    T_DOUBLE	: import JNI;

    ClassData	: import JNI;

include "reflect.m";

wrapper_class := array[T_LONG-T_BOOLEAN+1] of ClassData;
wrapper_name :=  array[] of {	"Boolean",
				"Character",
				"Float",
				"Double",
				"Byte",
				"Short",
				"Integer",
				"Long"	};
type_string := "ZCFDBSIJ";

illegalarg := "java.lang.IllegalArgumentException";
nullptr    := "java.lang.NullPointerException";

init(jni_m : JNI) {
    jni = jni_m;
    for ( i := 0; i <= T_LONG - T_BOOLEAN; i++ )
	wrapper_class[i] = jni->FindClass("java/lang/" + wrapper_name[i]);
    cast = jni->CastMod();
}

widen(have, want : int, val : ref Value) : ref Value
{
    if ( have == want )
	return val;
    havetype := have;
    wanttype := want;
    valint : int;
    valbig : big;
    valreal : real;
    if ( havetype == 0 || wanttype == 0 )
	return nil;
    pick sw := val {
      TByte =>
	valint = int sw.jbyte;
	valbig = big valint;
	valreal = real valint;
      TShort =>
	valint = sw.jshort;
	valbig = big valint;
	valreal = real valint;
      TChar =>
	valint = sw.jchar;
	valbig = big valint;
	valreal = real valint;
      TInt =>
	valint = sw.jint;
	valbig = big valint;
	valreal = real valint;
      TLong =>
	valbig = sw.jlong;
	valreal = real valbig;
      TFloat =>
	valreal = sw.jfloat;
    }
    case ( wanttype ) {
      T_BOOLEAN or T_BYTE or T_CHAR =>
	return nil;
      T_SHORT =>
	case ( havetype ) {
	  T_BYTE =>
	    sw := ref Value.TShort;
	    sw.jshort = valint;
	    val = sw;
	  * =>
	    return nil;
	}
      T_INT =>
	case ( havetype ) {
	  T_BYTE or T_SHORT or T_CHAR =>
	    sw := ref Value.TInt;
	    sw.jint = valint;
	    val = sw;
	  * =>
	    return nil;
	}
      T_LONG =>
	case ( havetype ) {
	  T_BYTE or T_SHORT or T_CHAR or T_INT =>
	    sw := ref Value.TLong;
	    sw.jlong = valbig;
	    val = sw;
	  * =>
	    return nil;
	}
      T_FLOAT =>
	case ( havetype ) {
	  T_BYTE or T_SHORT or T_CHAR or T_INT or T_LONG =>
	    sw := ref Value.TFloat;
	    sw.jfloat = valreal;
	    val = sw;
	  * =>
	    return nil;
	}
      T_DOUBLE =>
	case ( havetype ) {
	  T_BYTE or T_SHORT or T_CHAR or T_INT or T_LONG or T_FLOAT =>
	    sw := ref Value.TDouble;
	    sw.jdouble = valreal;
	    val = sw;
	  * =>
	    return nil;
	}
    }
    return val;
}
BuildArgList(parms : JArrayJClass, arg : JArrayJObject) : array of ref Value
{
    #
    #	First do some checking.
    #
    l := 0;
    formal: array of JClass;
    actual: array of JObject;
    args: array of ref Value;
    if ( parms != nil ) {
	if ( arg == nil )
	    jni->ThrowException(nullptr, "constructor requires parameters");
	if ( len parms.ary != len arg.ary )
	    jni->ThrowException(illegalarg, "Wrong number of args");
	l = len parms.ary;
	formal = parms.ary;		# array of JClass
	actual = arg.ary;			# array of JObject
	args = array[l] of ref Value;
    }
    else		# There are no formal parameters
	if ( arg != nil && len arg.ary != 0 ) # But there are actual arguments
	    jni->ThrowException(illegalarg, "Wrong number of args");

    #
    #	March through the arguments, checking for type as we go.
    #
    for ( i := 0; i < l; i++ ) {
	#
	#   Is the formal parameter a primitive?
	#
	if ( (want := jni->PrimitiveIndex(formal[i], 1)) > 0 ) {
	    #
	    #	Actual parameter should be (derived from) a wrapper, and
	    #	be able to be widened to the formal parameter type.
	    #
	    (typ, parmval) := GetVal(actual[i]);
	    if ( (val := widen(want, typ, parmval)) != nil )
		args[i] = val;
	    else
		jni->ThrowException(illegalarg, "Argument " + string (i+1) +
							", can't cast");
	}
	else if ( jni->IsInstanceOf(actual[i], formal[i].class) == JNI->TRUE ) {
	    val := ref Value.TObject;
	    val.jobj = actual[i];
	    args[i] = val;
	}
	else
	    jni->ThrowException(illegalarg, "Argument " + string (i+1) +
							" wrong type");
    }
    return args;
}
#
#	Return a JClass corresponding to the Java type t.
#
Class(t : int) : JClass
{
    if ( t < T_BOOLEAN || t > T_LONG )
	return nil;
    return jni->GetClassObject(wrapper_class[t - T_BOOLEAN]);
}
#
#	Return a Class Object corresponding to the Java type t.
#
ClassObject(t : int) : JObject
{
    return cast->FromJClass(Class(t));
}
#
#	Given the java type, get the Class object representing this
#	type, and return as a Value.
#
GetPrimitiveClass(typ : int) : ref Value
{
    return jni->GetStaticField(wrapper_class[typ - T_BOOLEAN], "TYPE",
							"Ljava/lang/Class;");
}
#
#	If the Object o is a wrapper for a Java primitive type, return the
#	primitive value (in a Value adt) and the type index.
#	Otherwise, return 0 and a nil Value.
#
GetVal(o : JObject) : (int, ref Value)
{
    j := T_BOOLEAN;
    for ( i := j; i <= T_LONG; i++ ) {
	if ( jni->IsInstanceOf(o, wrapper_class[i-j]) == TRUE ) {
	    val := jni->GetObjField(o, "value", type_string[i-j:i-j+1]);
	    return (i, val);
	}
    }
    return (0, nil);
}
#
#	Convert a signature to a java type index.
#
SigToType(sig : string) : int
{
    index : int;
    case sig[0] {
	'Z' =>
	    index = T_BOOLEAN;
	'B' =>
	    index = T_BYTE;
	'C' =>
	    index = T_CHAR;
	'S' =>
	    index = T_SHORT;
	'I' =>
	    index = T_INT;
	'J' =>
	    index = T_LONG;
	'F' =>
	    index = T_FLOAT;
	'D' =>
	    index = T_DOUBLE;
	* =>
	    index = 0;
    }
    return index;
}
#
#       Convert a java type index to a signature.
#
TypeToSig(typ : int) : string
{
    if ( typ < T_BOOLEAN || typ > T_LONG )
	return nil;
    return type_string[typ-T_BOOLEAN:typ-T_BOOLEAN+1];
}
#
#	Convert a Java type character to its corresponding type name.
#
TypeCharToName(c : int) : string
{
    tname : string;
    case c {
	'Z' =>
	    tname = "boolean";
	'B' =>
	    tname = "byte";
	'C' =>
	    tname = "char";
	'S' =>
	    tname = "short";
	'I' =>
	    tname = "int";
	'J' =>
	    tname = "long";
	'F' =>
	    tname = "float";
	'D' =>
	    tname = "double";
	* =>
	    tname = "blah";
    }
    return tname;
}
#
#	Calculate the type index of the quantity in val.  If it isn't a
#	Java primitive type, return 0;
#
ValType(val : ref Value) : int
{
    pick sw := val {
      TBoolean	=> return T_BOOLEAN;
      TByte	=> return T_BYTE;
      TChar	=> return T_CHAR;
      TShort	=> return T_SHORT;
      TInt	=> return T_INT;
      TLong	=> return T_LONG;
      TFloat	=> return T_FLOAT;
      TDouble	=> return T_DOUBLE;
      *		=> return 0;
    }
}
#
#	Create a wrapper Object for the primitive Java value corresponding
#	to the argument.
#
ValueToObject(val : ref Value) : JObject
{
    typ := ValType(val);
    j := T_BOOLEAN;
    jobj := jni->AllocObject(wrapper_class[typ - j]);
    sig := "(" + type_string[typ-j:typ-j+1] + ")V";
    (nil, ok) := jni->CallMethod(jobj, "<init>", sig, array[] of { val });
    if ( ok == OK )
	return jobj;
    return nil;
}

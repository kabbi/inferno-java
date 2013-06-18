implement Field_L;

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

	Value,
	ClassData : import jni;
    jldr : JavaClassLoader;
	Object,
	Class : import jldr;

#<<

include "Field_L.m";

#>> extra post includes here

include "reflect.m";
    refl : Reflect;

STATIC, NONSTATIC : con iota;

illegalacc,
illegalarg,
nullptr    : string;

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    jldr = jni->jldr;

    illegalacc = "java.lang.IllegalAccessException";
    illegalarg = "java.lang.IllegalArgumentException";
    nullptr    = "java.lang.NullPointerException";

    refl = load Reflect Reflect->PATH;
    if ( refl == nil )
	jni->InitError( jni->sys->sprint( "java.lang.reflect.Field: could not load %s: %r", Reflect->PATH ) );
    else
	refl->init(jni);

    #<<
}

getModifiers_I( this : ref Field_obj) : int
{#>>
    #
    #	Assume that lower part of slot points has modifier bits.
    #
    return this.slot & 16rffff;
}#<<

get_rObject_rObject( this : ref Field_obj, p0 : JObject) : JObject
{#>>
    val := getChecks(this, p0);

    typ := refl->ValType(val);

    if ( typ == 0 )	# array of Objects.  good.
	return val.Object();

    if ( typ >= JNI->T_BOOLEAN && typ <= JNI->T_LONG )
	return refl->ValueToObject(val);
    return nil;
}#<<

getBoolean_rObject_Z( this : ref Field_obj, p0 : JObject) : int
{#>>
    val := getChecks(this, p0);

    pick sw := val {
      TBoolean	=> return sw.jboolean;
    }
    jni->ThrowException(illegalarg, "Can't convert to boolean");
    return JNI->FALSE;
}#<<

getByte_rObject_B( this : ref Field_obj, p0 : JObject) : int
{#>>
    val := getChecks(this, p0);

    pick sw := val {
      TByte	=> return sw.jbyte;
    }
    jni->ThrowException(illegalarg, "Can't convert to byte");
    return JNI->FALSE;
}#<<

getChar_rObject_C( this : ref Field_obj, p0 : JObject) : int
{#>>
    val := getChecks(this, p0);
	
    pick sw := val {
      TChar	=> return sw.jchar;
    }
    jni->ThrowException(illegalarg, "Can't convert to char");
    return 0;
}#<<

getShort_rObject_S( this : ref Field_obj, p0 : JObject) : int
{#>>
    val := getChecks(this, p0);
	
    pick sw := val {
      TByte	=> return int sw.jbyte;
      TShort	=> return sw.jshort;
    }
    jni->ThrowException(illegalarg, "Can't convert to short");
    return 0;
}#<<

getInt_rObject_I( this : ref Field_obj, p0 : JObject) : int
{#>>
    val := getChecks(this, p0);
	
    pick sw := val {
      TByte	=> return int sw.jbyte;
      TChar	=> return sw.jchar;
      TShort	=> return sw.jshort;
      TInt	=> return sw.jint;
    }
    jni->ThrowException(illegalarg, "Can't convert to int");
    return 0;
}#<<

getLong_rObject_J( this : ref Field_obj, p0 : JObject) : big
{#>>
    val := getChecks(this, p0);
	
    pick sw := val {
      TByte	=> return big sw.jbyte;
      TChar	=> return big sw.jchar;
      TShort	=> return big sw.jshort;
      TInt	=> return big sw.jint;
      TLong	=> return sw.jlong;
    }
    jni->ThrowException(illegalarg, "Can't convert to long");
    return big 0;
}#<<

getFloat_rObject_F( this : ref Field_obj, p0 : JObject) : real
{#>>
    val := getChecks(this, p0);
	
    pick sw := val {
      TByte	=> return real sw.jbyte;
      TChar	=> return real sw.jchar;
      TShort	=> return real sw.jshort;
      TInt	=> return real sw.jint;
      TLong	=> return real sw.jlong;
      TFloat	=> return sw.jfloat;
    }
    jni->ThrowException(illegalarg, "Can't convert to float");
    return 0.0;
}#<<

getDouble_rObject_D( this : ref Field_obj, p0 : JObject) : real
{#>>
    val := getChecks(this, p0);
	
    pick sw := val {
      TByte	=> return real sw.jbyte;
      TChar	=> return real sw.jchar;
      TShort	=> return real sw.jshort;
      TInt	=> return real sw.jint;
      TLong	=> return real sw.jlong;
      TFloat	=> return sw.jfloat;
      TDouble	=> return sw.jdouble;
    }
    jni->ThrowException(illegalarg, "Can't convert to double");
    return 0.0;
}#<<

set_rObject_rObject_V( this : ref Field_obj, p0 : JObject,p1 : JObject)
{#>>
    want := putChecks(this, p0);
    clazz := jni->GetObjectClass(p1);
	
    if ( want == 0 ) {		# field value is Object
	p := ref Value.TObject;
	if ( jni->IsAssignable(clazz, this.clazz) == JNI->TRUE ) {
	    p.jobj = p1;
	    SetField(this, p0, p);
	    return;
	}
	else {
	    jni->ThrowException(illegalarg, "Can't safely cast");
	    return;
	}
    }
    # The field is a primitive type.  Then p1 better be a wrapper for that
    # type.  (Or is it okay if it's a wrapper for something that can be
    # safely cast to the target type?)
    #
    # is p1 a Boolean object, or sub-classed from a Boolean object,
    # or a String with value "true" or "false" ?
    #
    (typ, val) := refl->GetVal(p1);
    if ( typ == 0 || (val = refl->widen(typ, want, val)) == nil ) {
	jni->ThrowException(illegalarg, "Object can't be cast to needed type");
	return;
    }
    SetField(this, p0, val);
    return;
}#<<

setBoolean_rObject_Z_V( this : ref Field_obj, p0 : JObject,p1 : int)
{#>>
    want := putChecks(this, p0);

#
#	Note that if the field's signature is "Ljava.lang.Boolean;",
#	we could create an appropriate Object and assign it.
#	But it isn't clear if that is what's wanted.
#	A similar argument applies for the other set<Type> functions.
#
    p : ref Value;
    case want {
      JNI->T_BOOLEAN => p = ref Value.TBoolean(p1);
      * =>
	jni->ThrowException(illegalarg, "Can't convert from boolean");
	return;
    }
    SetField(this, p0, p);
}#<<

setByte_rObject_B_V( this : ref Field_obj, p0 : JObject,p1 : int)
{#>>
    want := putChecks(this, p0);

    p : ref Value;
    case want {
      JNI->T_BYTE =>	p = ref Value.TByte(p1);
      JNI->T_SHORT =>	p = ref Value.TShort(int p1);
      JNI->T_INT =>	p = ref Value.TInt(int p1);
      JNI->T_LONG =>	p = ref Value.TLong(big p1);
      JNI->T_FLOAT =>	p = ref Value.TFloat(real p1);
      JNI->T_DOUBLE =>	p = ref Value.TDouble(real p1);
      * =>
	jni->ThrowException(illegalarg, "Can't convert from byte");
	return;
    }
    SetField(this, p0, p);
}#<<

setChar_rObject_C_V( this : ref Field_obj, p0 : JObject,p1 : int)
{#>>
    want := putChecks(this, p0);

    p : ref Value;
    case want {
      JNI->T_CHAR =>	p = ref Value.TChar(p1);
      * =>
	jni->ThrowException(illegalarg, "Can't convert from char");
	return;
    }
    SetField(this, p0, p);
}#<<

setShort_rObject_S_V( this : ref Field_obj, p0 : JObject,p1 : int)
{#>>
    want := putChecks(this, p0);

    p : ref Value;
    case want {
      JNI->T_SHORT =>	p = ref Value.TShort(p1);
      JNI->T_INT =>	p = ref Value.TInt(p1);
      JNI->T_LONG =>	p = ref Value.TLong(big p1);
      JNI->T_FLOAT =>	p = ref Value.TFloat(real p1);
      JNI->T_DOUBLE =>	p = ref Value.TDouble(real p1);
      * =>
	jni->ThrowException(illegalarg, "Can't convert from short");
	return;
    }
    SetField(this, p0, p);
}#<<

setInt_rObject_I_V( this : ref Field_obj, p0 : JObject,p1 : int)
{#>>
    want := putChecks(this, p0);

    p : ref Value;
    case want {
      JNI->T_INT =>	p = ref Value.TInt(p1);
      JNI->T_LONG =>	p = ref Value.TLong(big p1);
      JNI->T_FLOAT =>	p = ref Value.TFloat(real p1);
      JNI->T_DOUBLE =>	p = ref Value.TDouble(real p1);
      * =>
	jni->ThrowException(illegalarg, "Can't convert from int");
	return;
    }
    SetField(this, p0, p);
}#<<

setLong_rObject_J_V( this : ref Field_obj, p0 : JObject,p1 : big)
{#>>
    want := putChecks(this, p0);

    p : ref Value;
    case want {
      JNI->T_LONG =>	p = ref Value.TLong(p1);
      JNI->T_FLOAT =>	p = ref Value.TFloat(real p1);
      JNI->T_DOUBLE =>	p = ref Value.TDouble(real p1);
      * =>
	jni->ThrowException(illegalarg, "Can't convert from long");
	return;
    }
    SetField(this, p0, p);
}#<<

setFloat_rObject_F_V( this : ref Field_obj, p0 : JObject,p1 : real)
{#>>
    want := putChecks(this, p0);

    p : ref Value;
    case want {
      JNI->T_FLOAT =>	p = ref Value.TFloat(p1);
      JNI->T_DOUBLE =>	p = ref Value.TDouble(p1);
      * =>
	jni->ThrowException(illegalarg, "Can't convert from float");
	return;
    }
    SetField(this, p0, p);
}#<<

setDouble_rObject_D_V( this : ref Field_obj, p0 : JObject,p1 : real)
{#>>
    want := putChecks(this, p0);

    p : ref Value;
    case want {
      JNI->T_DOUBLE =>	p = ref Value.TDouble(p1);
      * =>
	jni->ThrowException(illegalarg, "Can't convert from double");
	return;
    }
    SetField(this, p0, p);
}#<<



getChecks( this : ref Field_obj, p0 : JObject) : ref Value
{
    if ( (this.slot & jldr->ACC_STATIC) == 0 && p0 == nil )
	jni->ThrowException(nullptr, "reading field of null Object");

    # See if the target object is the same as the one declaring the field.
    # this.clazz.class_data is ref to a classloader.Class adt

    cldata := this.clazz.class;
    if ( (this.slot & jldr->ACC_STATIC) == 0 && jni->IsInstanceOf(p0, cldata) != JNI->TRUE ) {
	jni->ThrowException(illegalarg,
				"Object is not an instance of this class");
	return nil;
    }

    if ( (this.slot & jldr->ACC_PUBLIC) == 0 )
	jni->ThrowException(illegalacc, "reading non-public field");

    if ( this.slot & jldr->ACC_STATIC )
	return GetStat(cldata, this.slot);
    else
	return GetField(p0, this.slot);
}

putChecks( this : ref Field_obj, p0 : JObject) : int
{
    if ( (this.slot & jldr->ACC_STATIC) == 0 && p0 == nil )
	jni->ThrowException(nullptr, "writing field of null Object");

    # See if the target object is the same as the one declaring the field.
    # this.clazz.class_data is ref to a classloader.Class adt

    cldata := this.clazz.class;
    if ( (this.slot & jldr->ACC_STATIC) == 0 && jni->IsInstanceOf(p0, cldata) != JNI->TRUE ) {
	jni->ThrowException(illegalarg,
				"Object is not an instance of this class");
	return 0;
    }

    if ( (this.slot & jldr->ACC_PUBLIC) == 0 || (this.slot & jldr->ACC_FINAL) != 0 )
	jni->ThrowException(illegalacc, "writing non-public or final field");

    if ( this.slot & jldr->ACC_STATIC )
	return refl->SigToType(cldata.staticdata[this.slot >> 16].signature);
    else {
	flds := cldata.objectdata;
	for ( i := (this.slot >> 16); i > 0; i--)
	    flds = tl flds;
	return refl->SigToType((hd flds).signature);
    }
    return 0;
}

checkMemberAccess(which : int)
{
    return;
}

SetField(this : ref Field_obj, o : JObject, v : ref Value)
{
    cldata := this.clazz.class;
    if ( (this.slot & jldr->ACC_STATIC) != 0 ) {
	fld := cldata.staticdata[this.slot >> 16];
	jni->SetStaticField(cldata, fld.field, v);
    }
    else {
	flds := cldata.objectdata;
	for ( i := (this.slot >> 16); i > 0; i-- )
	    flds = tl flds;
	fld := hd flds;
	jni->SetObjField(o, fld.field, v);
    }
}

widen(have, want : string, val : ref Value) : ref Value
{
    if ( have == want )
	return val;
    havetype := refl->SigToType(have);
    wanttype := refl->SigToType(want);
    return refl->widen(havetype, wanttype, val);
}
#
#	Eventually JNI may provide a funtions to do this more directly.
#
GetStat(cldata : ClassData, slot : int) : ref Value
{
    fld := cldata.staticdata[slot >> 16];
    return jni->GetStaticField(cldata, fld.field, fld.signature);
}
#
#	Eventually JNI may provide a funtions to do this more directly.
#	It would probably know what to do about privatemethods, if anything.
#
GetField(obj : JObject, slot : int) : ref Value
{
    flds := obj.class().objectdata;
    for ( i := (slot >> 16); i > 0; i-- )
	flds = tl flds;
    fld := hd flds;
    return jni->GetObjField(obj, fld.field, fld.signature);
}


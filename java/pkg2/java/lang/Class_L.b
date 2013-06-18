implement Class_L;

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

    jldr : JavaClassLoader;
    cast : Cast;

#<<

include "Class_L.m";

#>> extra post includes here

    ClassData,
    Value : import jni;

include "reflect/reflect.m";
    refl : Reflect;

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    jldr = jni->jldr;
    cast = jni->CastMod();
    #<<
}

forName_rString_rClass( p0 : JString) : JClass
{#>>
	e := ref Sys->Exception;
	if (jni->sys->rescue("JLD:e0*", e) == Sys->HANDLER) 
	{
		if ( p0.str != nil && p0.str[0] == '[' )
			return( jni->LookupArrayClass(p0.str) );
		else
			return( jni->GetClassObject( jni->FindClass(p0.str) ) );
	}

	jni->sys->rescued(Sys->ONCE, nil);
	# turn into a ClassNotFoundException
	jni->ThrowException( "java.lang.ClassNotFoundException", p0.str );
	return(nil);
}#<<

newInstance_rObject( this : JClass) : JObject
{#>>
	if ( this.class.flags & (JNI->ACC_INTERFACE | JNI->ACC_ABSTRACT) ) {
		s : string;
		if ( isPrimitive_Z(this) == JNI->TRUE )
			s = this.class.name[len "inferno/vm/":len this.class.name - 2];
		else if ( this.aryname != nil )
			s = this.aryname;
		else
			s = this.class.name;
		jni->ThrowException( "java.lang.InstantiationException", s );
	}
	# create new object for the given class
	return( jni->NewObject(this.class) );
}#<<

isInstance_rObject_Z( this : JClass, p0 : JObject) : int
{#>>
	return( jni->IsInstanceOf( p0, this.class ) );
}#<<

isAssignableFrom_rClass_Z( this : JClass, p0 : JClass) : int
{#>>
	return( jni->IsAssignable( p0, this ) );
}#<<

isInterface_Z( this : JClass) : int
{#>>
	return( this.class.flags & JNI->ACC_INTERFACE );
}#<<

isArray_Z( this : JClass) : int
{#>>
	return( this.class.name == "inferno/vm/Array" );
}#<<

isPrimitive_Z( this : JClass) : int
{#>>
	ret : int;
	if ( jni->PrimitiveIndex(this, 0) > 0 )
		ret = JNI->TRUE;
	else
		ret = JNI->FALSE;
	return ret;
}#<<

getName_rString( this : JClass) : JString
{#>>
	name : string;
	if ( isPrimitive_Z(this) == JNI->TRUE )
	{
		# mk primitive name from a slice
		name = this.class.name[len "inferno/vm/":len this.class.name - 2];
	}
	else
	{
		if ( this.aryname != nil )
		{
			name = this.aryname;
		}
		else
		{
			name = this.class.name;
		}
		# change slashes to dots
		for ( i := 0; i < len name; i++ )
			if ( name[i] == '/' )
				name[i] = '.';
	}
	return( jni->NewString( name ) );
}#<<

getClassLoader_rClassLoader( this : JClass) : JObject
{#>>
	junk := (this);
	jni->FatalError( "getClassLoader() not implemented" );
	return(nil);
}#<<

getSuperclass_rClass( this : JClass) : JClass
{#>>
	if ( isPrimitive_Z(this) == JNI->TRUE
	|| this.class.flags & JNI->ACC_INTERFACE )
		return nil;
	if ( (superclass := jni->GetSuperclass(this.class)) == nil )
		return nil;
	return( jni->GetClassObject( superclass ) );
}#<<

getInterfaces_aClass( this : JClass) : JArrayJClass
{#>>
	n : int;
	# kludge for arrays to be consistent with JavaSoft's VM
	if ( isArray_Z(this) )
		n = 0;
	else
		n = len this.class.interdirect;
	interface := array [n] of JObject;
	il := this.class.interdirect;
	for (i := n-1; i >= 0; i--) {
		interface[i] = cast->FromJClass(jni->GetClassObject(hd il));
 		il = tl il;
	}
	classarray := cast->JArrayToClass(cast->ObjectToJArray(jni->MkAObject(interface)));
	classarray.class = jni->FindClass("java/lang/Class");
	return classarray;
}#<<

getComponentType_rClass(this : JClass) : JClass
{#>>
	if(this == nil || this.aryname == nil)
		return nil;

	name : string;
	c := this.aryname[1];
	if(c == '[') {
		return jni->LookupArrayClass(this.aryname[1:]);
	} else {
		if(c == 'L') {
			name = this.aryname[2:len this.aryname - 1];
		} else {
			getReflect();
			name = "inferno/vm/" + refl->TypeCharToName(c) + "_p";
		}
		return jni->GetClassObject(jni->FindClass(name));
	}
}#<<

getModifiers_I( this : JClass) : int
{#>>
	return( this.class.flags & (~ JNI->ACC_SYNCHRONIZED));
}#<<

getSigners_aObject( this : JClass) : JArrayJObject
{#>>
	junk := (this);
	jni->FatalError( "getSigners() not implemented" );
	return(nil);
}#<<

setSigners_aObject_V( this : JClass, p0 : JArrayJObject)
{#>>
	junk := (this,p0);
	jni->FatalError( "setSigners() not implemented" );
}#<<

getPrimitiveClass_rString_rClass( p0 : JString) : JClass
{#>>
	e := ref Sys->Exception;
	if (jni->sys->rescue("JLD:e0*", e) == Sys->HANDLER)
	{
		return( jni->GetClassObject(jni->FindClass("inferno/vm/"+ p0.str +"_p")) );
	}
	return(nil);
}#<<

getFields0_I_aField( this : JClass, p0 : int) : JArrayJObject
{#>>
#   'this' represents the class whose fields are wanted.
#   p0 == 0 for PUBLIC members (includes inherited members)
#   p0 == 1 for DECLARED members (All members but not inherited members)

    objs : list of JObject;
    if ( !isArray_Z(this) )
	objs = getFields(this, p0);

    obj_array := array[len objs] of JObject;
    for ( i := 0; objs != nil ; i++ ) {
	obj_array[i] = hd objs;
	objs = tl objs;
    }

    fieldarray := jni->MkAObject(obj_array);
    fieldarray.class = jni->FindClass("java/lang/reflect/Field");
    return fieldarray;
}#<<

getMethods0_I_aMethod( this : JClass, p0 : int) : JArrayJObject
{#>>
#   'this' represents the class whose methods are wanted.
#   p0 == 0 for PUBLIC members (includes inherited members)
#   p0 == 1 for DECLARED members (All members but not inherited members)

    objs : list of JObject;

    # if primitive or interface, filter out java.lang.Object methods
    if ( isPrimitive_Z(this) == JNI->TRUE
    || this.class.flags & JNI->ACC_INTERFACE )
	p0 = 1;
    objs = getMethods(this, p0);

    obj_array := array[len objs] of JObject;
    for ( i := 0; objs != nil ; i++ ) {
	obj_array[i] = hd objs;
	objs = tl objs;
    }

    methodarray := jni->MkAObject(obj_array);
    methodarray.class = jni->FindClass("java/lang/reflect/Method");
    return methodarray;
}#<<

getConstructors0_I_aConstructor( this : JClass, p0 : int) : JArrayJObject
{#>>
#   'this' represents the class whose constructors are wanted.
#   p0 == 0 for PUBLIC members (includes inherited members)
#   p0 == 1 for DECLARED members (All members but not inherited members)

    objs : list of JObject;
    if ( isPrimitive_Z(this) == JNI->FALSE && !isArray_Z(this) )
	objs = getConstructors(this, p0);

    obj_array := array[len objs] of JObject;
    for ( i := 0; objs != nil ; i++ ) {
	obj_array[i] = hd objs;
	objs = tl objs;
    }

    constructorarray := jni->MkAObject(obj_array);
    constructorarray.class = jni->FindClass("java/lang/reflect/Constructor");
    return constructorarray;
}#<<

getField0_rString_I_rField( this : JClass, p0 : JString,p1 : int) : JObject
{#>>
#   'this' represents the class for which a Field is desired.
#   p0 is the name of the field.
#   p1 == 0 for PUBLIC members (includes inherited members)
#   p1 == 1 for DECLARED members (All members but not inherited members)

	staticfields := this.class.staticdata;
	flg : int;
	fld : ref jldr->Field;
	for ( i := 0; i < len staticfields; i++ ) {
	    fld = staticfields[i];
	    flg = fld.flags;
	    if ( fld.field == p0.str &&
				(p1 != 0 || (flg & JNI->ACC_PUBLIC) != 0) )
		break;
	}
	if ( i >= len staticfields ) {	# Not a public static field
	    super : list of ref jldr->Field = nil;
	    if ( (superclass := jni->GetSuperclass(this.class)) != nil &&
						superclass != this.class )
		super = superclass.objectdata;
	    objfields := this.class.objectdata;
	    for ( i = 0; objfields != nil; i++ ) {
		if ( p1 == 1 && objfields == super )	# exclude inherited
		    break;
		fld = hd objfields;
		flg = fld.flags;
		if ( fld.field == p0.str && 
				(p1 != 0 || (flg & JNI->ACC_PUBLIC) != 0) )
		    break;
		objfields = tl objfields;
	    }
	    if ( objfields == super || objfields == nil )
		i = len staticfields + len this.class.objectdata;
	}
	if ( i >= len staticfields + len this.class.objectdata ) {
	    jni->ThrowException("java/lang/NoSuchFieldException", "");
	    return nil;
	}
	return makeField(this, fld, i);
}#<<

getMethod0_rString_aClass_I_rMethod( this : JClass, p0 : JString,p1 : JArrayJClass,p2 : int) : JObject
{#>>
#   'this' represents the class for which a Method is desired.
#   p0 is the name of the method.
#   p1 is a Java array of Class objects, corresponding to the formal parameters
#	of the method for which a Method object is desired.  The array
#	is used to construct a signature string which can be matched against
#	data compiled by the classloader.
#   p2 == 0 for PUBLIC members (includes inherited members)
#   p2 == 1 for DECLARED members (All members but not inherited members)

    signatur := "(" + MakeSignature(p1) + ")";

    methods := this.class.staticmethods;
    for ( i := 0; i < len methods; i++ ) {
	fld := methods[i];
	if ( fld.field == p0.str && jni->str->prefix(signatur, fld.signature) &&
			(p2 != 0 || (fld.flags & JNI->ACC_PUBLIC) != 0) )
	    return makeMethod(this, fld, i, p1, fld.signature[len signatur:]);
    }
    methods = this.class.privatemethods;
    for ( i = 0; i < len methods; i++ ) {
	fld := methods[i];
	if ( fld.field == p0.str && jni->str->prefix(signatur, fld.signature) &&
			(p2 != 0 || (fld.flags & JNI->ACC_PUBLIC) != 0) )
	    return makeMethod(this, fld, i, p1, fld.signature[len signatur:]);
    }
    vmethods := this.class.virtualmethods;
    for ( i = 0; i < len vmethods; i++ ) {
	fld := vmethods[i].field;
	if ( fld.field == p0.str && jni->str->prefix(signatur, fld.signature) &&
			((p2 != 0 && this.class == vmethods[i].class)
			|| (fld.flags & JNI->ACC_PUBLIC) != 0) ) {
	    if ( vmethods[i].class != this.class )
		this = jni->GetClassObject(vmethods[i].class);
	    return makeMethod(this, fld, i, p1, fld.signature[len signatur:]);
	}
    }
    jni->ThrowException("java/lang/NoSuchMethodException", "");
    return nil;
}#<<

getConstructor0_aClass_I_rConstructor( this : JClass, p0 : JArrayJClass,p1 : int) : JObject
{#>>
#   'this' represents the class for which a Constructor is desired.
#   p0 is a Java array of Class objects, corresponding to the formal parameters
#	of the constructor for which a Constructor object is desired.  The array
#	is used to construct a signature string which can be matched against
#	data compiled by the classloader.
#   p1 == 0 for PUBLIC members (includes inherited members)
#   p1 == 1 for DECLARED members (All members but not inherited members)

	signatur := "(" + MakeSignature(p0) + ")";

	initmethods := this.class.initmethods;
	flg : int;
	fld : ref jldr->Field;
	for ( i := 0; i < len initmethods; i++ ) {
	    fld = initmethods[i];
	    flg = fld.flags;
	    if ( jni->str->prefix(signatur, fld.signature) &&
				(p1 != 0 || (flg & JNI->ACC_PUBLIC) != 0) )
		break;
	}
	if ( i >= len initmethods ) {
	    jni->ThrowException("java/lang/NoSuchMethodException", "");
	    return nil;
	}
	return makeMethod(this, fld, i, p0, nil);
}#<<

#
#  getPublicStaticFields() and doInterfaces() are helper
#  functions for getFields().
#

#
#  Return list of public static fields of this class.
#

getPublicStaticFields(this : JClass, objs : list of JObject) : list of JObject
{
	flds := this.class.staticdata;
	for ( i := len flds - 1; i >= 0; i-- )
		if ( (flds[i].flags & JNI->ACC_PUBLIC) != 0 )
			objs = makeField(this, flds[i], i) :: objs;
	return objs;
}

#
#  Recursively (for superinterfaces) call getPublicStaticFields()
#  on interfaces of this class.
#

ifacelist: list of JClass;

doInterfaces(this : JClass, objs : list of JObject) : list of JObject
{
	ifaces := this.class.interfaces;
outer:	for ( i := 0; i < len ifaces; i++ ) {
		iface := jni->GetClassObject(ifaces[i].class);
		for ( l := ifacelist; l != nil; l = tl l )
			if ( hd l == iface )
				continue outer;
		ifacelist = iface :: ifacelist;
		objs = getPublicStaticFields(iface, objs);
		objs = doInterfaces(iface, objs);
	}
	return objs;
}

#
#	A helper function that gets fields for the class represented
#	by this.  p0 == 0 => PUBLIC fields, p0 == 1 => DECLARED fields.
#	Candidate fields are found in the loader array staticdata (for
#	static fields) and list objectdata (for instance fields).
#

getFields(this : JClass, p0 : int) : list of JObject
{
    objs : list of JObject;

    # get instance fields
    objdata := this.class.objectdata;
    flds := array[len objdata] of ref jldr->Field;
    super : list of ref jldr->Field = nil;
    if ( (superclass := jni->GetSuperclass(this.class)) != nil )
	super = superclass.objectdata;
    for ( i := 0; objdata != nil; i++ ) {
	if ( p0 == 1 && objdata == super )
	    break;
	flds[i] = hd objdata;
	objdata = tl objdata;
    }
    # need to associate declaring class with each instance field ???
    for ( i--; i >= 0; i-- )
	if ( p0 != 0 || (flds[i].flags & JNI->ACC_PUBLIC) != 0 )
	    objs = makeField(this, flds[i], i) :: objs;

    # get class fields of this class
    flds = this.class.staticdata;
    for ( i = len flds - 1; i >= 0; i-- )
	if ( p0 != 0 || (flds[i].flags & JNI->ACC_PUBLIC) != 0 )
	    objs = makeField(this, flds[i], i) :: objs;

    # get class fields of super classes and interfaces
    if ( p0 == 0 ) {
	ifacelist = nil;
	objs = doInterfaces(this, objs);
	curclass := this;
	while ( ( curclass = getSuperclass_rClass(curclass) ) != nil ) {
	    objs = getPublicStaticFields(curclass, objs);
	    objs = doInterfaces(curclass, objs);
	}
    }

    return objs;
}
#
#	A helper function that gets methods for the class represented
#	by this.  p0 == 0 => PUBLIC methods, p0 == 1 => DECLARED methods.
#	Candidate methods are found in the loader arrays staticmethods (for
#	class methods), privatemethods (for methods private to this
#	particular class), and virtualmethods (public instance methods of
#	this class and all its superclasses).
#
getMethods(this : JClass, p0 : int) : list of JObject
{
    objs : list of JObject;

    getReflect();

    flds := this.class.staticmethods;
    for ( i := 0; i < len flds; i++ )
	if ( p0 != 0 || (flds[i].flags & JNI->ACC_PUBLIC) != 0 )
	    objs = makeAMethod(this, flds[i], i) :: objs;

    if ( p0 != 0 ) {
	flds = this.class.privatemethods;
	for ( i = len flds - 1; i >= 0; i-- )
	    objs = makeAMethod(this, flds[i], i) :: objs;
    }

    vflds := this.class.virtualmethods;
    for ( i = len vflds - 1; i >= 0; i-- )
	if ( (p0 == 1 && vflds[i].class == this.class)	# declared, this class
	|| ( p0 == 0 && (vflds[i].field.flags & JNI->ACC_PUBLIC) != 0 ) ) {
	    if ( vflds[i].class != this.class )
		this = jni->GetClassObject(vflds[i].class);
	    objs = makeAMethod(this, vflds[i].field, i) :: objs;
	}

    return objs;
}
#
#	A helper function that gets constructors for the class represented
#	by this.  p0 == 0 => PUBLIC constructors, p0 == 1 => DECLARED
#	constructors.  Candidate constructors are found in the loader
#	array initmethods.
#
getConstructors(this : JClass, p0 : int) : list of JObject
{
    objs : list of JObject;

    getReflect();

    flds := this.class.initmethods;
    for ( i := len flds - 1; i >= 0; i-- )
	if ( p0 != 0 || (flds[i].flags & JNI->ACC_PUBLIC) != 0 )
	    objs = makeAMethod(this, flds[i], i) :: objs;

    return objs;
}
#
#	Make sure Reflect module is loaded.
#
getReflect()
{
    if ( refl == nil ) {
	refl = load Reflect Reflect->PATH;
	if ( refl == nil )
	    jni->InitError( jni->sys->sprint( "java.lang.Class: could not load %s: %r", Reflect->PATH ) );
	else
	    refl->init(jni);
    }
}
#
#	Construct a Field Object.  The field is a member of the class
#	represented by this, and the loader data for the field is in fld,
#	which is at offset ix in the appropriate array or list.  The 'slot'
#	elements of a Field_obj adt is used only by native methods, and has
#	the fields modifier flags in the low-order 16 bits, and the index
#	into the array/list in the upper 16 bits.  (The index into what
#	depends on the modifier flags.)
#
makeField(this : JClass, fld : ref jldr->Field, ix : int) : JObject
{
    getReflect();
    fldobj := jni->AllocObject(jni->FindClass("java/lang/reflect/Field"));

    clazz := ref Value.TObject(cast->FromJClass(this));
    jni->SetObjField(fldobj, "clazz", clazz);

    name := ref Value.TObject(cast->FromJString(jni->NewString(fld.field)));
    jni->SetObjField(fldobj, "name", name);

    class : ref Value;
    if ( (typ := refl->SigToType(fld.signature)) > 0 )
	class = refl->GetPrimitiveClass(typ);
    else {
	classname := fld.signature[1:len fld.signature - 1];
	class = ref Value.TObject(cast->FromJClass(
			jni->GetClassObject(jni->FindClass(classname))));
    }
    jni->SetObjField(fldobj, "type", class);

    slot := ref Value.TInt((fld.flags & 16rffff) | (ix << 16));
    jni->SetObjField(fldobj, "slot", slot);

    return fldobj;
}
#
#	Make a new Method/Constructor object for a method or constructor in
#	the class this.  The loader information for the method/constructor is
#	found in the loader Field adt fld, which is at offset ix in its
#	array or list.  The signature for the arguments is converted into
#	a corresponding array of Class objects by makeParamClassArray, then
#	makeMethod is called to generate the new object.
#
makeAMethod(this: JClass, fld : ref jldr->Field, ix : int) : JObject
{
    (sig, retsig) := jni->str->splitr(fld.signature, ")");
    objectarray := makeParamClassArray(sig);

    classarray := cast->JArrayToClass(cast->ObjectToJArray(objectarray));
    return makeMethod(this, fld, ix, classarray, retsig);
}
#
#	Construct a Method Object.  Also used to make Constructor Objects,
#	share several elements with Methods.  The two can be distinguished
#	because constructors have the name "<init>" (however, Constructor
#	Objects do not have a 'name' field, nor do they have a 'returnType'
#	field.  The 'slot' field, which is only used by native methods,
#	is filled with modifier flags in the lower 16 bits and an index (ix)
#	into an appropriate loader array/list in the upper 16 bits (which
#	array can be determined by the modifier flags. ).  The arguments
#	types required by the method are specified by the cl array of
#	Class ofjects.  The return value, if any, is specified by the
#	signature given in retsig.
#
makeMethod(this: JClass, fld : ref jldr->Field, ix : int, cl : JArrayJClass,
					retsig : string) : JObject
{
    mcl : ClassData;
    isConstructor := 0;
    if ( fld.field == "<init>" )
	isConstructor = 1;
    if ( isConstructor )
	mcl = jni->FindClass("java/lang/reflect/Constructor");
    else
	mcl = jni->FindClass("java/lang/reflect/Method");
    methobj := jni->AllocObject(mcl);

    clazz := ref Value.TObject(cast->FromJClass(this));
    jni->SetObjField(methobj, "clazz", clazz);

    if ( ! isConstructor ) {
	name := ref Value.TObject(cast->FromJString(jni->NewString(fld.field)));
	jni->SetObjField(methobj, "name", name);
    }

    slot := ref Value.TInt((fld.flags & 16rffff) | (ix << 16));
    jni->SetObjField(methobj, "slot", slot);

    if ( ! isConstructor ) {
	getReflect();
	ret : ref Value;
	if ( (typ := refl->SigToType(retsig)) > 0 )
	    ret = refl->GetPrimitiveClass(typ);
	else {
	    rclass: JClass;
	    case retsig[0] {
	      'L' =>
		rcdata := jni->FindClass(retsig[1:len retsig -1]);
		rclass = jni->GetClassObject(rcdata);
	      '[' =>
    		rclass = jni->LookupArrayClass(retsig);
	      'V' =>
		rcdata := jni->FindClass("inferno/vm/void_p");
		rclass = jni->GetClassObject(rcdata);
	    }
	    ret = ref Value.TObject(cast->FromJClass(rclass));
	}
	jni->SetObjField(methobj, "returnType", ret);
    }

    args := ref Value.TObject(cast->FromJArray(cast->ClassToJArray(cl)));
    jni->SetObjField(methobj, "parameterTypes", args);

    #	Don't know how to get the list of exceptions thrown.
    # jni->SetObjField(methobj, "exceptionTypes", excs);
    # Set to a sensible default for now.
    foo := cast->JArrayToClass(cast->ObjectToJArray(makeParamClassArray("()")));
    excs := ref Value.TObject(cast->FromJArray(cast->ClassToJArray(foo)));
    jni->SetObjField(methobj, "exceptionTypes", excs);
    return methobj;
}
#
#	Turn a signature into an array of Class Objects.
#
makeParamClassArray(sig : string) : JArrayJObject
{
    if ( sig[0] != '(' || sig[len sig -1] != ')' )
	return nil;
    clist := makeParamClass(sig[1:len sig -1]);
    jajcl := array[len clist] of JObject;
    for ( i := 0; i < len jajcl; i++ ) {
	jajcl[i] = hd clist;
	clist = tl clist;
    }
    paramclassarray := jni->MkAObject(jajcl);
    paramclassarray.class = jni->FindClass("java/lang/Class");
    return paramclassarray;
}
#
#	Recursively turn a signature into a list of JClass
#
makeParamClass(sig : string) : list of JObject
{
    if ( sig == "" )
	return nil;

    (first, rest) := splitSignature(sig);
    jobj: JObject;
    case first[0] {
      'L' =>
	first = first[1:len first - 1];
    	newcl := jni->GetClassObject(jni->FindClass(first));
    	jobj = cast->FromJClass(newcl);
      '[' =>
    	newcl := jni->LookupArrayClass(first);
    	jobj = cast->FromJClass(newcl);
      'Z' or 'B' or 'S' or 'C' or 'I' or 'J' or 'F' or 'D' =>
	typ := refl->SigToType(first);
	jobj = refl->GetPrimitiveClass(typ).Object();
      * =>
	return nil;
    }

    return jobj :: makeParamClass(rest);
}
#
#	Convert an array of JClass to the corresponding signature string.
#
MakeSignature(jcl : JArrayJClass) : string
{
    clarray: array of JClass;
    if ( jcl != nil )
	clarray = jcl.ary;
    sig := "";
    for ( i := 0; i < len clarray; i++)
	sig += MakeSingleSignature(clarray[i]);
    return sig;
}
#
#	Convert a Jclass to the corresponding signature.
#
MakeSingleSignature(this : JClass) : string
{
    if ( (typ := jni->PrimitiveIndex(this, 1)) > 0 ) {
	getReflect();
	return refl->TypeToSig(typ);
    }

    if ( this.aryname != nil )
	return this.aryname;

    #
    #	Must be a class type
    #
    return "L" + this.class.name + ";";
}
#
#	Break a signature into an initial type plus the remainder.
#
splitSignature(sig : string) : (string, string)
{
    case sig[0] {
      'L' =>
	for ( i := 1; sig[i] != ';'; i++ ) ;
	i++;
	return (sig[0:i], sig[i:]);

      '[' =>		# recurse to get element type
	(first, rest) := splitSignature(sig[1:]);
	return ("[" + first, rest);

      'Z' or 'B' or 'S' or 'C' or 'I' or 'J' or 'F' or 'D' =>
	return (sig[0:1], sig[1:]);
    }
    return (nil, nil);
}


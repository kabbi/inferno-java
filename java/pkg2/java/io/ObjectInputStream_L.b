implement ObjectInputStream_L;

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
    sys : import jni;
    str : import jni;
    FALSE : import jni;
    TRUE : import jni;
#<<

include "ObjectInputStream_L.m";

#>> extra post includes here
include "workdir.m";
include "regex.m";
str_mod : String;
ClassData, Value : import jni;
cast : Cast;
low : Low;
#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    sys = jni->sys;
    str_mod = jni->str;
    cast = jni->CastMod();
    low = jni->LowMod();
    #<<
}

loadClass0_rClass_rString_rClass( this : ref ObjectInputStream_obj, p0 : JClass,p1 : JString) : JClass
{#>>
	TRACE_1 := (this, p0);
	if(p1.str[0] == '[')
		return jni->LookupArrayClass(p1.str);
	else
		return jni->GetClassObject( jni->FindClass(p1.str) );
}#<<

inputClassFields_rObject_rClass_aI_V( this : JObject, p0 : JObject,p1 : JClass,p2 : JArrayI)
{#>>
	#p0 the object being inputted
	#p1 class being referred to
	#p2 fieldSequence array

	ok : int;
	val : ref Value;
	#
	# get all fields except the transient and static
	#
	fields_n_sigs := jni->GetFieldSignatures(p1, (JNI->ACC_STATIC|JNI->ACC_TRANSIENT));
	#
	# for each field, parse out the field name and signature. Then based on the
	# signature, call the appropriate read routine.
	#
	for (i:=0; i < len p2.ary; i += 2) {
		fldindex := p2.ary[i+1];

		(str_part, tmp_str) := str_mod->splitl((fields_n_sigs.ary[fldindex]).str, " ");
		sig_part := tmp_str[1];
		#
		# call the appropriate read routine to get the value of this field
		#
		case sig_part {
		# SIGNATURE_BYTE
		'B' =>
			(val, ok) = jni->CallMethod(this, "readByte", "()B", nil);
		# SIGNATURE_CHAR
		'C' =>
			(val, ok) = jni->CallMethod(this, "readChar", "()C", nil);
		# SIGNATURE_FLOAT
		'F' =>
			(val, ok) = jni->CallMethod(this, "readFloat", "()F", nil);
		# SIGNATURE_DOUBLE
		'D' =>
			(val, ok) = jni->CallMethod(this, "readDouble", "()D", nil);
		# SIGNATURE_INT
		'I' =>
			(val, ok) = jni->CallMethod(this, "readInt", "()I", nil);
		# SIGNATURE_LONG
		'J' =>
			(val, ok) = jni->CallMethod(this, "readLong", "()J", nil);
		# SIGNATURE_SHORT
		'S' =>
			(val, ok) = jni->CallMethod(this, "readShort", "()S", nil);
		# SIGNATURE_BOOLEAN
		'Z' =>
			(val, ok) = jni->CallMethod(this, "readBoolean", "()Z", nil);
		# SIGNATURE_ARRAY
		'[' =>
			(val, ok) = jni->CallMethod(this, "readObject", "()Ljava/lang/Object;", nil);
		# SIGNATURE_CLASS
		'L' =>
			(val, ok) = jni->CallMethod(this, "readObject", "()Ljava/lang/Object;", nil);
		}
		#
		# now take that just readin value and store into the object.
		#
		if (ok == JNI->OK)
			jni->SetObjField(p0, str_part, val);
        }
}#<<

inputArrayValues_rObject_rClass_V( this : JObject, p0 : JObject,p1 : JClass)
{#>>
	# p0 is an array of Objects. We have to look at the signature
	# of the array to find what the Objects really are.
	#
	# p1 the class name of the elements of the array (this is also
	# the arrays signature)
	#
	# make sure this is an array we have. If so, get its length.
	#
	if ( jni->IsArray(p0) == JNI->FALSE) {
		jni->ThrowException("java.io.InvalidClassException", "Not an array");
	}
	length := jni->GetArrayLength(cast->ToJArray(p0));
	ok : int;
	val : ref Value;

	#
	# dispatch on the signature of the array and read in each element.
	#
	i : int;
	case p1.aryname[1] {
	# SIGNATURE_BYTE
	'B' =>
	{
		mul_args := array[3] of ref Value;
		mul_args[0] = ref Value.TObject(p0);
		mul_args[1] = ref Value.TInt(0);
		mul_args[2] = ref Value.TInt(length);
		(val, ok) = jni->CallMethod(this, "readFully", "([BII)V", mul_args);
	}
	# SIGNATURE_CHAR
	'C' =>
	{
		JAChar := cast->ToJArrayI(p0);
		for (i = 0; i < length; i++) {
			(val, ok) = jni->CallMethod(this, "readChar", "()C", nil);
			JAChar.ary[i] = val.Char();
		}
	}
	# SIGNATURE_FLOAT
	'F' =>
	{
		JAFloat := cast->ToJArrayF(p0);
		for (i = 0; i < length; i++) {
			(val, ok) = jni->CallMethod(this, "readFloat", "()F", nil);
			JAFloat.ary[i] = val.Float();
		}
	}
	# SIGNATURE_DOUBLE
	'D' =>
	{
		JADouble := cast->ToJArrayD(p0);
		for (i = 0; i < length; i++) {
			(val, ok) = jni->CallMethod(this, "readDouble", "()D", nil);
			JADouble.ary[i] = val.Double();
		}
	}
	# SIGNATURE_INT
	'I' =>
	{
		JAInt := cast->ToJArrayI(p0);
		for (i = 0; i < length; i++) {
			(val, ok) = jni->CallMethod(this, "readInt", "()I", nil);
			JAInt.ary[i] = val.Int();
		}
	}
	# SIGNATURE_LONG
	'J' =>
	{
		JALong := cast->ToJArrayJ(p0);
		for (i = 0; i < length; i++) {
			(val, ok) = jni->CallMethod(this, "readLong", "()J", nil);
			JALong.ary[i] = val.Long();
		}
	}
	# SIGNATURE_SHORT
	'S' =>
	{
		JAShort := cast->ToJArrayI(p0);
		for (i = 0; i < length; i++) {
			(val, ok) = jni->CallMethod(this, "readShort", "()S", nil);
			JAShort.ary[i] = val.Short();
		}
	}
	# SIGNATURE_BOOLEAN
	'Z' =>
	{
		JABool := cast->ToJArrayZ(p0);
		for (i = 0; i < length; i++) {
			(val, ok) = jni->CallMethod(this, "readBoolean", "()Z", nil);
			JABool.ary[i] = byte val.Boolean();
		}
	}
	# SIGNATURE_ARRAY
	'[' =>
	{
		JAObj := cast->ToJArrayJObject(p0);
		for (i = 0; i < length; i++) {
			(val, ok) = jni->CallMethod(this, "readObject", "()Ljava/lang/Object;", nil);
			JAObj.ary[i] = val.Object();
		}
	}
	# SIGNATURE_CLASS
	'L' =>
	{
		JAObj := cast->ToJArrayJObject(p0);
		for (i = 0; i < length; i++) {
			(val, ok) = jni->CallMethod(this, "readObject", "()Ljava/lang/Object;", nil);
			JAObj.ary[i] = val.Object();
		}
	}
	}
}#<<

#
# Does class c directly implement interface iface?
#
directImp(c: ClassData, iface: string): int
{
	l := c.interdirect;
	while(l != nil) {
		i := hd l;
		if(i.name == iface)
			return 1;
		l = tl l;
	}
	return 0;
}

#
# If c directly implements Externalizable, then call its default
# constructor (if there is one).
# Otherwise, c must directly implement Serializable.  In this case,
# find the nearest super that doesn't implement Serializable and call
# its default constructor (if there is one).
# In either case, if there is a constructor to call, then it must be public.
# If not, an IllegalAccessException is thrown.
#

callCtor(c: ClassData, o: JObject)
{
	if(directImp(c, "java/io/Externalizable") == 0) {
		if(directImp(c, "java/io/Serializable") == 0)
			return;
		c = c.super;
		while(c != nil) {
			if(directImp(c, "java/io/Serializable") == 0)
				break;
			c = c.super;
		}
	}
	if(c == nil)
		return;
	(mod, ix) := jni->FindMethod(c, "<init>", "()V", JNI->METH_INIT);
	if(mod == nil)
		return;
	flags := jni->GetMethodFlags(c.this, "<init> ()V");
	if((flags & JNI->ACC_PUBLIC) == 0)
		jni->ThrowException("java.lang.IllegalAccessException", "");
	low->CallMethod(mod, ix, o, array[0] of ref Value, nil);
}

#
# Allocate a new object of class p0.
#
allocateNewObject_rClass_rClass_rObject(p0 : JClass, p1 : JClass) : JObject
{#>>
	TRACE_1 := p1;
	o := jni->AllocObject(p0.class);
	callCtor(p0.class, o);
	return o;
}#<<

allocateNewArray_rClass_I_rObject( p0 : JClass,p1 : int) : JObject
{#>>
	#
	# p0 is the class of the array elements
	# p1 is number of elelments.
	#
	#
	# example transformation.....
	# 	jni->MkALong(array[p1] of big)            ==> JArrayJ
	# 	cast->BigToJArray(JArrayJ (aka BigArray)) ==> JArray
	# 	cast->FromJArray(JArray)                  ==> JObject
	#
	case p0.aryname[1] {
	# SIGNATURE_BYTE
	'B' =>
	{
		# limbo array ==>JArrayB ==>JArray ==>JObject
		return (cast->FromJArray(cast->ByteToJArray(jni->MkAByte(array[p1] of byte))));
	}
	# SIGNATURE_CHAR
	'C' =>
	{
		# limbo array ==>JArrayC ==>JArray ==>JObject
		return (cast->FromJArray(cast->IntToJArray(jni->MkAChar(array[p1] of int))));
	}
	# SIGNATURE_FLOAT
	'F' =>
	{
		# limbo array ==>JArrayF ==>JArray ==>JObject
		return (cast->FromJArray(cast->RealToJArray(jni->MkAFloat(array[p1] of real))));
	}
	# SIGNATURE_DOUBLE
	'D' =>
	{
		# limbo array ==>JArrayD ==>JArray ==>JObject
		return (cast->FromJArray(cast->RealToJArray(jni->MkADouble(array[p1] of real))));
	}
	# SIGNATURE_INT
	'I' =>
	{
		# limbo array ==>JArrayI ==>JArray ==>JObject
		return (cast->FromJArray(cast->IntToJArray(jni->MkAInt(array[p1] of int))));
	}
	# SIGNATURE_LONG
	'J' =>
	{
		# limbo array ==>JArrayJ ==>JArray ==>JObject
		return (cast->FromJArray(cast->BigToJArray(jni->MkALong(array[p1] of big))));
	}
	# SIGNATURE_SHORT
	'S' =>
	{
		# limbo array ==>JArrayS ==>JArray ==>JObject
		return (cast->FromJArray(cast->IntToJArray(jni->MkAShort(array[p1] of int))));
	}
	# SIGNATURE_BOOLEAN
	'Z' =>
	{
		# limbo array ==>JArrayZ ==>JArray ==>JObject
		return (cast->FromJArray(cast->ByteToJArray(jni->MkABoolean(array[p1] of byte))));
	}
	# SIGNATURE_ARRAY
	'[' =>
	{
		objarray := cast->ObjectToJArray(jni->MkAObject(array[p1] of JObject));
		desc := jni->JSigToDescriptor(p0.aryname);
		objarray.dims = desc.dims;
		objarray.class = desc.class;
		objarray.primitive = desc.prim;
		return (cast->FromJArray(objarray));
	}
	# SIGNATURE_CLASS
	'L' =>
	{
		objarray := cast->ObjectToJArray(jni->MkAObject(array[p1] of JObject));
		objarray.class = jni->FindClass(p0.aryname[2:len p0.aryname-1]);
		return (cast->FromJArray(objarray));
	}
	}
	jni->ThrowException("java.io.InvalidClassException", "Unknown signature");
	return nil;
}#<<

invokeObjectReader_rObject_rClass_Z( this : JObject, p0 : JObject,p1 : JClass) : int
{#>>
	junk := p1;
	#
	# call readObject() on object "p0" with an argument of "this"
	#
	MyValueArray := array[] of {
		ref Value.TObject(this)
	};
	(a, b) := jni->CallMethod(p0, "readObject", "(Ljava/io/ObjectInputStream;)V", MyValueArray);

	return b == JNI->OK;
}#<<

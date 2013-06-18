implement ObjectStreamClass_L;

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

include "ObjectStreamClass_L.m";

#>> extra post includes here
include "workdir.m";
include "regex.m";
str_mod : String;
Value : import jni;
cast : Cast;
#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    sys = jni->sys;
    str_mod = jni->str;
    cast = jni->CastMod();
    #<<
}

getClassAccess_rClass_I( p0 : JClass) : int
{#>>
	return (jni->GetClassFlags(p0) & JNI->ACC_WRITTEN_FLAGS);
}#<<

getMethodSignatures_rClass_aString( p0 : JClass) : JArrayJString
{#>>
	# Return an array of Strings containing the method names and signatures.
	return (jni->GetMethodSignatures(p0, 0));
}#<<

getMethodAccess_rClass_rString_I( p0 : JClass,p1 : JString) : int
{#>>
	return (jni->GetMethodFlags(p0, p1.str) & JNI->ACC_WRITTEN_FLAGS);
}#<<

getFieldSignatures_rClass_aString( p0 : JClass) : JArrayJString
{#>>
	# Return an array of Strings containing the field names and signatures.
	return (jni->GetFieldSignatures(p0, 0));
}#<<

getFieldAccess_rClass_rString_I( p0 : JClass,p1 : JString) : int
{#>>
	return (jni->GetFieldFlags(p0, p1.str) & JNI->ACC_WRITTEN_FLAGS);
}#<<

getFields0_rClass_aObjectStreamField( this : ref ObjectStreamClass_obj, p0 : JClass) : JArrayJObject
{#>>
	#
	# Return an array of ObjectStreamField objects for each non-static and
	# non-transient field of the specified class. First find and load the
	# ObjectStreamField class.
	#
	junk := this;
	cl_data := jni->FindClass("java/io/ObjectStreamField");
	if (cl_data == nil)
		jni->FatalError("ObjectStreamClass could not load java/io/ObjectStreamField");

	#
	# Get a list of all non-static and non transient fields of this class. If there are
	# non, jni->GetFieldSignatures() returns an array of length 0.
	#
	fields_n_sigs := jni->GetFieldSignatures(p0, (JNI->ACC_STATIC|JNI->ACC_TRANSIENT));

	MyValueArray := array[4] of ref Value;
	MyObjectArray := array[len fields_n_sigs.ary] of JObject;

	#
	# for each non-static and non-transient fields of this class...
	# call constructor for ObjectStreamField as follows
	#	ObjectStreamField(n, sig, o, t)
	# where n is field name, sig is first byte of field signature
	# o is index into class field table and if sig != [ or L,
	# t is NULL. If sig is [ or L, t is signature.
	# For each of those constructors that are created, stuff them into
	# an array entry.
	#
	for (i:=0; i < len fields_n_sigs.ary; i++) {
		#
		# Each entry in fields_n_sigs.ary is of the format <name> <sig> where name is
		# the name of the field and signature is its full signature. Seperate them
		# out and format a call instruction to call the constructor for ObjectStreamField.
		#
		(name, full_sig) := str_mod->splitl((fields_n_sigs.ary[i]).str, " ");
		full_sig = full_sig[1:];

		MyValueArray[0] = ref Value.TObject(cast->FromJString(jni->NewString(name)));
		MyValueArray[1] = ref Value.TChar(full_sig[0]);
		# NOT offset of field in object (but does it matter)???
		MyValueArray[2] = ref Value.TInt(i);
		if ((full_sig[0] == 'L') || (full_sig[0] == '['))
			MyValueArray[3] = ref Value.TObject(cast->FromJString(jni->NewString(full_sig)));
		else
			MyValueArray[3] = ref Value.TObject(nil);

		jObj := jni->AllocObject(cl_data);
		(ret, ok) := jni->CallMethod(jObj, "<init>", "(Ljava/lang/String;CILjava/lang/String;)V", MyValueArray);
		if (ok != JNI->OK)
			jni->FatalError("ObjectStreamClass could not create ObjectStreamField");
		#
		# make an array of these created objects.
		#
		MyObjectArray[i] = jObj;
	}
	#
	# Finally, return the full array.
	#
	jary := jni->MkAObject(MyObjectArray);
	jary.class = cl_data;
	return jary;
}#<<

getSerialVersionUID_rClass_J( p0 : JClass) : big
{#>>
	ret : big;
	val : ref Value;
	val = jni->GetStaticField(p0.class, "serialVersionUID", "J");
	if (val != nil)
		ret = val.Long();
	else
		ret = big 0;
	return ret;
}#<<

hasWriteObject_rClass_Z( p0 : JClass) : int
{#>>
	if (jni->GetMethodFlags(p0, "writeObject (Ljava/io/ObjectOutputStream;)V") != 0)
		return JNI->TRUE;
	else
		return JNI->FALSE;
}#<<

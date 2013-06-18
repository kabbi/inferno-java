implement ObjectOutputStream_L;

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

include "ObjectOutputStream_L.m";

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

outputClassFields_rObject_rClass_aI_V( this : JObject, p0 : JObject,p1 : JClass,p2 : JArrayI)
{#>>

	class := jni->GetObjectClass(p0);
	#p0 the object being outputted
	#p1 class being referred to
	#p2 fieldSequence array

	a : ref Value;
	b : int;
	#
	# get all fields except the transient and static
	#
	fields_n_sigs := jni->GetFieldSignatures(p1, (JNI->ACC_STATIC|JNI->ACC_TRANSIENT));
	#
	# for each field, parse out the field name and signature. Then based on the
	# signature, call the appropriate write routine.
	#
	for (i:=0; i < len p2.ary; i += 2) {
		fldindex := p2.ary[i+1];

		(str_part, tmp_str) := str_mod->splitl((fields_n_sigs.ary[fldindex]).str, " ");
		sig_part := tmp_str[1];
		#
		# get the value of this field and call the write routine
		#
		argv := array[] of {
			jni->GetObjField(p0, str_part, tmp_str[1:])
		};
		pick v := argv[0] {
			TByte =>
				argv[0] = ref Value.TInt(v.jbyte);
			TChar =>
				argv[0] = ref Value.TInt(v.jchar);
			TShort =>
				argv[0] = ref Value.TInt(v.jshort);
		}
		case sig_part {
			# SIGNATURE_BYTE
			'B' =>
				(a, b) = jni->CallMethod(this, "writeByte", "(I)V", argv);
			# SIGNATURE_CHAR
			'C' =>
				(a, b) = jni->CallMethod(this, "writeChar", "(I)V", argv);
			# SIGNATURE_FLOAT
			'F' =>
				(a, b) = jni->CallMethod(this, "writeFloat", "(F)V", argv);
			# SIGNATURE_DOUBLE
			'D' =>
				(a, b) = jni->CallMethod(this, "writeDouble", "(D)V", argv);
			# SIGNATURE_INT
			'I' =>
				(a, b) = jni->CallMethod(this, "writeInt", "(I)V", argv);
			# SIGNATURE_LONG
			'J' =>
				(a, b) = jni->CallMethod(this, "writeLong", "(J)V", argv);
			# SIGNATURE_SHORT
			'S' =>
				(a, b) = jni->CallMethod(this, "writeShort", "(I)V", argv);
			# SIGNATURE_BOOLEAN
			'Z' =>
				(a, b) = jni->CallMethod(this, "writeBoolean", "(Z)V", argv);
			# SIGNATURE_ARRAY
			'[' =>
				(a, b) = jni->CallMethod(this, "writeObject", "(Ljava/lang/Object;)V", argv);
			# SIGNATURE_CLASS
			'L' =>
				(a, b) = jni->CallMethod(this, "writeObject", "(Ljava/lang/Object;)V", argv);
		}
	}
}#<<

outputArrayValues_rObject_rClass_V( this : JObject, p0 : JObject,p1 : JClass)
{#>>
	# p0 the array being outputted
	# p1 the class name of the elements of the array (this is also the arrays signature)
	#
	#
	# make sure this is an array we have. If so, get the
	# length and write it out.
	#
	if ( jni->IsArray(p0) == JNI->FALSE) {
		jni->ThrowException("java.io.InvalidClassException", "Not an array");
	}
	length := jni->GetArrayLength(cast->ToJArray(p0));
	argv := array[1] of ref Value;
	argv[0] = ref Value.TInt(length);
	(a, b) := jni->CallMethod(this, "writeInt", "(I)V", argv);

	#
	# dispatch on the signature of the array and print out each element.
	#
	i : int;
	case p1.aryname[1] {
		# SIGNATURE_BYTE
		'B' =>
		{
			JAByte := cast->ToJArrayB(p0);
			for (i = 0; i < length; i++) {
				argv[0] = ref Value.TInt(int JAByte.ary[i]);
				(a, b) = jni->CallMethod(this, "writeByte", "(I)V", argv);
			}
		}
		# SIGNATURE_CHAR
		'C' =>
		{
			JAChar := cast->ToJArrayI(p0);
			for (i = 0; i < length; i++) {
				argv[0] = ref Value.TInt(JAChar.ary[i]);
				(a, b) = jni->CallMethod(this, "writeChar", "(I)V", argv);
			}
		}
		# SIGNATURE_FLOAT
		'F' =>
		{
			JAFloat := cast->ToJArrayF(p0);
			for (i = 0; i < length; i++) {
				argv[0] = ref Value.TFloat(JAFloat.ary[i]);
				(a, b) = jni->CallMethod(this, "writeFloat", "(F)V", argv);
			}
		}
		# SIGNATURE_DOUBLE
		'D' =>
		{
			JADouble := cast->ToJArrayD(p0);
			for (i = 0; i < length; i++) {
				argv[0] = ref Value.TDouble(JADouble.ary[i]);
				(a, b) = jni->CallMethod(this, "writeDouble", "(D)V", argv);
			}
		}
		# SIGNATURE_INT
		'I' =>
		{
			JAInt := cast->ToJArrayI(p0);
			for (i = 0; i < length; i++) {
				argv[0] = ref Value.TInt(JAInt.ary[i]);
				(a, b) = jni->CallMethod(this, "writeInt", "(I)V", argv);
			}
		}
		# SIGNATURE_LONG
		'J' =>
		{
			JALong := cast->ToJArrayJ(p0);
			for (i = 0; i < length; i++) {
				argv[0] = ref Value.TLong(JALong.ary[i]);
				(a, b) = jni->CallMethod(this, "writeLong", "(J)V", argv);
			}
		}
		# SIGNATURE_SHORT
		'S' =>
		{
			JAShort := cast->ToJArrayI(p0);
			for (i = 0; i < length; i++) {
				argv[0] = ref Value.TInt(JAShort.ary[i]);
				(a, b) = jni->CallMethod(this, "writeShort", "(I)V", argv);
			}
		}
		# SIGNATURE_BOOLEAN
		'Z' =>
		{
			JABool := cast->ToJArrayZ(p0);
			for (i = 0; i < length; i++) {
				argv[0] = ref Value.TBoolean(int JABool.ary[i]);
				(a, b) = jni->CallMethod(this, "writeBoolean", "(Z)V", argv);
			}
		}
		# SIGNATURE_ARRAY
		'[' =>
		{
			JAObj := cast->ToJArrayJObject(p0);
			for (i = 0; i < length; i++) {
				argv[0] = ref Value.TObject(JAObj.ary[i]);
				(a, b) = jni->CallMethod(this, "writeObject", "(Ljava/lang/Object;)V", argv);
			}
		}
		# SIGNATURE_CLASS
		'L' =>
		{
			JAObj := cast->ToJArrayJObject(p0);
			for (i = 0; i < length; i++) {
				argv[0] = ref Value.TObject(JAObj.ary[i]);
				(a, b) = jni->CallMethod(this, "writeObject", "(Ljava/lang/Object;)V", argv);
			}
		}
	}
}#<<

invokeObjectWriter_rObject_rClass_Z( this : JObject, p0 : JObject,p1 : JClass) : int
{#>>
	junk := p1;
	#
	# call writeObject() on object "p0" with an argument of "this"
	#
	MyValueArray := array[] of {
		ref Value.TObject(this)
	};
	(a, b) := jni->CallMethod(p0, "writeObject", "(Ljava/io/ObjectOutputStream;)V", MyValueArray);

	return b == JNI->OK;
}#<<

getRefHashCode_rObject_I( p0 : JObject) : int
{#>>
	return( jni->IdentityHash(p0) );
}#<<

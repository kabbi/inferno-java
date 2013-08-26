#0
	movp	32(fp),0(16(fp))
	ret
	desc  $0,0,""
	desc	$1,40,"0080"
	var	@mp,0
	module	Cast
# cast to JObject
	link	1,0,0xb8ed9861,"FromJArray"
	link	1,0,0xb8884c9a,"FromJClass"
	link	1,0,0x76cd0754,"FromJString"
# cast JArray* to JArray
	link	1,0,0x308d465a,"ByteToJArray"
	link	1,0,0x54d1047d,"IntToJArray"
	link	1,0,0x8943ab,"BigToJArray"
	link	1,0,0xf7ce22ea,"RealToJArray"
	link	1,0,0x7e0e257a,"ClassToJArray"
	link	1,0,0xf0709f5f,"StringToJArray"
	link	1,0,0x5e96bb51,"ObjectToJArray"
# cast JArray to JArray*
	link	1,0,0xdab35b9b,"JArrayToByte"
	link	1,0,0xdfce047b,"JArrayToInt"
	link	1,0,0x8b84c7a8,"JArrayToBig"
	link	1,0,0x7960d11,"JArrayToReal"
	link	1,0,0xdaebabf,"JArrayToClass"
	link	1,0,0x1102d2ef,"JArrayToString"
	link	1,0,0x14d3cbb9,"JArrayToObject"

# cast from JObject
	link	1,0,0x6d675ef6,"ToJArray"
	link	1,0,0xe0b15252,"ToJArrayB"
	link	1,0,0x32346c9,"ToJArrayC"
	link	1,0,0x32346c9,"ToJArrayS"
	link	1,0,0x32346c9,"ToJArrayI"
	link	1,0,0xdea604f9,"ToJArrayJ"
	link	1,0,0x5cde7840,"ToJArrayF"
	link	1,0,0x5cde7840,"ToJArrayD"
	link	1,0,0xe0b15252,"ToJArrayZ"
	link	1,0,0xe6e32a84,"ToJArrayJString"
	link	1,0,0x4cbbe2c3,"ToJArrayJObject"
	link	1,0,0x424af2d7,"ToJClass"
	link	1,0,0x4fd3acd0,"ToJString"

# cast thread data
	link	1,0,0x52e73674,"JObjToJThd"
	link	1,0,0x7e48ea3a,"JThdToJObj"

# misc cast
	link	1,0,0x2b7b0708,"Class2Niladt"
	link	1,0,0x2e1c372c,"Obj2Niladt"
	link	1,0,0xa5cc9a8d,"JNI2Nilmod"
	link	1,0,0xe04c9ec8,"JArrayToHolder"


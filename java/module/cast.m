#
# cast.m
#
# cast from JNI types to generic JNI types
#
Cast : module
{
	PATH : con "/dis/java/cast.dis";

	# cast to JObject
	FromJArray       : fn( ary : JNI->JArray )  : (JNI->JObject);
	FromJClass       : fn( cl  : JNI->JClass )  : (JNI->JObject);
	FromJString      : fn( str : JNI->JString ) : (JNI->JObject);

	# cast JArray* to JArray
	ByteToJArray   : fn( ptr : ref JNI->ByteArray )   : (JNI->JArray);
	IntToJArray    : fn( ptr : ref JNI->IntArray )    : (JNI->JArray);
	BigToJArray    : fn( ptr : ref JNI->BigArray )    : (JNI->JArray);
	RealToJArray   : fn( ptr : ref JNI->RealArray )   : (JNI->JArray);
	ClassToJArray  : fn( ptr : ref JNI->ClassArray )  : (JNI->JArray);
	StringToJArray : fn( ptr : ref JNI->StringArray ) : (JNI->JArray);
	ObjectToJArray : fn( ptr : ref JNI->ObjectArray ) : (JNI->JArray);

	# cast JArray to JArray*
	JArrayToByte   : fn( ptr : JNI->JArray ) : ref JNI->ByteArray;
	JArrayToInt    : fn( ptr : JNI->JArray ) : ref JNI->IntArray;
	JArrayToBig    : fn( ptr : JNI->JArray ) : ref JNI->BigArray;
	JArrayToReal   : fn( ptr : JNI->JArray ) : ref JNI->RealArray;
	JArrayToClass  : fn( ptr : JNI->JArray ) : ref JNI->ClassArray;
	JArrayToString : fn( ptr : JNI->JArray ) : ref JNI->StringArray;
	JArrayToObject : fn( ptr : JNI->JArray ) : ref JNI->ObjectArray;

	# cast from JObjects
	ToJClass         : fn( obj : JNI->JObject ) : (JNI->JClass);
	ToJString        : fn( obj : JNI->JObject ) : (JNI->JString);
	ToJArray         : fn( obj : JNI->JObject ) : (JNI->JArray);
	ToJArrayB        : fn( obj : JNI->JObject ) : (JNI->JArrayB);
	ToJArrayC        : fn( obj : JNI->JObject ) : (JNI->JArrayC);
	ToJArrayS        : fn( obj : JNI->JObject ) : (JNI->JArrayS);
	ToJArrayI        : fn( obj : JNI->JObject ) : (JNI->JArrayI);
	ToJArrayJ        : fn( obj : JNI->JObject ) : (JNI->JArrayJ);
	ToJArrayF        : fn( obj : JNI->JObject ) : (JNI->JArrayF);
	ToJArrayD        : fn( obj : JNI->JObject ) : (JNI->JArrayD);
	ToJArrayZ        : fn( obj : JNI->JObject ) : (JNI->JArrayZ);
	ToJArrayJObject  : fn( obj : JNI->JObject ) : (JNI->JArrayJObject);
	ToJArrayJString  : fn( obj : JNI->JObject ) : (JNI->JArrayJString);

	# cast for thread data
	JObjToJThd       : fn( obj  : JNI->JObject ) : (JNI->JThread);
	JThdToJObj       : fn( jthd : JNI->JThread ) : (JNI->JObject);

	# cast to a niladt
	Class2Niladt     : fn( cl : JNI->ClassData ) : ref Loader->Niladt;
	Obj2Niladt       : fn( cl : JNI->JObject   ) : ref Loader->Niladt;

	# utility
	JNI2Nilmod       : fn( j : JNI ) : Nilmod;
	JArrayToHolder : fn( ary : array of JNI->JArray ) : array of JNI->JString;

};

Low : module
{
	PATH : con "/dis/java/low.dis";

	SetByte   : fn( ptr : ref Loader->Niladt, off : int, val : byte );
	SetInt    : fn( ptr : ref Loader->Niladt, off : int, val : int  );
	SetBig    : fn( ptr : ref Loader->Niladt, off : int, val : big  );
	SetReal   : fn( ptr : ref Loader->Niladt, off : int, val : real );
	SetObj    : fn( ptr : ref Loader->Niladt, off : int, val : JNI->JObject );
	
	GetByte   : fn( ptr : ref Loader->Niladt, off : int ) : byte;
	GetInt    : fn( ptr : ref Loader->Niladt, off : int ) : int;
	GetBig    : fn( ptr : ref Loader->Niladt, off : int ) : big;
	GetReal   : fn( ptr : ref Loader->Niladt, off : int ) : real;
	GetObj    : fn( ptr : ref Loader->Niladt, off : int ) : (JNI->JObject);

	CallMethod     : fn( mod : Nilmod, idx : int, this : JNI->JObject, args : array of ref JNI->Value, retval : ref JNI->Value );

};

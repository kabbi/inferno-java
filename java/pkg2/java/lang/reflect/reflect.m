Reflect : module {

    PATH  : con "/dis/java/java/lang/reflect/reflect.dis";

    init	: fn(jni_m : JNI);
    widen	: fn(havetype, wanttype : int, val : ref Value) : ref Value;
    BuildArgList: fn(parms : JArrayJClass, arg : JArrayJObject)
							: array of ref Value;
    Class	: fn(t : int) : JClass;
    ClassObject : fn(t : int) : JObject;
    GetPrimitiveClass : fn(typ : int) : ref Value;
    GetVal	: fn(o : JObject) : (int, ref Value);
    SigToType	: fn(sig : string) : int;
    TypeToSig	: fn(typ : int) : string;
    TypeCharToName : fn(c : int) : string;
    ValType	: fn(val : ref Value) : int;
    ValueToObject : fn(val : ref Value) : JObject;

};

# proto file will be replaced with low.s
implement Low;

include "jni.m";

SetByte( ptr : ref Loader->Niladt, off : int, val : byte )
{
	junk := (ptr,off,val);
}

SetInt( ptr : ref Loader->Niladt, off : int, val : int  )
{
	junk := (ptr,off,val);
}

SetBig( ptr : ref Loader->Niladt, off : int, val : big  )
{
	junk := (ptr,off,val);
}

SetReal( ptr : ref Loader->Niladt, off : int, val : real )
{
	junk := (ptr,off,val);
}

SetObj( ptr : ref Loader->Niladt, off : int, val : JNI->JObject )
{
	junk := (ptr,off,val);
}

GetByte( ptr : ref Loader->Niladt, off : int ) : byte 
{
	junk := (ptr,off);
	return( byte 0 );
}

GetInt( ptr : ref Loader->Niladt, off : int ) : int 
{
	junk := (ptr,off);
	return( 0 );
}

GetBig( ptr : ref Loader->Niladt, off : int ) : big 
{
	junk := (ptr,off);
	return( big 0 );
}

GetReal( ptr : ref Loader->Niladt, off : int ) : real 
{
	junk := (ptr,off);
	return( 0.0 );
}

GetObj( ptr : ref Loader->Niladt, off : int ) : JNI->JObject 
{
	junk := (ptr,off);
	return( nil );
}

CallMethod( mod : Nilmod, idx : int, this : JNI->JObject, args : array of ref JNI->Value, retval : ref JNI->Value )
{
	junk := (mod,idx,this,args,retval);
}


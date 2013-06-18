implement JNI;

include "jni.m";
include "hash.m";

cast : Cast;
low  : Low;
hash : Hash;

JNI_VER := 16r00010001;

#
# use the access functions at the bottom to
# retrive the values stored here. thease vars
# are initialized as late as possible.
#
string_class,      # class data for java.lang.String
array_class,       # for inferno.vm.Array
class_class,       # for java.lang.Class
throwable_class,   # for java.lang.Throwable
thread_class       # for java.lang.Thread
				   : ClassData;

# cache the main thread group
mainthreadgroup : JObject;

GetVersion() : int
{
	return( JNI_VER );
}


FindClass( name : string ) : ClassData
{
	# return class data adt used by the Java Loader
	# which stores all the class information.

	# replace all ocurrences of "." with "/" in name
	newname : string;
	for(x:=0;x<len name; x++)
	{
		if (name[x]=='.')
			newname[x] = '/';
		else
			newname[x] = name[x];
	}
	cl_data : ClassData;
	if ( newname != nil && newname[0] == '[' ) {
		class := LookupArrayClass(newname);
		cl_data = class.class;
	} else {
		cl_data = jldr->loader(newname);
	}
	return cl_data;
}

getContext(): ref Draw->Context
{
	return(jldr->getcontext());
}


GetSuperclass( cl_data : ClassData ) : ClassData
{
	# we need the superclass of this 
	# class.
	if ( cl_data == nil )
		return(nil);
	return( cl_data.super );
}
	

#
# Return the java.lang.Class instance associated
# with this instance.
#
GetObjectClass( obj : JObject ) : JClass
{
	if ( obj == nil ) 
		return( nil );
	# return the class of this obj
	Object : import jldr;
	cldata := obj.class();
	if ( cldata == nil )
		ThrowException( "java/lang/InternalError", "could not get objects class data" );
	if ( cldata.name == "inferno/vm/Array" )
	{
		# handle arrays specially synthesize a unique class object
		# for each type of array, and cache it for future use.
		# this blows memory, but java requires a unique class object
		# so two [[I's must result in the same class
		return( ArrayClassObject( cast->ToJArray(obj) ) );
	}
	return( GetClassObject( cldata ) ); 
}

#
# Return the internal Class Data information
# associated with this instance
#
GetObjectClassData( obj : JObject ) : ClassData
{
	if ( obj == nil )
		return( nil );
	# return the class of this obj
	Object : import jldr;
	return( obj.class() ); 
}



#
# return the associated java.lang.Class instance
# associated with the given internal Class
# Data.
#
GetClassObject( cl_data : ClassData ) : JClass
{
	if ( cl_data == nil )
		return( nil );
	# return the stored java.lang.Class instance
	classobj := cl_data.this;

	if ( classobj.mod == nil )
	{
		# first time, we used this object, we
		# must patch the objects's 'mod' field.
		classobj.mod = classclass().moddata;
	}

	return( classobj );
}


SetStaticField( class : ClassData, name : string, val : ref Value ) : int
{
	# get field info
	Class : import jldr;

	if ( (class == nil) || (val == nil) )
		return( ERR );

	field := class.findsfield( name );

	if ( ! CheckField( field, val ) )
		return( ERR );

	# static data is located in the "module data"
	# of the module wich corresponds to the class.
	# we can get this from the class.mod field and
	# then we must convert it to a "generic" Niladt
	ptr := jassist->getmd( class.mod );

	# check offset and compute absolute offset
	if ( field.value >= class.staticsize )
		return( ERR );

	off := class.staticoffset + field.value;

	return( SetField( ptr, off, val ) );
}



GetStaticField( class : ClassData, name : string, typsig : string ) : ref Value 
{
	# get field info
	Class : import jldr;

	if ( class == nil )
		return( nil );

	field := class.findsfield( name );

	if ( (field == nil) || (field.signature != typsig) )
		return( nil );

	# Static data is located in the "module data"
	# of the module which corresponds to the class.
	# We can get this from the class.mod field and
	# then we must convert it to a "generic" Niladt
	ptr := jassist->getmd( class.mod );

	# check offset and compute absolute offset
	if ( field.value >= class.staticsize )
		return( nil );

	off := class.staticoffset + field.value;

	return( GetField( ptr, off, typsig[0] ) );
}


SetObjField( object : JObject, name : string, val : ref Value ) : int
{
	# get field info
	Object : import jldr;
	Class  : import jldr;

	if ( (object == nil) || (val == nil) )
		return( ERR );

	class  := object.class();
	field  := class.findofield( name );

	if ( ! CheckField( field, val ) )
		return( ERR );

	# convert the object to a "generic" Niladt
	ptr := cast->Obj2Niladt(object);

	# check offset and compute absolute offset
	if ( field.value >= class.objectsize )
		return( ERR );

	SetField( ptr, field.value, val );

	return( OK );
}


GetObjField( object : JObject, name : string, typsig : string ) : ref Value
{
	# get field info
	Object : import jldr;
	Class  : import jldr;

	if ( object == nil )
		return( nil );

	class  := object.class();
	field  := class.findofield( name );

	if ( (field == nil) || (field.signature != typsig) )
		return( nil );

	# convert the object to a "generic" Niladt
	ptr := cast->Obj2Niladt(object);

	# check offset and compute absolute offset
	if ( field.value >= class.objectsize )
		return( nil );

	return( GetField( ptr, field.value, typsig[0] ) );
}


CallStatic( cldata : ClassData, meth : string, sig : string, args : array of ref Value ) : (ref Value,int)
{
	# lookup method first
	(mod,idx) := FindMethod( cldata, meth, sig, METH_STATIC );
	
	if ( mod == nil )
		return( nil, CALLERR_NOMETHOD );

	# check args against sig
	(fctdesc, err) := CheckMethodArgs( sig, args );
	if ( err )
		return( nil, err );

	retval : ref Value;
	if ( fctdesc != nil )
	{
		# create a Value to hold function result
		if ( fctdesc.class != nil )
			retval = ref Value.TObject;
		else
			case fctdesc.prim
			{
				T_BOOLEAN => retval = ref Value.TBoolean;
				T_CHAR    => retval = ref Value.TChar;
				T_FLOAT   => retval = ref Value.TFloat;
				T_DOUBLE  => retval = ref Value.TDouble;
				T_BYTE    => retval = ref Value.TByte;
				T_SHORT   => retval = ref Value.TShort;
				T_INT     => retval = ref Value.TInt;
				T_LONG    => retval = ref Value.TLong;
				*         => return( nil, ERR );
			}
	}

	low->CallMethod( mod, idx, nil, args, retval );
	return( retval, OK );

}

CallMethod( obj : JObject, meth : string, sig : string, args : array of ref Value ) : (ref Value,int)
{
	# lookup method first
	cldata := GetObjectClassData(obj);
	(mod,idx) := FindMethod( cldata, meth, sig, (METH_VIRTUAL|METH_PRIVATE|METH_INIT) );
	
	if ( mod == nil )	
		return( nil, CALLERR_NOMETHOD );

	# check args against sig -- sig can be assumed to be a 
	# valid meth sig, since a matching meth was found above
	(fctdesc, err) := CheckMethodArgs( sig, args );
	if ( err )
		return( nil, err );

	retval : ref Value;
	if ( fctdesc != nil )
	{
		# create a Value to hold function result
		if ( fctdesc.class != nil )
			retval = ref Value.TObject;
		else
			case fctdesc.prim
			{
				T_BOOLEAN => retval = ref Value.TBoolean;
				T_CHAR    => retval = ref Value.TChar;
				T_FLOAT   => retval = ref Value.TFloat;
				T_DOUBLE  => retval = ref Value.TDouble;
				T_BYTE    => retval = ref Value.TByte;
				T_SHORT   => retval = ref Value.TShort;
				T_INT     => retval = ref Value.TInt;
				T_LONG    => retval = ref Value.TLong;
				*         => return( nil, ERR );
			}
	}

	low->CallMethod( mod, idx, obj, args, retval );
	return( retval, OK );
}


LowCall( mod : Nilmod, idx : int, this : JNI->JObject, args : array of ref JNI->Value, retval : ref JNI->Value )
{
	low->CallMethod( mod, idx, this, args, retval );
}


# return modifiers

GetClassFlags(jcl : JClass) : int
{
	if ( jcl == nil )
		return 0;
	return jcl.class.flags;
}

GetFieldFlags(jcl : JClass, namesig : string) : int
{
	Class : import jldr;

	if ( jcl == nil || len namesig == 0 )
		return 0;
	(name, sig) := str->splitl(namesig, " ");
	if ( len sig == 0 )
		return 0;
	sig = sig[1:];

	field := jcl.class.findsfield(name);
	if ( field != nil && field.signature == sig )
		return field.flags;

	object := jcl.class.objectdata;
	super := GetSuperclass(jcl.class);
	while ( object != nil && object != super.objectdata ) {
		field = hd object;
		if ( field.field == name && field.signature == sig )
			return field.flags;
		object = tl object;
	}
	return 0;
}

GetMethodFlags(jcl : JClass, namesig : string) : int
{
	Class : import jldr;

	if ( jcl == nil || len namesig == 0 )
		return 0;
	(name, sig) := str->splitl(namesig, " ");
	if ( len sig == 0 )
		return 0;
	sig = sig[1:];

	method := jcl.class.findsmethod(name, sig);
	if ( method != nil )
		return method.flags;
	
	method = jcl.class.findpmethod(name, sig);
	if ( method != nil )
		return method.flags;

	method = jcl.class.findimethod(sig);
	if ( method != nil )
		return method.flags;
	
	vindex := jcl.class.findvmethod(name, sig);
	if ( vindex > -1 ) {
		vmethod := jcl.class.virtualmethods[vindex];
		if ( vmethod.class == jcl.class )
			return vmethod.field.flags;
	}
	return 0;
}

#	Return array of names combined with signatures.

GetFieldSignatures(jcl : JClass, excl : int) : JArrayJString
{
	Class : import jldr;

	jary := array[0] of string;
	if ( jcl == nil )
		return MkAString(jary);
	class := jcl.class;
	static := class.staticdata;
	object := class.objectdata;
	jary = array[len static + len object] of string;
	l := len static;
	i := 0;
	for ( j := 0; j < l; j++ ) {
		field := static[j];
		tmpf := field.flags & ACC_WRITTEN_FLAGS;
		if ( (tmpf & excl) != 0 )
			continue;
		jary[i++] = field.field + " " + field.signature;
	}
	for ( ; object != nil && object != class.super.objectdata; object = tl object ) {
		field := hd object;
		tmpf := field.flags & ACC_WRITTEN_FLAGS;
		if ( (tmpf & excl) != 0 )
			continue;
		jary[i++] = field.field + " " + field.signature;
	}
	if ( i < len jary ) {
		newj := array[i] of string;
		for ( j = 0; j < i; j++ )
			newj[j] = jary[j];
		jary = newj;
	}
	return MkAString(jary);
}

GetMethodSignatures(jcl : JClass, excl : int) : JArrayJString
{
	Class : import jldr;

	jary := array[0] of string;
	if ( jcl == nil )
		return MkAString(jary);
	class := jcl.class;
	static := class.staticmethods;
	virtual := class.virtualmethods;
	private := class.privatemethods;
	construct := class.initmethods;
	l := len static;
	jary = array[l + len virtual + len private + len construct + 1] of string;

	i := 0;
	if ( class.classinit != nil )
		jary[i++] = class.classinit.field + " " + class.classinit.signature;

	for ( j := 0; j < l; j++ ) {
		method := static[j];
		tmpf := method.flags & ACC_WRITTEN_FLAGS;
		if ( (tmpf & excl) != 0 )
			continue;
		jary[i++] = method.field + " " + method.signature;
	}
	l = len virtual;
	for ( j = 0; j < l; j++ ) {
		vmethod := virtual[j];
		if ( vmethod.class != class )
			continue;
		method := vmethod.field;
		tmpf := method.flags & ACC_WRITTEN_FLAGS;
		if ( (tmpf & excl) != 0 )
			continue;
		jary[i++] = method.field + " " + method.signature;
	}
	l = len private;
	for ( j = 0; j < l; j++ ) {
		method := private[j];
		tmpf := method.flags & ACC_WRITTEN_FLAGS;
		if ( (tmpf & excl) != 0 )
			continue;
		jary[i++] = method.field + " " + method.signature;
	}
	l = len construct;
	for ( j = 0; j < l; j++ ) {
		method := construct[j];
		tmpf := method.flags & ACC_WRITTEN_FLAGS;
		if ( (tmpf & excl) != 0 )
			continue;
		jary[i++] = method.field + " " + method.signature;
	}
	if ( i < len jary ) {
		newj := array[i] of string;
		for ( j = 0; j < i; j++ )
			newj[j] = jary[j];
		jary = newj;
	}
	return MkAString(jary);
}

# make a temporary JArray for IsAssignable()
tmpJArray( c : JClass ) : JArray
{
	desc := JSigToDescriptor( c.aryname );
	return JArray(arrayclass().moddata, nil, desc.dims, desc.class, desc.prim);
}

# can src be assigned to dst?
IsAssignable( src, dst : JClass ) : JBoolean
{
	if ( (src==nil) || (dst==nil) )
		return( FALSE );

	if ( dst.aryname != nil ) {
		if ( src.aryname == nil )
			return( FALSE );
		jasrc := tmpJArray(src);
		jadst := tmpJArray(dst);
		if ( jadst.class == nil )
			return jldr->pinstanceof(jasrc, jadst.primitive, jadst.dims);
		else
			return jldr->ainstanceof(jasrc, jadst.class, jadst.dims);
	}

	return( jldr->compatclass(src.class, dst.class) );
}

IsInstanceOf( obj : JObject, cl_data : ClassData ) : JBoolean
{
	if ( cl_data == nil )
		return( FALSE );
	return( jldr->instanceof( obj, cl_data ) );
}


ArrayInstanceOf( ary : JArray, desc : ref Descriptor ) : JBoolean
{
	if ( (ary != nil) && (desc != nil) )
	{
		# is it a array of ref or array of primitive
		if ( ary.class != nil )
			return( jldr->ainstanceof(ary, desc.class, desc.dims) );
		else
			return( jldr->pinstanceof(ary, desc.prim, desc.dims) );
	}
	# not an array or not expected instance
	return( FALSE );
}


IsArray( obj : JObject ) : JBoolean
{
	if ( obj == nil ) 
		return( FALSE );

	return( IsInstanceOf( obj, arrayclass() ) );
}


# are obj1 and obj2 the same object
IsSameObject( obj1, obj2 : JObject ) : JBoolean	
{
	return( obj1 == obj2 );
}

# Return T_BOOLEAN..T_LONG, T_VOID or 0 according to whether c represents
# a Java primitive type.  If ignorevoid != 0, return 0 for 'void';
# refection code generally wants to ignore void.

PrimitiveIndex(c : JClass, ignorevoid : int) : int
{
	clname     := c.class.name;	# name of class
	prefix     : con "inferno/vm/";	# will begin with this if primitive
	prefix_len : con len prefix;
	ret	   := 0;
	if ( len clname > prefix_len && prefix == clname[:prefix_len] )
	{
		# check rest of name
		suffix := clname[prefix_len:];
		case ( suffix )
		{
			# primitive class names
			"boolean_p" =>
				ret = T_BOOLEAN;
			"byte_p" =>
				ret = T_BYTE;
			"char_p" =>
				ret = T_CHAR;
			"short_p" =>
				ret = T_SHORT;
			"int_p" =>
				ret = T_INT;
			"long_p" =>
				ret = T_LONG;
			"float_p" =>
				ret = T_FLOAT;
			"double_p" =>
				ret = T_DOUBLE;
			"void_p" =>
				if ( ! ignorevoid )
					ret = T_VOID;
		}
	}
	return ret;
}

#
# throw the object
#
Throw( throwable : JObject )
{
	if ( jldr->instanceof( throwable, throwableclass() ) )
		jldr->throw( throwable );
	
	FatalError( "JNI Error: attempt to throw a non-throwable object" );
}


#
# create an instance of the throwable class 'name'
# fill it with 'msg' and throw it
#
ThrowException( name : string, msg : string )
{
	class := FindClass( name );
	if ( (class != nil) && (jldr->compatclass( class, throwableclass() )) )
	{
		obj := AllocObject( class );
		
		# put msg into the object and throw the object
		args := array [1] of ref Value;
		args[0] = ref Value.TObject(cast->FromJString(NewString(msg)));
		#if ( SetObjField( obj, "detailMessage", val ) == OK )
		(val,err) := CallMethod( obj, "<init>", "(Ljava/lang/String;)V", args );

		# throw regardless of constructor call
		jldr->throw( obj );
	}

	FatalError( sys->sprint("JNI Error: while throwing an Exception[%s:%s]",
		                    name, msg ) );
}

# 
# return a Java Exception
#
JavaException( ex : string ) : JObject
{
	# grab any Java object currently being thrown.
	jthrow := jldr->getthreaddata().culprit;

	# if ex is nil then the caller is just querying for
	# the current java throwable so just return 'jthrow'

	# if jthrow is non-nil then return it and ignore ex
	
	if ( (jthrow != nil) || (ex == nil) )
		return( jthrow );

	# if no java throwable but we have a non-nil ex then
	# convert the Inferno exception to an appropriate Java ex.
	# this will always produce a Java throwable object
	return( jldr->sysexception(ex) );

}

#
# clear the exception of the current thread.
#
ExceptionClear()
{
	thd := jldr->getthreaddata();
	thd.culprit = nil;
}



# allocate a new instance of the class; no constructor called
AllocObject( cl_data : ClassData ) : JObject
{
	Class : import jldr;
	
	if ( cl_data == nil ) 
		return( nil );
			
	obj     := jassist->new(cl_data.mod, cl_data.objtype);
	obj.mod  = cl_data.moddata;
	return( obj );
}


# allocate a new instance of the class; call default constructor
NewObject( cl_data : ClassData ) : JObject
{
	Class : import jldr;
	
	if ( cl_data == nil ) 
		return( nil );
			
	return( cl_data.new() );
}


#
# Create an instance of java.lang.Class which
# represents a specific java class. This
# instance contains a ptr to its own class
# information, as well as a ptr to the class
# it represents.
#
NewClassObject( targ_class : ClassData ) : JClass
{
	# create an instance of java.lang.Class
	cl_data  := classclass();
	return( JClass(classclass().moddata, targ_class, nil) );
}


NewString( val : string ) : JString
{
	return( JString( stringclass().moddata, val ) );
}

#
# just like above but return as a
# JObject type, rather then JString
#
NewStringObject( val : string ) : JObject
{
	# create a java string instance
	jstr := JString( stringclass().moddata, val );

	return( cast->FromJString(jstr) );
}

# duplicate the object
DupObject( src : JObject ) : JObject
{
	Object : import jldr;
	Class  : import jldr;
	newobj : JObject;

	if ( src == nil )
		return( nil );

	class  := src.class();
	if ( class != arrayclass() )
	{
		# safe-copy memory contents 
		# this calls a j2d generated <clone> method
		newobj = class.clone( src );
	}
	else
	{
		# handle arrays 

		# create object wrapper fro the array
		newobj = AllocObject( class );
		asrc := cast->ToJArray(src);
		adst := cast->ToJArray(newobj);
		# copy array description
		adst.dims      = asrc.dims;
		adst.class     = asrc.class;
		adst.primitive = asrc.primitive;

		# copy array data

		# first create the appropriate "kind" of array

		length := len asrc.holder;
		etype  := asrc.primitive;

		if ( etype == 0 || asrc.dims > 1 )
			adst.holder = array[length] of JString; #any reference type
		else 
		{
			case asrc.primitive 
			{
				T_BOOLEAN or T_BYTE =>
					adst.holder = jassist->bytearraytoJS(array[length] of byte);
				T_CHAR or T_SHORT or T_INT =>
					adst.holder = jassist->intarraytoJS(array[length] of int);
				T_LONG =>
					adst.holder = jassist->bigarraytoJS(array[length] of big);
				T_FLOAT or T_DOUBLE =>
					adst.holder = jassist->realarraytoJS(array[length] of real);
			}
		}

		# copy the contents
		adst.holder[:] = asrc.holder[:];   

	}
	return( newobj );
}


IdentityHash( obj : JObject ) : int
{
	return( jassist->objhash(obj) );
}


GetArrayLength ( ary : JArray ) : int
{
	return( len ary.holder );
}

#
# grab the lock associated with the object
#
MonitorEnter( obj : JObject )
{
	if ( obj == nil )
		ThrowException( "java.lang.NullPointerException", "JNI Error: nil passed to MonitorEnter()" );
	
	jldr->monitorenter( obj );
}


#
# release the lock associated with the object
#
MonitorExit( obj :JObject ) 
{
	if ( obj == nil )
		ThrowException( "java.lang.NullPointerException", "JNI Error: nil passed to MonitorExit()" );
	jldr->monitorexit( obj );
}

#
# Notify any waiters
#   all==1 => notify all
#
MonitorLockNotify( obj : JObject, all : int )
{
	if ( obj == nil )
		ThrowException( "java.lang.NullPointerException", "JNI Error: nil passed to MonitorNotify()" );
	jldr->monitorenter(obj);
	jldr->monitornotify(obj,(all==1));
	jldr->monitorexit(obj);
}

#
# Same as above but don't do the monitor-enter/exit
#
MonitorNotify( obj : JObject, all : int )
{
	if ( obj == nil )
		ThrowException( "java.lang.NullPointerException", "JNI Error: nil passed to MonitorNotify()" );
	jldr->monitornotify(obj,(all==1));
}

#
# attach/detach a Limbo thread
#

thdcnt := 0; #use to number threads

AttachCurrentThread( arg : ref ThreadAttachArgs ) : int
{
	# grab/create a thread struct for this thread
	thd := jldr->getthreaddata();

	# if no java obj then create and install one
	if ( thd.this == nil )
	{
		jobj := AllocObject( threadclass() );
		if (jobj == nil )
			return( -1 );
		jthd := cast->JObjToJThd(jobj);
		jthd.PrivateInfo = thd;
		jthd.daemon      = arg.daemon;
		if ( arg.daemon == byte 1)
			jldr->daemonize();

		if ( arg.group == nil )
			jthd.group = MainThreadGroup();
		else
			jthd.group = arg.group;
		
		thdname : string;
		if ( arg.name == nil )
			thdname = "nativethd-"+ string thdcnt++;
		else 
			thdname = arg.name;
		jthd.name = StringToAChar( thdname );

		# set rest to defaults
		jthd.priority = 5; #fake; not used
		jthd.was_interrupted = byte 0;
		jthd.stillborn       = byte 0;
		jthd.target          = nil;

		# put thread object into thread data struct
		thd.this = jobj;
	}

	return( 0 ); #no error
}


DetachCurrentThread() : int
{
	# get the low-thread struct 
	thd  := jldr->getthreaddata();

	jobj := thd.this; # grab the java Thread obj

	if ( jobj != nil )
	{
		#notify all waiters
		MonitorLockNotify(jobj,1);

		# do some cleanup -- break circularity
		jthd := cast->JObjToJThd(jobj);
		jthd.PrivateInfo = nil;
		thd.this = nil;
	}

	# remove calling thd from the internal list
	jldr->delthreaddata();

	return( 0 );
}


MainThreadGroup() : JObject
{
	if ( mainthreadgroup == nil )
	{
		thd_grp_cl := FindClass( "java.lang.ThreadGroup" );
		if ( thd_grp_cl == nil )
			FatalError( "could not obtain ThreadGroup class" );

		mainthreadgroup = NewObject( thd_grp_cl );
		if ( mainthreadgroup == nil )
			FatalError( "could not create root threadgroup" );
	}

	return( mainthreadgroup );
}


FatalError( msg : string )
{
	ThrowException( "java/lang/InternalError", msg );
}


InitError( msg : string )
{
	# prepend string to insure msg is not nil
	# nil passed to error forces reporting which
	# we will leave to the loader to determine
	jldr->error( "JNI: "+ msg );
}


#
# functions to make "java" arrays from limbo arrays
#
MkAByte( bary : array of byte ) : JArrayB
{
	# create Array object
	cl_data := arrayclass();
	jbary   := cast->ToJArrayB( AllocObject( cl_data ) );

	jbary.ary       = bary;
	jbary.dims      = 1;
	jbary.class     = nil;
	jbary.primitive = T_BYTE;

	return( jbary );
}

MkAChar( ary : array of int ) : JArrayC
{
	# create Array object
	jary   := cast->ToJArrayC( AllocObject( arrayclass() ) );

	jary.ary       = ary;
	jary.dims      = 1;
	jary.class     = nil;
	jary.primitive = T_CHAR;

	return( jary );
}

MkAShort( ary : array of int ) : JArrayS
{
	# create Array object
	jary   := cast->ToJArrayC( AllocObject( arrayclass() ) );

	jary.ary       = ary;
	jary.dims      = 1;
	jary.class     = nil;
	jary.primitive = T_SHORT;

	return( jary );
}

MkAInt( iary : array of int )  : JArrayI
{
	# create Array object
	jiary   := cast->ToJArrayI( AllocObject( arrayclass() ) );

	jiary.ary = iary;
	jiary.dims      = 1;
	jiary.class     = nil;
	jiary.primitive = T_INT;

	return( jiary );
}

MkALong( ary : array of big )  : JArrayJ
{
	# create Array object
	jary   := cast->ToJArrayJ( AllocObject( arrayclass() ) );

	jary.ary       = ary;
	jary.dims      = 1;
	jary.class     = nil;
	jary.primitive = T_LONG;

	return( jary );
}

MkAFloat( ary : array of real ) : JArrayF
{
	# create Array object
	jary   := cast->ToJArrayF( AllocObject( arrayclass() ) );

	jary.ary       = ary;
	jary.dims      = 1;
	jary.class     = nil;
	jary.primitive = T_FLOAT;

	return( jary );
}

MkADouble( ary : array of real ) : JArrayD
{
	# create Array object
	jary   := cast->ToJArrayD( AllocObject( arrayclass() ) );

	jary.ary       = ary;
	jary.dims      = 1;
	jary.class     = nil;
	jary.primitive = T_DOUBLE;

	return( jary );
}

MkABoolean( ary : array of byte ) : JArrayZ
{
	# create Array object
	jary   := cast->ToJArrayZ( AllocObject( arrayclass() ) );

	jary.ary       = ary;
	jary.dims      = 1;
	jary.class     = nil;
	jary.primitive = T_BOOLEAN;

	return( jary );
}


MkAString( sary : array of string ) : JArrayJString
{
	# create Array object
	jstrary := cast->ToJArrayJString( AllocObject( arrayclass() ) );

	# fill it with the real dis array
	jstrary.ary = array[len sary] of JString;

	# now fill the dis array 
	for( x:=0; x < len sary; x++ )
		jstrary.ary[x] = NewString( sary[x] );

	jstrary.dims      = 1;
	jstrary.class     = stringclass();
	jstrary.primitive = 0;

	return( jstrary );
}

MkAObject( ary : array of JObject ) : JArrayJObject
{
	# create Array object
	jary := cast->ToJArrayJObject( AllocObject( arrayclass() ) );

	jary.ary       = ary;
	jary.dims      = 1;
	jary.class     = stringclass();
	if ( len ary > 0 )
		jary.class = GetObjectClassData(ary[0]);
	jary.primitive = 0;

	return( jary );
}


MkAJArray( jaary : array of JArray ) : JArray
{
	# create Array object
	jary := cast->ToJArray( AllocObject( arrayclass() ) );

	# fill it with the real dis array
	jary.holder    = cast->JArrayToHolder( jaary );
	jary.dims      = jaary[0].dims + 1;
	jary.class     = arrayclass();
	jary.primitive = 0;
	return( jary );
}
	

MkAAByte( aabyte : array of array of byte ) : JArray
{
	# create array of JArray
	contents := array[len aabyte] of JArray;

	# fill contents with converted byte array
	for( x:=0; x<len aabyte; x++ )
	{
		contents[x] = cast->ByteToJArray( MkAByte( aabyte[x] ) );
	}

	# wrap up in an array of its own and return
	return( MkAJArray( contents ) );
}

MkAAInt( aary : array of array of int ) : JArray
{
	# create array of JArray
	contents := array[len aary] of JArray;

	# fill contents with converted byte array
	for( x:=0; x<len aary; x++ )
	{
		contents[x] = cast->IntToJArray( MkAInt( aary[x] ) );
	}

	# wrap up in an array of its own and return
	return( MkAJArray( contents ) );
}


#
# Value adt
#

Value.Boolean( this : self ref Value ) : JBoolean
{
	pick sw := this
	{
		TBoolean => return( sw.jboolean );
		* => FatalError( "Value: bad pick access" );
	}
	return( 0);
}

Value.Byte( this : self ref Value ) : int
{
	pick sw := this
	{
		TByte => return( sw.jbyte );
		* => FatalError( "Value: bad pick access" );
	}
	return(0);
}

Value.Short( this : self ref Value ) : int
{
	pick sw := this
	{
		TShort => return( sw.jshort );
		* => FatalError( "Value: bad pick access" );
	}
	return(0);
}

Value.Int( this : self ref Value ) : int
{
	pick sw := this
	{
		TInt => return( sw.jint );
		* => FatalError( "Value: bad pick access" );
	}
	return(0);
}

Value.Long( this : self ref Value ) : big
{
	pick sw := this
	{
		TLong => return( sw.jlong );
		* => FatalError( "Value: bad pick access" );
	}
	return(big 0);
}

Value.Float( this : self ref Value ) : real
{
	pick sw := this
	{
		TFloat => return( sw.jfloat );
		* => FatalError( "Value: bad pick access" );
	}
	return(0.0);
}

Value.Double( this : self ref Value ) : real
{
	pick sw := this
	{
		TDouble => return( sw.jdouble );
		* => FatalError( "Value: bad pick access" );
	}
	return(0.0);
}

Value.Char( this : self ref Value ) : int
{
	pick sw := this
	{
		TChar => return( sw.jchar );
		* => FatalError( "Value: bad pick access" );
	}
	return(0);
}

Value.Object( this : self ref Value ) : JObject
{
	pick sw := this
	{
		TObject => return( sw.jobj);
		* => FatalError( "Value: bad pick access" );
	}
	return(nil);
}


#
# Take a "java vm" signagure string and
# return a structure which describes the
# type represented by the sig. 
# SEE: declaration of 'Descriptor'
#
JSigToDescriptor( sig : string ) : ref Descriptor
{
	desc   := ref Descriptor(nil,0,0,nil,nil);
	siglen := len sig;
	if ( sig[0] == '(' )          # method
	{
		methsig := sig[1:];
		sigsize := 2;       #account for '(' and ')' in method sig
		while ( methsig[0] != ')' )
		{
			# get descriptor for current param
			paramdesc := JSigToDescriptor(methsig);
			if ( paramdesc == nil )
				return( nil );  #error
					
			# add the param to the list
			desc.params = paramdesc :: desc.params;

			# advance to next param
			tmp := len paramdesc.sig;
			if ( tmp >= len methsig )
				return( nil );  #error in signature
			methsig = methsig[tmp:];
			sigsize += tmp;
		}

		if ( len methsig <= 1 )
			return( nil );  #error expected a return type

		rettyp := JSigToDescriptor( methsig[1:] );
		if ( rettyp == nil )
			return( nil ); #error
		# save the return type information in the current desc
		desc.class = rettyp.class;
		desc.prim  = rettyp.prim;
		desc.dims  = rettyp.dims;
		
		# set sig for method
		desc.sig   = sig[0:sigsize+len rettyp.sig];
		
	}
	else if ( sig[0] == 'L' )     # object (non-array)
	{
		# find ';' indicating end of class name or
		# the end of the str
		for( last := 1; last<siglen; last++ )
			if ( sig[last] == ';' )
				break;
		desc.class = FindClass( sig[1:last] );
		desc.sig   = sig[:last] + ";";
	}
	else if ( sig[0] == '[' )     # array
	{
		# count dimensions
		last := siglen;
		for(x:=1; x<last; x++)
		{
			if ( sig[x] != '[' )
				break;
		}
		if ( x >= last )
			return nil; #error expect at least 1 char following ['s
		desc = JSigToDescriptor( sig[x:] );
		if ( desc == nil )
			return nil;

		# else just set dimensions and sig
		desc.dims = x;
		tmp := x + len desc.sig;
		desc.sig  = sig[:tmp];
	}
	else                      # primitive type
	{
		case sig[0]
		{
			'B' => desc.prim = T_BYTE;
			'Z' => desc.prim = T_BOOLEAN;
			'S' => desc.prim = T_SHORT;
			'C' => desc.prim = T_CHAR;
			'I' => desc.prim = T_INT;
			'J' => desc.prim = T_LONG;
			'F' => desc.prim = T_FLOAT;
			'D' => desc.prim = T_DOUBLE;
			'V' => desc.prim = T_VOID;
			*   => return( nil );  #unknown signature
		}
		desc.sig = sig[0:1];
	}

	return desc;
}


IsNative( flags : int ) : int
{
	return( flags & ACC_NATIVE );
}


#
# Search for a method.  Flags indicates which methods to
# search for, and we may try to find in more than one
# group, so cascade down.
#
FindMethod( class : ClassData, name : string, sig : string, flags : int ) : (Nilmod,int)
{
	Class : import jldr;

	if ( class == nil )
		return( nil, 0 );

	if ( flags & METH_PRIVATE )
	{
		f := class.findpmethod( name, sig );
		if ( f != nil )
		{
			mod : Nilmod;
			if ( IsNative(f.flags) )
				mod = class.native;
			else
				mod = class.mod;

			return ( mod, f.value );
		}
	}

	if ( flags & METH_VIRTUAL )
	{
		idx := class.findvmethod( name, sig );
		if ( idx != -1 )
		{
			m := class.virtualmethods[idx];
			return( m.class.mod, m.field.value );
		}
	}
			
	if ( flags & METH_STATIC )
	{
		f := class.findsmethod( name, sig );
		if ( f != nil )
		{
			mod : Nilmod;
			if ( IsNative(f.flags) )
				mod = class.native;
			else
				mod = class.mod;

			return ( mod, f.value );
		}
	}

	if ( flags & METH_INIT )
	{
		f := class.findimethod( sig );
		if ( f != nil )
		{
			mod := class.mod;  #constructors can't be native
			return ( mod, f.value ); 
		}
	}

	return (nil,0);
}

CastMod() : Cast
{
	return( cast );
}

LowMod() : Low
{
	return( low );
}

########## functions called by JavaClassLoader 

jinit( ldr : JavaClassLoader, jass : JavaAssist )
{
	jldr    = ldr;
	jassist = jass;
}

Self(s: Sys, j: JNI): (Nilmod, string)
{
	sys = s;
	math = load Math Math->PATH;
	if ( math == nil )
		return (nil, sys->sprint("could not load %s: %r", Math->PATH));

	str = load String String->PATH;
	if ( str == nil )
		return (nil, sys->sprint("could not load %s: %r", String->PATH));

	cast = load Cast Cast->PATH;
	if (cast == nil)
		return (nil, sys->sprint("could not load %s: %r", Cast->PATH));
	low = load Low Low->PATH;
	if (low == nil)
		return (nil, sys->sprint("could not load %s: %r", Low->PATH));
	return (cast->JNI2Nilmod(j), nil);
}

init(nil: JNI)
{
}

########## private functions

#
# private fct to create an instance of java.lang.Class
# for a specific array type. each class instance is
# cached in a hash table so future queries for the same
# class will get the same object back. 
ArrayClassObject( ary : JArray ) : JClass
{
	arycodes := "[[[[[[[[[[";
	if ( ary.dims >= len arycodes )
		while ( ary.dims >= len arycodes )
			arycodes += arycodes;
	sig := arycodes[:ary.dims];
	if ( ary.primitive == 0 )
	{
		clname := ary.class.name;
		for(x:=0;x<len clname; x++ )
			if ( clname[x] == '.' )
				clname[x] = '/';
		sig += "L"+ clname +";";
	}
	else
	{
		typ := ary.primitive;
		if ( (typ >= T_BOOLEAN) || (typ <= T_LONG) )
		{
			typcode := "ZCFDBSIJ";
			sig[len sig] = typcode[typ-T_BOOLEAN];
		}
	}
	clobj := LookupArrayClass( sig );

	return( clobj );
}

#
# maintain a hash table of array class objects
# order based on the array signature string.
#
ACSZ     :  con 31;
actable  := array[ACSZ] of list of JClass;

LookupArrayClass( sig : string ) : JClass
{
	if ( hash == nil )
	{
		hash = load Hash Hash->PATH;
		if ( hash == nil )
			FatalError( sys->sprint( "could not load %s:%r", Hash->PATH ) );
	}

	# search for an existing class object with same name
	for( l := actable[hash->fun1(sig,ACSZ)]; l != nil; l = tl l )
	{
		class := hd l;
		if (class.aryname == sig)
			return( class );
	}

	# could not find so add this class
	class := NewClassObject( arrayclass() );
	class.aryname = sig;
	idx := hash->fun1(sig,ACSZ);
	actable[idx] = class :: actable[idx];
	return( class );
}


#
# check argument array against method signature.  It is assumed
# that 'sig' is a well-formed method signature.  This fct verifies
# that the arguments match the signature (no widening of primtive
# types is performed.  It returns a tuple specifiying if the method
# is a function and an error flag
# RETURN: (isfct,err)
#    (desc,0)  -- function; no error
#    (nil,0)   -- procedure; no error
#    (nil,ERR)   -- error; params did not match
#
CheckMethodArgs( sig : string, args : array of ref Value ) : (ref Descriptor,int)
{
	desc := JSigToDescriptor( sig );  # description of method
	if ( desc == nil )
		return( nil,ERR ); # error
	
	# determine if the method returns a value
	isfct : ref Descriptor;
	if ((desc.class!=nil) || (desc.prim!=T_VOID))
		isfct = desc;

	count := len args;
	if ( count != len desc.params )
		return(nil,CALLERR_BADARGCNT); #argument count mismatch

	if ( count == 0 )
		return(isfct,OK);  # no params to compare

	for( params := desc.params; params!=nil; params = tl params )
	{
		param := hd params;
		count--;
		valid := 0;  #assume bad arg
		pick sw := args[count]
		{
			TObject =>
				# check if actual ref arg compatible with formal
				if ( ( sw.jobj == nil )
				|| ( IsArray(sw.jobj) && (ArrayInstanceOf(cast->ToJArray(sw.jobj), param) ) )
				|| ( IsInstanceOf( sw.jobj, param.class ) ) )
					valid = 1;
			TByte    => valid = (param.prim == T_BYTE);
			TBoolean => valid = (param.prim == T_BOOLEAN);
			TChar    => valid = (param.prim == T_CHAR);
			TShort   => valid = (param.prim == T_SHORT);
			TInt     => valid = (param.prim == T_INT);
			TLong    => valid = (param.prim == T_LONG);
			TFloat   => valid = (param.prim == T_FLOAT);
			TDouble  => valid = (param.prim == T_DOUBLE);
		}

		if ( ! valid )
			return(nil,CALLERR_BADARG+count); #class mismatch
	}

	# if we survived then all args matched
	return(isfct,OK);
}

# verify that 'val' matches 'field'
# RETURN: 0 => no match
#         1 => match
#
CheckField( field : ref jldr->Field, val : ref Value ) : int
{
	# check we have the right one 
	if ( field == nil )
		return( 0 );

	valid := 0;

	pick sw := val
	{
		TObject =>
			{
				# check reference type: object or array
				desc := JSigToDescriptor( field.signature );

				if ( (field.signature[0] == 'L') && (desc.class != nil) )
				{
					if ( sw.jobj != nil && IsInstanceOf( sw.jobj, desc.class ) == FALSE )
						return( 0 );
				}
				else if ( (field.signature[0] == '[') && (desc.dims>0) )
				{
					# array ref type
					if ( sw.jobj != nil && ArrayInstanceOf( cast->ToJArray(sw.jobj), desc ) == FALSE )
						return( 0 );
				}
				else
					return( 0 );
				valid = 1;  # ref field is ok
			}					
		TByte    => valid = (field.signature[0] == 'B');
		TBoolean => valid = (field.signature[0] == 'Z');
		TChar    => valid = (field.signature[0] == 'C');
		TShort   => valid = (field.signature[0] == 'S');
		TInt     => valid = (field.signature[0] == 'I');
		TLong    => valid = (field.signature[0] == 'J');
		TFloat   => valid = (field.signature[0] == 'F');
		TDouble  => valid = (field.signature[0] == 'D');
	}

	return( valid );
}

#
# Set a field at the given refernce and offset.
#
SetField( ptr : ref Loader->Niladt, off : int, val : ref Value ) : int
{
	# must be good, set the field to the provided value
	pick sw := val
	{
		TByte    => low->SetByte( ptr, off, byte sw.jbyte );
		TBoolean => low->SetByte( ptr, off, byte sw.jboolean );
		TShort   => low->SetInt( ptr, off, sw.jshort );
		TChar    => low->SetInt( ptr, off, sw.jchar );
		TInt     => low->SetInt( ptr, off, sw.jint );
		TLong    => low->SetBig( ptr, off, sw.jlong );
		TFloat   => low->SetReal( ptr, off, sw.jfloat );
		TDouble  => low->SetReal( ptr, off, sw.jdouble );
		TObject  => low->SetObj( ptr, off, sw.jobj );
		*         => return( ERR );
	}

	return( OK );
}


#
# grab a given field from the reference and offset given
#
GetField( ptr : ref Loader->Niladt, off : int, typ : int ) : ref Value
{
	val : ref Value;

	if ( (ptr==nil) || (off < 0) )
		return( nil );

	# use typ char to determine type we are after
	case typ
	{
		'B' => val = ref Value.TByte(int low->GetByte( ptr, off ));
		'C' => val = ref Value.TChar(low->GetInt( ptr, off ));
		'S' => val = ref Value.TShort(low->GetInt( ptr, off ));
		'I' => val = ref Value.TInt(low->GetInt( ptr, off ));
		'Z' => val = ref Value.TBoolean(int low->GetByte( ptr, off ));
		'J' => val = ref Value.TLong(low->GetBig( ptr, off ));
		'F' => val = ref Value.TFloat(low->GetReal( ptr, off ));
		'D' => val = ref Value.TDouble(low->GetReal( ptr, off ));
		'L' or
		'[' => val = ref Value.TObject(low->GetObj( ptr, off ));
		*           => return(nil);
	}

	return( val );
}


#
# The following  functions will load specific java
# classes on demand. The classes are loaded as late
# as possible
#
stringclass() : ClassData
{
	if ( string_class == nil )
		string_class = jldr->loader( "java/lang/String" );
	return( string_class );
}

arrayclass() : ClassData
{
	if ( array_class == nil )
		array_class = jldr->loader( "inferno/vm/Array" );
	return( array_class );
}

classclass() : ClassData
{
	if ( class_class == nil )
		class_class = jldr->loader( "java/lang/Class" );
	return( class_class );
}

throwableclass() : ClassData
{
	if (throwable_class == nil)
		throwable_class = jldr->loader("java/lang/Throwable");
	return( throwable_class );
}

threadclass() : ClassData
{
	if (thread_class == nil)
		thread_class = jldr->loader("java/lang/Thread");
	return( thread_class );
}

StringToAChar( s : string ) : JArrayC
{
	l := len s;
	ac := array[l] of int;

	for( x:=0; x<l; x++ )
		ac[x] = s[x];	

	return( MkAChar(ac) );
}

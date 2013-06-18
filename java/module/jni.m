#
# jni -- java native interface
#
# this module defines the limbo helper
# functions for java class library 
# native methods (limbo). 
#
# This module is based on the JNI 
# specification from JavaSoft for
# VM implementations supporting a C/C++
# interface.
#

include "sys.m";
include "math.m";
include "string.m";
include "loader.m";
include "classloader.m";
include "cast.m";	

JNI : module
{
	# where to find jni.dis
	PATH   : con "/dis/java/jni.dis";

	#
	# exported read-only vars
	# upon JNI initialization the following
	# variables are assigned. Native method modules
	# can use the following instances rather than
	# loading their own copies. These variables
	# should never be assigned.
	sys     : Sys;                 # std inferno sys module
	math    : Math;                # std inferno math module
	str     : String;              # std inferno string module       
	jldr    : JavaClassLoader;     # primary java class loader
	jassist : JavaAssist;          # java assist module

	# boolean constants
	FALSE  : con 0;
	TRUE   : con 1;
	BFALSE : con byte 0;
	BTRUE  : con byte 1;

	# return error flags for JNI functions
	OK     : con 0;   
	ERR    : con -1;  

	# JVM Type Constants: used for identifying Java primitive types.
	T_JVMSTART : con 4;
	T_BOOLEAN, T_CHAR, T_FLOAT, T_DOUBLE, T_BYTE, T_SHORT, 
	T_INT, T_LONG, T_OBJECT, T_ARRAY, T_VOID,
	T_JVMLAST
	: con (iota + T_JVMSTART);

	# JVM class flags constants
	ACC_PUBLIC:         con 16r0001;
	ACC_PRIVATE:        con 16r0002;
	ACC_PROTECTED:      con 16r0004;
	ACC_STATIC:         con 16r0008;
	ACC_FINAL:          con 16r0010;
	ACC_SUPER:          con 16r0020;
	ACC_SYNCHRONIZED:   con 16r0020;
 	ACC_VOLATILE:       con 16r0040;
	ACC_TRANSIENT:      con 16r0080;
	ACC_NATIVE:         con 16r0100;
	ACC_INTERFACE:      con 16r0200;
 	ACC_ABSTRACT:       con 16r0400;

	ACC_WRITTEN_FLAGS:  con 16r0fff;


	# common java types

	#
	# The following two types are used to represent
	# Java classes. The 'ClassData' type contains all
	# of the information pertaining to a class and is
	# used to obtain class information and instantiate
	# objects.  Although there  is information in the
	# structure it should normally be treated as an
	# opaque type by client native method modules.
	#
	ClassModule : type ref Loader->Niladt;
	ClassData   : type ref JavaClassLoader->Class;

	#
	# This is the "generic" type of any Java instance.
	# Operations on the object can be performed via this
	# generic handle.
	#
	JObject  : type ref JavaClassLoader->Object;

	#
	# This represents an instance of java.lang.Class
	# It is an object which contains a ptr to the
	# actual class data it represents.
	#
	JClass   : type ref JavaClassLoader->ClassObject;

	#
	# This is an instance of java.lang.String.
	# This class is a wrapper of a Dis string.
	#
	JString  : type ref JavaClassLoader->JavaString;

	JBoolean : type int;

	# Java arrays are actually classes
	# which wrap a Dis array.  The array
	# class matches the adt 'Array' defined
	# in JavaClassLoader. The following arrays
	# should mirror that adt and are used by
	# limbo modules to access the array contents
	# directly. Java Arrays should only be created
	# in Java code or via the Array functions
	# below.  A simple limbo instance of the
	# array adt's is not good enough. 

	# JArray is used as a "generic" array and to represent
	# multi-dimensional arrays.
	JArray        : type ref JavaClassLoader->Array;  # x[][]..

	IntArray : adt
	{
		cl_mod:		ref Loader->Niladt;     # object's class data 
		ary:		array of int;           # actual dis array
		dims:		int;                    # number of dimensions
		class:		ClassData;              # class data of base type
		primitive:	int;                    # set if base type is primitive
	};

	ByteArray : adt
	{
		cl_mod:		ref Loader->Niladt;     # object's class data 
		ary:		array of byte;          # actual dis array
		dims:		int;                    # number of dimensions
		class:		ClassData;              # class data of base type
		primitive:	int;                    # set if base type is primitive
	};

	BigArray : adt
	{
		cl_mod:		ref Loader->Niladt;     # object's class data 
		ary:		array of big;           # actual dis array 
		dims:		int;                    # number of dimensions
		class:		ClassData;              # class data of base type
		primitive:	int;                    # set if base type is primitive
	};

	RealArray : adt
	{
		cl_mod:		ref Loader->Niladt;     # object's class data 
		ary:		array of real;          # actual dis array
		dims:		int;                    # number of dimensions
		class:		ClassData;              # class data of base type
		primitive:	int;                    # set if base type is primitive
	};

	StringArray : adt
	{
		cl_mod:		ref Loader->Niladt;     # object's class data 
		ary:		array of JString;       # actual dis array
		dims:		int;                    # number of dimensions
		class:		ClassData;              # class data of base type
		primitive:	int;                    # set if base type is primitive
	};

	ClassArray : adt
	{
		cl_mod:		ref Loader->Niladt;     # object's class data 
		ary:		array of JClass;        # actual dis array
		dims:		int;                    # number of dimensions
		class:		ClassData;              # class data of base type
		primitive:	int;                    # set if base type is primitive
	};
	
	ObjectArray : adt
	{
		cl_mod:		ref Loader->Niladt;     # object's class data 
		ary:		array of JObject;       # actual dis array
		dims:		int;                    # number of dimensions
		class:		ClassData;              # class data of base type
		primitive:	int;                    # set if base type is primitive
	};

	ArrayArray : adt
	{
		cl_mod:		ref Loader->Niladt;     # object's class data 
		ary:		array of JArray;        # actual dis array
		dims:		int;                    # number of dimensions
		class:		ClassData;              # class data of base type
		primitive:	int;                    # set if base type is primitive
	};

	#
	# Common type names emitted by 'javal'.
	#
	JArrayI : type ref IntArray;    # int[]
	JArrayC : type ref IntArray;    # char[]
	JArrayB : type ref ByteArray;   # byte[]
	JArrayS : type ref IntArray;    # short[]
	JArrayJ : type ref BigArray;    # long[]
	JArrayF : type ref RealArray;   # float[]
	JArrayD : type ref RealArray;   # double[]
	JArrayZ : type ref ByteArray;   # boolean[]

	JArrayJClass  : type ref ClassArray;  # Class[]
	JArrayJString : type ref StringArray; # String[]
	JArrayJObject : type ref ObjectArray; # Object[]

	ThreadObject : adt
    {
        cl_mod               : ClassModule;
        name                 : JArrayC;
        priority             : int;
        #threadQ             : cyclic ref ThreadObject;
        PrivateInfo          : ref JavaClassLoader->ThreadData;
		was_interrupted      : byte;    #boolean
        #eetop               : int;
        #single_step         : byte;    #boolean
        daemon               : byte;    #boolean
        stillborn            : byte;    #boolean
        target               : JObject;
        group                : JObject;
        #initial_stack_memory : int;
    };
	JThread : type ref ThreadObject;


	#
	# This union type is used for setting/getting fields
	# of an arbitrary Java object/class, and also for
	# calling arbitrary object/class methods.
	# To set Java reference types (i.e. objects, arrays)
	# they must be converted to a JObject (i.e. use TObject).
	#
	# One way to create an instance of this type is:
	#     val := ref Value.TObject(obj);
	#
	# To retrieve a value use a 'pick' statement or one
	# of the "getter" functions below.
	#
	# NOTE: the Low module is aware of the order of the "pick" tags 
	#
	Value :adt
	{
		pick 
		{
			TObject   => jobj    : JObject; 
			TByte     => jbyte   : int;
			TBoolean  => jboolean: int;
			TChar     => jchar   : int;
			TShort    => jshort  : int;
			TInt      => jint    : int;
			TLong     => jlong   : big;
			TFloat    => jfloat  : real;
			TDouble   => jdouble : real;
		}

		#
		# Get a value of the expected type. If the
		# actual type is not the expected type then
		# a FatalError() is called.
		#
		Boolean : fn( this : self ref Value ) : JBoolean;
		Byte    : fn( this : self ref Value ) : int;
		Short   : fn( this : self ref Value ) : int;
		Int     : fn( this : self ref Value ) : int;
		Long    : fn( this : self ref Value ) : big;
		Float   : fn( this : self ref Value ) : real;
		Double  : fn( this : self ref Value ) : real;
		Char    : fn( this : self ref Value ) : int;
		Object  : fn( this : self ref Value ) : JObject;


	};

	# 
	# This structure is used to "describe" a Java type. A Java signature
	# stored as a string is converted into this ADT for better comparisons.
	# Depending on the actual type vairous parts of the ADT will be filled
	# in. The 'sig' field will contain the appropriate java signagure string
	# associated with the type. The following details how to distinguish the 
	# type:
	# non-array ref: 
	#     'class' represents the class info; other fields are 0/nil
	# array ref:
	#     "class" is nil for primitive array and 'prim' contains one of
	#     the "Java Type Constants" representing the array's base type.
	#     for non-primitive arrays 'class' is the ClassData for the base
	#     type; 'prim' is 0; 'dims' contains the number of dimensions
	# primitive:  
	#     'class' is nil; 'dims' is 0; 'prim' is one of Java Type Consts
	# method:
	#     'params' is a list of Descriptor's for each param -- nil if the
	#     method has no parameters. The method return value is represented 
	#     by the other fields as described above; a method w/ no return 
	#     value will have (nil,T_VOID,0,"V",nil) descriptor. NOTE: the param 
	#     list is in (Right-to-Left order -- i.e right most param is the 
	#     list-head).
	# 
	Descriptor : adt
	{
		class   : ClassData; 
		prim    : int;       
		dims    : int;       
		sig     : string;       #type's java signature
		params  : cyclic list of ref Descriptor;
	};

	
	#
	# argument passed to AttachCurrentThread
	#
	ThreadAttachArgs : adt
	{
		name   : string;  #can be nil
		daemon : byte;    #1=true
	    group  : JObject; #nil ==> main group
	};


	#
	# JNI Functions
	#

	# 
	# Return JNI version number in the form
	# of 0xVVVVIIII where VVVV=major version
	# and IIII= minor version
	#
	GetVersion : fn() : int;  


	##
	## Class/Object access
	##

	#
	# Find the class data for a given class name.
	# Will cause a load of the class if necessary.
	# NOTE: this does not return a java.lang.Class
	# object, but rather the internal structure.
	#
	FindClass  : fn( name : string ) : ClassData;

	#
	# Return the class's superclass data.
	#
	GetSuperclass  : fn( cl_data : ClassData ) : ClassData;

	#
	# Return the java.lang.Class instance associated
	# with this instance.
	#
	GetObjectClass : fn( obj : JObject ) : JClass;

	#
	# Return the internal Class Data information
	# associated with this instance
	#
	GetObjectClassData : fn( obj : JObject ) : ClassData;

	#
	# return the associated java.lang.Class instance
	# associated with the given internal Class
	# Data.
	#
	GetClassObject : fn( cl_data : ClassData ) : JClass;

	#
	# return the java.lang.Class instance associated
	# with the array class that has signature 'sig'.
	#
	LookupArrayClass : fn( sig : string ) : JClass;

	#
	# Allocate an instance of java.lang.Class that 
	# represents the class indicated by 'cl_data'.
	# The 'cl_data' can be obtained via the functions above.
	#
	NewClassObject : fn( cl_data : ClassData ) : JClass;

	#
	# Allocate a new instance of the class; no constructor called.
	#
	AllocObject    : fn( cl_data : ClassData ) : JObject;

	#
	# Allocate a new instance of the class and 
	# attempt to call the "default" constructor.
	# NOTE: this routine should be used with care, 
	# because not all classes have default constructors.	
	#
	NewObject      : fn( cl_data : ClassData ) : JObject;

	#
	# Duplicate the object. This function will create
	# a new instance of the object's class and perform
	# a shallow copy of the the objects data contents
	# into the new instance.
	# NOTE: the constructor of the new object is not invoked
	#
	DupObject      : fn( obj : JObject ) : JObject;

	#
	# Return a hash code based on the object's reference,
	# not its contents. This is called by 
	# java.lang.Object.hashCode() as well as 
	# System.identityHashCode().
	#
	IdentityHash   : fn( obj : JObject ) : int;

	#
	# Allocate a java string object and place the
	# dis string as its contents.
	#
	NewString      : fn( val : string ) : JString;

	#
	# Just like NewString but return as a
	# JObject type, rather then JString
	#
	NewStringObject : fn( val : string ) : JObject;
    
	#
	# Set object/class data fields.
	# Must pass the "object instance"/"class data" along with the
	# field name and the value it should be set to. The contents of
	# the 'val' union type is used to determine the field type and if
	# they are not compatable the function fails.
	#
	# RETURN:  JNI->OK=> success;  
	#          JNI->ERR=> failure
	#
	SetStaticField : fn( cl_data : ClassData, name : string, val : ref Value ) : int;
	SetObjField    : fn( obj : JObject, name : string, val : ref Value ) : int;

	# Get object/class data fields.
	# Must pass the "object instance"/"class data" along with the field
	# name and a "type signature" (see JVM reference). The type sig must
	# match the actual field sig exactly. 
	# 
	# RETURN: nil=> failure; 
	#         non-nil=> a 'Value' union type with the field contents
	#
	GetStaticField : fn( cl_data : ClassData, name : string, typ : string ) : ref Value;
	GetObjField    : fn( obj : JObject, name : string, typ : string ) : ref Value;

	
	#
	# Call a method:
	#   cl_data/obj : the class or object being called
	#   meth        : name of method to call
	#   sig         : signature of method being called
	#   args        : array of args to pass (nil==void) 'this' is implicitly
	#                 passed for dynamic (object) method calls
	#   return      : tuple: value of method call (nil==void), error code
	#
	#   example:  
	#   v := Value.Int(99);
	#   args := array[] of {v};
	#   (val,err) := CallMeth( o, "foo", "(I)I", args );
	#   if ( err == JNI->OK )
	#		sys->print( "return: %d\n", val.Int() );
	#
	CallStatic     : fn( cl_data : ClassData, meth : string, sig : string, args : array of ref Value ) : (ref Value,int);
	CallMethod     : fn( obj : JObject, meth : string, sig : string, args : array of ref Value ) : (ref Value,int);


	#
	# Method call error codes
	#
	CALLERR_NOMETHOD,   # method not found
	CALLERR_BADSIG,     # bad signature
	CALLERR_BADARGCNT,  # arg count mismatch
	CALLERR_BADARG      # argument mismatch: errcode-CALLERR_BADARG==argument position
	                    # 'badarg' must be last.
				        : con (iota+1);


	##
	## Object/Class comparison functions
	##

	IsInstanceOf    : fn( obj : JObject, cl_data : ClassData )  : JBoolean;
	IsAssignable    : fn( assignee, assignTo : JClass )         : JBoolean;
	IsSameObject    : fn( obj1, obj2 : JObject )                : JBoolean;	

	# Check if 'ary' can be assigned to an instance with matching 'desc'.
	# If 'ary' or 'desc' are nil then return FALSE.
	ArrayInstanceOf : fn( ary : JArray, desc : ref Descriptor ) : JBoolean;

	# Is the object an array? (nil==FALSE)
	IsArray         : fn( obj : JObject )                       : JBoolean;

	##
	## Support for Serializable
	##

	#  Return the modifiers for the item.
	#  Return 0 if field or method not found in class.
	#  Do not search for fields/methods in superclass.
	#  string args are same format as strings returned
	#  by GetFieldSignatures and GetMethodSignatures.
	#
	GetClassFlags	: fn(jcl : JClass) : int;
	GetFieldFlags	: fn(jcl : JClass, fieldsignature : string) : int;
	GetMethodFlags	: fn(jcl : JClass, methodsignature : string) : int;

	#  Return array of Fields/Methods plus signatures as strings.
	#  Should be limited Fields/methods in this class, not superclass.
	#  Returned value strings are "fieldormethodname signature".
	#
	GetFieldSignatures  : fn(jcl: JClass, excl : int) : JArrayJString;
	GetMethodSignatures : fn(jcl: JClass, excl : int) : JArrayJString;

	##
	## Throwing Exceptions
	##

	#
	# Throw the pre-created 'throwable' object. The 
	# 'throwable' object must be an instance of 
	# "java.lang.Throwable", else failure.
	#
	Throw          : fn( throwable : JObject );
	ThrowException : fn( name : string, msg : string );

	#
	# return the current Java Exception.  The object
	# returned can be used by "Throw" to re-throw it.
	# 
	# ex is the current Inferno exception if in a rescue.
	# if ex is nil then the current value of culprit() is
	# returned (that may be nil).  If ex is non nil and
	# culprit() is nil then ex is converted to the appropriate
	# Java throwable and returned.
	#
	JavaException: fn( ex : string ) : JObject;

	#
	# Clear any current Exception for the calling thread.
	#
	ExceptionClear : fn();

	##
	## Array functions
	##

	GetArrayLength : fn( ary : JArray ) : int;

	#
	# functions to make "java" arrays from limbo arrays
	#
	MkAByte    : fn( ary : array of byte )    : JArrayB;
	MkAChar    : fn( ary : array of int )     : JArrayC;
	MkAShort   : fn( ary : array of int )     : JArrayS;
	MkAInt     : fn( ary : array of int )     : JArrayI;
	MkALong    : fn( ary : array of big )     : JArrayJ;
	MkAFloat   : fn( ary : array of real )    : JArrayF;
	MkADouble  : fn( ary : array of real )    : JArrayD;
	MkABoolean : fn( ary : array of byte )    : JArrayZ;
	MkAObject  : fn( ary : array of JObject ) : JArrayJObject;
	MkAString  : fn( ary : array of string )  : JArrayJString;

	MkAAByte   : fn( aary : array of array of byte ) : JArray;	
	MkAAInt    : fn( aary : array of array of int )  : JArray;

	# This can be used to create arrays of arbitrary dimensions.
	MkAJArray   : fn( ary : array of JArray ) : JArray;

	# make a JArrayC from a Dis string
	StringToAChar : fn( s : string ) : JArrayC;

	##
	## Monitor, locking, and Thread functions
	##

	#
	# Lock or unlock the object's associated
	# lock. Block until the operation is complete.
	# Upon an error: FatalError() is called
	#
	MonitorEnter   : fn( obj : JObject );
	MonitorExit    : fn( obj :JObject );
	
	#
	# Notify any waiters. 
	#   all==1 => notify all
	# *Lock* version will do a enter/exit.
	#
	MonitorLockNotify : fn( obj : JObject, all : int );
	MonitorNotify     : fn( obj : JObject, all : int );

	#
	# Attach a "Limbo thread" to the "Java vm".
	# This allows a Limbo "spawned" thread to
	# look like a "Java thread" to the Java Classes.
	#
	# return 0=>success; <0=>fail
	#
	AttachCurrentThread  : fn( arg : ref ThreadAttachArgs ) : int;

	#
	# Detach a thread from the "java VM".
	#
	DetachCurrentThread  : fn() : int;

	#
	# returns the Main thread group.
	#
	MainThreadGroup      : fn() : JObject;
	
	##
	## Utility Functions
	##

	# flags indicating which methods to find
	METH_PRIVATE,   # private methods
	METH_VIRTUAL,   # virtual methods
	METH_STATIC,    # static methods
	METH_INIT       # constructors
	                : con ( 1 << iota );

	#
	# look up a method based on its name and signature.
	#
	# class : class descritpor to look in
	# name  : method name to look up
	# sig   : method signature
	# flags : specifies what type of method to find and
	#         can be any of the above flags or'ed togeather.
	# 
	# return: the (module,index) of the method
	#
	FindMethod          : fn( class : ClassData,
				  name : string,
				  sig : string,
				  flags : int ) : (Nilmod,int);

	#
	# If c represents a Java primitive type, return
	# T_BOOLEAN..T_LONG or T_VOID; otherwise, return 0.
	# Also return 0 if T_VOID applies, but ignorevoid != 0.
	#
	PrimitiveIndex: fn(c : JClass, ignorevoid : int) : int;

	#
	# Convert a Java type signature string into
	# a type descriptor structure.  The signature
	# passed in can represent any single type (including
	# a method).  Extra characters on the end are ignored.
	#
	JSigToDescriptor    : fn( sig : string ) : ref Descriptor;

	#
	# Throw a java.lang.InternalError 
	#
	FatalError     : fn( msg : string );

	#
	# Indicate to loader a native module init()
	# function has failed.
	#
	InitError      : fn( msg : string );

	#
	# Return an instance of the Cast module.
	#
	CastMod        : fn() : Cast;

	#
	# Return an instance of the Low module.
	#
	LowMod         : fn() : Low;

	# return the current draw context
	getContext:fn(): ref Draw->Context;

	#
	# The following routines are called by the JavaClassLoader
	# module to initialize JNI. Native method modules must not
	# call thease routines.
	#
	jinit : fn( jldr : JavaClassLoader, jass : JavaAssist );
	Self:	fn(s: Sys, j: JNI): (Nilmod, string);
	init:	fn(j: JNI);
};

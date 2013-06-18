implement StringBuffer_L;

# javal v1.4 generated file: edit with care

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

# this module implements the class java.lang.StringBuffer
# the buffer is really a Limbo string type. In the original
# Java implementation an array of char was used and the array
# size was always >= to the buffer contents. In this version
# The limbo string represents only the buffer contents and
# contains no extra "padding".  This is done because the
# Inferno implementation of string is optimized for string
# operations. Thus, the actual buffer contents is simply the
# length of the Limbo string; the original Java version 
# maintained the buffer content size in the field 'count'. 
# For conveience of the Java code, and to negate a call into
# the native Limbo, the 'count' field is maintained to always
# be the length of the Limbo string: e.g. "count=len Ivalue".
#
# In the Java version the character array can be shared with
# an instance of the Java String class, hence a flag for being
# shared. This is not the case for the Inferno implementation.
# whenever data is passed out it must be a copy of the 'Ivalue'
# string.
#
# When this was implemented synchronizatio of native methods 
# was not complete, so this module assumes if a method should
# be synchronized it is done before entering the native method
# so each native method should be a private method and wrapped
# in Java code by a synchronized method (or block).
#
# The java.lang.StringBuffer class is serialzable. For Inferno
# since the internal structure has changed serialization must
# be explitily handled by this class. This is done by adding
# writeObject()/readObject() methods in the Java side to write
# and read in the expected format, so outside VM's do not know
# we have a differen implementation.
#

#<<

include "StringBuffer_L.m";

#>> extra post includes here
Value : import jni;
cast : Cast;

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
    cast = jni->CastMod();
    #<<
}

setLength0_I_V( this : ref StringBuffer_obj, p0 : int)
{#>>
	# p0 => length to set buf to; assume >=0

	l := len this.Ivalue;

	if ( p0 < l )	# truncate
		this.Ivalue = this.Ivalue[:p0];
	else {		# pad with null characters
		for( i := l; i < p0; i++ )
			this.Ivalue[i] = '\0';
	}
	this.count = len this.Ivalue;
}#<<

charAt0_I_C( this : ref StringBuffer_obj, p0 : int) : int
{#>>
	# assume p0 is within the range 0..len this.Ivalue
	return( this.Ivalue[p0] );
}#<<

getChars0_I_I_aC_I_V( this : ref StringBuffer_obj, p0 : int,p1 : int,p2 : JArrayC,p3 : int)
{#>>
	# assume the index ranges are already checked
	copy_count := (p1-p0);
	dst_end    := p3 + copy_count;
	if ( dst_end > len p2.ary )
		jni->ThrowException( "java.lang.ArrayIndexOutOfBoundsException", "destination array not large enough" );

	# copy one char at a time
	for( (x,y) := (p3,p0); x < copy_count; junk:=(x++,y++) )
		p2.ary[x] = this.Ivalue[y];

}#<<

setCharAt0_I_C_V( this : ref StringBuffer_obj, p0 : int,p1 : int)
{#>>
	# assume index has been checked
	this.Ivalue[p0] = p1;
}#<<

reverse0_V( this : ref StringBuffer_obj)
{#>>
	# reverse the string buffer contents
	str := this.Ivalue[:];  # slice a copy
	for( (x,y):=(0,(len str)-1); x<len str; junk:=(x++,y--) )
		this.Ivalue[x] = str[y];
			
}#<<

append_int_I_V( this : ref StringBuffer_obj, p0 : int)
{#>>
	# append the Ivalue to the string
	this.Ivalue += string p0;
	this.count = len this.Ivalue;
}#<<

append_long_J_V( this : ref StringBuffer_obj, p0 : big)
{#>>
	# append the Ivalue to the string
	this.Ivalue += string p0;
	this.count = len this.Ivalue;
}#<<

append_str_rString_V( this : ref StringBuffer_obj, p0 : JString)
{#>>
	# append the Ivalue to the string
	val : string;
	if ( p0 == nil )
		val = "null"; #this is what Java wants
	else 
		val = p0.str;

	this.Ivalue += val;
	this.count = len this.Ivalue;
}#<<

append_chars_aC_I_I_V( this : ref StringBuffer_obj, p0 : JArrayC,p1 : int,p2 : int)
{#>>
	# append the Ivalue to the string
	if ( p0 == nil ) return;

	val := p0.ary[p1:p1+p2];
	l   := len this.Ivalue;
	for( x:=0; x < len val; x++ )
		this.Ivalue[l++] = val[x];
	this.count = len this.Ivalue;
}#<<

append_ch_C_V( this : ref StringBuffer_obj, p0 : int)
{#>>
	# append the Ivalue to the string
	this.Ivalue[this.count] = p0;
	this.count++;
}#<<

append_float_F_V( this : ref StringBuffer_obj, p0 : real)
{#>>
	# append the Ivalue to the string
	s := string p0;
	if(p0 == 0.0)
		s += ".0";
	this.Ivalue += s;
	this.count = len this.Ivalue;
}#<<

append_double_D_V( this : ref StringBuffer_obj, p0 : real)
{#>>
	# append the Ivalue to the string
	s := string p0;
	if(p0 == 0.0)
		s += ".0";
	this.Ivalue += s;
	this.count = len this.Ivalue;
}#<<

insert_int_I_I_V( this : ref StringBuffer_obj, p0 : int,p1 : int)
{#>>
	# insert 'p1' into the string the new string is
	# left + p1 + right; where left is Ivalue[:p0] 
	# and right is Ivalue[p0:].  newright is
	# p1+right
	# assume args have been checked
	#
	newright := (string p1) + this.Ivalue[p0:];
	this.Ivalue = this.Ivalue[:p0] + newright;
	this.count = len this.Ivalue;
}#<<

insert_long_I_J_V( this : ref StringBuffer_obj, p0 : int,p1 : big)
{#>>
	# insert 'p1' into the string the new string is
	# left + p1 + right; where left is Ivalue[0:p0] 
	# and right is Ivalue[p0:count].  newright is
	# p1+right
	#
	newright := (string p1) + this.Ivalue[p0:];
	this.Ivalue = this.Ivalue[:p0] + newright;
	this.count = len this.Ivalue;
}#<<

insert_str_I_rString_V( this : ref StringBuffer_obj, p0 : int,p1 : JString)
{#>>
	# insert 'p1' into the string the new string is
	# left + p1 + right; where left is Ivalue[0:p0] 
	# and right is Ivalue[p0:count].  newright is
	# p1+right
	#
	val : string;
	if ( p1 == nil ) 
		val = "null";
	else
		val = p1.str;
	newright := val + this.Ivalue[p0:];
	left     := this.Ivalue[:p0];
	this.Ivalue = left + newright;
	this.count = len this.Ivalue;
}#<<

insert_chars_I_aC_V( this : ref StringBuffer_obj, p0 : int,p1 : JArrayC)
{#>>
	# insert 'p1' into the string the new string is
	# left + p1 + right; where left is Ivalue[:p0] 
	# and right is Ivalue[p0:].  newright is
	# p1+right
	#
	if ( p1 == nil ) return;

	# get copy of old right part and lop it off
	oldright := this.Ivalue[p0:];
	this.Ivalue = this.Ivalue[:p0];

	# insert char array first
	for( x:=0; x<len p1.ary; x++ )
		this.Ivalue[p0 + x] = p1.ary[x];

	# now add the old right back
	this.Ivalue += oldright;
	this.count  = len this.Ivalue;
}#<<

insert_ch_I_C_V( this : ref StringBuffer_obj, p0 : int,p1 : int)
{#>>
	# insert 'p1' into the string the new string is
	# left + p1 + right; where left is Ivalue[:p0] 
	# and right is Ivalue[p0:].  newright is
	# p1+right
	#
	newright: string;
	newright[0] = p1;
	newright += this.Ivalue[p0:];
	this.Ivalue = this.Ivalue[:p0] + newright;
	this.count = len this.Ivalue;
}#<<

insert_float_I_F_V( this : ref StringBuffer_obj, p0 : int,p1 : real)
{#>>
	# insert 'p1' into the string the new string is
	# left + p1 + right; where left is Ivalue[0:p0] 
	# and right is Ivalue[p0:count].  newright is
	# p1+right
	#
	s := string p1;
	if(p1 == 0.0)
		s += ".0";
	newright := s + this.Ivalue[p0:];
	this.Ivalue = this.Ivalue[:p0] + newright;
	this.count = len this.Ivalue;
}#<<

insert_double_I_D_V( this : ref StringBuffer_obj, p0 : int,p1 : real)
{#>>
	# insert 'p1' into the string the new string is
	# left + p1 + right; where left is Ivalue[0:p0] 
	# and right is Ivalue[p0:count].  newright is
	# p1+right
	#
	s := string p1;
	if(p1 == 0.0)
		s += ".0";
	newright := s + this.Ivalue[p0:];
	this.Ivalue = this.Ivalue[:p0] + newright;
	this.count = len this.Ivalue;
}#<<

get_string_rString( this : ref StringBuffer_obj) : JString
{#>>
	return( jni->NewString( this.Ivalue[:] ) );  #return a copy
}#<<

get_chars_aC( this : ref StringBuffer_obj) : JArrayC
{#>>
	# return a char array
	l     := len this.Ivalue;
	chars := array[l] of int;
	for( x:=0; x<l; x++ )
		chars[x] = this.Ivalue[x];

	return( jni->MkAChar( chars ) );
}#<<

#
# the next two functions are for serialization
#

#
# write this.Ivalue (a Dis string) to an ObjectOutputStream as a char[]
#

writeObject0_rObjectOutputStream_V(this : ref StringBuffer_obj, p0 : JObject)
{#>>
	jaryc := jni->StringToAChar(this.Ivalue);
	args := array[] of {
		ref Value.TObject(cast->FromJArray(cast->IntToJArray(jaryc)))
	};
	jni->CallMethod(p0, "writeObject", "(Ljava/lang/Object;)V", args);
}#<<

#
# read a char[] from an ObjectInputStream and convert it to a Dis string
#

readObject0_rObjectInputStream_V(this : ref StringBuffer_obj, p0 : JObject)
{#>>
	jaryc : JArrayC;

	(val, ok) := jni->CallMethod(p0, "readObject", "()Ljava/lang/Object;", nil);
	if(ok == JNI->OK) {
		pick v := val {
			TObject =>
				jaryc = cast->ToJArrayC(v.jobj);
		}
	}
	if(jaryc == nil || len jaryc.ary < this.count)
		jni->ThrowException("java.io.IOException", "bad StringBuffer object serialized");

	# JavaSoft JVM serializes trailing null characters; we can ignore
	for(i := 0; i < this.count; i++)
		this.Ivalue[i] = jaryc.ary[i];
}#<<

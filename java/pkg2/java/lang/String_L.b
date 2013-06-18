implement String_L;

# javal v1.6 generated file: edit with care

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

#<<

include "String_L.m";

#>> extra post includes here
include "hash.m";

str  : String;
hash : Hash;

#
# the following are for the intern() method
# a pool of all Java String classes is maintained
# hashed on the actual string contents. For any
# given actual string the same Java String object
# should be returned. We maingain a hash table
# of String objects, hashed on the string value.
#
PSZ  :  con 31;
pool := array[PSZ] of list of JString;

PoolAdd( jstr : JString )
{
	idx := hash->fun1(jstr.str,PSZ);
	pool[idx] = jstr :: pool[idx];
}

PoolGet( val : JString ) : JString 
{
	# search for an existing object with same value
	for( l := pool[hash->fun1(val.str,PSZ)]; l != nil; l = tl l )
	{
		jstr := hd l;
		if (jstr.str == val.str)
			return( jstr );
	}

	# could not find so add this class
	PoolAdd( val );
	return( val );
}

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
	str = jni->str;
	hash = load Hash Hash->PATH;
	if ( hash == nil )
		jni->InitError( jni->sys->sprint( "java.lang.String: could not load %s: %r", Hash->PATH ) );
    #<<
}

length_I( this : JString) : int
{#>>
	return( len this.str );
}#<<

charAt_I_C( this : JString, p0 : int) : int
{#>>
	if ((this.str == nil) || (p0 > (len this.str -1)) || (p0 < 0))
		jni->ThrowException( "java.lang.StringIndexOutOfBoundsException", string p0 );
	return( this.str[p0] );
}#<<

getChars_I_I_aC_I_V( this : JString, p0 : int,p1 : int,p2 : JArrayC,p3 : int)
{#>>
	# fill the char array with each char from the string

	# do some checking first
	if ( p0 < 0 ) 
		jni->ThrowException( "java.lang.StringIndexOutOfBoundsException", string p0 );
	if ( p1 > len this.str ) 
		jni->ThrowException( "java.lang.StringIndexOutOfBoundsException", string p1 );
	if ( p0 > p1 ) 
		jni->ThrowException( "java.lang.StringIndexOutOfBoundsException", string (p1-p0) );

	# now check array and copy chars into
	copy_count := p1-p0;   # number of chars to copy

	#STD?? I will just throw an exception here if I know 
	# I will overwrite the array bounds. To really be
	# legit I may need to copy upto the end and then throw
	if ( (copy_count + p3) > (len p2.ary) )
		jni->ThrowException( "java.lang.ArrayIndexOutOfBoundsException", string (len p2.ary) );

	# now copy chars from this string into
	# the char array, starting at the indicated
	# position (p3) of the char array.
	for( x:=0; x<copy_count; x++ )
		p2.ary[p3+x] = this.str[p0+x];
		
}#<<

equality_rString_Z_Z( this : JString, p0 : JString,p1 : int) : int
{#>>
	if ( p0 == nil )
		return( JNI->FALSE );

	if ( this.str == p0.str )
		return( JNI->TRUE );

	# check if we should ignore case
	if ( p1 )
		return( str->toupper(this.str) == str->toupper(p0.str) );

	# strings not equal
	return( JNI->FALSE );

}#<<

compareTo_rString_I( this : JString, p0 : JString) : int
{#>>
	# compare 'p0' to this.  
	# return:  0 => equal
	#         <0 => this < p0
	#         >0 => this > p0

	this_str := this.str;
	other    := p0.str;

	# simple equlity check
	if ( this_str == other )
		return( 0 );

	# otherwise, determine if "this" is
	# lexicographically smaller than "other"
		
	this_len  := len this_str;
	other_len := len other;
	min       := 0;
	if ( this_len < other_len )
		min = this_len;
	else
		min = other_len;

	# find char where strings differ
	x:=0;
	while( (x<min) && (this_str[x]==other[x]) ) x++;

	# is one string a proper prefix of the other?
	if(x == min)
		return this_len - other_len;

	# if some chars were common then "this" is
	# smaller if the character where they differ
	# has a smaller value than "other"
	return( this_str[x] - other[x] );
}#<<

regionMatches_Z_I_rString_I_I_Z( this : JString, p0 : int,p1 : int,p2 : JString,p3 : int,p4 : int) : int
{#>>
	# p0 => ignore case==1
	# p1 => this start index
	# p2 => other string
	# p3 => other start index
	# p4 => length to compare

	# check params
	if ( (p1<0) || (p1 > (len this.str - p4)) ||
	     (p3<0) || (p3 > (len p2.str - p4))     )
		return( jni->FALSE );

	this_str, other : string;
	
	this_last  := (p1+p4);
	other_last := (p3+p4);

	if ( int p0 == 1 )
	{
		# ignore case
		this_str = str->toupper(this.str[p1:this_last]);
		other    = str->toupper(p2.str[p3:other_last]);
	}
	else
	{
		# case sensitive
		this_str = this.str[p1:this_last];
		other    = p2.str[p3:other_last];
	}

	# now compare the two substrings
	return( this_str == other );
}#<<

hashCode_I( this : JString) : int
{#>>
	# hashcode of string as defined in JLS
	strhash     := 0;
	this_str := this.str;
	this_len := len this_str;
	
	if ( this_len <= 15 )
	{
		for(x:=0; x<this_len; x++)
			strhash = (strhash*37) + this_str[x];
	}
	else
	{
		k := int (this_len/8);
		for(x:=0; x < this_len; x+=k)
			strhash = (strhash*39) + this_str[x];
	}

	return( strhash );
}#<<

substring_I_I_rString( this : JString, p0 : int,p1 : int) : JString
{#>>
	# return string composed of chars p0..p1-1 both
	# java and limbo allow the p1 to be (len this.str)
	this_len := len this.str;
	if ( (p0 < 0) || (p1 > this_len) || (p0 > p1) )
		jni->ThrowException( "java.lang.StringIndexOutOfBoundsException", 
			                 jni->sys->sprint( "len=%d begin=%d end=%d", this_len, p0, p1 ) );

	return( jni->NewString( this.str[p0:p1] ) );
}#<<

concat_rString_rString( this : JString, p0 : JString) : JString
{#>>
	if ( p0 == nil ) 
		jni->ThrowException( "java.lang.NullPointerException", "concat arg is null" );

	# as defined in JLS: if p0 is 0 len return ref to this
	if ( (len p0.str) == 0 )
		return( this );

	# return a new string composed of this+p0
	return( jni->NewString( this.str + p0.str ) );
}#<<

replace_C_C_rString( this : JString, p0 : int,p1 : int) : JString
{#>>
	# p0 => old char, p1 => new char
	# if p0 does not exist in this then
	# return reference to this
	# otherwise return a new string which
	# is composed of the 'this' with all
	# old char's (p0) replaced with new chars (p1)

	newstr := this.str[:];
	found  := 0;
	for(x:=0; x<(len newstr); x++)
	{
		if ( newstr[x] == p0 )
		{
			found = 1;
			newstr[x] = p1;
		}
	}

	if ( ! found )
		return( this );

	return( jni->NewString( newstr ) );
}#<<

trim_rString( this : JString) : JString
{#>>
	# as defined in JLS
	if ( this.str == "" ) 
		return( this );

	this_str := this.str;
	if ( (this_str[0] > '\u0020') && (this_str[len this_str-1] > '\u0020') )
		return( this );
	
	# look for first char > \u0020
	for( x:=0; x<(len this_str); x++ )
		if ( this_str[x] > '\u0020' ) break;

	# if no chars < \u0020 found return a new "empty string"
	if ( x == len this_str )
		return( jni->NewString( "" ) );

	first := x;

	# look for last char > \u0020
	for( x=(len this_str -1); x >= 0; x-- )
		if ( this_str[x] > '\u0020' ) break;

	last := x;  # this has to be at least ==first

	return( jni->NewString( this_str[first:last+1] ) );

}#<<

intern_rString( this : JString) : JString
{#>>
	# as defined in JLS
	# need to maintain a private pool of String
	# objects and return the same object for a
	# given string
	return( PoolGet( this ) );
}#<<

utfLength_I( this : JString) : int
{#>>
	b : array of byte;
	b = array of byte this.str;
	return( len b );
}#<<

fill_aC_I_I_V( this : JString, p0 : JArrayC,p1 : int,p2 : int)
{#>>
	#
	# create a newstring from the array of int
	# 
	
	# check array length
	if ( (p1+p2) > len p0.ary )
		jni->ThrowException( "java.lang.ArrayIndexOutOfBoundsException", string (len p0.ary) );
	
	this.str = nil; # get rid of what is there

	# now append each char to the string value
	# Lecuona correction: for( x:=0; x<(p2-p1); x++ )
	for( x:=0; x<p2; x++ )
		this.str[x] = p0.ary[x+p1];
}#<<

isPrefix_rString_I_Z( this : JString, p0 : JString,p1 : int) : int
{#>>
	# p0 => string to compare
	# p1 => start index 

	# do some checking
	if ( p0 == nil )
		jni->ThrowException( "java.lang.NullPointerException", "String.isPrefix()" );
	other_len := len p0.str;
	endix := other_len + p1;	# can overflow
	if ( p1 < 0 || endix > len this.str || endix < 0 )
		return( jni->FALSE );
	if ( other_len == 0 )
		return( jni->TRUE );	# JLS defined
	return( p0.str == this.str[p1:p1+other_len] );
}#<<

isSuffix_rString_Z( this : JString, p0 : JString) : int
{#>>
	start := (len this.str) - (len p0.str);
	if ( start < 0 )
		return( jni->FALSE );

	return( p0.str == this.str[start:] );
}#<<

uppercase_rString( this : JString) : JString
{#>>
	return( jni->NewString( str->toupper(this.str) ) );
}#<<

lowercase_rString( this : JString) : JString
{#>>
	return( jni->NewString( str->tolower(this.str) ) );
}#<<

index_rString_I_I( this : JString, p0 : JString,p1 : int) : int
{#>>
	# p0 => string to match
	# p1 => index to start search from
	# p2 => searche left-right=1 right-left=0
	this_str  := this.str;
	this_len  := len this_str;
	other     := p0.str;
	other_len := len other;

	# if other > this then it can't be a substring
	if ( other_len > this_len )
		return( -1 );

	# if start index <0 make it 0, if > len return -1
	from := 0;
	if ( p1 > 0 )
	{
		from = p1;
		# this also handles p1 > this_len
		# which will return -1 below, we
	}

	# null string always matches
	if ( other_len == 0 )
		return from;

	# determine char of this to stop searching on
	stop_char := this_len - other_len;

	# look for first-char match then
	# match the substring.
	for( i:=from; i <= stop_char; i++ )
		if ( (this_str[i] == other[0]) &&
			 (this_str[i:i+other_len] == other) )
			return( i );

	# match failed
	return( -1 );
}#<<

index_I_I_I( this : JString, p0 : int,p1 : int) : int
{#>>
	# p0 => char to match
	# p1 => start index

	this_str  := this.str;
	this_len  := len this_str;

	# if start index <0 make it 0, if > len return -1
	from := 0;
	if ( p1 > 0 )
		from = p1;

	# start from left, 
	# look for first match
	for( i:=from; i < this_len; i++ )
		if ( this_str[i] == p0 )
			return( i );

	# match failed
	return( -1 );
}#<<

rindex_rString_I_Z_I( this : JString, p0 : JString,p1 : int,p2 : int) : int
{#>>
	# p0 => string to match
	# p1 => index to start search from
	# p2 => 1 == search from end (ignore p1)
	this_str  := this.str;
	this_len  := len this_str;
	other     := p0.str;
	other_len := len other;

	# if other > this then it can't be a substring
	if ( other_len > this_len )
		return( -1 );

	# if start index > this_len-other_len make it this_len-other_len
	# if < 0 return -1
	from := this_len - other_len;
	if ( (p2 != 1) && (p1 < from) )
	{
		from = p1;  
		# this also handles the defined case
		# of p1 < 0 is the same as p1==-1 and
		# will return -1 below
	}

	# start from end
	if ( other_len == 0 )
		return( from ); # empty string always matches

	# look for first char match starting from right
	# then match the substring
	for( i:=from; i >= 0; i-- )
		if ( (this_str[i] == other[0]) &&
			 (this_str[i:i+other_len] == other) )
			return(i);

	return(-1); #no match
}#<<

rindex_I_I_Z_I( this : JString, p0 : int,p1 : int,p2 : int) : int
{#>>
	# p0 => char to match
	# p1 => start index
	# p2 => 1 == scan from (len this.str -1)

	this_str  := this.str;

	# if start index < 0 return -1, if > len this.str make it the length
	from := len this_str - 1;
	if ( (p2 != 1) && (p1 < from) )
	{
		from = p1;
	}

	# start from right
	# look for first match 
	for( i:=from; i >= 0; i-- )
		if ( this_str[i] == p0 )
			return(i);

	# match failed
	return( -1 );
}#<<




implement CharToByteConverter_L;

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

#<<

include "CharToByteConverter_L.m";

#>> extra post includes here
include "converter.m";

alias : EncoderAlias;



#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
	#
	# load the encoder alias table
	#
	alias = load EncoderAlias EncoderAlias->PATH;
	if ( alias == nil )
		jni->InitError( jni->sys->sprint( "CharToByteConverter: could not load %s:%r", EncoderAlias->PATH ) );

    #<<
}

Init_rString_V( this : ref CharToByteConverter_obj, p0 : JString)
{#>>
	# this is called each time an encoder instance is created. 
	#   p0 -- the name of the encoder to use
	name := "8859_1";
	if ( p0 != nil )
	{
		tmp := alias->lookup( p0.str );
		if ( tmp != nil )
			name = tmp;
		else
			name = p0.str;
	}

	# load the encoder module
	mod_name := Converter->PREFIX + name + ".dis";
	convert  := load Converter mod_name;
	if ( convert== nil )
	{
		jni->ThrowException( "java.io.UnsupportedEncodingException", 
			                 jni->sys->sprint( "could not load %s:%r", mod_name ) );
	}
	# initialize the encoder

	err := convert->init();
	if ( err != nil )
		jni->ThrowException( "java.io.UnsupportedEncodingException", 
			                 jni->sys->sprint( "could not init %s", mod_name ) );

	# store in object data
	this.convert = convert;
		
}#<<

convert_aC_I_I_aB_I_I_I( this : ref CharToByteConverter_obj, p0 : JArrayC,p1 : int,p2 : int,p3 : JArrayB,p4 : int,p5 : int) : int
{#>>
	# check array params
	if ( (p0==nil) || (p3==nil) )
		jni->ThrowException( "java.lang.NullPointerException", "parameters null" );

	chars             := p0.ary;   #chars to convert
	(inStart,inEnd)   := (p1,p2);  #slice of chars
	output            := p3.ary;   #output byte array
	(outStart,outEnd) := (p4,p5);  #slice of array

	# check indicated array sizes
	if ( (inStart < 0) || (outStart<0) || (inEnd > len chars) || (outEnd > len output) )
		jni->ThrowException( "java.lang.ArrayIndexOutOfBoundsException", "bad parameters" );

	# try conversion
	this.convert->char_off = inStart;
	this.convert->byte_off = outStart;

	(rc,count) := this.convert->toBytes( chars[inStart:inEnd], output[outStart:outEnd] );

	# check for errors
	case ( rc )
	{
		Converter->RC_MALFORMED => jni->ThrowException( "sun.io.MalformedInputException", "bad character sequence" );
		Converter->RC_UNKNOWN   => jni->ThrowException( "java.io.UnknownCharacterException", "no character mapping" );
		Converter->RC_BUFFULL   => jni->ThrowException( "sun.io.ConversionBufferFullException", "output buffer too small" );
	}

	# no errors 
	return( count );

}#<<

convertAll_aC_aB( this : ref CharToByteConverter_obj, p0 : JArrayC) : JArrayB
{#>>
	# check param
	if ( p0 == nil )
		jni->ThrowException( "java.lang.NullPointerException", "parameters null" );

	chars := p0.ary;

	# set submode
	oldMode := this.convert->submode;
	this.convert->submode = jni->TRUE;

	# create buffer to hold all chars
	output := array[ (len chars * this.convert->maxBPC()) ] of byte;

	# try conversion
	this.convert->char_off = 0;
	this.convert->byte_off = 0;

	(rc,count) := this.convert->toBytes( chars, output );

	# reset sub mode
	this.convert->submode = oldMode;

	# check for errors
	case ( rc )
	{
		Converter->RC_MALFORMED => jni->ThrowException( "sun.io.MalformedInputException", "bad character sequence" );
		Converter->RC_UNKNOWN   => jni->ThrowException( "java.io.UnknownCharacterException", "no character mapping" );
		Converter->RC_BUFFULL   => jni->ThrowException( "sun.io.ConversionBufferFullException", "output buffer too small" );
	}

	# no errors -- create new array, copy bytes, and return
	buf   := array[count] of byte;
	buf[:] = output[:count]; 
	return( jni->MkAByte( buf ) );

}#<<

flush_aB_I_I_I( this : ref CharToByteConverter_obj, p0 : JArrayB,p1 : int,p2 : int) : int
{#>>
	# looks like this is never really used, since input chars are not
	# being buffered ??? just reset.

	this.convert->reset();
	return(0);

	junk := (p0,p1,p2);

}#<<

reset_V( this : ref CharToByteConverter_obj)
{#>>
	this.convert->reset();
}#<<

canConvert_C_Z( this : ref CharToByteConverter_obj, p0 : int) : int
{#>>
	return( this.convert->isMapped( p0 ) );
}#<<

getMaxBytesPerChar_I( this : ref CharToByteConverter_obj) : int
{#>>
	return( this.convert->maxBPC() );
}#<<

getBadInputLength_I( this : ref CharToByteConverter_obj) : int
{#>>
	return( this.convert->bad_len );
}#<<

nextCharIndex_I( this : ref CharToByteConverter_obj) : int
{#>>
	return( this.convert->char_off );
}#<<

nextByteIndex_I( this : ref CharToByteConverter_obj) : int
{#>>
	return( this.convert->byte_off );
}#<<

setSubstitutionMode_Z_V( this : ref CharToByteConverter_obj, p0 : int)
{#>>
	this.convert->submode = p0;
}#<<

setSubstitutionBytes_aB_V( this : ref CharToByteConverter_obj, p0 : JArrayB)
{#>>
	if ( (p0 == nil) || (p0.ary == nil) )
		jni->ThrowException( "java.lang.NullPointerException", "bad parameters" );

	subs := p0.ary;

	if ( len subs > this.convert->maxBPC() )
		jni->ThrowException( "java.lang.IllegalArgumentException", "substitution byte array too long" );

	this.convert->subbytes    = array[len subs] of byte;
	this.convert->subbytes[:] = subs[:];  #copy contents
}#<<

getCharacterEncoding_rString( this : ref CharToByteConverter_obj) : JString
{#>>
	return( jni->NewString(this.convert->name) );
}#<<

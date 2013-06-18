#
# An encoder for ASCII7
#
implement Converter;

include "sys.m";
include "converter.m";

# module private constants

NAME : con "ASCII7";
BPC  : con 1;

SUBCHARS := array[] of {'\uFFFD'};
SUBBYTES := array[] of {byte '?'};

# module private data
isInitialized : int;


# Peform initialization. This should only
# be called once after loading and before
# its first use.  If called a second time
# an error will result.  If it is not called
# before being used, then the module behavior
# is undefined.
# return nil==no err else err message.
init() : string
{
	# set module instance data

	name     = NAME;
	
	reset();

	return( nil );
}


toBytes( input    : array of int,        #chars to convert
	     output   : array of byte        #store bytes here
	   ) : (int,int)                     #RC, bytes written
{
	inEnd  := len input;
	outEnd := len output;
	j := 0;
	for (i := 0; i < inEnd; i++) 
	{
		if (j >= outEnd)
		{
			byte_off += j;
			char_off += i;
			return( RC_BUFFULL, 0 );
		}
		output[j] = byte (input[i] & 16r7f);
		j++;
	}

	byte_off += j;
	char_off += inEnd;
	
	return( RC_OK, j );
}


toChars( input    : array of byte,       #bytes to convert
	     output   : array of int         #store chars here
	   ) : (int,int)                     #RC, bytes written
{
	inEnd  := len input;
	outEnd := len output;
	j      := 0;

	for (i := 0; i < inEnd; i++) 
	{
	    if (j >= outEnd) 
		{
			byte_off = i;
			char_off = j;
			return( RC_BUFFULL, 0 );
	    }
	    output[j] = (int input[i]) & 16r7f;
		j++;
	}
	byte_off = inEnd;
	char_off = j;
	return(RC_OK, j);
}


#
# return the maximum bytes per char (BPC) for the encoding
#
maxBPC() : int
{
	return( BPC );
}


#
# can a character be mapped?
#
isMapped( ch : int ) : int
{
	junk := ch;
	return( 1 );
}


#
# reinitialize module instance data. If this is called
# prior to init() then it is equivalent to calling init().
#
reset()
{
	submode  = 1;
	subbytes = array[] of {byte '0'};
	subchars = array[] of {'?'};
	
	char_off = byte_off = bad_len = 0;

	isInitialized = 1;
}	


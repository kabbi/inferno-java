#
# An encoder for ASCII7
#
implement Converter;

include "sys.m";
include "converter.m";

# module private constants

NAME : con "8859_1";
BPC  : con 1;

SUBCHARS := array[] of {'\uFFFD'};
SUBBYTES := array[] of {byte '?'};

# module private data
isInitialized : int;

highHalfZoneCode := 0;


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
	
	outOff := char_off;

	inputChar : int;          # Input character to be converted
	outputByte : array of byte ;    # Output byte written to output
	tmpArray   := array[1] of byte;

	inputSize  := 0;   # Size of input
	outputSize := 0;   # Size of output	

	if (highHalfZoneCode != 0) 
	{
		inputChar = highHalfZoneCode;
		highHalfZoneCode = 0;
		if (input[char_off] >= 16rdc00 && input[char_off] <= 16rdfff) 
		{
			# This is legal UTF16 sequence.
			bad_len = 1;
			return( RC_UNKNOWN, 0 );
		} 
		else 
		{
			# This is illegal UTF16 sequence.
			bad_len  = 0;
			return( RC_MALFORMED, 0 );
		}
	}

	# Loop until we hit the end of the input
	while(char_off < inEnd) 
	{
		outputByte = tmpArray;

		# Get the input character
		inputChar = input[char_off];

		# default outputSize
		outputSize = 1;

		# Assume this is a simple character
		inputSize = 1;

		# Is this a high surrogate?
		if(inputChar >= '\uD800' && inputChar <= '\uDBFF') 
		{
			# Is this the last character in the input?
			if (char_off + 1 == inEnd) 
			{
				highHalfZoneCode = inputChar;
				break;
			}

			# Is there a low surrogate following?
			inputChar = input[char_off + 1];
			if (inputChar >= '\uDC00' && inputChar <= '\uDFFF') 
			{
				# We have a valid surrogate pair.  Too bad we don't map
				#  surrogates.  Is substitution enabled?
				if (submode) 
				{
					outputByte = subbytes;
					outputSize = len subbytes;
					inputSize = 2;
				} 
				else 
				{
					bad_len = 2;
					return( RC_UNKNOWN, 0 );
				}
			} 
			else 
			{
				# We have a malformed surrogate pair
				bad_len = 1;
				return( RC_MALFORMED, 0 );
			}
		}
		# Is this an unaccompanied low surrogate?
		else if (inputChar >= '\uDC00' && inputChar <= '\uDFFF') 
		{
			bad_len = 1;
			return( RC_MALFORMED, 0 );
		}
		# Not part of a surrogate, so try to convert
		else 
		{
			# Is this character mappable?
			if (inputChar <= '\u00FF') 
			{
				outputByte[0] = byte inputChar;
			} 
			else 
			{
				# Is substitution enabled?
				if (submode) 
				{
					outputByte = subbytes;
					outputSize = len subbytes;
				} 
				else 
				{
					bad_len = 1;
					return( RC_UNKNOWN, 0 );
				}
			}
		}

		# If we don't have room for the output, throw an exception
		if ( (byte_off + outputSize) > outEnd)
			return( RC_BUFFULL, 0 );

		# Put the byte in the output buffer
		for (i := 0; i < outputSize; i++) 
		{
			output[byte_off++] = outputByte[i];
		}
		char_off += inputSize;
	}

	# Return the length written to the output buffer
	return( RC_OK, byte_off-outOff );
}


toChars( input    : array of byte,       #bytes to convert
	     output   : array of int         #store chars here
	   ) : (int,int)                     #RC, bytes written
{
	# Loop until we hit the end of the input
	for( (i,j):=(0,0); i < len input; i++ )
	{
		byte_off++;  #increment buffer index

		# If we don't have room for the output, throw an exception
		if ( j >= len output )
			return( RC_BUFFULL, 0 );

		# Convert the input byte
		input_val := int input[i];

		if ( input_val < 0 )
		{
			input_val += 256;
		}
		output[j] = input_val;

		j++;
		char_off++;
	}

	# Return the length written to the output buffer
	return( RC_OK, j );
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


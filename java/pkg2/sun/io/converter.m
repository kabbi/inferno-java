#
# Perform transformation to/from Unicode chars and
# bytes.  This module stores stat informatio in
# module data and thus a sing instance should not
# be used by more then one thread at a time.  Each
# thread can create its own instance of the module
# (i.e. load), thus getting its own instance data
# yet sharing code.
#

Converter : module
{
	# the prefix of character encoding converstion modules
	# to load a conversion module construct its name from
	#   PREFIX + <name> + ".dis";
	PREFIX : con "/dis/java/sun/io/Cvt";

	name     : string;         # encoder name
	submode  : int;            # substitution mode flag
	subbytes : array of byte;  # bytes to substitute for unmappable chars
	subchars : array of int;   # chars to substitute for unmappable bytes
	char_off : int;            # offset of next char to be converted
	byte_off : int;            # offset of next byte to be output
	bad_len  : int;            # length of bad input that stopped conversion

	# the conversion fct return code (RC)
	RC_OK,         # conversion ok 
	RC_MALFORMED,  # malformed input
	RC_UNKNOWN,    # unknown input
	RC_BUFFULL     # output buffer full
		           : con iota;

	#
	# toBytes
	# toChars
	#
	# These two functions convert from unicode characters
	# into an array of bytes; and from an array of bytes into
	# unicode characters.  The conversion is done using an 
	# implementation specific character encoding
	#
	# If 'submode' is true then unmappable bytes/chars or
	# replaced by 'subchars'/'subbytes'.  If 'submode'
	# is false then the function returns with an RC_UNKNOWN.
	#
	# The module fields 'byte_off', 'char_off', and 'bad_len'
	# are updated to enable the same buffers to be used repeatedly.
	#
	# return: 
	#  (RC_OK, bytes written)
	#  (RC_MALFORMED, 0 ) -- input contained illegal unicode sequence
	#                        this.bad_len contains length of invalid input
	#  (RC_UNKNOWN, 0)    -- unmappable input chars, and not in substitution mode
	#  (RC_BUFFULL, 0)    -- output buffer not big enough
	#

	toBytes : fn( input    : array of int,        #chars to convert
				  output   : array of byte        #store bytes here
				) : (int,int);                    #RC, bytes written

	toChars : fn( input    : array of byte,       #bytes to convert
				  output   : array of int         #store chars here
				) : (int,int);                    #RC, bytes written

	#
	# return the maximum bytes per char (BPC) for the encoding
	#
	maxBPC  : fn() : int;		

	#
	# can a character be mapped?
	#
	isMapped : fn( ch : int ) : int;

	#
	# reinitialize module instance data. If this is called
	# prior to init() then it is equivalent to calling init().
	#
	reset   : fn();

	# Peform initialization. This should only
	# be called once after loading and before
	# its first use.  If called a second time
	# an error will result.  If it is not called
	# before being used, then the module behavior
	# is undefined.
	# return nil==no err else err message.
	init  : fn() : string;

};

EncoderAlias : module
{
	PATH : con "/dis/java/sun/io/encoderalias.dis";

	# return the proper name associated with the 
	# given alias; or nil
	lookup : fn( alias : string ) : string;
};

Rgetputfield:		con 16r1 << 16;
Rgetputstatic:		con 16r2 << 16;
Rinvokeinterface:	con 16r3 << 16;
Rinvokespecial:		con 16r4 << 16;
Rinvokestatic:		con 16r5 << 16;
Rinvokevirtual:		con 16r6 << 16;

Rstaticmp:		con 16r8 << 16;
Rspecialmp:		con 16r10 << 16;

PSRC:			con 16r1 << 2;	# patch source operand
PDST:			con 16r2 << 2;	# destination
PMID:			con 16r3 << 2;	# middle

PIMM:			con 16r0;	# patch immediate operand
PSIND:			con 16r1;	# single indirect offset
PDIND1:			con 16r2;	# 1st offset of double indirect
PDIND2:			con 16r3;	# 2nd offset

SAVEINST:		con 1;		# save 'ref Inst' for patching

# special fields
RCLASS:			con "@Class";
RADT:			con "@adt";
RJEX:			con "@jex";
RMP:			con "@mp";
RNP:			con "@np";
ROBJ:			con "@obj";
RSYS:			con "@sys";

# special class name
RLOADER:		con "@Loader";

Ipatch: adt {
	n:	int;			# no. of significant elts. in pinfo & i
	max:	int;			# number of elements pinfo & i can hold
	pinfo:	array of int;		# operand patch directives
	i:	array of ref Inst;	# instructions to patch (runtime relocation)
};

#
# Load-time relocation.
#

Freloc: adt {
	field:	string;			# field name
	sig:	string;			# Java type signature
	flags:	int;			# access flags
	ipatch:	ref Ipatch;		# instruction patch information
	next:	cyclic ref Freloc;
};

Creloc: adt {
	classname:	string;
	fr:		ref Freloc;
	tail:		ref Freloc;
	n:		int;		# number of elements in 'fr'
};

#
# Run-time relocation.
#

RTReloc: adt {
	field:		string;		# field name
	sig:		string;		# Java type signature
	flags:		int;		# access flags
	ipatch:		ref Ipatch;	# instruction patch information
	next:		cyclic ref RTReloc;
};

RTClass: adt {
	classname:	string;
	rtr:		ref RTReloc;
	tail:		ref RTReloc;
	n:		int;		# number of elements in 'rtr'
	off:		int;		# Module Data offset
};

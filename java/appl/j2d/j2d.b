implement J2d;

include "sys.m";
include "bufio.m";
include "draw.m";
include "keyring.m";
include "math.m";
include "string.m";
include "isa.m";

include "java.m";
include "javaisa.m";
include "reloc.m";

J2d: module {
	init: fn(nil: ref Draw->Context, argv: list of string);
};

include "arg.m";
include "main.b";
include "loader.b";
include "javadas.b";
include "bb.b";
include "datarloc.b";
include "ltreloc.b";
include "rtreloc.b";
include "mdata.b";
include "simjvm.b";
include "module.b";
include "entry.b";
include "desc.b";
include "links.b";
include "patch.b";
include "frame.b";
include "unify.b";
include "javatbl.b";
include "finally.b";
include "xlate.b";
include "asm.b";
include "dis.b";
include "sbl.b";
include "util.b";

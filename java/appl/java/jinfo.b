implement JInfo;

include "sys.m";
include "loader.m";
include "classloader.m";

JInfo: module
{
	init:	fn(ctxt: ref Draw->Context, argv: list of string);
};

sys:	Sys;

init(ctxt: ref Draw->Context, args: list of string)
{
	sys = load Sys Sys->PATH;
	cl := load JavaClassLoader JavaClassLoader->PATH;
	if (cl == nil) {
		sys->print("could not load %s: %r\n", JavaClassLoader->PATH);
		exit;
	}
	cl->init(cl, ctxt);
	for (l := tl args; l != nil; l = tl l)
		cl->info(hd l);
}

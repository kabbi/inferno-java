implement Loadertest;

include "sys.m";
	sys: Sys;
include "draw.m";
include "loader.m";
	loader: Loader;

Loadertest: module {
	init:	fn(ctxt: ref Draw->Context, args: list of string);
};

error(msg: string)
{
	sys->print("fail: %s\n", msg);
	exit;
}

badmodule(path: string)
{
	error(sys->sprint("cannot load module %s: %r", path));
}

usage(cmd: string)
{
	sys->print("Usage:\t%s <disfile>\n", cmd);
	exit;
}

init(ctxt: ref Draw->Context, args: list of string) {
	sys = load Sys Sys->PATH;
	loader = load Loader Loader->PATH;
	if (loader == nil)
		badmodule(Loader->PATH);

	if (len args != 2)
		usage(hd args);

	modpath := hd tl args;
	mod := load Nilmod modpath;
	if (mod == nil)
		badmodule(modpath);

	handlers := loader->handlers(mod);
	if (handlers == nil)
		error("cannot get handlers");

	printhandlers(handlers);

	sys->print("Setting handlers\n");
	result := loader->sethandlers(mod, handlers);
	if (result < 0)
		error("cannot set handlers");

	handlers = loader->handlers(mod);
	if (handlers == nil)
		error("cannot reload handlers");

	printhandlers(handlers);
}

printhandlers(handlers: array of Loader->Handler)
{
	for (i := 0; i < len handlers; i++) {
		h := handlers[i];
		sys->print("Handler %d-%d, eoff %d, type %d, %d exc\n",
			h.pc1, h.pc2, h.eoff, h.tdesc, len h.etab);
		for (j := 0; j < len h.etab; j++) {
			exname := "any";
			if (h.etab[j].e != nil)
				exname = h.etab[j].e;
			sys->print("\t'%s': %d\n", exname, h.etab[j].pc);
		}
	}
}

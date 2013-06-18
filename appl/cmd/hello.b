implement Hello;

include "sys.m";
	sys: Sys;
include "draw.m";
include "loader.m";
	loader: Loader;

Hello: module
{
	init:	fn(ctxt: ref Draw->Context, args: list of string);
};

hello: con "hello, world";

init(ctxt: ref Draw->Context, args: list of string)
{
	sys = load Sys Sys->PATH;
	sys->print("%s!\n", hello);
	loader = load Loader Loader->PATH;
	if (loader == nil)
	{
		sys->print("loader load fail\n");
		return;
	}

	if (len args != 2)
	{
		sys->print("Usage: %s <dis path>\n", hd args);
		return;
	}

	mod := load Nilmod hd tl args;
	if (mod == nil)
	{
		sys->print("%s load fail\n", hd tl args);
		return;
	}

	data := loader->imports(mod);
	if (data == nil)
	{
		sys->print("imports failed\n");
		return;
	}
	sys->print("%d imports:\n", len data);
	for (i := 0; i < len data; i++)
	{
		if (data[i] == nil)
		{
			sys->print("%dth array item is nil, fail", i);
			return;
		}
		sys->print("\t%d imports:\n", len data[i]);
		for (ii := 0; ii < len data[i]; ii++)
			sys->print("\timport[%d][%d]: %s, %uX\n", i, ii, data[i][ii].name, data[i][ii].sig);
	}
}

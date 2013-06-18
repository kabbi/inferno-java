#
#  %W% - %E%
#

implement FrameManager;

include "sys.m";
	sys: Sys;

include "string.m";
	str: String;

include "draw.m";
	draw: Draw;
	Context, Display, Point, Rect, Image, Screen: import draw;

include "tk.m";
	tk: Tk;
	Toplevel: import tk;

include	"wmlib.m";
	wmlib: Wmlib;

include	"awt_Frame.m";

screen: ref Screen;
display: ref Display;
ones: ref Image;
white: ref Image;
nochan: chan of string;
tHeight : int;
bWidth: int;

win_cfg := array[] of {
	"canvas .c -height 306 -width 406",
	"pack .c -side bottom -fill both -expand 1",
#	".c configure -side bottom -fill both -expand 1",
	"pack propagate . 0",
};

win_bind := array[] of {
	"bind # <Motion> {send butt m %b %X %Y}",
	"bind # <Leave> {send butt Leave}",
#	"bind # <ButtonPress> {focus #; send foc focus; send butt p %b %X %Y}",
	"bind # <ButtonPress> {focus #; send butt p %b %X %Y}",
	"bind # <ButtonRelease> {send butt r %b %X %Y}",
	"bind # <Double-Button> {send butt d %b %X %Y}",
	"bind # <Enter> {send butt Enter}",
	"bind # <KeyPress> {send key %K}",
#        "bind . <FocusIn> {send foc focus}",
#	"bind .Wm_t <Button-1> +{focus #; send foc focus}",
	"bind .Wm_t <Button-1> +{focus #}",
#	"bind .Wm_t.title <Button-1> +{focus #; send foc focus}",
	"bind .Wm_t.title <Button-1> +{focus #}",
};

modinit(ctxt: ref Context)
{
	if (sys != nil)
		return;

	sys = load Sys Sys->PATH;
	str = load String String->PATH;
	draw = load Draw Draw->PATH;
	tk = load Tk Tk->PATH;
	wmlib = load Wmlib Wmlib->PATH;
	nochan = chan of string;

	display = ctxt.display;
	screen = ctxt.screen;
	ones = display.ones;
	white = display.color(Draw->White);

	wmlib->init();
}
showwin(cv : ref Canvas)
{
	tk->cmd(cv.top, "pack " + cv.canvas);
}
makewin(ctxt: ref Context, title: string, x, y, width, height: int): ref Canvas
{
	modinit(ctxt);
	where := "-x " + string x + " -y " + string y;
	(t, menu) := wmlib->titlebar(screen, where, title, Wmlib->Appl);

# calculate topInset and boardwidth
        bWidth = int tk->cmd(t, ". cget -bd");
        tHeight = int tk->cmd(t, ". cget -height");



	if (width > 0 && height > 0)
                win_cfg[0] = "canvas .c -height " + string (height - tHeight - bWidth) +
	 " -width " + string (width - 2*bWidth);

#		win_cfg[0] = "canvas .c -height " + string height + " -width " + string width;

	wmlib->tkcmds(t, win_cfg);
	return alloccanvas(t, ctxt, ".c", menu);
}

resizewin(cv: ref Canvas, x, y, width, height : int)
{
}

alloccanvas(t: ref Toplevel, ctxt: ref Draw->Context, canvas: string, menu: chan of string): ref Canvas
{
	cmd := chan of string;
	tk->namechan(t, cmd, "cmd");
	butt := chan of string;
	tk->namechan(t, butt, "butt");
#	mouse := chan of string;
#	tk->namechan(t, mouse, "mouse");

	key := chan of string;
	tk->namechan(t, key, "key");

	foc := chan of string;
	tk->namechan(t, foc, "foc");

	tk->cmd(t, "bind . <Configure> {send cmd resize}");
	tk->cmd(t, "bind . <Map> {send cmd map}");

	for (i := 0; i < len win_bind; i++)
		tk->cmd(t, expand(win_bind[i], canvas));

	tk->cmd(t, "update");

	c := ref Canvas;
	display = ctxt.display;
	c.image = display.image;
	c.rect = canvposn(t, canvas);
	c.buf = display.newimage(c.image.r, c.image.ldepth , 0, Draw->White);
	c.events = chan of ref Event;
	c.top = t;
	c.ctxt = ctxt;
	c.canvas = canvas;
	c.pid = sys->pctl(0, nil);

# calculate topInset and boardwidth
	y1 := int tk->cmd(t, ". cget -acty") + int tk->cmd(t, ".dy get");
	y2 := int tk->cmd(t, ".c cget -acty") + int tk->cmd(t, ".dy get");

#	tHeight = int tk->cmd(t, ".Wm_t cget -actheight");
	tHeight = y2 - y1;
	bWidth = int tk->cmd(t, ". cget -bd");

	paint(c, c_canvposn(t, canvas));
	spawn handler(c, menu, cmd, butt, key, foc);
	return c;
}

hidewin(c: ref Canvas)
{
	tk->cmd(c.top, "pack forget " + c.canvas);
}

handler(c: ref Canvas, menu, cmd, butt, key, foc: chan of string)
{
	detail: string;
	t := c.top;
	if (menu == nil)
		menu = nochan;
	for (;;) alt {
	detail = <- menu =>
		case detail {
		"exit" =>
			c.events <- = ref Event(Event.Shutdown, nil);
		"task" =>
			c.events <- = ref Event(Event.Icon, nil);
#		"move" =>
#			sys->print("===== moving \n");
		* =>
			;
		}
		wmlib->titlectl(c.top, detail);

	detail = <- cmd =>
		(n, word) := sys->tokenize(detail, " ");
		case hd word {
		"resize" or "map" =>
			c.rect = canvposn(t, c.canvas);
			paint(c, c_canvposn(t, c.canvas));
			e := Event.Resize;
			if (hd word == "map") {
				e = Event.DeIcon;
				tk->cmd(t, "focus " + c.canvas);
			}
			c.events <- = ref Event(e, nil);
		* =>
			;
		}
	detail = <- butt =>
			
		c.events <- = ref Event(Event.Button, detail);
	detail = <- key =>
		c.events <- = ref Event(Event.Key, detail);
#	detail = <- foc =>
#		c.events <- = ref Event(Event.Focus, detail);

	}
}

expand(cmd, canvas: string): string
{
	s: string;
	for (;;) {
		(l, r) := str->splitl(cmd, "#");
		s = s + l;
		if (r == nil)
			return s;
		s = s + canvas;
		cmd = r[1:];
	}
}

paint(c: ref Canvas, r: Rect)
{
	c.image.draw(r, white, ones, (0, 0));
}

c_canvposn(t: ref Toplevel, c: string): Rect
{
	r: Rect;

	r.min.x = int tk->cmd(t, c + " cget -actx") + int tk->cmd(t, ".dx get");
	r.min.y = int tk->cmd(t, c + " cget -acty") + int tk->cmd(t, ".dy get");
	r.max.x = r.min.x + int tk->cmd(t, c + " cget -actwidth") + int tk->cmd(t, ".dw get");
	r.max.y = r.min.y + int tk->cmd(t, c + " cget -actheight") + int tk->cmd(t, ".dh get");
	return r;
}
canvposn(t: ref Toplevel, c: string): Rect
{
	r: Rect;

	r.min.x = int tk->cmd(t, ". cget -actx") + int tk->cmd(t, ".dx get");
	r.min.y = int tk->cmd(t, ". cget -acty") + int tk->cmd(t, ".dy get");
	r.max.x = r.min.x + int tk->cmd(t, ". cget -actwidth") + int tk->cmd(t, ".dw get");
	r.max.y = r.min.y + int tk->cmd(t, ". cget -actheight") + int tk->cmd(t, ".dh get");
	return r;
}
getInsets(): (int, int)
{
	return (bWidth, tHeight);
}

mapCanvas(dimg : ref Image, wimg : ref Image)
{
	dimg.draw(dimg.r, wimg, ones, dimg.r.min);
}
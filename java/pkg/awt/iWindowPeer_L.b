implement iWindowPeer_L;

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
        JObject : import jni;

#>> extra pre includes here
#
#  %W% - %E%
# 
	cast : Cast;
	sys : Sys;
        draw: Draw;
        Context, Screen, Display, Rect, Font, Point, Image: import draw;

include "tk.m";
	tk: Tk;
	Toplevel: import tk;

include	"wmlib.m";
	wmlib: Wmlib;
 
include "awt_Color.m";
        awt : AwtColor;
#<<

include "iWindowPeer_L.m";

#>> extra post includes here
	str : String;
	Value : import jni;
	ctxt : ref Draw->Context;
	cvm : ref Canvas;
#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
        sys = jni->sys;
        str = load String String->PATH;
        awt = load AwtColor AwtColor->PATH;
        cast = jni->CastMod();
        ctxt = jni->getContext();
    #<<
}

getRefImage_rObject( this : ref iWindowPeer_obj) : ref Draw->Image
{#>>
	return this.pCanvas.image;
}#<<

getRefOffScreenImage_rObject( this : ref iWindowPeer_obj) : ref Draw->Image
{#>>
	return this.pCanvas.buf;
}#<<

pReshape_I_I_I_I_V( this : ref iWindowPeer_obj, p0 : int,p1 : int,p2 : int,p3 : int)
{#>>
	strcmd := ". configure -x " + 
		string p0 + " -y " + string p1 + " -width " + string p2 + " -height " + string p3;
	
	tk->cmd(this.pCanvas.top, strcmd);
	tk->cmd(this.pCanvas.top, "update");
	this.pCanvas.image = this.pCanvas.top.image;	
}#<<

pHide_V( this : ref iWindowPeer_obj)
{#>>
	tk->cmd(this.pCanvas.top, ". unmap");
	this.pCanvas.image = nil;
}#<<

pShow_riWindowPeer_V( this : ref iWindowPeer_obj, p0: JObject)
{#>>
	tk->cmd(this.pCanvas.top, ". map");	
return; 
	args := array[0] of ref Value;
	(val, err) := jni->CallMethod(this.target, "repaint", "()V", args);
	if (err != jni->OK){
		sys->print( "CallMethod Error %d: repaint\n",err);
	}
}#<<

getXYLoc_I_I( this : ref iWindowPeer_obj, p0 : int) : int
{#>>
	if (p0 == 0)
		return cvm.rect.min.x;
	else
		return cvm.rect.min.y;
}#<<

create_riWindowPeer_V( this : ref iWindowPeer_obj, p0 : JObject)
{#>>
	xval := jni->GetObjField(this.target, "x", "I");
	yval := jni->GetObjField(this.target, "y", "I");
	wval := jni->GetObjField(this.target, "width", "I");
	hval := jni->GetObjField(this.target, "height", "I");
	
	x := xval.Int();
	y := yval.Int();
	w := wval.Int();
	h := hval.Int();

	makewin(ctxt, x, y, w, h, this, p0);

	this.topInset = 0;
	this.leftInset = 0;
	this.rightInset = 0;
	this.bottomInset = 0;
	this.left = this.pCanvas.rect.min.x;
	this.top = this.pCanvas.rect.min.y;

        tk->cmd(this.pCanvas.top, ". unmap");
	this.pCanvas.image = nil;
	
}#<<

pDispose_V( this : ref iWindowPeer_obj)
{#>>
	this.pCanvas.jtd <- = "Die!";
	
	this.pCanvas.top = nil;
	this.pCanvas.image = nil;
	this.pCanvas.buf = nil;
	this.pCanvas = nil;
}#<<

setCursor_I_V( this : ref iWindowPeer_obj, p0 : int)
{#>>
}#<<

toFront_V( this : ref iWindowPeer_obj)
{#>>
	this.pCanvas.image.top();
}#<<

toBack_V( this : ref iWindowPeer_obj)
{#>>
	this.pCanvas.image.bottom();
}#<<

#>> 
screen: ref Screen;
display: ref Display;
ones: ref Image;
white: ref Image;

	Event: adt
	{
		event:	int;
		detail:	string;

		Button, Key,
		Icon, DeIcon,
		Resize, Shutdown
			: con iota;
	};

	Attr: adt
	{
		origin:	Draw->Point;
		dims:		Draw->Point;
	};

	Canvas: adt
	{
		# interface
		image:	ref Draw->Image;
		buf:	ref Draw->Image;
		rect:		Draw->Rect;
		events:	chan of ref Event;
		attr:		ref Attr;
		jtd : chan of string;
		# implementation
		ctxt : ref Draw->Context;
		top:		ref Tk->Toplevel;
		canvas:	string;
		pid:		int;
	};
#<<

#>>
win_cfg := array[] of {
	"canvas .w -height 2 -width 2",
	"pack .w -side bottom -fill both -expand 1",
	"pack propagate . 0",
};

win_bind := array[] of {
	"bind # <Motion> {send butt m %b %X %Y}",
#	"bind # <Leave> {send butt Leave}",
	"bind # <ButtonPress> {focus #;send butt p %b %X %Y}",
	"bind # <ButtonRelease> {send butt r %b %X %Y}",
	"bind # <Double-Button> {send butt d %b %X %Y}",
#	"bind # <Enter> {send butt Enter}",
	"bind # <KeyPress> {send key %K}",
#        "bind . <FocusIn> {send foc focus}",
};

modinit(ctxt: ref Context)
{
	draw = load Draw Draw->PATH;
	tk = load Tk Tk->PATH;
	wmlib = load Wmlib Wmlib->PATH;

	screen = ctxt.screen;
	wmlib->init();
}

makewin(ctxt: ref Context, x, y, width, height: int, this: ref iWindowPeer_obj, job: JObject)
{
	modinit(ctxt);
	where := "-x " + string x + " -y " + string y;
	t := tk->toplevel(screen, "-borderwidth 0 -relief raised "+where);
#	(t, menu) := wmlib->titlebar(screen, where, title, Wmlib->Appl);

	if (width > 0 && height > 0)
		win_cfg[0] = "canvas .w -height " + string height + " -width " + string width;

	wmlib->tkcmds(t, win_cfg);
	ones = t.image.display.ones;
	white = t.image.display.color(Draw->White);
	alloccanvas(t, ctxt, ".w", this, job);
}

alloccanvas(t: ref Toplevel, ctxt: ref Draw->Context, canvas: string, this :ref iWindowPeer_obj, job: JObject)
{
	cmd := chan of string;
	tk->namechan(t, cmd, "cmd");
	butt := chan of string;
	tk->namechan(t, butt, "butt");

	key := chan of string;
	tk->namechan(t, key, "key");

	tk->cmd(t, "bind . <Configure> {send cmd resize}");
	tk->cmd(t, "bind . <Map> {send cmd map}");

	for (i := 0; i < len win_bind; i++)
		tk->cmd(t, expand(win_bind[i], canvas));

	tk->cmd(t, "update");
	
	c := ref Canvas;
	this.pCanvas = c;
	c = nil;
 
        bg := Draw->White;
        jcol := jni->GetObjField(this.target, "background", "Ljava/awt/Color;");
        if (jcol == nil) {
                sys->print("Cannot get background color\n");
        } else {
                color := jcol.Object();
                bg = awt->getColorIndex(jni, color);
        }

	this.pCanvas.image = t.image;
	display = t.image.display;	
	this.pCanvas.rect = canvposn(t, canvas);
	this.pCanvas.buf = ctxt.display.newimage(ctxt.display.image.r, 
                                this.pCanvas.image.ldepth , 0, bg);
	this.pCanvas.events = chan of ref Event;
	this.pCanvas.top = t;
	this.pCanvas.ctxt = ctxt;
	this.pCanvas.canvas = canvas;
	this.pCanvas.pid = sys->pctl(0, nil);

	spawn handler(cmd, butt, key, this, job);
}

handler(cmd, butt, key : chan of string, this : ref iWindowPeer_obj, job: JObject)
{

	detail: string;

	jtd := chan of string;
	this.pCanvas.jtd = jtd;

	for (;;) alt {
	detail = <- this.pCanvas.jtd => 
		return;
	detail = <- cmd =>
		(n, word) := sys->tokenize(detail, " ");
		case hd word {
		"map" =>
			this.pCanvas.image = this.pCanvas.top.image;
			handleRepaint(this);

		* =>
			;
		}

	detail = <- butt =>
		               doMouseEvent(job, detail);
	detail = <- key =>
			 (kchar, st) := str->toint(detail, 16);
			 args := array[1] of ref Value;
			 args[0] = ref Value.TInt(kchar);
			(val, err) := jni->CallMethod(job, "handleKeyEvents", "(I)V", args);
				if (err != jni->OK){
				sys->print( "CallMethod Error %d: handleKeyEvents\n",err);
			}
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

canvposn(t: ref Toplevel, c: string): Rect
{
	r: Rect;

	r.min.x = int tk->cmd(t, ". cget -actx") + int tk->cmd(t, ".dx get");
	r.min.y = int tk->cmd(t, ". cget -acty") + int tk->cmd(t, ".dy get");
	r.max.x = r.min.x + int tk->cmd(t, ". cget -actwidth") + int tk->cmd(t, ".dw get");
	r.max.y = r.min.y + int tk->cmd(t, ". cget -actheight") + int tk->cmd(t, ".dh get");
	return r;
}

doMouseEvent(job: JObject, detail : string)
{
	(n,toks) := sys->tokenize(detail," ");
	if (n != 4) return;
	mode := array of byte hd toks;
	toks = tl toks;
	button:=int hd toks;
	toks = tl toks;		
	x:=int hd toks;
	toks = tl toks;		
	y:=int hd toks;
    args := array[4] of ref Value;
    args[0] = ref Value.TInt(int mode[0]);
    args[1] = ref Value.TInt(button);
    args[2] = ref Value.TInt(x);
    args[3] = ref Value.TInt(y);
    (val, err) := jni->CallMethod(job, "handleMouseEvents", "(IIII)V", args);
    if (err != jni->OK){
        sys->print( "CallMethod Error %d: handleMouseEvents\n",err);
    }
}

handleRepaint(this : ref iWindowPeer_obj)
{
        args := array[0] of ref Value;
        (val, err) := jni->CallMethod(this.target, "repaint", "()V", args);
        if (err != jni->OK){
                sys->print( "CallMethod Error %d: repaint\n",err);
        }
}
#<<


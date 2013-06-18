implement iFramePeer_L;

# javal v1.5 generated file: edit with care

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
	JThread,
        JObject : import jni;

#>> extra pre includes here

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

include "iFramePeer_L.m";

#>> extra post includes here
	str : String;
	Value : import jni;
	ctxt : ref Draw->Context;
	title : string;

	# channel for receiving Tk events and "reallyExit" from dispose().
	cmdchan: chan of string;

	# 
	# the following was included from awt_Frame.b and sees varying
	# degrees of use.
	#

	screen: ref Screen;
	display: ref Display;
	ones: ref Image;
	white: ref Image;
	nochan: chan of string;
	tHeight : int;
	bWidth: int;
	last_x, last_y : int;

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
		dims:   Draw->Point;
	};

	Canvas: adt
	{
		# interface
		image:	ref Draw->Image;
		buf:	ref Draw->Image;
		rect:		Draw->Rect;
		events:	chan of ref Event;
		attr:		ref Attr;
		# implementation
		ctxt : ref Draw->Context;
		top:		ref Tk->Toplevel;
		canvas:	string;
		pid:		int;
	};
	# end of historical inclusions from awt_Frame.b
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

    # draw and tk are module refs that JNI may someday provide, saving a
    # Limbo load operation for every FramePeer construction
	draw = load Draw Draw->PATH;
	tk = load Tk Tk->PATH;
	wmlib = load Wmlib Wmlib->PATH;

	ctxt = jni->getContext();
	title = "Untitled";

	nochan = chan of string;
	screen = ctxt.screen;
	last_x = last_y = -10;
	wmlib->init();
    #<<
}

getRefImage_rObject( this : ref iFramePeer_obj) : ref Draw->Image
{#>>
	return this.pCanvas.image;
}#<<

getRefOffScreenImage_rObject(this :ref iFramePeer_obj) : ref Draw->Image
{#>>
	return this.pCanvas.buf;
}#<<

pReshape_I_I_I_I_V( this : ref iFramePeer_obj, p0 : int,p1 : int,p2 : int,p3 : int)
{#>>
	strcmd := ". configure -x " + string p0 + " -y " + string p1 + 
		  " -width " + string p2 + " -height " + string p3;
	
	tk->cmd(this.pCanvas.top, strcmd);
	tk->cmd(this.pCanvas.top, "update");
}#<<

pHide_V( this : ref iFramePeer_obj)
{#>>
    # Explicit filtering of input (mouse and keyboard) events shouldn't
    # be needed if Tk is doing it's job wrt "map" and "unmap".
	tk->cmd(this.pCanvas.top, ". unmap");	
	this.pCanvas.image = nil;
}#<<

pShow_riFramePeer_V( this : ref iFramePeer_obj, p0 : JObject)
{#>>
    # Window.show() has already produced a WINDOW_OPENED event
    # Tk\'s " . map" will result in a WINDOW_ACTIVATE event when it
    # directs focus to the newly mapped frame.

	tk->cmd(this.pCanvas.top, ". map");	
#	spawn doEvent(this, p0);
}#<<

getXYLoc_I_I( this : ref iFramePeer_obj,p0 : int) : int
{#>>
	if (p0 == 0)
		return this.pCanvas.rect.min.x;
	else
		return this.pCanvas.rect.min.y;
}#<<

create_riFramePeer_V( this : ref iFramePeer_obj, p0 : JObject)
{#>>
        # make's for easy punning around the Limbo type system.
        # two refs to same object: "this" and "thisAsJObject".
	this.thisAsJObject = p0; 

	t := jni->GetObjField(this.target, "title", "Ljava/lang/String;");

	if (t == nil)
		sys->print("Cannot get title\n");
	else{
		sobj := t.Object();
		c := jni->CastMod();
		js := cast->ToJString(sobj);
		title = js.str;
	}

	xval := jni->GetObjField(this.target, "x", "I");
	yval := jni->GetObjField(this.target, "y", "I");
	wval := jni->GetObjField(this.target, "width", "I");
	hval := jni->GetObjField(this.target, "height", "I");

	
	x := xval.Int();
	y := yval.Int();
	w := wval.Int();
	h := hval.Int();

	makewin(ctxt, title, x, y, w, h, this, p0);

	this.topInset = tHeight + bWidth + bWidth;
	this.leftInset = bWidth;
	this.rightInset = bWidth;
	this.bottomInset = bWidth;
	this.left = this.pCanvas.rect.min.x;
	this.top = this.pCanvas.rect.min.y;

        tk->cmd(this.pCanvas.top, ". unmap");
	this.pCanvas.image = nil;
}#<<

pDispose_V( this : ref iFramePeer_obj)
{#>>
    # sys->print("iFramePeer_L.pDispose_V(): entered on pid=%d\n", sys->pctl(0,nil));

    # request evenhandler's suicide, and sync until done
    cmdchan <- = "reallyExit"; 

    this.pCanvas = nil;
}#<<

setCursor_I_V( this : ref iFramePeer_obj, p0 : int)
{#>>
}#<<


setTitle_rString_V( this : ref iFramePeer_obj, p0 : JString)
{#>>
    title = p0.str;
    if (wmlib != nil && this.pCanvas != nil && this.pCanvas.top != nil &&
        title != nil)
    {

        # sys->print("iFramePeer_L.b.setTitle(): %s\n", title);

        # A change of title string to an iconfied Frmae will only be seen
        # after deiconification, as Inferno's wm provides no mechanism
        # to change the value displayed on the "taskbar" once a window's
        # been iconified, contrary to the commentary in appl/lib/wmlib.b
        wmlib->taskbar(this.pCanvas.top, title);  
    }
}#<<

toFront_V( this : ref iFramePeer_obj)
{#>>
	this.pCanvas.image.top();
}#<<

toBack_V( this : ref iFramePeer_obj)
{#>>
	this.pCanvas.image.bottom();
}#<<

#>>
doEvent(i : ref iFramePeer_obj, job : JObject)
{
#	cc := i.pCanvas;
        for (;;) {
                e := <- i.pCanvas.events;
                case e.event {
	                Event.Shutdown =>
        	                exit;
                	* =>
				;
                }
        }
}

javapainttarget(j : JObject, r : Draw->Rect)
{
	args := array[4] of ref Value;
	args[0] = ref Value.TInt(r.min.x);
	args[1] = ref Value.TInt(r.min.y);
	args[2] = ref Value.TInt(r.max.x - r.min.x + 1);
	args[3] = ref Value.TInt(r.max.y - r.min.y + 1);
	(val, err) := jni->CallMethod(j, "paintTarget", "(IIII)V", args);
	if (err != jni->OK){
		sys->print( "CallMethod Error %d: paintTarget\n",err);
	}
}

javamvsz(j : JObject, r : Draw->Rect)
{
	args := array[4] of ref Value;
	args[0] = ref Value.TInt(r.min.x);
	args[1] = ref Value.TInt(r.min.y);
	args[2] = ref Value.TInt(r.max.x - r.min.x + 1);
	args[3] = ref Value.TInt(r.max.y - r.min.y + 1);
	(val, err) := jni->CallMethod(j, "moveSize", "(IIII)V", args);
	if (err != jni->OK){
		sys->print( "CallMethod Error %d: moveSize\n",err);
	}
}
#<<


#>>
win_cfg := array[] of {
	"canvas .c -height 6 -width 6",
	"pack .c -side bottom -fill both -expand 1",
	"pack propagate . 0",
};

win_bind := array[] of {
	"bind . <Configure> {send cmd configure}",
	"bind . <Map> {send cmd map}", 
        "bind . <FocusIn> +{send cmd focusIn}",
        "bind . <FocusOut> +{send cmd focusOut}",
	"bind # <Motion> {send butt m %b %X %Y}",
	"bind # <Leave> {send butt Leave}",
	"bind # <ButtonPress> {focus #;send butt p %b %X %Y}",
	"bind # <ButtonRelease> {send butt r %b %X %Y}",
	"bind # <Double-Button> {send butt d %b %X %Y}",
	"bind # <Enter> {send butt Enter}",
	"bind # <KeyPress> {send key %K}",
	"bind .Wm_t <Button-1> +{send butt p %b %x %y}",
	"bind .Wm_t.title <Button-1> +{send butt p %b %x %y}",
	"bind .Wm_t <Button-1> +{focus #}",
	"bind .Wm_t.title <Button-1> +{focus #}",

        # Optional button 2 input focus to frame. Deviates from
        # current (crippled IMHO) wmlib practice. Benefit is keyboard
        # focus without raising frame to top. - jfs
	"bind .Wm_t <Button-2> +{focus #}",
	"bind .Wm_t.title <Button-2> +{focus #}",
};

modinit(ctxt: ref Context)
{
	draw = load Draw Draw->PATH;
	tk = load Tk Tk->PATH;
	wmlib = load Wmlib Wmlib->PATH;

	nochan = chan of string;

	screen = ctxt.screen;
	last_x = last_y = -10;

	wmlib->init();
}

makewin(ctxt: ref Context, title: string, x, y, width, height: int, this: ref iFramePeer_obj, job: JObject)
{
#	modinit(ctxt);
	t : ref Toplevel;
	menu : chan of string;
	where := "-x " + string x + " -y " + string y;
	if (this.resizable == 1)
		(t, menu) = wmlib->titlebar(screen, where, title, Wmlib->Appl);
	else
		(t, menu) = wmlib->titlebar(screen, where, title, Wmlib->Hide);

# calculate topInset and boardwidth
	bWidth = int tk->cmd(t, ". cget -bd");
	tHeight = int tk->cmd(t, ". cget -height");

	if (width > 0 && height > 0)
		win_cfg[0] = "canvas .c -height " + string (height - tHeight -bWidth -bWidth) + " -width " + string (width);
#		win_cfg[0] = "canvas .c -height " + string (height - tHeight) + " -width " + string width;

	wmlib->tkcmds(t, win_cfg);

	ones = t.image.display.ones;
	white = t.image.display.color(Draw->White);
	alloccanvas(t, ctxt, ".c", menu, this, job);
}

alloccanvas(t: ref Toplevel, ctxt: ref Draw->Context, canvas: string, menu: chan of string, this :ref iFramePeer_obj, job: JObject)
{
        cmdchan = chan of string;
	tk->namechan(t, cmdchan, "cmd");
	butt := chan of string;
	tk->namechan(t, butt, "butt");

	key := chan of string;
	tk->namechan(t, key, "key");

#	tk->cmd(t, "bind . <Configure> {send cmd resize}");
#	tk->cmd(t, "bind . <Map> {send cmd map}");

	for (i := 0; i < len win_bind; i++)
		tk->cmd(t, expand(win_bind[i], canvas));

	tk->cmd(t, "update");
	
	c := ref Canvas;
	this.pCanvas = c;
	c = nil;

	bg := Draw->White;
	jcol := jni->GetObjField(this.target, "background", "Ljava/awt/Color;");
	if (jcol == nil) {
		sys->print("iFramePeer_L: Cannot get background color\n");
	} else {
		color := jcol.Object();
		bg = awt->getColorIndex(jni, color);
	}

	this.pCanvas.image = t.image;
	display = t.image.display;	
	this.pCanvas.rect = canvposn(t, canvas);
	this.pCanvas.buf = ctxt.display.newimage(ctxt.display.image.r, 
				this.pCanvas.image.ldepth , 0, bg);
	this.pCanvas.events = nil; # not currently used
	this.pCanvas.top = t;
	this.pCanvas.ctxt = ctxt;
	this.pCanvas.canvas = canvas;
	this.pCanvas.pid = sys->pctl(0, nil);

	spawn handler(menu, cmdchan, butt, key, this, job);
}

handler(menu, cmd, butt, key : chan of string, this : ref iFramePeer_obj, job: JObject)
{
	detail: string;
        iconified := 0;
	toplvl := this.pCanvas.top;

	if (menu == nil)
		menu = nochan;
	for (;;) alt {
	detail = <- menu =>
		case detail {
		"exit" =>
# 			this.pCanvas.events <- = ref Event(Event.Shutdown, nil);
                    # 'X' button in titlebar is passed to Java code
                    # as a WINDOW_CLOSING event.
                    doFclosing(this.thisAsJObject);

		"task" =>
			iconified = 1;
			this.pCanvas.image = nil;
			doFiconified(job);

                    # synthesize a WINDOW_DEACTIVATED event, the TK "FocusOut"
                    # event doesn't arrive until after this window has been
                    # selected and deiconified from the toolbar.
                    doFdeactivated(this.thisAsJObject);
                    wmlib->titlectl(toplvl, detail); # shrink it

		* => # default wmlib actions for  move, size, ok, help
                    wmlib->titlectl(toplvl, detail);
		}
#		wmlib->titlectl(this.pCanvas.top, detail);

	detail = <- cmd =>
		(n, word) := sys->tokenize(detail, " ");
		case hd word {
		"configure" or "map" =>
			this.pCanvas.image = this.pCanvas.top.image;
			this.pCanvas.rect = canvposn(toplvl, this.pCanvas.canvas);
#			e := Event.Resize;
			if (hd word == "map") {
                       		# if being mapped after an iconfication
                       		if (iconified) {
                          		  iconified = 0;
                          		  doFdeIconified(this.thisAsJObject);
                     		   }
#				sys->print("mapped\n");
				tk->cmd(toplvl, "focus " + this.pCanvas.canvas);
#				deIconify(job);
                   		r := this.pCanvas.rect;
				javapainttarget(job, r);
				}
			else{
                   		r := this.pCanvas.rect;
				javamvsz(job, r);
			}

                 # receiving or losing window's keyboard focus should
                 # generate frame activation events upto Javaland
                "focusIn" => 
                    doFactivated(this.thisAsJObject);
                "focusOut" =>
                    # ignore loss-of-Tk-focus events that result from 
                    # iconification.
                    if (! iconified) {
                        doFdeactivated(this.thisAsJObject);
                    }
                # sent by dispose() to terminate this event handling thread
                "reallyExit" =>
                    sys->print("iFrame_Peer_L.handler(): suicide\n");
                    exit;
		* =>
                    sys->print("iFrame_Peer_L.handler(): unknown event - %s\n",
                                  detail);
		}

	detail = <- butt =>
		doMouseEvent(job, detail);
	detail = <- key =>
                doKeyEvent(job, detail);
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

	r.min.x = int tk->cmd(t, ". cget -actx");
	r.min.y = int tk->cmd(t, ". cget -acty");
	r.max.x = r.min.x - 1 + int tk->cmd(t, ". cget -actwidth");
	r.max.y = r.min.y - 1 + int tk->cmd(t, ". cget -actheight");
	return r;
}

doFactivated(job : JObject) {
    (val, err) := jni->CallMethod(job, "handleActivated", "()V", nil);
    if (err != jni->OK)
        sys->print( "CallMethod Error %d: handleActivated\n",err);

}

doFdeactivated(job : JObject) {
    (val, err) := jni->CallMethod(job, "handleDeactivated", "()V", nil);
    if (err != jni->OK)
        sys->print( "CallMethod Error %d: handleDeactivated\n",err);

}

doFclosing(job : JObject) {
    (val, err) := jni->CallMethod(job, "handleClosing", "()V", nil);
    if (err != jni->OK)
        sys->print( "CallMethod Error %d: handleClosingt\n",err);

}

doFiconified(job : JObject) {
    (val, err) := jni->CallMethod(job, "handleIconified", "()V", nil);
    if (err != jni->OK)
        sys->print( "CallMethod Error %d: handleIconified\n",err);
}

doFdeIconified(job : JObject) {
    (val, err) := jni->CallMethod(job, "handleDeIconified", "()V", nil);
    if (err != jni->OK)
        sys->print( "CallMethod Error %d: handleDeIconified\n",err);
}
doKeyEvent(job : JObject, detail : string) {
    (kchar, st) := str->toint(detail, 16);
    args := array[1] of ref Value;
    args[0] = ref Value.TInt(kchar);
    (val, err) := jni->CallMethod(job, "handleKeyEvents", "(I)V", args);
    if (err != jni->OK){
        sys->print( "CallMethod Error %d: handleKeyEvents\n",err);
    }
}

doMouseEvent(job : JObject, detail : string) {
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
#<<

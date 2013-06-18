#
#  %W% - %E%
#

FrameManager: module
{
	PATH:	con "/dis/java/inferno/awt/awt_Frame.dis";

	Event: adt
	{
		event:	int;
		detail:	string;

		Button, Key,
		Icon, DeIcon,
		Resize, Shutdown, Focus
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
		# implementation
		ctxt : ref Draw->Context;
		top:		ref Tk->Toplevel;
		canvas:	string;
		pid:		int;
	};

	makewin:	fn(ctxt: ref Draw->Context, title: string, x, y, width, height: int): ref Canvas;
	resizewin: 	fn(cv: ref Canvas, x, y, width, height : int);
	hidewin:	fn(c: ref Canvas);
	getInsets:	fn(): (int, int);
	mapCanvas :	fn(dimg : ref Draw->Image, wimg : ref Draw->Image);
};

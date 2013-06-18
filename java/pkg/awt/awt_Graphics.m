#
#  %W% - %E%
#
AwtGraphics : module
{
	PATH : con "/dis/java/inferno/awt/awt_Graphics.dis";

	init :		fn(img : ref Draw->Image, bufimg: ref Draw->Image);

	dispose :  	fn();
	setForeground :	fn(r, g, b : int);
	changeClip :	fn(p0, p1, p2, p3 : int);

#	removeClip : 	fn();
	clearRect :	fn( p0 : int,p1 : int,p2 : int,p3 : int);

	fillRect :	fn(ply: array of Draw->Point);
	drawRect :	fn(ply: array of Draw->Point);

	drawStringWidth: fn(txt : string, sp : Draw->Point, font : ref Draw->Font) : int;
	drawLine :	fn(sp, ep : Draw->Point);

	genDraw :	fn(r : Draw->Rect, img : array of byte);

	copyArea :	fn(rect0, rect1 : Draw->Rect, data : array of byte);

	drawRoundRect:	fn(p0 : int,p1 : int,p2 : int,p3 : int,p4 : int,p5 : int);

	fillRoundRect:	fn(p0 : int,p1 : int,p2 : int,p3 : int,p4 : int,p5 : int);

	drawPolygon :	fn(ply : array of Draw->Point);
	drawPolyline:	fn(ply : array of Draw->Point);
	fillPolygon :	fn(ply : array of Draw->Point);
	drawOval :	fn(p : Draw->Point, p2 : int,p3 : int);

	fillOval :	fn(p: Draw->Point, p2 : int,p3 : int);

	drawArc :	fn(p : Draw->Point, p2 : int,p3 : int,p4 : int,p5 : int);

	fillArc :	fn(p : Draw->Point, p2 : int,p3 : int,p4 : int,p5 : int);
	sendToDisplay : fn(r : Draw->Rect);
	getDC :		fn(img: ref Draw->Image, bufimg : ref Draw->Image);
};

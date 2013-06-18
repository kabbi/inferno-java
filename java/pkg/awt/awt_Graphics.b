#
#  %W% - %E%
#
implement AwtGraphics;

include "sys.m";
	sys : Sys;

include "draw.m";
        draw: Draw;
        Screen, Display, Rect, Font, Point, Image: import draw;

include "math.m";
	math: Math;
	Pi, atan, tan: import math;

disp : ref Display;
wimg, dimg, white, ones, icolor : ref Image;

include "awt_Graphics.m";

init(img : ref Image, bufimg : ref Image){
	sys = load Sys Sys->PATH;
	draw = load Draw Draw->PATH;
	math = load Math Math->PATH;
	dimg = img;
	wimg = bufimg;
	disp = wimg.display;
	ones = disp.ones;
	icolor = disp.color(Draw->White);
	white = disp.color(Draw->White);
}

undoClip()
{
	wimg.clipr = wimg.r;
}

dispose()
{
	dimg = nil;
	wimg = nil;
}
setForeground(p0, p1, p2 : int)
{
	icolor = disp.rgb(p0, p1, p2);
}

changeClip(p0, p1, p2, p3 : int)
{
#	sys->print("=== Change Cliping Area\n");
	wimg.clipr = ((p0, p1), (p0 + p2 - 1, p1 + p3 -1));
}

clearRect( p0 : int,p1 : int,p2 : int,p3 : int)
{
	r := ((p0, p1), (p0 + p2 - 1, p1 + p3 - 1));
	wimg.draw(r, white, ones, (0, 0));	
}

fillRect(ply: array of Point)
{
	wimg.fillpoly(ply, 1, icolor, ply[0]);
}

drawRect(ply: array of Point)
{
	wimg.poly(ply, 0, 0, 0, icolor, ply[0]);
}

drawStringWidth(txt : string, sp : Point, font : ref Font) : int
{
	ep := wimg.text(sp, icolor, sp, font, txt);
	return(ep.x-sp.x); 	

}

drawLine(sp, ep : Point)
{
	wimg.line(sp, ep, 0, 0, 0, icolor, sp);
}

genDraw(r : Rect, data : array of byte)
{
	wimg.writepixels(r, data);
}

copyArea(rect0, rect1 : Draw->Rect, data : array of byte)
{
	wimg.readpixels(rect0, data);
	wimg.writepixels(rect1, data);
}

drawRoundRect(p0 : int,p1 : int,p2 : int,p3 : int,p4 : int,p5 : int)
{
}

fillRoundRect(p0 : int,p1 : int,p2 : int,p3 : int,p4 : int,p5 : int)
{
}

drawPolygon(ply : array of Point)
{
	wimg.poly(ply, 0, 0, 0, icolor, icolor.r.min);
}

drawPolyline(ply : array of Point)
{
	wimg.poly(ply, 0, 0, 0, icolor, icolor.r.min);
}

fillPolygon(ply : array of Point)
{
	wimg.fillpoly(ply, 1, icolor, icolor.r.min);
}

drawOval(p : Point, p2 : int,p3 : int)
{
	p.x += p2 / 2;
	p.y += p3 / 2;
	wimg.ellipse(p, p2/2, p3/2, 0, icolor, p);
}

fillOval(p: Point, p2 : int,p3 : int)
{
	p.x += p2 / 2;
	p.y += p3 / 2;
	wimg.fillellipse(p, p2/2, p3/2, icolor, p);
}

drawArc(p : Point, p2 : int,p3 : int,p4 : int,p5 : int)
{
	p.x += p2 / 2;
	p.y += p3 / 2;
	(p4, p5) = adjustArcAngles(p2, p3, p4, p5);
	wimg.arc(p, p2/2, p3/2, 0, icolor, p, p4, p5);
}

fillArc(p : Point, p2 : int,p3 : int,p4 : int,p5 : int)
{
	p.x += p2 / 2;
	p.y += p3 / 2;
	(p4, p5) = adjustArcAngles(p2, p3, p4, p5);
	wimg.fillarc(p, p2/2, p3/2, icolor, p, p4, p5);
}

adjustArcAngles(w, h, start, arc: int): (int, int)
{
	laps, end: int;

	if (arc >= 360 || arc <= -360) {
		start = 0;
		arc = 360;
	} else
		start = start % 360;

	if (w != h && arc != 0 && arc != 360) {
		laps = (start + arc) / 360;
		end = (start + arc) % 360;
		start = skewAngle(w, h, start);
		end = skewAngle(w, h, end);
		arc = end - start + (laps * 360);
	}
	return (start, arc);
}

skewAngle(width, height, angle: int): int
{
	if (width == 0 || height == 0)
		return angle;

	normAngle := real angle * (2.0 * Pi) / 360.0;

	w := real width;
	h := real height;
	skewedAngle := h/w * tan(normAngle);
	skewedAngle = atan(skewedAngle);

	if (normAngle > 1.5 * Pi)
		skewedAngle += 2.0 * Pi;
	else if (normAngle > 0.5 * Pi)
		skewedAngle += Pi;
	else if (normAngle < -1.5 * Pi)
		skewedAngle -= 2.0 * Pi;
	else if (normAngle < -0.5 * Pi)
		skewedAngle -= Pi;

	skewedAngle = skewedAngle * 360.0 / (2.0 * Pi);
	return int skewedAngle;
}

sendToDisplay(r : Draw->Rect)
{
#	if (dimg == nil)
#		sys->print("on screen image is nil\n");
#	else
	if (dimg != nil)
	{
		wimg.clipr=r;
		dimg.draw(r, wimg, ones, r.min);
#		dimg.draw(dimg.r, wimg, ones, dimg.r.min);
	}
}

getDC(img: ref Draw->Image, bufimg : ref Draw->Image)
{
	dimg = img;
}


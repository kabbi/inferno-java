implement iGraphics_L;

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
#
#  %W% - %E%
#
	sys : Sys;
        draw: Draw;
        Point, Font: import draw;
include "awt_Graphics.m";

include "iFontPeer_L.m";
    ifontpeerm: iFontPeer_L;
    iFontPeer_obj : import ifontpeerm;

#<<

include "iGraphics_L.m";

#>> extra post includes here

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here
	sys = jni->sys;
	
    #<<
}


pSetForeground_I_I_I_V( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int)
{#>>
	this.awt->setForeground(p0, p1, p2);
}#<<

createGraphics_V( this : ref iGraphics_obj)
{#>>
	this.awt = load AwtGraphics AwtGraphics->PATH;;
        if (this.awt == nil) {
                sys->print("could not load %s: %r\n", AwtGraphics->PATH);
                return;
	}
	this.awt->init(this.refImage, this.refOffScreenImage);
}#<<

pDispose_V( this : ref iGraphics_obj)
{#>>
}#<<

setPaintMode_V( this : ref iGraphics_obj)
{#>>
}#<<

setXORMode_rColor_V( this : ref iGraphics_obj, p0 : JObject)
{#>>
}#<<

changeClip_I_I_I_I_Z_V( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int,p4 : int)
{#>>
	this.awt->changeClip(p0 + this.originX, p1 + this.originY, p2, p3);
}#<<

pClearRect_I_I_I_I_V( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int)
{#>>
	this.awt->clearRect(p0 + this.originX, p1 + this.originY, p2, p3);
}#<<

pFillRect_I_I_I_I_V( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int)
{#>>

	tp := (p0, p1);
	p := dp(this, tp);
	
	ply := array [5] of {p, (p.x + p2 - 1, p.y), (p.x + p2 - 1, p.y + p3 - 1), 
				(p.x, p.y + p3 - 1), p};
	this.awt->fillRect(ply);
}#<<

pDrawRect_I_I_I_I_V( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int)
{#>>
	tp := (p0, p1);
	p := dp(this, tp);
	
	ply := array [5] of {p, (p.x + p2 - 1, p.y), (p.x + p2 - 1, p.y + p3 - 1), 
				(p.x, p.y + p3 - 1), p};
	this.awt->drawRect(ply);
}#<<

pDrawStringWidth_rString_I_I_I( this : ref iGraphics_obj, p0 : JString,p1 : int,p2 : int) : int
{#>>
	str : string;
	sp : Point;
	sp.x = p1;
	sp.y = p2;

	str = p0.str;
	sp =  dp(this, sp);
	return this.awt->drawStringWidth(str, sp, this.ifontpeer.iFontRef );
}#<<

pDrawLine_I_I_I_I_V( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int)
{#>>
	sp, ep : Point;
	sp.x = this.originX + p0;
	sp.y = this.originY + p1;
	ep.x = this.originX + p2;
	ep.y = this.originY + p3;
	this.awt->drawLine(sp, ep);
}#<<

pGenDraw_I_I_I_I_aB_V( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int, p4 : JArrayB)
{#>>
	p0 += this.originX;
	p1 += this.originY;
	r := Draw->Rect((p0,p1),(p0+p2,p1+p3));
	this.awt->genDraw(r, p4.ary);
}#<<

copyArea_I_I_I_I_I_I_V( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int,p4 : int,p5 : int)
{#>>
	data := array [(p2 - p0 + 1) * (p3 - p1 + 1)] of byte;
	rect0, rect1 : Draw->Rect;
	rect0.min = (p0, p1);
	rect0.max = (p2, p3);
	rect1.min = (p0 + p4, p1 + p5);
	rect1.max = (p2 + p4, p3 + p5);
	this.awt->copyArea(rect0, rect1, data);
}#<<

pDrawRoundRect_I_I_I_I_I_I_V( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int,p4 : int,p5 : int)
{#>>
}#<<

pFillRoundRect_I_I_I_I_I_I_V( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int,p4 : int,p5 : int)
{#>>
}#<<

pDrawPolygon_aI_aI_I_V( this : ref iGraphics_obj, p0 : JArrayI,p1 : JArrayI,p2 : int)
{#>>
	ply := array [p2 + 1] of Point;
	for (i := 0; i < p2; i++){
	     ply[i].x = p0.ary[i] + this.originX;
	     ply[i].y = p1.ary[i] + this.originY;
	}
	ply[p2].x = ply[0].x;
	ply[p2].y = ply[0].y;
	this.awt->drawPolygon(ply);
}#<<

pDrawPolyline_aI_aI_I_V( this : ref iGraphics_obj, p0 : JArrayI,p1 : JArrayI,p2 : int)
{#>>
	ply := array [p2] of Point;
	for (i := 0; i < p2; i++){
	     ply[i].x = p0.ary[i] + this.originX;
	     ply[i].y = p1.ary[i] + this.originY;
	}
	this.awt->drawPolygon(ply);
}#<<

pFillPolygon_aI_aI_I_V( this : ref iGraphics_obj, p0 : JArrayI,p1 : JArrayI,p2 : int)
{#>>
	ply := array [p2 + 1] of Point;
	for (i := 0; i < p2; i++){
	     ply[i].x = p0.ary[i] + this.originX;
	     ply[i].y = p1.ary[i] + this.originY;
	}
	ply[p2].x = ply[0].x;
	ply[p2].y = ply[0].y;
	this.awt->fillPolygon(ply);
}#<<

pDrawOval_I_I_I_I_V( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int)
{#>>
	tp := (p0, p1);
	p := dp(this, tp);
	this.awt->drawOval(p, p2, p3);
}#<<

pFillOval_I_I_I_I_V( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int)
{#>>
	tp := (p0, p1);
	p := dp(this, tp);

	this.awt->fillOval(p, p2, p3);
}#<<

pDrawArc_I_I_I_I_I_I_V( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int,p4 : int,p5 : int)
{#>>

	tp := (p0, p1);
	p := dp(this, tp);
	this.awt->drawArc(p, p2, p3, p4, p5);
}#<<

pFillArc_I_I_I_I_I_I_V( this : ref iGraphics_obj, p0 : int,p1 : int,p2 : int,p3 : int,p4 : int,p5 : int)
{#>>
	tp := (p0, p1);
	p := dp(this, tp);
	this.awt->fillArc(p, p2, p3, p4, p5);
}#<<

copyOffscreenImage_I_I_I_I_V( this : ref iGraphics_obj, p0 : int, p1: int, p2: int, p3: int)
{#>>
	this.awt->getDC(this.refImage, this.refOffScreenImage);
	this.awt->sendToDisplay(((p0+this.originX,p1+this.originY),
				(p0+this.originX+p2-1,p1+this.originY+p3-1)));
}#<<


#>>

# duplicates a point and translates into this graphic's region
dp(this : ref iGraphics_obj, p : Point) :Point
{
	pt := p;
	pt.x += this.originX;
	pt.y += this.originY;
	return pt;
}

#<<

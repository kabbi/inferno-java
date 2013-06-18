package inferno.awt;

import java.awt.*;
import java.awt.peer.*;
import java.io.*;
import java.util.*;
import java.awt.image.ImageObserver;
import inferno.awt.iFontPeer;

//import sun.awt.image.OffScreenImageSource;
//import sun.awt.image.ImageRepresentation;

/**
 * iGraphics is an object that encapsulates a graphics context for a
 * particular canvas.
 *
 * @version 1.18 18 Mar 1996
 */

public class iGraphics extends Graphics {
  //    Object      pcanvas;
    Object	refImage;
    Object	refOffScreenImage;
    Component   target;
    Color	foreground;
    Font	font;
    private iFontPeer ifontpeer;
    int		originX;
    int		originY;
    Rectangle   clipRect;
    Rectangle   initialClipRect;
    boolean dirty;

    //private native void imageCreate(ImageRepresentation ir);
    private native void pSetForeground(int r, int g, int b);

    private Image		image;

    private Object		awt; // Pointer to awt object	

    private native void createGraphics();

    public iGraphics(Object refImage, Object refOffScreenImage, Rectangle initialClipRect, Component target)
    {
     this.refImage = refImage;
     this.refOffScreenImage = refOffScreenImage;
     this.initialClipRect = new Rectangle(initialClipRect);
     this.clipRect = new Rectangle(initialClipRect);
     this.target = target;
     this.font = target.getFont();
	 if (font != null) {
		 this.ifontpeer = (iFontPeer)font.getPeer();
	 }
     dirty = false;
     createGraphics();
    }

// a dummy constructor for testing
   public iGraphics(Object im) {
    }


    public iGraphics(Image image) {
    }

    /**
     * Create a new iGraphics Object based on this one.
     */
    public Graphics create() {
	iGraphics g = new iGraphics(refImage, refOffScreenImage, initialClipRect, target);
	g.foreground = foreground;
	g.font = font;
        g.ifontpeer = ifontpeer;
	g.originX = originX;
	g.originY = originY;
	g.image = image;
        //g.clipRect = clipRect;
        //g.initialClipRect = initialClipRect;
	return g;
    }

    private void checkDirty()
    {
     if (dirty)
     {
      dirty = false;
      copyOffscreenImage(clipRect.x,clipRect.y,clipRect.width,clipRect.height);
     }

    }


    /**
     * Translate
     */
    public void translate(int x, int y) {
	originX += x;
	originY += y;
        clipRect.translate(-x,-y);
        initialClipRect.translate(-x,-y);
    }

    /**
     * Disposes of this iGraphics context. It cannot be used after being
     * disposed.
     */
    private native void pDispose();

    public void dispose()
    {
      checkDirty();
      pDispose();
    }

    public void setFont(Font font) {
		if ((font != null) && (this.font != font)) {
			synchronized (this.font) {
				this.font = font;
				ifontpeer = (iFontPeer)font.getPeer();
			}
		}
    }
    public Font getFont() {
		return this.font;
    }

    /**
     * Gets font metrics for the given font.
     */
    public FontMetrics getFontMetrics(Font font) {
	return iFontMetrics.getFontMetrics(font);
    }


    private void ourSetForeground()
    {
     pSetForeground(foreground.getRed(), foreground.getGreen(), foreground.getBlue());
    }

    /**
     * Sets the foreground color.
     */
    public void setColor(Color c) {
	if ((c != null) && (c != foreground)) {
	    foreground = c;
	    pSetForeground(c.getRed(), c.getGreen(), c.getBlue());
	}
    }
    public Color getColor() {
	return foreground;
    }


    /**
     * Sets the paint mode to overwrite the destination with the
     * current color. This is the default paint mode.
     */
    public native void setPaintMode();

    /**
     * Sets the paint mode to alternate between the current color
     * and the given color.
     */
    public native void setXORMode(Color c1);

    /**
     * Gets the current clipping area
     */
    public Rectangle getClipBounds()
    {
     return new Rectangle(clipRect);
    }

    private native void changeClip(int X, int Y, int W, int H, boolean set);

    private void removeClip()
    {
      checkDirty();
      clipRect = new Rectangle(initialClipRect);
    }

    private void ourSetClip()
    {
     dirty = true;
     changeClip(clipRect.x,clipRect.y,clipRect.width,clipRect.height,true);
    }

    /** Crops the clipping rectangle for this iGraphics context. */
    public void clipRect(int X, int Y, int W, int H) {
        checkDirty();
        clipRect = clipRect.intersection(new Rectangle(X,Y,W,H));	// test lg
	//	System.out.println("java == intersection: "+ clipRect);
	//changeClip(X, Y, W, H, false);
    }

    /** Sets the clipping rectangle for this iGraphics context. */
    public void setClip(int X, int Y, int W, int H) {
        checkDirty();
        clipRect = new Rectangle(X,Y,W,H);
	//changeClip(X, Y, W, H, true);
    }

    /** Returns a Shape object representing the clip. */
    public Shape getClip() {
	return getClipBounds();
    }

    /** Sets the clip to a Shape (only Rectangle allowed). */
    public void setClip(Shape clip) {
	if (clip == null) {
	    removeClip();
	} else if (clip instanceof Rectangle) {
	    Rectangle r = (Rectangle) clip;
            checkDirty();
            clipRect = new Rectangle(r);
	    //changeClip(r.x, r.y, r.width, r.height, true);
	} else {
	    throw new IllegalArgumentException("setClip(Shape) only supports Rectangle objects");
	}
    }

    /** Clears the rectangle indicated by x,y,w,h. */
    private native void pClearRect(int x, int y, int w, int h);

    public void clearRect(int x, int y, int w, int h)
    {
     ourSetClip();
     pClearRect(x,y,w,h);
    }

    /** Fills the given rectangle with the foreground color. */
    private native void pFillRect(int X, int Y, int W, int H);

    public void fillRect(int X, int Y, int W, int H)
    {
     ourSetClip();
     pFillRect(X,Y,W,H);
    }

    /** Draws the given rectangle. */
    private native void pDrawRect(int X, int Y, int W, int H);

    public void drawRect(int X, int Y, int W, int H)
    {
     ourSetClip();
     pDrawRect(X,Y,W,H);
    }


    /** Draws the given string. */
    public void drawString(String str, int x, int y) {
        drawStringWidth(str, x, y);
    }

    /** Draws the given character array. */
    public void drawChars(char data[], int offset, int length, int x, int y) {
       String str = new String(data, offset, length);
       drawStringWidth(str, x, y);
       // drawCharsWidth(data, offset, length, x, y);
    }

    /** Draws the given byte array. */
    public void drawBytes(byte data[], int offset, int length, int x, int y) {
      String str = new String(data, offset, length);
      drawStringWidth(str, x, y);
      //  drawBytesWidth(data, offset, length, x, y);
    }

    /** Draws the given string and returns the length of the drawn
      string in pixels.  If font is not set then returns -1. */
    private native int pDrawStringWidth(String str, int x, int y);

    private int drawStringWidth(String str, int x, int y)
    {
	int r;
        ourSetClip();
        if (ifontpeer == null) {
               return 0;
	}
        r = pDrawStringWidth(str, x, y - ifontpeer.iAscent - ifontpeer.fLeading);
        //	System.out.println("Length of string "+r);
		return r;
    }

    /** Draws the given character array and return the width in
      pixels. If font is not set then returns -1. */
//    public native int drawCharsWidth(char data[], int offset, int length,
//                                     int x, int y);

    /** Draws the given character array and return the width in
      pixels. If font is not set then returns -1. */
//    public native int drawBytesWidth(byte data[], int offset, int length,
//                                     int x, int y);

    /** Draws the given line. */
    private native void pDrawLine(int x1, int y1, int x2, int y2);

    public void drawLine(int x1, int y1, int x2, int y2) {
        ourSetClip();
        pDrawLine(x1, y1, x2, y2);
    }

    /**
     * Draws an image at x,y in nonblocking mode with a callback object.
     */
    public boolean drawImage(Image img, int x, int y, ImageObserver observer) {
	//	We need to get the bits.
	if ( img == null )
	    return false;
	java.awt.image.ImageProducer ip = img.getSource();
	java.awt.image.ImageConsumer ic = new iImageConsumer(this, img, x, y);
	ip.startProduction(ic);
	ip.removeConsumer(ic);
	/*WImage wImg = (WImage) img;
	if (wImg.hasError()) {
	    if (observer != null) {
		observer.imageUpdate(img,
				     ImageObserver.ERROR|ImageObserver.ABORT,
				     -1, -1, -1, -1);
	    }
	    return false;
	}
	ImageRepresentation ir = wImg.getImageRep();
	return ir.drawImage(this, x, y, null, observer);
        */
        return false;
    }

    /**
     * Draws an image scaled to x,y,w,h in nonblocking mode with a
     * callback object.
     */
    public boolean drawImage(Image img, int x, int y, int width, int height,
			     ImageObserver observer) {
	/*if (width == 0 || height == 0) {
	    return true;
	}
	WImage wImg = (WImage) img;
	if (wImg.hasError()) {
	    if (observer != null) {
		observer.imageUpdate(img,
				     ImageObserver.ERROR|ImageObserver.ABORT,
				     -1, -1, -1, -1);
	    }
	    return false;
	}
	ImageRepresentation ir = wImg.getImageRep();
	return ir.drawScaledImage(this, x, y, width, height, null, observer);
        */
        return false;
    }

    /**
     * Draws an image at x,y in nonblocking mode with a solid background
     * color and a callback object.
     */
    public boolean drawImage(Image img, int x, int y, Color bg,
			     ImageObserver observer) {
	/*WImage wImg = (WImage) img;
	if (wImg.hasError()) {
	    if (observer != null) {
		observer.imageUpdate(img,
				     ImageObserver.ERROR|ImageObserver.ABORT,
				     -1, -1, -1, -1);
	    }
	    return false;
	}
	ImageRepresentation ir = wImg.getImageRep();
	return ir.drawImage(this, x, y, bg, observer);
        */
        return false;
    }

    /**
     * Draws an image scaled to x,y,w,h in nonblocking mode with a
     * solid background color and a callback object.
     */
    public boolean drawImage(Image img, int x, int y, int width, int height,
			     Color bg, ImageObserver observer) {
	/*if (width == 0 || height == 0) {
	    return true;
	}
	WImage wImg = (WImage) img;
	if (wImg.hasError()) {
	    if (observer != null) {
		observer.imageUpdate(img,
				     ImageObserver.ERROR|ImageObserver.ABORT,
				     -1, -1, -1, -1);
	    }
	    return false;
	}
	ImageRepresentation ir = wImg.getImageRep();
	return ir.drawScaledImage(this, x, y, width, height, bg, observer);
        */
        return false;
    }

    /**
     * Draws a subrectangle of an image scaled to a destination rectangle
     * in nonblocking mode with a callback object.
     */
    public boolean drawImage(Image img,
			     int dx1, int dy1, int dx2, int dy2,
			     int sx1, int sy1, int sx2, int sy2,
			     ImageObserver observer) {
	/*if (dx1 == dx2 || dy1 == dy2) {
	    return true;
	}
	WImage wImg = (WImage) img;
	if (wImg.hasError()) {
	    if (observer != null) {
		observer.imageUpdate(img,
				     ImageObserver.ERROR|ImageObserver.ABORT,
				     -1, -1, -1, -1);
	    }
	    return false;
	}
	ImageRepresentation ir = wImg.getImageRep();
	return ir.drawStretchImage(this,
				   dx1, dy1, dx2, dy2,
				   sx1, sy1, sx2, sy2,
				   null, observer);
        */
        return false;
    }

    /**
     * Draws a subrectangle of an image scaled to a destination rectangle in
     * nonblocking mode with a solid background color and a callback object.
     */
    public boolean drawImage(Image img,
			     int dx1, int dy1, int dx2, int dy2,
			     int sx1, int sy1, int sx2, int sy2,
			     Color bgcolor, ImageObserver observer) {
	/*if (dx1 == dx2 || dy1 == dy2) {
	    return true;
	}
	WImage wImg = (WImage) img;
	if (wImg.hasError()) {
	    if (observer != null) {
		observer.imageUpdate(img,
				     ImageObserver.ERROR|ImageObserver.ABORT,
				     -1, -1, -1, -1);
	    }
	    return false;
	}
	ImageRepresentation ir = wImg.getImageRep();
	return ir.drawStretchImage(this,
				   dx1, dy1, dx2, dy2,
				   sx1, sy1, sx2, sy2,
				   bgcolor, observer);
        */
        return false;
    }

    /**
     * Actually draws the image on the Inferno display in a blocking mode.
     */
    private native void pGenDraw(int x, int y, int w, int h, byte pixels[]);

    protected void drawImage(int x, int y, int w, int h, byte pixels[]) {
        ourSetClip();
        //ourSetForeground();
        pGenDraw(x, y, w, h, pixels);
	return;
    }

    /**
     * Copies an area of the canvas that this graphics context paints to.
     * @param X the x-coordinate of the source.
     * @param Y the y-coordinate of the source.
     * @param W the width.
     * @param H the height.
     * @param dx the x-coordinate of the destination.
     * @param dy the y-coordinate of the destination.
     */
    public native void copyArea(int X, int Y, int W, int H, int dx, int dy);


    /** Draws a rounded rectangle. */
    private native void pDrawRoundRect(int x, int y, int w, int h,
				     int arcWidth, int arcHeight);

    public void drawRoundRect(int x, int y, int w, int h,
				     int arcWidth, int arcHeight)
    {
        ourSetClip();
        pDrawRoundRect(x,y,w,h,arcWidth,arcHeight);
    }

    /** Draws a filled rounded rectangle. */
    private native void pFillRoundRect(int x, int y, int w, int h,
				     int arcWidth, int arcHeight);

    public void fillRoundRect(int x, int y, int w, int h,
				     int arcWidth, int arcHeight)
    {
        ourSetClip();
        pFillRoundRect(x,y,w,h,arcWidth,arcHeight);
    }

    /** Draws a polygon defined by an array of x points and y points */
    private native void pDrawPolygon(int xPoints[], int yPoints[], int nPoints);

    public void drawPolygon(int xPoints[], int yPoints[], int nPoints)
    {
        ourSetClip();
        pDrawPolygon(xPoints,yPoints,nPoints);
    }

    /** Draws a polygon defined by an array of x points and y points */
    private native void pDrawPolyline(int xPoints[], int yPoints[], int nPoints);

    public void drawPolyline(int xPoints[], int yPoints[], int nPoints)
    {
        ourSetClip();
        pDrawPolyline(xPoints,yPoints,nPoints);
    }

    /** Fills a polygon with the current fill mask */
    private native void pFillPolygon(int xPoints[], int yPoints[], int nPoints);

    public void fillPolygon(int xPoints[], int yPoints[], int nPoints)
    {
        ourSetClip();
        pFillPolygon(xPoints,yPoints,nPoints);
    }

    /** Draws an oval to fit in the given rectangle */
    private native void pDrawOval(int x, int y, int w, int h);

    public void drawOval(int x, int y, int w, int h)
    {
        ourSetClip();
        pDrawOval(x,y,w,h);
    }

    /** Fills an oval to fit in the given rectangle */
    private native void pFillOval(int x, int y, int w, int h);

    public void fillOval(int x, int y, int w, int h)
    {
        ourSetClip();
        pFillOval(x,y,w,h);
    }

    /**
     * Draws an arc bounded by the given rectangle from startAngle to
     * endAngle. 0 degrees is a vertical line straight up from the
     * center of the rectangle. Positive angles indicate clockwise
     * rotations, negative angle are counter-clockwise.
     */
    private native void pDrawArc(int x, int y, int w, int h,
			       int startAngle,
			       int endAngle);

    public void drawArc(int x, int y, int w, int h,
			       int startAngle,
			       int endAngle)
    {
        ourSetClip();
        pDrawArc(x,y,w,h,startAngle,endAngle);
    }

    /** fills an arc. arguments are the same as drawArc. */
    private native void pFillArc(int x, int y, int w, int h,
			       int startAngle,
			       int endAngle);

    public void fillArc(int x, int y, int w, int h,
			       int startAngle,
			       int endAngle)
    {
        ourSetClip();
        pFillArc(x,y,w,h,startAngle,endAngle);
    }


    public String toString() {
		return (getClass().getName() + "[" + originX + "," + originY + 
				"[font=" + getFont() + "], color=" + getColor() + "]");
    }

    // Print a peer using this graphics object.
    void print(ComponentPeer peer)
    {
    }

    /* Outline the given region. */
    //public native void drawRegion(Region r);

    /* Fill the given region. */
    //public native void fillRegion(Region r);

    /** Terminates a PrintJob and releases resources */
    public void close(PrintJob pj)
    {
    }

    private native void copyOffscreenImage(int X, int Y, int W, int H);

}





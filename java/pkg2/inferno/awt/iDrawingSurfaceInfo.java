/*
 *
 * Adapted from MDrawingSurfaceInfo.java version - 1.3 96/12/20
 * 
 */

package inferno.awt;

import sun.awt.DrawingSurfaceInfo;
import sun.awt.PhysicalDrawingSurface;
import sun.awt.image.ImageRepresentation;
import java.awt.Rectangle;
import java.awt.Shape;
import java.awt.image.ColorModel;
import java.awt.peer.ComponentPeer; // eventually inferno.awt.iComponentPeer ??

/**
 * The iDrawingSurfaceInfo object provides direct access for rendering
 * on Components maintained by the Inferno iToolkit.
 *
 */

public class iDrawingSurfaceInfo
    implements DrawingSurfaceInfo, PhysicalDrawingSurface /* , iDrawingSurface */
{
    int state;
    int w, h;
    ComponentPeer peer = null;   // eventually an iComponentPeer
    ImageRepresentation imgrep;

    /**
     * Construct a new iDrawingSurfaceInfo for the specified peer.
     */
    /* To date Inferno doesn't need this constructor from 
       MDrawingSurfaceInfo if it does, we'll need an 
       inferno.awt.iComponentPeer 
    iDrawingSurfaceInfo(iComponentPeer peer) {
        this.peer = peer;
    }
    */

    /**
     * Construct a new iDrawingSurfaceInfo for the specified offscreen image.
     */
    iDrawingSurfaceInfo(ImageRepresentation imgrep) {
	this.imgrep = imgrep;
    }

    // implementation of lock from sun.awt.DrawingSurfaceInfo interface
    public native int lock();

    // implementation of unlock from sun.awt.DrawingSurfaceInfo interface
    public native void unlock();

    // implementation of getBounds from sun.awt.DrawingSurfaceInfo interface
    public Rectangle getBounds() {
	Rectangle r;
       // comment out to keep compiler happy, eventually may
       // need this code ? -  jfs
        /*
	if (peer != null) {
            r = peer.target.getBounds(); 
	    r.setLocation(0, 0);
	} else {
            r = new Rectangle(0, 0, imgrep.width, imgrep.height);
        }
	return r;
        */
        return (r = new Rectangle(0, 0, imgrep.width, imgrep.height));
    }

    // implementation of getSurface from sun.awt.DrawingSurfaceInfo interface
    public PhysicalDrawingSurface getSurface() {
	return this;
    }

    // implementation of getClip from sun.awt.DrawingSurfaceInfo interface
    public Shape getClip() {
	return getBounds();
    }

    public ColorModel getColorModel() {
        return iToolkit.getStaticColorModel();
    }

    /**
     * Returns a an Object pointer to the rendered $Draw->Image 
     * represented by this object.
     */
    final native Object getDrawable();

    /**
     * Return the depth (log2 of pixel width) of the 
     * $Draw->Image represented by this object.
     */
    final native int getDepth();

     /* 
       for future reference: 
         X11DrawingSurfaceInfo implements X11DrawingSurface:
           public native int getDisplay();
           public native int getDrawable();
           public native int getDepth();
           public native int getVisualID();
           public native int getColormapID();
           public ColorModel getColorModel();

         and WDrawingSurfaceInfo implements WDrawingSurface:
           public native int getHWnd();
           public native int getHBitmap();
           public native int getPBits();
           public native int getHDC();
           public native int getDepth();
           public native int getHPalette();

      */
}

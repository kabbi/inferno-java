/*
 *  %W% - %E%
 *
 * Adapted from SunSoft's X11OffScreenImage.java 1.2 97/02/23
 */

package inferno.awt;

import java.awt.Component;
import java.awt.Graphics;
import sun.awt.DrawingSurface;
import sun.awt.DrawingSurfaceInfo;

class iOffScreenImage extends iImage implements DrawingSurface {
    /**
     * Construct an image for offscreen rendering to be used with a
     * given Component.
     */
    public iOffScreenImage(Component c, int w, int h) {
	super(c, w, h);
    }

    public Graphics getGraphics() {
	Graphics g = new iGraphics(this);
	initGraphics(g);
	return g;
    }

    // implementation of sun.awt.DrawingSurface's getDrawingSurfaceInfo()
    public DrawingSurfaceInfo getDrawingSurfaceInfo() {
	return new iDrawingSurfaceInfo(getImageRep());
    }
}

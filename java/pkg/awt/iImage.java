/*
 * 
 *  %W% - %E%
 *
 * Adapted from SunSoft's X11Image.java	1.7 97/02/24
 */
package inferno.awt;

import java.awt.Component;
import java.awt.Graphics;
import java.awt.image.ImageProducer;

import sun.awt.image.ImageRepresentation;

class iImage extends sun.awt.image.Image {
    /**
     * Construct an image for offscreen rendering to be used with a
     * given Component.
     */
    public iImage(Component c, int w, int h) {
	super(c, w, h);
    }

    /**
     * Construct an image from an ImageProducer object.
     */
    public iImage(ImageProducer producer) {
	super(producer);
    }

    public Graphics getGraphics() {
        throw new IllegalAccessError("getGraphics() only valid for images created with createImage(w, h)");
    }

    protected ImageRepresentation makeImageRep() {
	// make Inferno ImageRepresentation  - jfs
	//return new ImageRepresentation(this, -1, -1, 0);
	return new iImageRepresentation(this, -1, -1, 0);
    }

    protected ImageRepresentation getImageRep() {
	return super.getImageRep();
    }

    // overridden strictly for tracing and debugging. - jfs
    protected void initGraphics(Graphics g) {
        System.out.println("iImage.initGraphics() this=" + this +
                           "\n     g=" + g);
        super.initGraphics(g);
    }
}

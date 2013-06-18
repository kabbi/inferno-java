/*
 * 
 */

package inferno.awt;

import java.awt.Color;
import java.awt.Graphics;
//import java.awt.AWTException;
//import java.awt.Rectangle;
import java.awt.image.ColorModel;
import java.awt.image.ImageConsumer;
import java.awt.image.ImageObserver;
import sun.awt.image.ImageWatched;
import sun.awt.image.Image;
//import sun.awt.AWTFinalizeable;
//import sun.awt.AWTFinalizer;
//import java.util.Hashtable;

/* 
 * This implementation the implementation class  for Sun's
 * sun.awt.image.ImageRepresentation.
 * - jfs
 */
public class iImageRepresentation extends sun.awt.image.ImageRepresentation
{
    /* ref Draw->Image, used by native code */
    Object piImage; 

     /**
     * Create an ImageRepresentation for the given Image scaled
     * to the given width and height and dithered or converted to
     * a ColorModel appropriate for the given image tag.
     */
    //public iImageRepresentation(Image im, int w, int h, int t) {
    public iImageRepresentation(iImage im, int w, int h, int t) {
	super(im, w, h, t);
        System.out.println("iImageRep.iImagRep(): w=" + w + " h=" + h +
              "t=" + t + "im=" + im);
    }
    /**
     * Initialize this ImageRepresentation object to act as the
     * destination drawable for this OffScreen Image.
     */
    protected native void offscreenInit(Color bg); 

    /* make Inferno's own ImageRepresentation - jfs
    private native boolean setBytePixels(int x, int y, int w, int h,
					 ColorModel model,
					 byte pix[], int off, int scansize);
    */
    protected native boolean setBytePixels(int x, int y, int w, int h,
					 ColorModel model,
					 byte pix[], int off, int scansize);

    /* make Inferno's own ImageRepresentation - jfs
    private native boolean setIntPixels(int x, int y, int w, int h,
					ColorModel model,
					int pix[], int off, int scansize);
    */
    protected native boolean setIntPixels(int x, int y, int w, int h,
					ColorModel model,
					int pix[], int off, int scansize);

   /* make Inferno's own ImageRepresentation - jfs
    private native boolean finish(boolean force);
    */
    protected native boolean finish(boolean force);

    /* make Inferno's own ImageRepresentation - jfs
    native synchronized void imageDraw(Graphics g, int x, int y, Color c);

    */
    native protected synchronized void imageDraw(Graphics g, int x, int y, Color c);

    /* make Inferno's own ImageRepresentation - jfs
    native synchronized void imageStretch(Graphics g,
				  int dx1, int dy1, int dx2, int dy2,
				  int sx1, int sy1, int sx2, int sy2,
				  Color c);
     */
    native protected synchronized void imageStretch(Graphics g,
				  int dx1, int dy1, int dx2, int dy2,
				  int sx1, int sy1, int sx2, int sy2,
				  Color c);

    /* make Inferno's own ImageRepresentation - jfs
    private native void disposeImage();
    */
    protected native void disposeImage();
}

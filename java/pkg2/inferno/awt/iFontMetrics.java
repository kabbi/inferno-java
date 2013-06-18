/*
 *  %W% - %E%
 */

  /*
   The only font metrics that Inferno provides are height, the distance 
   in pixels between baselines of lines of text rendered in a particular 
   font, and ascent, the distance from the top of the bounding box to the 
   baseline.  So there really isn't much vertical information to provide.  
   In particular there's no leading, and descent information.

   To do better than this will require, putting max bounds, leading, and 
   descent information in the Inferno subfont files, and augmenting $Draw 
   built-in module to make this information visible to Limbo programs.
  */

/*
 *
 */

package inferno.awt;

import java.awt.*;
import java.util.Hashtable;
import java.lang.IllegalArgumentException;

/** 
 * A font metrics object for a font.
 * 
 */
public class iFontMetrics extends FontMetrics {

	private static final boolean debug = false;

    int widths[];
    int ascent;
    int descent;
    int leading;
    int height;
    int maxAscent;
    int maxDescent;
    int maxHeight;

	/*
	  maxAdvance can't be readily determined without 
	  parsing the Inferno font file and calling
	  Draw->(Draw->Font).width() for every char mapped by
	  that Inferno Font. An alternate fudging strategy is to 
	  set it to the max width of any char in the first 256
	  (getWidths()) characters.
	*/
    int maxAdvance = -1;

	private boolean needWidths = true;

	// rather than ask our Font for it's peer everytime we want it. We'll
	// ask once at construction time, as a small optimization.

    private iFontPeer ifontpeer;
	
    public iFontMetrics(Font font) {
		super(font);
	    // Some vertical font metrics (height, and ascent) are (conveniently)
	    // already available in the iFontPeer of a constructed Font.
	    if (font == null) {
	    	throw new IllegalArgumentException("font");
	    }
	    ifontpeer = (iFontPeer)font.getPeer(); // our Inferno peer
		height = ifontpeer.iHeight;
	    ascent = ifontpeer.iAscent;

		// fudge a pixel for leading if the difference between height
		// and ascent permits, done by iFontPeer() like so
		// leading = ((height - ascent) > 2) ? 1 : 0;
		leading = ifontpeer.fLeading;
	    descent = height - ascent - leading; 

		// There's no information regarding the following available to Limbo,
		// or even in the Inferno subfont files, so fudge 'em.
		maxHeight = height;
		maxAscent = ascent;
		maxDescent = descent;

		// widths and maybe maxAdvance is evaluated lazily as needed.
    }

    /**
     * Get leading
     */
    public int getLeading() {
		return leading;
    }

    /**
     * Get ascent.
     */
    public int getAscent() {
		return ascent;
    }

    /**
     * Get descent
     */
    public int getDescent() {
		return descent;
    }

    /**
     * Get height
     */
    public int getHeight() {
		return height;
    }

    /**
     * Get maxAscent
     */
    public int getMaxAscent() {
		return maxAscent;
    }

    /**
     * Get maxDescent
     */
    public int getMaxDescent() {
		return maxDescent;
    }

    /**
     * Get maxAdvance
     */
    public int getMaxAdvance() {
		if (needWidths) {
			initWidths();
		}
		return maxAdvance;
    }

	/**
	 * Returns the advance width of the sprcified character in this Font.
	 */
	public int charWidth(char ch) {
		if (ch < 256) { // chars are zero extended upon promotin to ints
			if (needWidths) {
				initWidths();
			}
			return widths[ch & 0xFF];
		} else {
			char data[] = { ch };
			return charsWidth(data, 0, 1);
		}
	}
			
	
	/**
	 * Return the advance widh of the specified chars in this Font
	 */
    public int charsWidth(char data[], int off, int len) {
		int w = 0;
		int tlen = len; 
		int toff = off;
		boolean tooBig = false;
		if (data == null || off < 0) {
			throw new IllegalArgumentException();
		}
		while(len-- > 0) {
			if (data[off] >= 256) {
				tooBig = true;
				break;
			}
			if (needWidths) {
				initWidths();
			}
			w += widths[data[off++]];
		}
		if (tooBig) {
			if (debug) {
				System.out.println("iFontMetrics.charsWidth - tooBig");
			}
			w = stringWidth(new String(data, off, len));
		} 
		return w;
    }
    
	
    /**
     * Return the width of the specified string in this Font. 
	 * 
	 * Why not bust up the string into a char[] and try for the optimization
	 * of charsWidth if all elemment values are less than 256? -jfs?
     */
    public int stringWidth(String str) {
		if (str == null) {
			throw new IllegalArgumentException();
		}
    	return iStringWidth(str);
    }
    
    public int bytesWidth(byte[] data, int off, int len) {
		// check args here?
		if (data == null || off < 0 || len < 0) {
			throw new IllegalArgumentException();
		}
		byte[] ndata = new byte[len]; 
		System.arraycopy(data, off, ndata, 0, len);
		return iBytesWidth(ndata);
    }

    // Compute width of string in this font.
    private native int iStringWidth(String str);

	// translate bytes from UTF-8 encoding into a Unicode Limbo string,
	// compute the advance width of the string in this Font and return
	// the advance in pixels.
	private native int iBytesWidth(byte data[]);

	// get advance widths of the first 256 characters of this font.
    private synchronized void initWidths() {
		widths = new int[256];
		maxAdvance = iInitWidths(widths);
		if (debug) {
			System.out.println("iFontMetrics.initWidths(): maxAdvance=" + maxAdvance);
		}
		needWidths = false;
	}

	// populates widths with the advance width of the first 256 chars
    // in this font, returns the width of the widest character.
	private native int iInitWidths(int widths[]);
	
	/**
     * Get the widths of the first 256 characters in the font.
     */
    public int[] getWidths() {
		if (needWidths) {
			initWidths();
		}
		return widths;
    }

    static Hashtable table = new Hashtable();

    static  synchronized FontMetrics getFontMetrics(Font font) {
		if (font == null) {
			throw new NullPointerException("FontMetrics.getFontMetrics()");
		}
		FontMetrics fm = (FontMetrics)table.get(font);
		if (fm == null) {
			table.put(font, fm = new iFontMetrics(font));
		}
		return fm;
    }

	/**
	  Returns a representation of this  <code>FontMetric</code>
	  object's values as a string.
	  @return	a string representation of this font metric.
	  */
    public String toString() {
		return getClass().getName() + "[font=" + getFont() + "ascent=" +
			getAscent() + ", descent=" + getDescent() + ", leading=" +
			getLeading() + ", height=" + getHeight() + ", maxAdvance=" +
			maxAdvance + ", font.getPeer()=" + font.getPeer().toString() +
			" ]" ;
	}
}

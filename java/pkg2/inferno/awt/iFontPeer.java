/*
 *  %W% - %E%
 */

/**
 * Inferno's Font peer
 *
 */

 /*
 * If you're not using xemacs to view this file, you may find it's indentation
 * more ledgible if you set your tabstops to four spaces.
 */
package inferno.awt;

import java.io.FileNotFoundException;
import java.awt.Font;
import java.util.Properties;
import java.util.Hashtable;
import java.util.Vector;
import java.io.File;
import java.io.InputStream;
import java.io.FileInputStream;
import java.io.BufferedInputStream;
import java.util.StringTokenizer;

public class iFontPeer implements java.awt.peer.FontPeer {

	// a default Inferno pathname to a font
    //	"/fonts/lucidasans/latin1.7.font" is a popular default font
	private final static String defifpathname = "*default*";

    /*
     An object to hold a Limbo reference of type ref Draw->Font
     the handle to Inferno platform font capabilities.
     Inferno JNI access as this.iFontRef.
	 Pertinent size metrics are kept here in the peer for quicker
	 text rendering.
     */
    Object iFontRef; 
    int iAscent = -1; // Inferno font's ascent value
    int iHeight = -1; // Inferno font's height value
	int fLeading = -1; // a fudged value for leading (none in Inferno fonts)
	String iName = ""; // Inferno font's name (should match ifpathname)

	private static Properties fprops;
	static {
		// Find property file
		String jhome = System.getProperty("java.home");
		if (jhome == null){
			throw new Error("java.home property not set");
		}
		// trace("jhome=" + jhome);

		String language = System.getProperty("user.language", "en");
		String region = System.getProperty("user.region");

		// trace("language=" + language);
		// trace("region=" + region);
		// trace("File.separator=" + File.separator);

		try {
			File f = null;
			if (region != null) {
				f = new File(jhome + File.separator +
							 "lib" + File.separator +
							 "font.properties." + language + "_" +
							 region);
			}

			if (f == null || !f.canRead()) {
				f = new File(jhome + File.separator +
							 "lib" + File.separator + "font.properties." +
							 language);
				if (!f.canRead()) {
					f = new File(jhome + File.separator +
								 "lib" + File.separator + "font.properties");
					if (!f.canRead()){
						throw new Exception();
					}
				}
			}

			fprops = new Properties();

			// Load property file
			// trace("trying to load props at path " + f.getPath());
			InputStream in =
				new BufferedInputStream(new FileInputStream(f.getPath()));
			fprops.load(in);
			in.close();
		} catch (Exception e){
			System.out.println("iFontPeer: can't load font.properties");
			System.out.println("exception: " + e.getMessage());
			e.printStackTrace();
		} // end try
	} // end static
	

	// The do-nothing constructor
    public iFontPeer(String name, int style) {
		// Don't do anything with name and style, they're implementation
        // artifacts from a different (better?) world of scalable
		// platform fonts where size is a final argument to platform
		// dependant rendering libraries, but Inferno's are static bitmaps.
		//
		// a better (more general) signatures for this constructor would 
		// have been FontPeer(Font font) or 
		// FontPeer(String name,int style,int size)
		// but alas, Sun's API hasn't been quite general enough in that regard.
	}	

	// Native method to actually create font in Inferno Display and 
	// populate this object with reference to Draw->Font and some 
	// font metrics.
    private native void initFontPeer(String ifpathname) throws FileNotFoundException;

	//
    // initializeFontPeer is called by java.awt.Font.java so this 
    // method must, regretably, have public scope.
    //
    public String initializeFontPeer(String name, int style, int size)
	{
		String ifpn = ""; // pathname to Inferno font
		// trace("iFontPeer.initializeFontPeer(): name=" + name +" ,style=" 
		//              + style + ", size=" + size);

		boolean triedDefault = false;
		ifpn = mapifpath(name, style, size);
		if (ifpn == null) {
			ifpn = defifpathname;
		}
				
        retry:
		try {
			initFontPeer(ifpn); // sets iName, iAscent, iHeight, and fLeading
		} catch (FileNotFoundException e) {
			// case: properties maps to a file but font file doesn't
			// exist
			if (!triedDefault) {
				triedDefault = true;
				ifpn = defifpathname;
				// trace("initializeFontPeer: trying default");
				break retry;
			}
		}
	
		if (debug) {
			trace("iFontPeer.initializeFontPeer():");
			trace("    iName=" + iName);
			trace("    iAscent=" + iAscent + " iHeight=" + iHeight);
		}
		return ifpn;
    }

    // 
    // map a Java font triple into the full pathname of an Inferno
    // font description file.
    //
    private static String mapifpath(String name, int style, int size) {

		if (fprops == null) {
			return defifpathname;
		}

		String aName = name.toLowerCase();
        String aStyle = styleStr(style);
        String aSize = String.valueOf(size);

		//trace("mapifpath(" + aName + ", " + aStyle + ", " + aSize + ")");
		String aStr = aName + "." + aStyle + "." + aSize;
		int idx;

        // perform face name substitution
        String rStr = fprops.getProperty("alias." + aName);
        if (rStr != null && rStr.indexOf('.') < 0) {
			aName = rStr;
        }
		//trace("gp1 rStr=" +rStr+ " aName=" +aName+ " aStyle=" +aStyle+
	    //      " aSize=" + aSize);

        // perform style substitution on result of above
		rStr = fprops.getProperty("alias." + aName + "." + aStyle);
        if (rStr != null) {
			idx = rStr.indexOf('.');
			if (idx > 0 && rStr.lastIndexOf('.') == idx &&
				(idx+1 < rStr.length()))
				{
					aName = rStr.substring(0,idx);
					aStyle = rStr.substring(idx+1);
				}
        }
        //trace("gp2 rStr=" +rStr+ " aName=" +aName+ " aStyle=" +aStyle+
	    //      " aSize=" + aSize);


		// Now see if there's a complete alias for this "font+style+size"
		rStr = fprops.getProperty("alias." + aName + "." + aStyle +
								  "." + aSize);
		if (rStr != null) {
			StringTokenizer st = new StringTokenizer(rStr,".",false);
			if (st.countTokens() == 3) {
				aName = st.nextToken();
				aStyle = st.nextToken();
				aSize = st.nextToken();
			}
		}
        //trace("gp3 rStr=" +rStr+ " aName=" +aName+ " aStyle=" +aStyle+
	    //      " aSize=" + aSize);


		// after these substitutions, see if the font string has
        // a match, applying the followin heuristic.
		// if stlye isn't "plain", adjust size +-2, if no match
		//     change style to "plain" and proceed per style is "plain"
		// if style is "plain" adjust size +-4 if need be.
		//

		while(true) {
			int nsize;
			boolean up = true;
			int range = (style != Font.PLAIN) ? 2 : 4;

			for (int i = 0; i <= range;) {
				nsize = Math.abs(size + ((up) ? i : -i));
				// trace("nsize=" + nsize);
				aSize = String.valueOf(nsize);
				rStr = fprops.getProperty(aName +"."+ aStyle + "." + aSize);
				if (rStr != null) {
					//trace("***mapifpath: got it!");
					break;
				}
				if (!up) {
					i++;
				}
				up = (!up);
			}
			if (rStr == null) { 
				if (style != Font.PLAIN) { // retry with plain style
					style = Font.PLAIN;
					aStyle = styleStr(style);
					//trace("***mapifpath: retry w/plain font!, nsize=" + nsize);
					continue;
				}
				rStr = defifpathname; // no Match, returns default
			}
			break;
		} 
        trace ("mapifpath: gp4 aName=" +aName+ " aStyle=" +aStyle+
			   " aSize=" + aSize + " rStr=" + rStr);
		return(rStr);
    }

     /*
     * return String representation of style
     */
    private static String styleStr(int num){
		switch(num){
		  case Font.BOLD:
		    return "bold";
		  case Font.ITALIC:
		    return "italic";
		  case Font.ITALIC+Font.BOLD:
		    return "bolditalic";
		  default:
		    return "plain";
		}
    }

	private static final boolean debug = false;
	private static void trace(String arg) {
		if (debug) {
			System.out.println(arg);
		}
	}
}

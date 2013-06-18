/*
 *  %W% - %E%
 */

package inferno.awt;

import java.util.Hashtable;
import java.awt.*;
import java.awt.Toolkit;
import java.awt.image.*;
import java.awt.peer.*;
import java.awt.event.MouseEvent;
import java.awt.datatransfer.Clipboard;
import java.io.*;
import java.net.URL;
import java.util.Properties;
import sun.awt.image.*;

public class iToolkit extends Toolkit {

    // System clipboard.
    Clipboard clipboard;

    // the system EventQueue
    protected static EventQueue theEventQueue;

    public iToolkit() {
	
        String eqName = Toolkit.getProperty("AWT.EventQueueClass",
                                            "java.awt.EventQueue");
        try {
            theEventQueue = (EventQueue)Class.forName(eqName).newInstance();
        } catch (Exception e) {
            System.err.println("Failed loading " + eqName + ": " + e);
            theEventQueue = new EventQueue();
        }
    }

    protected EventQueue getSystemEventQueueImpl() {
        return theEventQueue;
    }

     public Clipboard getSystemClipboard() {
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
	  security.checkSystemClipboardAccess();
	}
        if (clipboard == null) {
	    //clipboard = new WClipboard();
	}
	return clipboard;
    }


  static public void postEvent(AWTEvent event)
  {
  // System.out.println("PeekEvent = "+theEventQueue.peekEvent());		
   theEventQueue.postEvent(event);
  }

  public void beep()
  {

  }

    public PrintJob getPrintJob(Frame frame, String doctitle, Properties props)
    {
    return null;
    }

    public java.awt.Image createImage(byte[] data, int offset, int length) {
	return createImage(new ByteArrayImageSource(data, offset, length));
    }



    public java.awt.Image createImage(ImageProducer producer) {
	return null/*new WImage(producer)*/;
    }
	
    public int checkImage(java.awt.Image img, int w, int h, ImageObserver o) {
	return 0/*checkScrImage(img, w, h, o)*/;
    }

    public boolean prepareImage(java.awt.Image img, int w, int h, ImageObserver o) {
	return false/*prepareScrImage(img, w, h, o)*/;
    }

    public java.awt.Image getImage(String filename) {
	return null/*getImageFromHash(this, filename)*/;
    }

    public java.awt.Image getImage(URL url) {
	return null/*getImageFromHash(this, url)*/;
    }

    public void sync()
    {
    }

    public FontMetrics getFontMetrics(Font font) {
		return iFontMetrics.getFontMetrics(font);
    }

    public String[] getFontList() {
	// REMIND: "Helvetica", "TimesRoman", "Courier" and "ZapfDingbats"
	//         will go awy from this list.
	String list[] = {"Dialog", "SansSerif", "Serif", "Monospaced",
					 "Helvetica", "TimesRoman", "Courier",
                     "DialogInput", "ZapfDingbats"};
	return list;
    }


    static native ColorModel makeColorModel();
    static ColorModel screenmodel;

    static ColorModel getStaticColorModel() {
        if (screenmodel == null) {
            screenmodel = makeColorModel();
        }
        return screenmodel;
    }
 
    public ColorModel getColorModel() {
        return getStaticColorModel();
    }
	// nwk+
    public native void loadSystemColors(int[] systemColors);
	// -nwk

    public Dimension getScreenSize() {
	return new Dimension(getScreenWidth(), getScreenHeight());
    }

    public int getScreenResolution()
    {
     return 96;
    }

    protected int getScreenWidth()
    {
     return 640;
    }

    protected int getScreenHeight()
    {
     return 480;
    }

    public FontPeer getFontPeer(String name, int style) {
		return new inferno.awt.iFontPeer(name, style);
    }

    /*
     * Create peer objects.
     */

    public ButtonPeer createButton(Button target) {
	ButtonPeer peer = null;
	//ButtonPeer peer = new WButtonPeer(target);
	//peerMap.put(target, peer);
	return peer;
    }

    public TextFieldPeer createTextField(TextField target) {
	TextFieldPeer peer = null;
	//TextFieldPeer peer = new WTextFieldPeer(target);
	//peerMap.put(target, peer);
	return peer;
    }

    public LabelPeer createLabel(Label target) {
	LabelPeer peer = null;
	//LabelPeer peer = new WLabelPeer(target);
	//peerMap.put(target, peer);
	return peer;
    }

    public ListPeer createList(List target) {
	ListPeer peer = null;
	//ListPeer peer = new WListPeer(target);
	//peerMap.put(target, peer);
	return peer;
    }

    public CheckboxPeer createCheckbox(Checkbox target) {
	CheckboxPeer peer = null;
	//CheckboxPeer peer = new WCheckboxPeer(target);
	//peerMap.put(target, peer);
	return peer;
    }

    public ScrollbarPeer createScrollbar(Scrollbar target) {
	ScrollbarPeer peer = null;
	//ScrollbarPeer peer = new WScrollbarPeer(target);
	//peerMap.put(target, peer);
	return peer;
    }

    public ScrollPanePeer createScrollPane(ScrollPane target) {
	ScrollPanePeer peer = null;
	//ScrollPanePeer peer = new WScrollPanePeer(target);
	//peerMap.put(target, peer);
	return peer;
    }

    public TextAreaPeer createTextArea(TextArea target) {
	TextAreaPeer peer = null;
	//TextAreaPeer peer = new WTextAreaPeer(target);
	//peerMap.put(target, peer);
	return peer;
    }

    public ChoicePeer createChoice(Choice target) {
	ChoicePeer peer = null;
	//ChoicePeer peer = new WChoicePeer(target);
	//peerMap.put(target, peer);
	return peer;
    }

    public FramePeer  createFrame(Frame target) {
//	FramePeer peer = null;
	FramePeer peer = new iFramePeer(target);
	//peerMap.put(target, peer);
	return peer;
    }

    public CanvasPeer createCanvas(Canvas target) {
	CanvasPeer peer = null;
	//CanvasPeer peer = new WCanvasPeer(target);
	//peerMap.put(target, peer);
	return peer;
    }

    public PanelPeer createPanel(Panel target) {
	PanelPeer peer = null;
	//PanelPeer peer = new WPanelPeer(target);
	//peerMap.put(target, peer);
	return peer;
    }

    public WindowPeer createWindow(Window target) {
      //	WindowPeer peer = null;
	WindowPeer peer = new iWindowPeer(target);
	//peerMap.put(target, peer);
	return peer;
    }

    public DialogPeer createDialog(Dialog target) {
	DialogPeer peer = null;
	//DialogPeer peer = new WDialogPeer(target);
	//peerMap.put(target, peer);
	return peer;
    }

    public FileDialogPeer createFileDialog(FileDialog target) {
	FileDialogPeer peer = null;
	//FileDialogPeer peer = new WFileDialogPeer(target);
	//peerMap.put(target, peer);
	return peer;
    }

   public MenuBarPeer createMenuBar(MenuBar target) {
	MenuBarPeer peer = new iMenuBarPeer(target);
	//peerMap.put(target, peer);
	return peer;
//	return null;
    }

    public MenuPeer createMenu(Menu target) {
	MenuPeer peer = null;
	//MenuPeer peer = new WMenuPeer(target);
	//peerMap.put(target, peer);
	return peer;
    }

    public PopupMenuPeer createPopupMenu(PopupMenu target) {
        //PopupMenuPeer peer = null;
	PopupMenuPeer peer = new iPopupMenuPeer(target);
	//peerMap.put(target, peer);
	return peer;
    }

    public MenuItemPeer createMenuItem(MenuItem target) {
	MenuItemPeer peer = null;
	//MenuItemPeer peer = new WMenuItemPeer(target);
	//peerMap.put(target, peer);
	return peer;
    }

    public CheckboxMenuItemPeer createCheckboxMenuItem(CheckboxMenuItem target) {
	CheckboxMenuItemPeer peer = null;
	//CheckboxMenuItemPeer peer = new WCheckboxMenuItemPeer(target);
	//peerMap.put(target, peer);
	return peer;
    }


}




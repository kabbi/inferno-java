package inferno.awt;

import java.awt.*;
import java.awt.event.*;
import java.awt.peer.*;
import java.awt.image.ImageProducer;
import java.awt.image.ImageObserver;
import java.awt.image.ColorModel;
import java.awt.image.DirectColorModel;
import java.util.*;
import inferno.awt.iGraphics;

public class iFramePeer implements FramePeer, DoubleBufferingPeer {
  private Object pCanvas;  // Set inside create() used by natives

  // set inside create(), used by natives, to avoid some clutter in
  // escaping the Limbo type system.
  private Object thisAsJObject; 

  private Frame target;

  private int leftInset=0; // How much canvas is inset from frame
  private int rightInset=0;
  private int topInset=0;
  private int bottomInset=0;
  private int left;  // x position of left of frame
  private int top;   // y position of top of frame

  private Point oldMousePoint;
  private boolean buttonState[];

  private int resizable = 1;

  public iFramePeer(Frame target) {
    this.target = target;
    oldMousePoint=new Point(-1,-1);
    buttonState=new boolean[3];
    for (int i=0;i<3;i++) buttonState[i]=false; //up
    //    create(this);
	if (target.getTitle() != null) {
	    setTitle(target.getTitle());
	}
	Font f = target.getFont();
	if (f == null) {
	    f = new Font("Dialog", Font.PLAIN, 12);
	    target.setFont(f);
	    setFont(f);
	}
	Color c = target.getBackground();
	if (c == null) {
            c = SystemColor.window;
	    target.setBackground(c);
	    setBackground(c);
	}
	c = target.getForeground();
	if (c == null) {
	    target.setForeground(Color.black);
	    setForeground(Color.black);
	}
	if (!target.isResizable())
	    this.resizable = 0;

    create(this);

  }

    /* implementation of java.awt.peer.DoubleBufferingPeer */
    public boolean isDoubleBuffered() {
        return true;
    }

  private native Object getRefImage(); // Returns dev/draw image of canvas

  private native Object getRefOffScreenImage(); // Returns off-screen buffer image

  private native void pReshape(int x, int y, int width, int height);

  private native void pHide();  // Hide frame

  private native void pShow(iFramePeer fp);  // Show frame

  private native int getXYLoc(int coord); // get x or y value of the global position
 
  // Create frame putting canvas in pcanvas
  private native void create(iFramePeer me);

  public native void pDispose(); // Destroy frame
  public native void setCursor(int cursorType); // Set cursor
  public native void setTitle(String title); // Set title of frame
  public native void toFront(); // Move frame to front
  public native void toBack();  // Move frame to back
 

    /* New 1.1 API */
  public Point getLocationOnScreen()  // Return position on screen
    {
  Point p = new Point();
  p.x = getXYLoc(0);
  p.y = getXYLoc(1);
  return p;
    }

  public void recalculate()
  {
        MenuBar mb=target.getMenuBar();
        if (mb!=null)
        {
           iMenuBarPeer ip=(iMenuBarPeer)mb.getPeer();

           if (ip!=null)
           {
            ip.recalculate();
           }
        }
  }

  public void setCursor(Cursor c)
  {
   if (c!=null)
   setCursor(c.getType());
  }

  public void setResizable(boolean resizable)
  {
    System.out.println("java: setResizable() get called" + resizable);
    if(!resizable)
      this.resizable = 0;
  }

  public void setMenuBar(MenuBar mb)
  {
  recalculate();
  }

  public void setIconImage(Image im)
  {
  }

  public Insets getInsets()
  {
   Insets i=new Insets(topInset,leftInset,bottomInset,rightInset);

   MenuBar mb=target.getMenuBar();

   if (mb!=null)
   {
    iMenuBarPeer peer=(iMenuBarPeer)mb.getPeer();

    if (peer!=null)
    {
     i=(Insets)i.clone(); //Get new copy

     i.top+=peer.getHeight();
    }

   }

   return i;
  }

  public Insets insets()
  {
   return getInsets();
  }

  public void endValidate()
  {

  }

  public void beginValidate()
  {

  }

  public void setBounds(int x, int y, int width, int height) {
	pReshape(x, y, width, height);
    }

  public void reshape(int x, int y, int width, int height) {
	pReshape(x, y, width, height);
    }


  public void dispose()
  {
    pDispose();
    pCanvas=null;
  }

  public void disable()
  {
   setEnabled(false);
  }

  public void enable()
  {
   setEnabled(false);
  }

  public void setEnabled(boolean b)
  {

  }

  public void hide()
  {
   setVisible(false);
  }

  public void show()
  {
   setVisible(true);
  }

  public void setVisible(boolean b)
  {
    if (b)
    pShow(this);
    else
    pHide();
  }

    public Dimension getMinimumSize() {
	return target.getSize();
    }

    public Dimension getPreferredSize() {
	return getMinimumSize();
    }

    public Dimension minimumSize() {
	return getMinimumSize();
    }

    public Dimension preferredSize() {
	return getPreferredSize();
    }


    public int checkImage(Image img, int w, int h, ImageObserver o) {
	return 0;
    }

    public FontMetrics getFontMetrics(Font font) {
	return iFontMetrics.getFontMetrics(font);
    }

    public boolean prepareImage(Image img, int w, int h, ImageObserver o) {
	return false;
    }


    public Image createImage(ImageProducer producer) {
	return null/*new Win32Image(producer)*/;
    }
    public Image createImage(int width, int height) {
	return null/*new Win32Image(target, width, height)*/;
    }

    public boolean isFocusTraversable() {
	return false;
    }

    public void requestFocus()
    {
    }

    public void nextFocus()
    {
    }

    public void setFont(Font f)
    {

    }

    public Font getFont()
    {
     return null;
    }

    public void setBackground(Color c)
    {

    }

   public void setForeground(Color c)
    {

    }

    public Graphics getGraphics()
    {
        if (pCanvas==null) {
            System.out.println("iFramePeer.getGraphics(): pCanvas == null!"); // jfs - remove
            return null;	
        }
        Rectangle bounds = target.getBounds();
        Rectangle clip = new Rectangle(bounds.x+leftInset,
				bounds.y+topInset,
				bounds.width-leftInset-rightInset,
				bounds.height-topInset-bottomInset);
       Graphics g=new iGraphics(getRefImage(),getRefOffScreenImage(), clip, target);
       g.translate(bounds.x,bounds.y);   // bounds have already been set - lg
       return g;
    }

    public java.awt.Toolkit getToolkit() {
	return Toolkit.getDefaultToolkit();
    }

    public ColorModel getColorModel() {
	return iToolkit.getStaticColorModel();
    }

    public void handleEvent(AWTEvent e)
    {

    }

    public void print(Graphics g)
    {
    }

    public void paint(Graphics g)
    {
	g.setColor(target.getForeground());
	g.setFont(target.getFont());
        MenuBar mb=target.getMenuBar();
        if (mb!=null)
        {
           iMenuBarPeer ip=(iMenuBarPeer)mb.getPeer();

           if (ip!=null)
           {
             ip.paint(g);
           }
        }
        target.paint(g);
    }


    public void repaint(long tm, int x, int y, int width, int height) {

           iToolkit.postEvent(new PaintEvent((Component)target, PaintEvent.UPDATE,
                                 new Rectangle(x, y, width, height)));

    }

    private void handleKeyEvents(int ch)
    {
      char keyChar = (char)ch;
      boolean control = ch >= 0 && ch <= 31;
      boolean lowercase = ch >= (int)'a' && ch <= (int)'z';
      boolean uppercase = ch >= (int)'A' && ch <= (int)'Z';
      int modifiers = control?InputEvent.CTRL_MASK:
      uppercase?InputEvent.SHIFT_MASK:0;
      int keyCode = control?ch+64:lowercase?ch-32:ch;

      // constructing a Date is slow, System.currentTimeMillis(),
      // is faster, but it's implementation opens #c/time and 
      // converts a string to a big. Fastest still and probably
      // with sufficient resolution would be natively time stamping
      // events with sys->millisec(). -jfs
      //// Date d = new Date();
      //// long when = d.getTime();
      long when = System.currentTimeMillis();


      iToolkit.postEvent(new KeyEvent(target,KeyEvent.KEY_PRESSED,
      when,modifiers,keyCode,keyChar));

      // synthesize events that we don't get from /dev/keyboard via
      // Inferno's Tk (this is some fast typist!)
      /*
        iToolkit.postEvent(new KeyEvent(target,KeyEvent.KEY_TYPED,
                   when+1,modifiers,keyCode,keyChar));
        iToolkit.postEvent(new KeyEvent(target,KeyEvent.KEY_RELEASED,
                   when+2,modifiers,keyCode,keyChar));
      */
    }

    private void handleMouseEvents(int m,int button,int x,int y)
    {
      char mode=(char)m;
      //      System.out.println("Mouse event "+mode+" "+button+" "+x+" "+y);
      switch(mode)
      {
case 'd':
case 'r':
case 'm':
case 'p':
          Rectangle bounds = target.getBounds();
          int xx=x-bounds.x-leftInset;
          int yy=y-bounds.y; // -topInset; 

          Point mousePoint=new Point(xx,yy);
          long when = System.currentTimeMillis();
          int modifier;

          switch(button)
          {
case 1:
       modifier=InputEvent.BUTTON1_MASK;
       break;

case 2:
       modifier=InputEvent.BUTTON2_MASK;
       break;

case 3:
       modifier=InputEvent.BUTTON3_MASK;
       break;

default:
        modifier=0;
        }

         switch(mode)
         {
case 'p': // Pressed
case 'd': // Double click
         {
          if (button>0 && button<=3 && buttonState[button-1]==false)
          {
            oldMousePoint=mousePoint;
             buttonState[button-1]=true;
           iToolkit.postEvent(new MouseEvent(target,MouseEvent.MOUSE_PRESSED,
           when,modifier,xx,yy,1,false));

          }
           break;
         }
case 'r':  // Released
         {
          if (button>0 && button<=3 && buttonState[button-1]==true)
          {
             buttonState[button-1]=false;
           iToolkit.postEvent(new MouseEvent(target,MouseEvent.MOUSE_RELEASED,
           when,modifier,xx,yy,1,false));
           if (mousePoint.equals(oldMousePoint))
           {
           iToolkit.postEvent(new MouseEvent(target,MouseEvent.MOUSE_CLICKED,
           when,modifier,xx,yy,1,button==2));
           }
          }
           break;
         }
case 'm':  // Moved
           {
            modifier=0;
            if (buttonState[0]) modifier|=InputEvent.BUTTON1_MASK;
            if (buttonState[1]) modifier|=InputEvent.BUTTON2_MASK;
            if (buttonState[2]) modifier|=InputEvent.BUTTON3_MASK;
           iToolkit.postEvent(new MouseEvent(target,
           modifier==0?MouseEvent.MOUSE_MOVED:MouseEvent.MOUSE_DRAGGED,
           when,modifier,xx,yy,1,false));

           break;
           }
default:
  //	   System.out.println("focusEvent:" + mouseString);
         }
	 break;
      }

    //	 System.out.println("mouseString "+mouseString);
    }

    private void moveSize(int x, int y, int width, int height)
    {
	Rectangle old = target.getBounds();
	Rectangle n = new Rectangle(x, y, width, height);
	if (!n.equals(old)){
		target.setBounds(x, y, width, height);
		target.validate();
       		target.repaint();
	}
     }

    private void paintTarget(int x, int y, int width, int height)
    {
	target.setBounds(x, y, width, height);
	target.validate();
	target.repaint();
     }

    // 
    // Callbacks from native for Window Events
    //
    private void handleActivated() {
        iToolkit.postEvent(new WindowEvent(target,
                     WindowEvent.WINDOW_ACTIVATED));
        iToolkit.postEvent(new FocusEvent(target,
                     FocusEvent.FOCUS_GAINED, false));
    }
    private void handleDeactivated() { 
        iToolkit.postEvent(new WindowEvent(target,
                     WindowEvent.WINDOW_DEACTIVATED));
        iToolkit.postEvent(new FocusEvent(target,
                     FocusEvent.FOCUS_LOST, true));
    }
    private void handleClosing() { 
        //System.out.println("iFramePeer.handleClosing():");
        // Java Frame can then call System.exit() to shutdown the VM
        // if it so desires
        iToolkit.postEvent(new WindowEvent(target,
                     WindowEvent.WINDOW_CLOSING));
    }
    private void handleIconified() {
        //System.out.println("iFramePeer.handleIconified():");
        iToolkit.postEvent(new WindowEvent(target,
                     WindowEvent.WINDOW_ICONIFIED));

    }
    private void handleDeIconified() {
      // System.out.println("iFramePeer.handleDeiconified():");
	        iToolkit.postEvent(new WindowEvent(target,
                     WindowEvent.WINDOW_DEICONIFIED));

        // may need to make Cursors visible as well??? - jfs
	// target.repaint();
    }
}



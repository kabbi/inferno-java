/*
 * %W% - %E%
 */

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

public class iWindowPeer implements WindowPeer, DoubleBufferingPeer {
  Object pCanvas;  // Set inside create()
  Window target;
  int leftInset=0; // How much canvas is inset from window
  int rightInset=0;
  int topInset=0;
  int bottomInset=0;
  int left;  // x position of left of window
  int top;   // y position of top of window

  private Point oldMousePoint;
  private boolean buttonState[];

  public iWindowPeer(Window target) {
    this.target = target;
    oldMousePoint=new Point(-1,-1);
    buttonState=new boolean[3];
    for (int i=0;i<3;i++) buttonState[i]=false; //up
    create(this);
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

  }

    /* implementation of java.awt.peer.DoubleBufferingPeer */
    public boolean isDoubleBuffered() {
        return true;
    }

  native Object getRefImage(); // Returns $Draw->Image of canvas
  native Object getRefOffScreenImage(); // Returns off-screen buffer image

  native void pReshape(int x, int y, int width, int height);

  native void pHide();  // Hide window

  native void pShow(iWindowPeer fp);  // Show window

  native int getXYLoc(int coord); // get x or y value of the global position

  public native void create(iWindowPeer fp); // Create window putting canvas in pcanvas

  public native void pDispose(); // Destroy window

  public native void setCursor(int cursorType); // Set cursor


    /* New 1.1 API */
  public Point getLocationOnScreen()  // Return position on screen
    {
  Point p = new Point();
  p.x = getXYLoc(0);
  p.y = getXYLoc(1);
  return p;
    }

  public void setCursor(Cursor c)
  {
   if (c!=null)
   setCursor(c.getType());
  }

  public native void toFront(); // Move window to front

  public native void toBack();  // Move window to back

  public Insets getInsets()
  {
   Insets i=new Insets(topInset,leftInset,bottomInset,rightInset);
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
       if (pCanvas == null) {
		System.out.println("iWindowPeer:getGraphics()s: pCanvas == null, continuing!"); // jfs -remove
  		return null;   	
	}
       Rectangle bounds = target.getBounds();
       Rectangle clip = new Rectangle(bounds.x+leftInset,
                                bounds.y+topInset,
                                bounds.width-leftInset-rightInset,
                                bounds.height-topInset-bottomInset);
       Graphics g=new iGraphics(getRefImage(),getRefOffScreenImage(), clip,
target);
       g.translate(bounds.x,bounds.y);
       return g;
    }

    public java.awt.Toolkit getToolkit() {
        // XXX: bogus
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
        target.paint(g);
    }


    public void repaint(long tm, int x, int y, int width, int height) {
           iToolkit.postEvent(new PaintEvent((Component)target, PaintEvent.UPDATE,
                              new Rectangle(x, y, width, height)));

    }

    public void handleKeyEvents(int ch)
    {
      char keyChar = (char)ch;
      boolean control = ch >= 0 && ch <= 31;
      boolean lowercase = ch >= (int)'a' && ch <= (int)'z';
      boolean uppercase = ch >= (int)'A' && ch <= (int)'Z';
      int modifiers = control?InputEvent.CTRL_MASK:
      uppercase?InputEvent.SHIFT_MASK:0;
      int keyCode = control?ch+64:lowercase?ch-32:ch;
      Date d = new Date();
      long when = d.getTime();

      iToolkit.postEvent(new KeyEvent(target,KeyEvent.KEY_PRESSED,
      when,modifiers,keyCode,keyChar));

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
          //Date d = new Date();
          //long when = d.getTime();
	  long when=0;
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
	      //	  System.out.println("MouseString: " + mouseString);
	    }
      break;
    }
}

    private void movesize(int x, int y, int width, int height)
    {
        Rectangle old = target.getBounds();
        Rectangle n = new Rectangle(x, y, width, height);
        if (!n.equals(old)){
                target.setBounds(x, y, width, height);
                target.repaint();
        }
     }

    public void handleFocusGained()
    {

    }
}









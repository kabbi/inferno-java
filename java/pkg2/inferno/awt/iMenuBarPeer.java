package inferno.awt;

import java.awt.*;
import java.awt.event.*;
import java.awt.peer.*;

public class iMenuBarPeer implements
MenuBarPeer,MouseListener,MouseMotionListener,zMenuParent {
    MenuBar     target;
    int height;
    zMenuBarObject selectedMenuObject;
    zMenuBarObject menuObjects[];
    int menuObjectCount;
    Window child;

    public void closeChild(Window w)
    {
     // Called from child via zMenuParent interface to
     // close itself down. Since Window may take some time to
     // close down, check to see if we are still the child window
     // not the previous window
     if (child!=null && child==w)
     {

      child.setVisible(false);   // Hide Window
      child.dispose();           // Destroy window
      child=null;                // Lose reference to Window
      if (selectedMenuObject!=null)
	{
         // If menu item selected, display not selected
	  Frame frm=(Frame)target.getParent();
	  Graphics g=frm.getGraphics();
	  selectedMenuObject.paint(g,0);
	  g.dispose();
	}
     }
    }

    public void closeEverything()
	{
         // Close our child
	  closeChild(child);
	}

    void create(Frame f)
    {
     // Calculate sizes
      recalculate();
    }

    public iMenuBarPeer(MenuBar target) {
        Frame frm=(Frame)target.getParent();
        frm.addMouseListener(this);
        frm.addMouseMotionListener(this);
        this.target = target;
        create(frm);
    }

    // Required by MenuBarPeer interface but not used
    public void dispose()
    {
    }

    public void addMenu(Menu m) {
     // Calculate sizes
      recalculate();
    }

    public void delMenu(int index) {
     // Calculate sizes
      recalculate();
    }

    public void addHelpMenu(Menu m) {
     // Calculate sizes
      recalculate();
    }

    // Calculate height of menubar
    public int getHeight()
    {
     height=0;

     if (target!=null)
     {
        Frame frm=(Frame)target.getParent();
        for (int i=target.getMenuCount()-1;i>=0;--i)
        {
         Menu m=target.getMenu(i);
         Font f=m.getFont();
         FontMetrics fm=frm.getFontMetrics(f);

         height=Math.max(height,fm.getHeight()+2);
        }
     }
     return height;
    }

    public void recalculate()
    {
    // Create all the objects
     if (target!=null)
     {
      Frame frm=(Frame)target.getParent();
      Rectangle d=frm.getBounds();
      Insets is=frm.getInsets();
      Menu hm=target.getHelpMenu();

       selectedMenuObject=null;
       menuObjects=null;
       menuObjectCount=target.getMenuCount();
       if (menuObjectCount!=0)
	 {
	   int x=is.left;
	   int y=is.top-height;
	   menuObjects=new zMenuBarObject[menuObjectCount];


	   for (int i=0;i<menuObjectCount;i++)
	     {
	       int w,xx;
	       Menu m=target.getMenu(i);
	       Font f=m.getFont();
	       if (f==null)
		 {
		   w=0;
		   xx=0;
		 }
	       else
		 {
		   FontMetrics fm=frm.getFontMetrics(f);
		   w=fm.stringWidth(" "+m.getLabel()+" ")+2;

		   if (m==hm)
		     {
		       xx=d.width-is.right-w;
		     }
		   else
		     {
		       xx=x;
		       x+=w;
		     }

		 }
	       menuObjects[i]=new zMenuBarObject(m,new Rectangle(xx,y,w,height));

	     }
	 }

     }
    }

    // Not the Component paint but similar
    // called from Frame.paint
    public void paint(Graphics gg)
    {
      Frame frm=(Frame)target.getParent();
      Insets is=frm.getInsets();
      Rectangle d=frm.getBounds();
      int y=is.top-height;
      int x=is.left;
      int w=d.width-is.left-is.right;
      int h=height;
      Graphics g=gg.create();

      // Display the menu objects
     g.setClip(x,y,w,h);
     g.setColor(SystemColor.menu);
     g.fillRect(x,y,w,h);

     for (int i=0;i<menuObjectCount;i++)
     menuObjects[i].paint(g);


     g.dispose();
    }

    public void mouseExited(MouseEvent e)
    {
    // Deselect if mouse exits window
    // (Almost certainly never called by inferno)
    if (selectedMenuObject!=null)
    {
      Frame frm=(Frame)target.getParent();
    Graphics g=frm.getGraphics();
     selectedMenuObject.paint(g,0);
     selectedMenuObject=null;
     g.dispose();
    }
    }

    // Required by listener interface but not used
    public void mouseEntered(MouseEvent e)
    {
    }

    // Required by listener interface but not used
    public void mouseClicked(MouseEvent e)
    {
    }

    public void mousePressed(MouseEvent e)
    {
     // If within an object (selectMenuObject set by mouseMove)
     if (selectedMenuObject!=null && selectedMenuObject.area.contains(e.getPoint()))
       {
	 Frame frm=(Frame)target.getParent();
	 Graphics g=frm.getGraphics();
	 selectedMenuObject.paint(g,-1);
	 g.dispose();

	 Menu menu=selectedMenuObject.menu;
	 if(menu != null){
	   Rectangle md=selectedMenuObject.area;
	   Rectangle fd=frm.getBounds();
	   int xoff=md.x;
	   int yoff=md.y+md.height;

	   closeChild(child);
	   child=new zMenuWindow(frm,this,menu,xoff,yoff);
	   child.pack();
	   child.setVisible(true);
	 }
       }
     else
       {
        // Close child window (if any)
	 if (child != null)
	   closeChild(child);
           // Display deselected
	 if(selectedMenuObject != null){
	   Frame frm=(Frame)target.getParent();
	   Graphics g=frm.getGraphics();
	   selectedMenuObject.paint(g,0);
	   g.dispose();
	 }
       }
    }

    // Require by listener interface but not used
    public void mouseReleased(MouseEvent e)
    {
    }

    public void mouseMoved(MouseEvent e)
    {
     // Track the mouse movement over the menuObjects
     // setting selectedMenuObject as appropriate
      if (selectedMenuObject==null ||
	  !selectedMenuObject.area.contains(e.getPoint()))
	{
	  Frame frm=(Frame)target.getParent();
	  Graphics g=frm.getGraphics();
	  //	  if (selectedMenuObject!=null && child==null)
	  if (selectedMenuObject!=null)
	    {
	      selectedMenuObject.paint(g,0);
	      selectedMenuObject=null;
	    }

	  for (int i=0;i<menuObjectCount;i++)
	    if (menuObjects[i].area.contains(e.getPoint()))
	      {
		if (selectedMenuObject!=null)
		  {
		    selectedMenuObject.paint(g,0);
		    selectedMenuObject=null;
		  }
		if (menuObjects[i].menu.isEnabled())
		  {
		    int mode=1;
		    selectedMenuObject=menuObjects[i];
		    if (child!=null)
		      {
			Menu menu=selectedMenuObject.menu;
			Rectangle md=selectedMenuObject.area;
			Rectangle fd=frm.getBounds();
			int xoff=md.x;
			int yoff=md.y+md.height;

			Window newChild=new zMenuWindow(frm,this,menu,xoff,yoff);
			newChild.pack();
			newChild.setVisible(true);
			closeChild(child);
			child=newChild;
			mode=-1;
		      }

		    selectedMenuObject.paint(g,mode);
		  }
		break;
	      }

	  g.dispose();
	}
    }

    // Require by listener interface but not used
    public void mouseDragged(MouseEvent e)
    {
    }


}

// This is the object corresponding to the menu items
// on the menubar
class zMenuBarObject {
      Menu menu;
      Rectangle area;
      int mode;

      public zMenuBarObject(Menu menu,Rectangle area)
      {
       this.menu=menu;
       this.area=area;
       this.mode=0;
      }

      public void paint(Graphics g,int mode)
      {
       this.mode=mode;
       paint(g);
      }

      // Not the component paint but similar
      // displays the menu item
      public void paint(Graphics g)
      {
       Font f=menu.getFont();
       FontMetrics fm=g.getFontMetrics(f);

            g.setColor(SystemColor.menu);

      if (mode!=0)
      Misc.fill3DRect(area,mode>0,g);
      else
      g.fillRect(area.x,area.y,area.width,area.height);

     g.translate(-mode,-mode);

            g.setFont(f);
            if (menu.isEnabled())
            {
            g.setColor(SystemColor.menuText);
            g.drawString(" "+menu.getLabel(),area.x+1,area.y+fm.getAscent()+1);
            }
            else
            {
            Misc.drawDisabledString(" "+menu.getLabel(),area.x+1,area.y+fm.getAscent()+1,g);

            }

     g.translate(+mode,+mode);

      }

}

// This the window containing the dropdown menus
// the painting is done by zMenuDisplay
// zMenuDisplay returns its size and the Window sizes itself
// accordingly

class zMenuWindow extends Window implements ComponentListener,zMenuParent{
     zMenuDisplay menudisplay;
     zMenuParent ancestor;
     int xoffset,yoffset;

  public zMenuWindow(Frame f,zMenuParent ancestor,Menu menu,int xoffset,int yoffset)
{
         super(f);
         this.xoffset=xoffset;
         this.yoffset=yoffset;
         this.ancestor=ancestor;
         Point p=f.getLocation();
         p.translate(this.xoffset,this.yoffset);
         setLocation(p);
         f.addComponentListener(this);
         this.menudisplay=new zMenuDisplay(menu);
         add(this.menudisplay,BorderLayout.CENTER);
  }

  public void closeChild(Window w)
  {
   if (menudisplay!=null)
   {
       if (!menudisplay.gotFocus() && ancestor!=null)
       ancestor.closeChild(this);
       else
       menudisplay.closeChild(w);
   }
  }

 public void closeEverything()
{
	if (ancestor!=null)
	ancestor.closeEverything();
}	

  public boolean gotFocus()
  {
   if (menudisplay==null)
   return false;
   else
   return menudisplay.gotFocus();

  }

  public void componentHidden(ComponentEvent e)
  {

  }

  public void componentMoved(ComponentEvent e)
  {
   Point p=e.getComponent().getLocation();
   p.translate(xoffset,yoffset);
   setLocation(p);
  }

  public void componentResized(ComponentEvent e)
  {

  }

  public void componentShown(ComponentEvent e)
  {

  }

  public void dispose()
  {
  if (menudisplay!=null)
  {
   menudisplay.closeChild(this);
  }
   super.dispose();
  }

}

// This is the display part of the zMenuWindow
// it covers the whole window

class zMenuDisplay extends Canvas implements
MouseListener,MouseMotionListener,
FocusListener{
  zMenuObject menuObjects[];
  zMenuObject selectedMenuObject;
  zMenuWindow child;
  int menuObjectCount;
  Dimension pSize;
  boolean focus;
  Menu menu;
    static Color highlight  = SystemColor.controlHighlight;
    static Color light = SystemColor.controlLtHighlight;
    static Color medium = SystemColor.controlShadow;
    static Color dark = SystemColor.controlDkShadow;


    static final int TickBoxSize=13;

    static final int TickLabelGap=4;

    static final int SeparatorHeight=6;


  public zMenuDisplay(Menu menu)

  {
   super();
   setMenu(menu);
         addMouseListener(this);
         addMouseMotionListener(this);
         addFocusListener(this);
  }

    public boolean isFocusTraversable() {
        return false;
    }


 void setMenu(Menu menu)

 {

   int maxwidth=0;

   int yy=4;

   int xx=4;

   this.menu=menu;


   menuObjectCount=menu.getItemCount();


   selectedMenuObject=null;


   if (menuObjectCount==0)

   menuObjects=null;

   else

   {

   menuObjects=new zMenuObject[menuObjectCount];


   boolean submenu=false;

   for (int i=0;i<menuObjectCount;i++)

   {

    MenuItem mi=menu.getItem(i);

    String label=mi.getLabel();
    if (!submenu && mi instanceof Menu) submenu=true;


    if (!label.equals("-"))

    {

     Font f=mi.getFont();

     FontMetrics fm=getFontMetrics(f);


     maxwidth=Math.max(maxwidth,TickBoxSize+TickLabelGap+fm.stringWidth(label));


    }


   }

   maxwidth+=2; // For outside lines

   if (submenu) maxwidth+=8;

   for (int i=0;i<menuObjectCount;i++)
   {

    MenuItem mi=menu.getItem(i);

    String label=mi.getLabel();
    int h;


    if (label.equals("-"))
    {
     h=SeparatorHeight;     // Height

        menuObjects[i]=new zMenuSeparator(new Rectangle(xx,yy,maxwidth,h));

    }
    else
    {
     Font f=mi.getFont();
     FontMetrics fm=getFontMetrics(f);
     h=Math.max(fm.getHeight(),TickBoxSize)+4; //Height

        menuObjects[i]=new zMenuText(mi,new Rectangle(xx,yy,maxwidth,h));

    }

    yy+=h;


   }


   }

   pSize=new Dimension(xx+maxwidth+4,yy+4);

 }


 public Dimension getPreferredSize()

 {

  return pSize;

 }


  public void paint(Graphics g)
  {
   Dimension d=getSize();

   g.setColor(SystemColor.menu);

   Misc.Draw3DArea(0,0,d.width,d.height,g);

   for (int i=0;i<menuObjectCount;i++)
   menuObjects[i].paint(g,0);

  }

  void closeChild()
  {
   closeChild(child);
  }

  void closeChild(Window w)
  {
     if (w!=null && w == child)
     {
      w.setVisible(false);
      w.dispose();
      w=null;
     }
     if (child!=null)
     {
      child.setVisible(false);
      child.dispose();
      child = null;
     }     
  }

   	

  // Required by listener interface but not used
  public void mouseClicked(MouseEvent e)
  {
  }

  // Required by listener interface but not used
  public void mouseEntered(MouseEvent e)
  {
  }

  // Required by listener interface but not used
  public void mouseExited(MouseEvent e)
  {
  }

  // Required by listener interface but not used
  public void mousePressed(MouseEvent e)
  {
  }

  public void mouseReleased(MouseEvent e)
  {
   if (selectedMenuObject!=null && selectedMenuObject instanceof zMenuText)
   {
     MenuItem menuItem=((zMenuText)selectedMenuObject).item;
     if (menuItem.isEnabled() && !(menuItem instanceof Menu))
       {
	 String actionCommand=menuItem.getActionCommand();
	 iToolkit.postEvent(new ActionEvent(menuItem, ActionEvent.ACTION_PERFORMED,
                          actionCommand));
	 zMenuWindow w=(zMenuWindow)getParent();
	 Frame f=(Frame)w.getParent();
	 f.requestFocus();
	 w.closeEverything();	
       }
   }
  }

  public void mouseMoved(MouseEvent e)
  {
   if (!focus)
   {
    focus=true;
    requestFocus();
   }

   if (selectedMenuObject==null ||
   !selectedMenuObject.area.contains(e.getPoint()))
   {
    Graphics g=getGraphics();
    if (selectedMenuObject!=null)
    {
     selectedMenuObject.paint(g,0);
     selectedMenuObject=null;
     closeChild(child);
    }
     for (int i=0;i<menuObjectCount;i++)
     if (menuObjects[i].area.contains(e.getPoint()))
       {
	 int mode=1;

	 selectedMenuObject=menuObjects[i];
	 if (selectedMenuObject instanceof zMenuText)
	 {
	   zMenuText mo=(zMenuText)selectedMenuObject;

	   if (mo.item.isEnabled())
	     {
	       zMenuWindow w=(zMenuWindow)getParent();
	       Frame f=(Frame)w.getParent();

	       if (mo.item instanceof Menu)
		 {
		   int xx=w.xoffset+mo.area.x+mo.area.width;
		   int yy=w.yoffset+mo.area.y;
		   Menu menu=(Menu)mo.item;

		   mode=-1;

		   zMenuWindow newChild=new zMenuWindow(f,w,menu,xx,yy);
		   newChild.pack();
		   newChild.setVisible(true);
		   closeChild(child);
		   child=newChild;
		 }
	     }
	   selectedMenuObject.paint(g,mode);
	 }
       break;
     }

     g.dispose();
   }
  }

  public void mouseDragged(MouseEvent e)
  {
   mouseMoved(e);
  }

  public boolean gotFocus()
  {
   if (focus)
   return true;
   else
   if (child==null)
   return false;
   else
   return child.gotFocus();

  }

  public void focusLost(FocusEvent e)
  {
   focus=false;
   if (!gotFocus())
   {
    zMenuWindow m=(zMenuWindow)getParent();
    if (m.ancestor!=null) m.ancestor.closeChild(m);
   }
  }

  public void focusGained(FocusEvent e)
  {
   focus=true;

  }

}

// base class for the menuObjects

abstract class zMenuObject {
      Rectangle area;

      public zMenuObject()
      {
      }

      public zMenuObject(Rectangle area)
      {
       this.area=area;
      }

      public abstract void paint(Graphics g,int mode);

}

// Standard item item class

class zMenuText extends zMenuObject {
      MenuItem item;

public zMenuText(MenuItem item,Rectangle area)
{
 super(area);
 this.item=item;
}


void drawArrow(Graphics g,int x,int y)
{
 for (int i=0;i<4;i++)
 {
   g.drawLine(x,y+i,x+3-i,y+i);
   if (i!=0)
   g.drawLine(x,y-i,x+3-i,y-i);
 }
}

public void paint(Graphics g,int mode)
{
     Font f=item.getFont();
     FontMetrics fm=g.getFontMetrics(f);
     int fa=fm.getAscent();
     boolean enabled=item.isEnabled();
     boolean submenu=item instanceof Menu;
     boolean checked=(item instanceof CheckboxMenuItem?
     ((CheckboxMenuItem)item).getState():false);
     String s=item.getLabel();
     int xx=area.x;
     int yy=area.y;

     g.setFont(f);
     if (enabled)
     {
     g.setColor(SystemColor.menu);
      if (mode!=0)
      Misc.fill3DRect(area,mode>0,g);
      else
      g.fillRect(xx,yy,area.width,area.height);

      xx+=2;
      yy+=2;
     g.setColor(SystemColor.menuText);
     g.translate(-mode,-mode);
     if (checked) Misc.drawTick(g,xx,yy,zMenuDisplay.TickBoxSize);

g.drawString(s,zMenuDisplay.TickBoxSize+zMenuDisplay.TickLabelGap+xx,yy+fa);
     if (submenu)
     drawArrow(g,area.x+area.width-6,area.y+area.height/2);
     g.translate(+mode,+mode);
     }
     else
     {
      xx+=2;
      yy+=2;
     if (checked)
     {
       g.setColor(SystemColor.controlLtHighlight);
       Misc.drawTick(g,xx+1,yy+1,zMenuDisplay.TickBoxSize);
       g.setColor(SystemColor.controlShadow);
       Misc.drawTick(g,xx,yy,zMenuDisplay.TickBoxSize);
     }

Misc.drawDisabledString(s,zMenuDisplay.TickBoxSize+zMenuDisplay.TickLabelGap+xx,yy+fa,g);
      if (submenu)
      {
       g.setColor(SystemColor.controlLtHighlight);
       drawArrow(g,area.x+area.width-6+1,area.y+area.height/2+1);
       g.setColor(SystemColor.controlShadow);
       drawArrow(g,area.x+area.width-6,area.y+area.height/2);
      }
     }


}

}

// separator bar

class zMenuSeparator extends zMenuObject {

public zMenuSeparator(Rectangle area)
{
 super(area);
}

public void paint(Graphics g,int mode)
{
    int y=area.y+zMenuDisplay.SeparatorHeight/2-1;

    g.setColor(zMenuDisplay.medium);
    g.drawLine(area.x,y,area.x+area.width,y);

    y+=1;

    g.setColor(zMenuDisplay.light);
    g.drawLine(area.x,y,area.x+area.width,y);


}

}

// The interface to look backwards to parent to close ourselves

interface zMenuParent {


          // Called by child (or parent) to close and delete itself
       public void closeChild(Window W);

       // Close all the windows back to the menubar
	public void closeEverything();

}









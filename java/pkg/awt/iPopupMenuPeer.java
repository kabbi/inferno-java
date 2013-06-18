package inferno.awt;

import java.awt.*;
import java.applet.*;
import java.awt.event.*;
import java.awt.peer.*;
import inferno.awt.*;

public class iPopupMenuPeer implements PopupMenuPeer,zPopupMenuParent {
    PopupMenu     target;
    Window child;

    public void show(Event e)
    {
     Object o=e.target;

     if (o instanceof Component)
     {
      Component c=(Component)o;
      Point pc=c.getLocationOnScreen();
      Container p;

      if (c instanceof Container)
      p=(Container)c;
      else
      p=c.getParent();

      if (p!=null)
      {
       Window w=null;

       while (true)
       {
         if (p instanceof Frame)
         {
          Frame f=(Frame)p;

          Point pf=f.getLocationOnScreen();

          closeChild(child);

          child=new zPopupMenu(f,this,target,pc.x+e.x-pf.x,pc.y+e.y-pf.y);
          child.pack();
          child.setVisible(true);

          break;
        }
        else
        if (p instanceof Applet)
        {
         Applet a=(Applet)p;

         break;
        }

        p=p.getParent();

        if (p==null) break;
       }


      }



     }


    }

    public void delItem(int item)
    {

    }


    public void addItem(MenuItem item)
    {

    }

    public void addSeparator()
    {
    }

    public void disable()
    {

    }

    public void enable()
    {

    }

    public void setEnabled(boolean state)
    {

    }

    public void setLabel(String label)
    {

    }


    public void closeChild(Window w)
    {
     if (child!=null && child==w)
     {
      child.setVisible(false);
      child.dispose();
      child=null;
     }
    }

    public void closeEverything()
        {
          closeChild(child);
        }

    public iPopupMenuPeer(PopupMenu target) {
        this.target = target;
    }

    public void dispose()
    {
    }

}

class zPopupMenu extends Window implements ComponentListener,zPopupMenuParent{
     zPopupMenuDisplay menudisplay;
     zPopupMenuParent ancestor;
     int xoffset,yoffset;

  public zPopupMenu(Frame f,zPopupMenuParent ancestor,Menu menu,int xoffset,int yoffset)
{
         super(f);
         this.xoffset=xoffset;
         this.yoffset=yoffset;
         this.ancestor=ancestor;
         Point p=f.getLocation();
         p.translate(this.xoffset,this.yoffset);
         setLocation(p);
         f.addComponentListener(this);
         this.menudisplay=new zPopupMenuDisplay(menu);
         add(this.menudisplay,BorderLayout.CENTER);
         //System.out.println("zPopupMenu Called: " + this);
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

class zPopupMenuDisplay extends Canvas implements
MouseListener,MouseMotionListener,
FocusListener{
  zPopupMenuObject menuObjects[];
  zPopupMenuObject selectedMenuObject;
  zPopupMenu child;
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


  public zPopupMenuDisplay(Menu menu)

  {
   super();
   setMenu(menu);
         addMouseListener(this);
         addMouseMotionListener(this);
         /*addKeyListener(this);*/
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

   menuObjects=new zPopupMenuObject[menuObjectCount];


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

        menuObjects[i]=new zPopupMenuSeparator(new Rectangle(xx,yy,maxwidth,h));

    }
    else
    {
     Font f=mi.getFont();
     FontMetrics fm=getFontMetrics(f);
     h=Math.max(fm.getHeight(),TickBoxSize)+4; //Height

        menuObjects[i]=new zPopupMenuText(mi,new Rectangle(xx,yy,maxwidth,h));

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
     if (child!=null && child==w)
     {
      child.setVisible(false);
      child.dispose();
      child=null;
     }
  }

        


  public void mouseClicked(MouseEvent e)
  {
  }

  public void mouseEntered(MouseEvent e)
  {
  }

  public void mouseExited(MouseEvent e)
  {
  }

  public void mousePressed(MouseEvent e)
  {
  }

  public void mouseReleased(MouseEvent e)
  {
   if (selectedMenuObject!=null && selectedMenuObject instanceof zPopupMenuText)
   {
   MenuItem menuItem=((zPopupMenuText)selectedMenuObject).item;
   if (menuItem.isEnabled() && !(menuItem instanceof Menu))
   {
   String actionCommand=menuItem.getActionCommand();
   iToolkit.postEvent(new ActionEvent(menuItem, ActionEvent.ACTION_PERFORMED,
                          actionCommand));
    zPopupMenu w=(zPopupMenu)getParent();
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
   if (selectedMenuObject instanceof zPopupMenuText)
   {
    zPopupMenuText mo=(zPopupMenuText)selectedMenuObject;

     if (mo.item.isEnabled())
     {
    zPopupMenu w=(zPopupMenu)getParent();
    Frame f=(Frame)w.getParent();

    if (mo.item instanceof Menu)
    {
      int xx=w.xoffset+mo.area.x+mo.area.width;
      int yy=w.yoffset+mo.area.y;
     Menu menu=(Menu)mo.item;

     mode=-1;

        zPopupMenu newChild=new zPopupMenu(f,w,menu,xx,yy);
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
    zPopupMenu m=(zPopupMenu)getParent();
    if (m.ancestor!=null) m.ancestor.closeChild(m);
   }
  }

  public void focusGained(FocusEvent e)
  {
   focus=true;

  }

}

abstract class zPopupMenuObject {
      Rectangle area;

      public zPopupMenuObject()
      {
      }

      public zPopupMenuObject(Rectangle area)
      {
       this.area=area;
      }

      public abstract void paint(Graphics g,int mode);

}

class zPopupMenuText extends zPopupMenuObject {
      MenuItem item;

public zPopupMenuText(MenuItem item,Rectangle area)
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
     if (checked) Misc.drawTick(g,xx,yy,zPopupMenuDisplay.TickBoxSize);

g.drawString(s,zPopupMenuDisplay.TickBoxSize+zPopupMenuDisplay.TickLabelGap+xx,yy+fa);
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
       Misc.drawTick(g,xx+1,yy+1,zPopupMenuDisplay.TickBoxSize);
       g.setColor(SystemColor.controlShadow);
       Misc.drawTick(g,xx,yy,zPopupMenuDisplay.TickBoxSize);
     }


Misc.drawDisabledString(s,zPopupMenuDisplay.TickBoxSize+zPopupMenuDisplay.TickLabelGap+xx,yy+fa,g);
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

class zPopupMenuSeparator extends zPopupMenuObject {

public zPopupMenuSeparator(Rectangle area)
{
 super(area);
}

public void paint(Graphics g,int mode)
{
    int y=area.y+zPopupMenuDisplay.SeparatorHeight/2-1;

    g.setColor(zPopupMenuDisplay.medium);
    g.drawLine(area.x,y,area.x+area.width,y);

    y+=1;

    g.setColor(zPopupMenuDisplay.light);
    g.drawLine(area.x,y,area.x+area.width,y);


}

}

interface zPopupMenuParent {

       public void closeChild(Window W);

        public void closeEverything();          

}






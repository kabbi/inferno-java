package java.awt;

import java.awt.*;

public class Misc {

       public static void drawDisabledString(String label,int x,int y,Graphics g)
       {
        Color c=g.getColor();
         g.setColor(SystemColor.controlLtHighlight);
         g.drawString(label,x+1,y+1);
         g.setColor(SystemColor.controlShadow);
         g.drawString(label,x,y);
         g.setColor(c);
       }

       public static void fill3DRect(int x,int y,int width,int height,boolean raised,Graphics g)
       {
        fill3DRect(new Rectangle(x,y,width,height),raised,g);
       }

       public static void fill3DRect(Rectangle area,boolean raised,Graphics g)
       {
       int left=area.x;
       int top=area.y;
       int bottom=top+area.height-1;
       int right=left+area.width-1;

       Color c=g.getColor();

        g.setColor(raised?SystemColor.controlLtHighlight:SystemColor.controlShadow);

        g.drawLine(left,top,right-1,top);
        g.drawLine(left,top+1,left,bottom);

        g.setColor(raised?SystemColor.controlShadow:SystemColor.controlLtHighlight);

        g.drawLine(right,bottom,right,top);
        g.drawLine(right-1,bottom,left+1,bottom);

        g.setColor(c);

        g.fillRect(left+1,top+1,area.width-2,area.height-2);

       }


      public static void Draw3DArea(int x,int y,int width,int height,Graphics g)
      {
       Draw3DArea(new Rectangle(x,y,width,height),g);
    }

      public static void Draw3DArea(Rectangle area,Graphics g)
      {
       int left=area.x;
       int top=area.y;
       int bottom=top+area.height-1;
       int right=left+area.width-1;

        g.setColor(SystemColor.controlHighlight);
        g.drawLine(left,top,left,bottom-1);
        g.drawLine(left,top,right-1,top);

        g.setColor(SystemColor.controlLtHighlight);
        g.drawLine(left+1, top+1, right-2, top+1);
        g.drawLine(left+1, top+2, left+1, bottom-2);

        g.setColor(SystemColor.controlShadow);
        g.drawLine(right-1, top+1, right-1, bottom-1);
        g.drawLine(left+1, bottom-1, right-1, bottom-1);

        g.setColor(SystemColor.controlDkShadow);
        g.drawLine(right, top, right, bottom);
        g.drawLine(left, bottom, right, bottom);


        }


        public static void drawTick(Graphics g,int x,int y,int boxsize)

          {
       int tickWidth=(boxsize-4)/3;
       for (int off=0;off<tickWidth;off++)
       {
        g.drawLine(x+3,y+boxsize-3-tickWidth-off,x+tickWidth+2,y+boxsize-4-off);
        g.drawLine(x+tickWidth+3,y+boxsize-5-off,x+boxsize-4,y+tickWidth+2-off);
       }
  }




}


$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
public static class SmoothSprites {
  static bool Foreground(Color p) {
    return p.A > 32 && !(p.R > 100 && p.B > 95 && p.R > p.G * 1.45 && p.B > p.G * 1.45);
  }
  static List<int[]> Bands(int[] counts, int threshold, int gap, int minSize) {
    var result = new List<int[]>(); int start = -1, end = -1;
    for (int i=0; i<=counts.Length+gap; i++) {
      if (i<counts.Length && counts[i]>=threshold) { if(start<0) start=i; end=i; }
      else if(start>=0 && i-end>gap) {
        if(end-start+1>=minSize) result.Add(new int[]{start,end+1});
        start=-1;
      }
    }
    return result;
  }
  static double Median(List<double> values) { values.Sort(); return values[values.Count/2]; }
  public static void Build(string source, string destination, string action) {
    using(var input = new Bitmap(source))
    using(var clean = new Bitmap(input.Width,input.Height,PixelFormat.Format32bppArgb)) {
      var yc = new int[input.Height];
      for(int y=0;y<input.Height;y++) for(int x=0;x<input.Width;x++) {
        Color p=input.GetPixel(x,y);
        if(Foreground(p)) { clean.SetPixel(x,y,Color.FromArgb(255,p.R,p.G,p.B)); yc[y]++; }
      }
      var rows=Bands(yc,8,3,24);
      if(rows.Count!=8) throw new Exception(action+": expected 8 rows, found "+rows.Count);
      var poses = new List<Rectangle[]>();
      var heights = new List<double>();
      for(int row=0;row<8;row++) {
        int top=rows[row][0], bottom=rows[row][1];
        var xc=new int[input.Width];
        for(int x=0;x<input.Width;x++) for(int y=top;y<bottom;y++) if(clean.GetPixel(x,y).A>0) xc[x]++;
        var spans=Bands(xc,2,6,12);
        // The death source has eleven poses: the twelfth slot holds the final
        // settled body, preserving the timing of the fall without resampling.
        if(action=="death" && spans.Count==11) spans.Add(spans[10]);
        if(spans.Count!=12) throw new Exception(action+" row "+row+": expected 12 poses, found "+spans.Count);
        var rects=new Rectangle[12];
        for(int f=0;f<12;f++) {
          int l=Math.Max(0,spans[f][0]-2),r=Math.Min(input.Width,spans[f][1]+2),t=bottom,b=top;
          for(int y=top;y<bottom;y++) for(int x=l;x<r;x++) if(clean.GetPixel(x,y).A>0) {t=Math.Min(t,y);b=Math.Max(b,y+1);}
          rects[f]=Rectangle.FromLTRB(l,t,r,b);
          if(f==0) heights.Add(b-t);
        }
        poses.Add(rects);
      }
      // A single scale for the entire action preserves crouch/fall size.
      float scale=(float)(180.0/Median(heights));
      // Generated right views sometimes face the wrong way. Export mirrored
      // matching left views for consistent eight-direction motion.
      int[] sourceRows=action=="walk" ? new int[]{0,6,2,3,4,3,2,6} : new int[]{0,1,2,3,4,3,2,1};
      using(var output=new Bitmap(3072,2048,PixelFormat.Format32bppArgb))
      using(var g=Graphics.FromImage(output)) {
        g.InterpolationMode=InterpolationMode.NearestNeighbor;
        g.PixelOffsetMode=PixelOffsetMode.Half;
        for(int row=0;row<8;row++) {
          int sr=sourceRows[row]; var rects=poses[sr];
          for(int frame=0;frame<12;frame++) {
            // Idle stability is baked into the exported PNG, not a player trick.
            int f=action=="idle" ? 0 : frame;
            Rectangle rect=rects[f];
            double anchor=rect.Left+rect.Width/2.0;
            // Head center keeps locomotion in place without tracking the stride.
            // Planted actions use boot contact, leaving reaching/crouching intact.
            if(action!="death" && action!="stagger") {
              bool locomotion=action=="walk" || action=="run";
              int t=locomotion?rect.Top:Math.Max(rect.Top,rect.Bottom-6);
              int b=locomotion?Math.Min(rect.Bottom,rect.Top+18):rect.Bottom;
              long sum=0;int n=0;
              for(int y=t;y<b;y++) for(int x=rect.Left;x<rect.Right;x++) if(clean.GetPixel(x,y).A>0) {sum+=x;n++;}
              if(n>0) anchor=(double)sum/n;
            }
            using(var cell=new Bitmap(256,256,PixelFormat.Format32bppArgb))
            using(var cg=Graphics.FromImage(cell)) {
              cg.InterpolationMode=InterpolationMode.NearestNeighbor; cg.PixelOffsetMode=PixelOffsetMode.Half;
              int w=(int)Math.Round(rect.Width*scale),h=(int)Math.Round(rect.Height*scale);
              int dx=128-(int)Math.Round((anchor-rect.Left)*scale),dy=224-h;
              if(dx<2 || dx+w>254 || dy<2) throw new Exception(action+" clipped pose "+row+"/"+frame);
              cg.DrawImage(clean,new Rectangle(dx,dy,w,h),rect,GraphicsUnit.Pixel);
              if(row>=5) cell.RotateFlip(RotateFlipType.RotateNoneFlipX);
              g.DrawImageUnscaled(cell,frame*256,row*256);
            }
          }
        }
        output.Save(destination,ImageFormat.Png);
      }
      Console.WriteLine(action+": 12 frames x 8 directions, alpha, 256px cells");
    }
  }
}
'@
foreach ($action in @('idle','walk','run','interact','unlock','pickup','flashlight','damage','stagger','death')) {
  [SmoothSprites]::Build((Join-Path $PSScriptRoot "source/$action.png"), (Join-Path $PSScriptRoot "$action.png"), $action)
}

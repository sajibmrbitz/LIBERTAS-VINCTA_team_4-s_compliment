$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
public static class VerifySprites {
  public static void Check(string file, bool idle) {
    using(var image=new Bitmap(file)) {
      if(image.Width!=3072 || image.Height!=2048) throw new Exception("Wrong sheet dimensions: "+file);
      for(int row=0;row<8;row++) for(int frame=0;frame<12;frame++) {
        int opaque=0;
        for(int y=0;y<256;y++) for(int x=0;x<256;x++) {
          Color p=image.GetPixel(frame*256+x,row*256+y);
          if(p.A>0) {
            opaque++;
            if(x==0 || y==0 || x==255 || y==255) throw new Exception("Clipped sprite: "+file);
            if(p.R>100 && p.B>95 && p.R>p.G*1.45 && p.B>p.G*1.45) throw new Exception("Magenta residue: "+file);
          }
          if(idle && p.ToArgb()!=image.GetPixel(x,row*256+y).ToArgb()) throw new Exception("Idle jitter: "+file);
        }
        if(opaque<100 || opaque>60000) throw new Exception("Empty or opaque background: "+file);
      }
    }
  }
}
'@
foreach ($action in @('idle','walk','run','interact','unlock','pickup','flashlight','damage','stagger','death')) {
  [VerifySprites]::Check((Join-Path $PSScriptRoot "$action.png"), $action -eq 'idle')
  Write-Output "PASS $action : 96 nonempty transparent cells, no clipped edges or magenta"
}
Write-Output 'PASS idle: all twelve frames are pixel-identical in every direction'

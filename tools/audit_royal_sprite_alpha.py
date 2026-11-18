from pathlib import Path
from PIL import Image
r=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\assets\reverie_custom\royal_gardens\production")
for f in sorted(r.glob("*.png")):
 im=Image.open(f).convert("RGBA"); a=im.getchannel("A"); w,h=im.size
 corners=[im.getpixel(q)[3] for q in [(0,0),(w-1,0),(0,h-1),(w-1,h-1)]]
 ratio=sum(1 for v in a.getdata() if v>0)/(w*h)
 if min(corners)>0 or ratio>0.92:
  print(f.name,im.size,"alpha_bbox",a.getbbox(),"corner_alpha",corners,"opaque_ratio",round(ratio,3))

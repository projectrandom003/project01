from PIL import Image
from pathlib import Path
r=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\assets\reverie_custom\royal_gardens\production")
for n in ["pink_flower_shrub.png","purple_flower_shrub.png","violet_flower_shrub.png","white_flower_shrub.png","round_rose_shrub.png"]:
 im=Image.open(r/n).convert("RGBA"); a=im.getchannel("A")
 print("\n",n,im.size)
 for y in range(im.height-12,im.height):
  row=[im.getpixel((x,y)) for x in range(im.width)]
  opaque=sum(v[3]>0 for v in row)
  dark=sum(v[3]>0 and max(v[:3])<135 for v in row)
  print(y,opaque,dark)

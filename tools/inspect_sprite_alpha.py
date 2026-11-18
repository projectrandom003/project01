from PIL import Image
from pathlib import Path
r=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\assets\reverie_custom\royal_gardens\production")
for n in ["rose_hedge_block.png","pink_flower_shrub.png","purple_flower_shrub.png","white_flower_shrub.png","round_rose_shrub.png"]:
 im=Image.open(r/n).convert("RGBA"); w,h=im.size
 pts=[im.getpixel((0,0)),im.getpixel((w-1,0)),im.getpixel((0,h-1)),im.getpixel((w-1,h-1))]
 opaque=sum(1 for a in im.getchannel("A").getdata() if a>0)
 dark=sum(1 for R,G,B,A in im.getdata() if A>0 and max(R,G,B)<65)
 print(n,im.size,"corners",pts,"opaque",opaque,"dark",dark)

from PIL import Image
from pathlib import Path
r=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\assets\reverie_custom\royal_gardens\production")
# Remove the horizontal atlas separator rows left in these three extracted shrubs.
for name, bottom in [("purple_flower_shrub.png",60),("violet_flower_shrub.png",60),("white_flower_shrub.png",60)]:
    f=r/name
    im=Image.open(f).convert("RGBA")
    im.crop((0,0,im.width,bottom)).save(f)
    print("Clean crop",name,im.size)

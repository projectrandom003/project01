from PIL import Image
from pathlib import Path
r=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy")
src=Image.open(r/"assets/environment/castle_gardens/terrain/royal_garden_paths_water_atlas_32x32.png").convert("RGBA")
tile=src.crop((0,0,32,32))
out=Image.new("RGBA",(96,96))
for y in range(3):
 for x in range(3): out.paste(tile,(x*32,y*32))
p=r/"assets/reverie_custom/royal_gardens/production/royal_cobble_ribbon_96.png"
out.save(p)
print("COBBLE_RIBBON_TEXTURE",p,out.size)

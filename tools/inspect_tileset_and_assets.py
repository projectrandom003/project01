from pathlib import Path
from PIL import Image
import re
b=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy")
for rel in ["assets/environment/castle_gardens/terrain/royal_garden_paths_water_isometric_tileset.tres","assets/environment/castle_gardens/terrain/royal_garden_ground_isometric_tileset.tres","assets/environment/castle_gardens/terrain/royal_garden_vegetation_isometric_tileset.tres","scenes/world/castle_gardens/components/royal_garden_isometric_layers_baked.tscn"]:
 print("\n###",rel)
 s=(b/rel).read_text(encoding="utf-8-sig")
 if rel.endswith(".tres"): print(s[:18000])
 else:
  for line in s.splitlines():
   if line.startswith("[node name=") or line.startswith("tile_set =") or line.startswith("tile_map_data =") or line.startswith("position ="): print(line[:250])
print("\n### IMAGE PIXEL CHECK")
for rel in ["assets/reverie_custom/royal_gardens/production/rose_hedge_block.png","assets/reverie_custom/royal_gardens/production/purple_flower_shrub.png","assets/reverie_custom/royal_gardens/production/violet_flower_shrub.png","assets/reverie_custom/royal_gardens/production/white_flower_shrub.png"]:
 im=Image.open(b/rel).convert("RGBA"); print(rel,im.size)
 for y in [0,1,2,im.height//2,im.height-4,im.height-3,im.height-2,im.height-1]:
  vals=[im.getpixel((x,y)) for x in [0,1,im.width//2,im.width-2,im.width-1]]
  print(y,vals)

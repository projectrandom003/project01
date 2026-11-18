from pathlib import Path
from PIL import Image
b=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy")
for rel in ["scenes/world/castle_gardens/components/reverie_royal_gardens_full_preview.tscn","scenes/world/castle_gardens/components/royal_garden_isometric_layers_baked.tscn","scenes/world/castle_gardens/components/castle_flora_assembly.tscn","scenes/world/castle_gardens/components/castle_water_assembly.tscn","scenes/world/castle_gardens/components/castle_props_assembly.tscn","scenes/world/castle_gardens/components/reverie_royal_gardens_castle_collection.tscn"]:
 p=b/rel; print("\n###",rel)
 lines=p.read_text(encoding="utf-8-sig").splitlines()
 for i,l in enumerate(lines):
  if l.startswith("[ext_resource") or l.startswith("[node name=") or l.startswith("texture =") or l.startswith("position =") or l.startswith("scale =") or l.startswith("tile_map_data ="):
   print(f"{i+1}: {l[:240]}")
print("\n### SPRITE SIZES / ALPHA")
for p in sorted((b/"assets/reverie_custom/royal_gardens/production").glob("*.png")):
 im=Image.open(p).convert("RGBA"); a=im.getchannel("A")
 print(p.name,im.size,"bbox",a.getbbox(),"opaque",sum(v>0 for v in a.getdata()),"corners",[im.getpixel(pt) for pt in [(0,0),(im.width-1,0),(0,im.height-1),(im.width-1,im.height-1)]])

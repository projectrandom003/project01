from PIL import Image
from pathlib import Path
root=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\assets\reverie_custom\royal_gardens")
out=root/"production"; out.mkdir(exist_ok=True)
crops={
 "walls/wall_corner_module.png":("wall_corner_tower.png",(20,0,130,178)),
 "walls/corner_spire_tower_01.png":("corner_spire_tower.png",(0,0,108,178)),
 "walls/corner_tower_01.png":("corner_tower.png",(18,25,122,170)),
 "walls/wall_segment_03.png":("ornate_wall_segment.png",(0,48,185,174)),
 "walls/wall_segment_04.png":("banner_wall_segment.png",(44,45,190,173)),
 "vegetation/hedge_block_rose.png":("rose_hedge_block.png",(0,22,65,95)),
 "vegetation/pink_flower_shrub.png":("pink_flower_shrub.png",(0,20,62,94)),
 "vegetation/purple_flower_shrub.png":("purple_flower_shrub.png",(0,0,54,65)),
 "vegetation/round_rose_shrub.png":("round_rose_shrub.png",(0,20,60,95)),
 "vegetation/violet_flower_shrub.png":("violet_flower_shrub.png",(0,0,55,65)),
 "vegetation/white_flower_shrub.png":("white_flower_shrub.png",(0,0,60,65)),
}
for rel,(name,box) in crops.items():
 im=Image.open(root/rel).convert("RGBA").crop(box)
 # Trim only transparent alpha; keep illustrated pixels and their original color.
 bb=im.getchannel("A").getbbox()
 if bb: im=im.crop(bb)
 im.save(out/name)
 print(name,im.size)
# Mask atlas captions in previously cropped hero sprites; these areas are known to contain text, not artwork.
for name,box in [("grand_royal_palace.png",(0,0,170,32)),("pink_blossom_tree.png",(0,0,45,20)),("rose_gazebo.png",(0,0,45,12))]:
 f=out/name; im=Image.open(f).convert("RGBA")
 from PIL import ImageDraw
 ImageDraw.Draw(im).rectangle(box,fill=(0,0,0,0))
 im.save(f)
 print("caption cleared",name)

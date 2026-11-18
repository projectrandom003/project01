from PIL import Image
from pathlib import Path
root=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\assets\reverie_custom\royal_gardens")
out=root/"production"
# Pixel-exact crops isolate each illustrated sprite and exclude atlas captions, rules and neighboring sprites.
crops={
 "castle/grand_royal_palace.png":(0,12,438,285),
 "towers/tower_module_01.png":(0,0,140,218),
 "towers/tower_module_02.png":(0,0,155,218),
 "gates/grand_ornate_gate.png":(0,0,285,166),
 "garden_structures/rose_gazebo.png":(0,0,165,168),
 "garden_structures/rose_arch.png":(0,0,170,165),
 "fountains/angel_tiered_fountain.png":(0,0,150,165),
 "trees/pink_blossom_tree.png":(0,0,110,166),
 "trees/purple_wisteria_tree.png":(0,0,105,166),
 "trees/white_blossom_tree.png":(0,0,110,166),
 "trees/royal_cypress_tree.png":(0,0,110,166),
 "garden_structures/flower_pedestal.png":(0,0,75,165),
}
for rel,box in crops.items():
 im=Image.open(root/rel).convert("RGBA").crop(box)
 bb=im.getchannel("A").getbbox()
 if bb: im=im.crop(bb)
 dest=out/Path(rel).name; dest.parent.mkdir(parents=True,exist_ok=True); im.save(dest)
 print(dest.name,im.size)

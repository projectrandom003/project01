from PIL import Image
from pathlib import Path
r=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\assets\reverie_custom\royal_gardens")
for f in [r/"castle/grand_royal_palace.png",r/"towers/tower_module_01.png",r/"towers/tower_module_02.png",r/"gates/grand_ornate_gate.png",r/"trees/pink_blossom_tree.png",r/"garden_structures/rose_gazebo.png",r/"fountains/angel_tiered_fountain.png",r/"walls/wall_segment_01.png",r/"walls/wall_segment_02.png"]:
 im=Image.open(f); print(f.name,im.size)

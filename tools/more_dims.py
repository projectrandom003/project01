from PIL import Image
from pathlib import Path
r=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\assets\reverie_custom\royal_gardens")
for rel in ["vegetation/hedge_block_rose.png","vegetation/pink_flower_shrub.png","vegetation/purple_flower_shrub.png","vegetation/round_rose_shrub.png","vegetation/violet_flower_shrub.png","vegetation/white_flower_shrub.png","walls/wall_corner_module.png","walls/corner_spire_tower_01.png","walls/corner_tower_01.png","walls/wall_segment_03.png","walls/wall_segment_04.png"]:
 im=Image.open(r/rel); print(rel, im.size)

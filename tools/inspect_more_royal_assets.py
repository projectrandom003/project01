from PIL import Image
from pathlib import Path
r=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\assets\reverie_custom\royal_gardens")
for rel in ["fountains/blue_royal_fountain.png","fountains/lotus_fountain.png","gates/gothic_archway.png","garden_structures/robed_statue.png","gates/gate_lantern_post.png","gates/royal_banner.png","benches/ornate_stone_bench.png","benches/flower_bench.png","walls/wall_segment_01.png","walls/wall_segment_02.png"]:
 im=Image.open(r/rel); print(rel,im.size)

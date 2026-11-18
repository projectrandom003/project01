from PIL import Image
from pathlib import Path
root=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\assets\reverie_custom\royal_gardens")
out=root/"production"; out.mkdir(exist_ok=True)
items={
 "fountains/blue_royal_fountain.png":"blue_royal_fountain.png",
 "fountains/lotus_fountain.png":"lotus_fountain.png",
 "gates/gothic_archway.png":"gothic_archway.png",
 "garden_structures/robed_statue.png":"robed_guardian_statue.png",
 "gates/gate_lantern_post.png":"royal_lantern_post.png",
 "gates/royal_banner.png":"royal_banner.png",
 "benches/ornate_stone_bench.png":"ornate_stone_bench.png",
 "benches/flower_bench.png":"flower_bench.png",
}
for rel,name in items.items():
 im=Image.open(root/rel).convert("RGBA")
 bb=im.getchannel("A").getbbox()
 if bb: im=im.crop(bb)
 im.save(out/name)
 print(name,im.size)

from PIL import Image
from pathlib import Path
root=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\assets\reverie_custom\royal_gardens")
out=root/"production"
# Exact sprite-area crops: preserve pixel dimensions and alpha; remove atlas labels/dividers.
crops={
 "castle/grand_royal_palace.png":(0,18,500,285),
 "towers/tower_module_01.png":(0,0,140,290),
 "towers/tower_module_02.png":(0,0,155,290),
 "gates/grand_ornate_gate.png":(0,0,285,170),
 "walls/wall_segment_01.png":(0,28,170,176),
 "walls/wall_segment_02.png":(0,28,185,176),
 "garden_structures/rose_gazebo.png":(0,25,165,165),
 "garden_structures/rose_arch.png":(0,25,170,165),
 "fountains/angel_tiered_fountain.png":(0,28,150,170),
 "trees/pink_blossom_tree.png":(0,28,110,183),
 "trees/purple_wisteria_tree.png":(0,28,105,183),
 "trees/white_blossom_tree.png":(0,28,110,183),
 "trees/royal_cypress_tree.png":(0,28,110,183),
}
for rel,box in crops.items():
    src=root/rel
    im=Image.open(src).convert("RGBA").crop(box)
    # Remove isolated non-art atlas background pixels only when connected to image edges.
    px=im.load(); w,h=im.size
    from collections import deque
    q=deque()
    seen=bytearray(w*h)
    def bg(x,y):
        r,g,b,a=px[x,y]
        return a==0 or (r<18 and g<18 and b<18)
    for x in range(w):
        if bg(x,0): q.append((x,0))
        if bg(x,h-1): q.append((x,h-1))
    for y in range(h):
        if bg(0,y): q.append((0,y))
        if bg(w-1,y): q.append((w-1,y))
    while q:
        x,y=q.popleft(); i=y*w+x
        if seen[i]: continue
        seen[i]=1
        if bg(x,y): px[x,y]=(0,0,0,0)
        for nx,ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
            if 0<=nx<w and 0<=ny<h and not seen[ny*w+nx] and bg(nx,ny): q.append((nx,ny))
    # Tight trim transparent margins without resampling.
    alpha=im.getchannel("A")
    bb=alpha.getbbox()
    if bb: im=im.crop(bb)
    dest=out/Path(rel).name
    dest.parent.mkdir(parents=True,exist_ok=True)
    im.save(dest)
    print(dest.name, im.size)

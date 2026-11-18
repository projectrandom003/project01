from PIL import Image
from pathlib import Path
from collections import deque
root=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\assets\reverie_custom\royal_gardens\production")
fixed=[]
for f in root.glob("*.png"):
    im=Image.open(f).convert("RGBA")
    px=im.load(); w,h=im.size
    seen=bytearray(w*h); q=deque()
    def is_bg(x,y):
        r,g,b,a=px[x,y]
        return a==0 or (a>0 and r<=24 and g<=24 and b<=24)
    for x in range(w):
        if is_bg(x,0): q.append((x,0))
        if is_bg(x,h-1): q.append((x,h-1))
    for y in range(h):
        if is_bg(0,y): q.append((0,y))
        if is_bg(w-1,y): q.append((w-1,y))
    removed=0
    while q:
        x,y=q.popleft(); i=y*w+x
        if seen[i]: continue
        seen[i]=1
        if is_bg(x,y) and px[x,y][3]:
            px[x,y]=(0,0,0,0); removed+=1
        for nx,ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
            if 0<=nx<w and 0<=ny<h and not seen[ny*w+nx] and is_bg(nx,ny): q.append((nx,ny))
    if removed:
        im.save(f); fixed.append((f.name,removed))
print("Removed edge-connected black atlas backgrounds:")
for name,n in fixed: print(name,n)
print("Processed",len(list(root.glob("*.png"))),"production sprites")

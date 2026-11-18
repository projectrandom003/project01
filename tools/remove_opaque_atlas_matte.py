from PIL import Image
from pathlib import Path
from collections import deque
root=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\assets\reverie_custom\royal_gardens\production")
targets=["rose_hedge_block.png","purple_flower_shrub.png"]
for name in targets:
 f=root/name; im=Image.open(f).convert("RGBA"); px=im.load(); w,h=im.size
 corners=[px[0,0][:3],px[w-1,0][:3],px[0,h-1][:3],px[w-1,h-1][:3]]
 def matte(c):
  return min(sum((c[k]-q[k])**2 for k in range(3)) for q in corners)<=24*24
 q=deque()
 for x in range(w):
  if matte(px[x,0][:3]): q.append((x,0))
  if matte(px[x,h-1][:3]): q.append((x,h-1))
 for y in range(h):
  if matte(px[0,y][:3]): q.append((0,y))
  if matte(px[w-1,y][:3]): q.append((w-1,y))
 seen=set(); removed=0
 while q:
  x,y=q.popleft()
  if (x,y) in seen: continue
  seen.add((x,y))
  if matte(px[x,y][:3]) and px[x,y][3]:
   px[x,y]=(0,0,0,0); removed+=1
   for nx,ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
    if 0<=nx<w and 0<=ny<h and (nx,ny) not in seen: q.append((nx,ny))
 im.save(f)
 print(name,"removed matte pixels",removed,"remaining alpha bbox",im.getchannel("A").getbbox())

from PIL import Image
p=r"C:\Users\quoth\Documents\Default Project\project-fantasy\assets\environment\castle_gardens\terrain\royal_garden_paths_water_atlas_32x32.png"
im=Image.open(p).convert("RGBA")
for y in range(4):
 row=[]
 for x in range(4):
  c=im.crop((x*32,y*32,(x+1)*32,(y+1)*32))
  px=[v for v in c.getdata() if v[3]>100]
  if px:
   avg=tuple(round(sum(q[i] for q in px)/len(px)) for i in range(3))
   row.append((x,y,avg,len(px)))
  else: row.append((x,y,None,0))
 print(row)

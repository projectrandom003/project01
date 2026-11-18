from PIL import Image, ImageDraw, ImageFilter
import random, math
random.seed(18)
S=2; W,H=1280,900
im=Image.new("RGBA",(W*S,H*S),(29,34,48,255))
d=ImageDraw.Draw(im)
def poly(points, fill, outline=None, width=1):
    pts=[(int(x*S),int(y*S)) for x,y in points]; d.polygon(pts,fill=fill,outline=outline,width=width*S if outline else 1)
def line(points, fill, width=2):
    d.line([(int(x*S),int(y*S)) for x,y in points],fill=fill,width=width*S,joint="curve")
def ell(box, fill, outline=None, width=1):
    b=tuple(int(v*S) for v in box); d.ellipse(b,fill=fill,outline=outline,width=width*S if outline else 1)
def rect(box, fill, outline=None, width=1):
    b=tuple(int(v*S) for v in box); d.rectangle(b,fill=fill,outline=outline,width=width*S if outline else 1)
# garden base, deep moss with layered subtle stipple
poly([(640,28),(1210,330),(640,870),(70,330)],"#314b3c","#a68b70",7)
for i in range(6200):
    x=random.randint(90,1190); y=random.randint(80,840)
    if abs((x-640)/570)+abs((y-449)/420)<.96:
        c=random.choice(["#3b5944","#405e48","#294536","#52684b","#68704e"])
        ell((x,y,x+random.choice([1,2,3]),y+1),c)
# perimeter hedges, golden stone edging
poly([(640,78),(1138,339),(640,810),(142,339)],None if False else "#36523e","#b69a72",14)
poly([(640,104),(1090,340),(640,772),(190,340)],"#405a43","#d5b88b",5)
# flower garden beds around perimeter
for cx,cy in [(350,250),(930,250),(300,520),(980,520),(480,690),(800,690)]:
    ell((cx-74,cy-25,cx+74,cy+25),"#263d32","#c4a47c",3)
    for j in range(34):
        x=cx+random.randint(-65,65); y=cy+random.randint(-16,16)
        ell((x-3,y-3,x+3,y+3),random.choice(["#df7da8","#e9b5c7","#c8a4e8","#f2d6a2"]))
# central stone promenade as diamond ribbon
poly([(640,180),(680,202),(680,666),(640,688),(600,666),(600,202)],"#aa9a91","#e4d4bd",3)
for y in range(215,665,34):
    line([(605,y),(675,y)],"#766e72",1)
# cross promenades
poly([(350,420),(390,398),(890,398),(930,420),(890,442),(390,442)],"#aa9a91","#e4d4bd",3)
# water pools symmetric
for cx,cy in [(470,470),(810,470)]:
    poly([(cx,cy-65),(cx+88,cy),(cx,cy+65),(cx-88,cy)],"#b8a18b","#e8d2ae",5)
    poly([(cx,cy-52),(cx+70,cy),(cx,cy+52),(cx-70,cy)],"#286b78","#8ed4cf",3)
    for k in range(14):
        x=cx+random.randint(-48,48); y=cy+random.randint(-30,30)
        ell((x,y,x+3,y+2),random.choice(["#8fd9d2","#d3a6cf","#f2d8a1"]))
# bridge caps
for cx in [470,810]:
    poly([(cx-42,420),(cx,398),(cx+42,420),(cx,442)],"#d9c4a1","#f2dfbd",3)
# castle plinth at upper center
poly([(640,112),(865,230),(640,352),(415,230)],"#7c657c","#d5b7cb",5)
poly([(640,128),(834,230),(640,332),(446,230)],"#b8a4b5","#f0d8e0",4)
# castle keep base
poly([(640,116),(780,190),(640,266),(500,190)],"#d7c1c2","#f9e5d9",4)
# castle walls facade
poly([(500,180),(640,252),(780,180),(780,248),(640,326),(500,248)],"#e9d5c8","#9c7893",4)
# roof main
poly([(480,180),(640,92),(800,180),(640,265)],"#57416f","#d6a4c4",5)
poly([(515,180),(640,112),(765,180),(640,244)],"#75558d","#c7a2d2",3)
# roof tile rows
for t in range(5):
    y=145+t*19
    line([(535-t*11,y),(640,y+57),(745+t*11,y)],"#a88bb8",2)
# front windows, gothic pointed
for x in [550,605,675,730]:
    poly([(x-12,222),(x,199),(x+12,222),(x+12,257),(x-12,257)],"#493e62","#f0c58f",3)
    line([(x,204),(x,254)],"#d7a6a8",2)
# center arched entrance
poly([(608,286),(640,245),(672,286),(672,322),(608,322)],"#3b2d48","#f5c987",4)
poly([(618,287),(640,260),(662,287),(662,319),(618,319)],"#62425e","#d9a46f",2)
# towers
for cx,cy in [(500,190),(780,190),(548,128),(732,128)]:
    ell((cx-39,cy+24,cx+39,cy+54),"#9e819e","#e8c8d1",3)
    rect((cx-31,cy-28,cx+31,cy+37),"#e8d2cb","#9e7895",3)
    for wx in [-16,16]:
        poly([(cx+wx-6,cy+2),(cx+wx,cy-9),(cx+wx+6,cy+2),(cx+wx+6,cy+21),(cx+wx-6,cy+21)],"#57476c","#f5cf9c",2)
    poly([(cx-38,cy-28),(cx,cy-100),(cx+38,cy-28)],"#563a73","#d3a0c8",4)
    line([(cx,cy-95),(cx,cy-34)],"#d6a4d2",2)
# wall perimeter with towers, enclosing upper castle
for y in [302]:
    poly([(410,y),(640,y+120),(870,y)],"#dfc8bb","#9e7c91",8)
    line([(420,y-10),(640,y+105),(860,y-10)],"#f4dfc8",6)
# crenels
for i in range(13):
    x=425+i*35; yy=302+abs(640-x)*.5
    rect((x-7,yy-13,x+7,yy+3),"#e9d4c5","#9d7c94",2)
# gatehouse foreground
poly([(590,430),(640,403),(690,430),(690,492),(640,520),(590,492)],"#ddc3b7","#f1d7c5",4)
poly([(610,441),(640,420),(670,441),(670,493),(610,493)],"#5b456d","#d7a2b5",3)
poly([(619,447),(640,430),(661,447),(661,491),(619,491)],"#342d48","#eac18d",2)
# gold gate bars
for x in range(624,658,8): line([(x,450),(x,490)],"#e8bc75",2)
# garden gazebo lower left/right
for cx,cy in [(380,610),(900,610)]:
    ell((cx-60,cy+22,cx+60,cy+42),"#8b7189","#e7c9b2",3)
    for dx in [-42,42]:
        line([(cx+dx,cy-28),(cx+dx,cy+24)],"#d6b5b0",7)
    poly([(cx-68,cy-28),(cx,cy-88),(cx+68,cy-28),(cx,cy+2)],"#674a7b","#e8b6cf",4)
    ell((cx-7,cy-91,cx+7,cy-77),"#f2c87f")
# trees
for cx,cy,col in [(240,350,"#e58eb8"),(1040,350,"#e58eb8"),(250,680,"#628d68"),(1030,680,"#628d68"),(500,760,"#e58eb8"),(780,760,"#e58eb8")]:
    rect((cx-5,cy-12,cx+5,cy+35),"#77533f")
    for dx,dy,r in [(-16,-23,22),(8,-33,25),(0,-7,26)]:
        ell((cx+dx-r,cy+dy-r,cx+dx+r,cy+dy+r),col,"#3e5946",2)
    for j in range(20):
        x=cx+random.randint(-30,30); y=cy+random.randint(-48,12)
        ell((x,y,x+3,y+3),random.choice(["#f6bfd1","#f5d6e1","#d9a5d0"]) if col=="#e58eb8" else "#8eb68b")
# lantern pairs
for x,y in [(560,385),(720,385),(550,550),(730,550),(640,710)]:
    line([(x,y),(x,y-27)],"#c89b60",3)
    ell((x-7,y-38,x+7,y-24),"#f8d58a","#8d5e4b",2)
    ell((x-16,y-45,x+16,y-37),"#f5cc7e")
# roses along path edge
for x,y in [(585,300),(695,300),(575,480),(705,480),(600,630),(680,630)]:
    for j in range(8):
        xx=x+random.randint(-13,13); yy=y+random.randint(-8,8)
        ell((xx-3,yy-3,xx+3,yy+3),random.choice(["#d95f91","#f29aba","#e9b4ce"]))
# soft outer frame
# scale downsample crisp pixel illustration
im=im.resize((W,H),Image.Resampling.LANCZOS)
out=r"C:\Users\quoth\Documents\Default Project\project-fantasy\assets\environment\castle_gardens\royal_gardens_target_layout.png"
im.save(out,optimize=True)
print("Wrote",out,im.size)

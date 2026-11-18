from PIL import Image, ImageDraw
import random, math
random.seed(92)
p=r"C:\Users\quoth\Documents\Default Project\project-fantasy\assets\environment\castle_gardens\royal_gardens_target_layout.png"
im=Image.open(p).convert("RGB"); d=ImageDraw.Draw(im)
# Outer perimeter: pale stone wall runs with a deliberate front gate opening
edges=[((640,28),(110,330)),((640,28),(1170,330)),((110,330),(640,870)),((1170,330),(640,870))]
for (x1,y1),(x2,y2) in edges:
    d.line((x1,y1,x2,y2),fill="#806e79",width=16)
    d.line((x1,y1-3,x2,y2-3),fill="#f0d9c6",width=11)
    d.line((x1,y1+5,x2,y2+5),fill="#b69a9b",width=5)
    length=math.hypot(x2-x1,y2-y1)
    n=int(length/20)
    for i in range(1,n):
        t=i/n; x=int(x1+(x2-x1)*t); y=int(y1+(y2-y1)*t)
        d.line((x,y-5,x+2,y+5),fill="#9d8290",width=2)
        if i%3==0:
            d.rectangle((x-5,y-15,x+5,y-7),fill="#ead6c7",outline="#967b89",width=1)
# break central southern wall for main entrance and add gate pylons
# cover the central portion of the southern wall with the main entrance bridge/gate
d.line((590,820,690,820),fill="#34483b",width=23)
for x in [588,692]:
    d.rectangle((x-15,790,x+15,844),fill="#e6d0c3",outline="#806c7b",width=3)
    d.polygon([(x-19,790),(x,766),(x+19,790)],fill="#654a78",outline="#d9a6c5")
    d.rectangle((x-5,800,x+5,833),fill="#4b3b59",outline="#eac58b",width=2)
# Corner bastion towers
for x,y in [(640,100),(110,330),(1170,330),(575,810),(705,810)]:
    d.ellipse((x-28,y-12,x+28,y+14),fill="#8d7784",outline="#e6cdbd",width=3)
    d.rectangle((x-21,y-42,x+21,y+5),fill="#e6d1c5",outline="#8e7385",width=3)
    for wx in [-10,10]:
        d.rectangle((x+wx-3,y-29,x+wx+3,y-12),fill="#594565",outline="#f0c78e",width=1)
    d.polygon([(x-26,y-42),(x,y-82),(x+26,y-42)],fill="#594171",outline="#d9a2c9",width=3)
    d.line((x,y-78,x,y-44),fill="#e7bd8b",width=2)
# wall flower vines at selected points
for x,y in [(350,207),(930,207),(260,480),(1020,480),(500,750),(780,750)]:
    for j in range(35):
        xx=x+random.randint(-22,22); yy=y+random.randint(-12,12)
        d.ellipse((xx-2,yy-2,xx+2,yy+2),fill=random.choice(["#d95f93","#f0a3c0","#a98bc2","#58764c"]))
# stronger highlights on cathedral towers and roof ridges
for x in [500,548,732,780]:
    d.line((x-20,190,x,90),fill="#e9c6d6",width=3)
    d.line((x,90,x+18,190),fill="#a98abb",width=2)
# entrance rose-gold finials
for x,y in [(588,790),(692,790),(640,766)]:
    d.ellipse((x-5,y-5,x+5,y+5),fill="#f7d18c",outline="#986b54",width=1)
# pixel stone tile joints in forecourt
for y in range(520,690,18):
    for x in range(610,671,18):
        d.line((x,y,x+10,y),fill="#9c8990",width=1)
# subtle sparkle accents
for x,y in [(454,320),(826,320),(392,570),(888,570),(640,730),(320,340),(960,340)]:
    d.line((x-5,y,x+5,y),fill="#f5dba8",width=1); d.line((x,y-5,x,y+5),fill="#f5dba8",width=1)
im.save(p,optimize=True)
print("Perimeter walls, corner bastions, formal entrance and stone details completed.")

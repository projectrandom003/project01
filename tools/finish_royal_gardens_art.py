from PIL import Image, ImageDraw, ImageFilter
import random, math
random.seed(33)
p=r"C:\Users\quoth\Documents\Default Project\project-fantasy\assets\environment\castle_gardens\royal_gardens_target_layout.png"
im=Image.open(p).convert("RGB")
d=ImageDraw.Draw(im)
# pixel-like masonry seams across the palace, gate and plinth
for y in range(175,330,13):
    for x in range(475,805,28):
        if random.random()<.68:
            d.line((x,y,x+random.randint(10,22),y),fill=random.choice(["#b79da8","#c9aeb0","#f2dfcf"]),width=1)
# roof tile scales
for y in range(125,240,13):
    for x in range(535,750,16):
        if abs(x-640)<(y-100)*1.6:
            d.line((x,y,x+8,y+4),fill=random.choice(["#9c7db0","#b18bb8","#493b68"]),width=2)
# windows glow + mullions
for x in [550,605,675,730,484,516,764,796]:
    for y in [215,232,249]:
        if x in [484,516,764,796] and y>230: continue
        d.point((x,y),fill="#ffe7a8")
# wall stones around garden boundary, repeating blocks
for a,b in [((145,330),(640,600)),((1135,330),(640,600))]:
    x1,y1=a; x2,y2=b
    for t in [i/36 for i in range(37)]:
        x=int(x1+(x2-x1)*t); y=int(y1+(y2-y1)*t)
        d.rectangle((x-3,y-2,x+3,y+2),fill="#d8c0a7",outline="#987e82")
# decorative rose vine dots along garden edges
for cx,cy in [(350,250),(930,250),(300,520),(980,520),(480,690),(800,690)]:
    for i in range(100):
        ang=random.random()*math.tau; r=random.random()
        x=int(cx+68*math.cos(ang)*r); y=int(cy+21*math.sin(ang)*r)
        col=random.choice(["#df6e9b","#f3a9c5","#f5d4e2","#c6a0dc","#627e4e"])
        d.rectangle((x,y,x+2,y+2),fill=col)
# grass pixel texture in lawn spaces
for i in range(5000):
    x=random.randrange(180,1100); y=random.randrange(180,780)
    if (x<580 or x>700) and random.random()<.8:
        d.line((x,y,x+random.randrange(1,4),y-2),fill=random.choice(["#4b674a","#58724f","#263e36","#71805a"]),width=1)
# pave joints on central promenade
for y in range(210,670,22):
    d.line((606,y,674,y),fill="#82777d",width=1)
# fountain center in pools and stepping stone details
for cx in [470,810]:
    d.ellipse((cx-13,438,cx+13,462),fill="#b9d9d0",outline="#f2d9ba",width=2)
    d.ellipse((cx-5,442,cx+5,452),fill="#e5c18a")
# lantern glow halos
for x,y in [(560,347),(720,347),(550,512),(730,512),(640,672)]:
    d.ellipse((x-13,y-47,x+13,y-21),fill="#e7bd79",outline="#fff0c4",width=1)
# rose arch embellishments
for cx,cy in [(380,580),(900,580)]:
    for i in range(35):
        x=cx+random.randint(-52,52); y=cy+random.randint(-68,2)
        d.ellipse((x-3,y-3,x+3,y+3),fill=random.choice(["#e76c9e","#f4b1ca","#b88dcf"]))
# pixel finish: downsample and nearest-neighbor upscale
im=im.resize((640,450),Image.Resampling.LANCZOS).resize((1280,900),Image.Resampling.NEAREST)
im.save(p,optimize=True)
print("Detailed pixel finish applied")

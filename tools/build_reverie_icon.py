from PIL import Image, ImageDraw, ImageFilter
import math, os
root=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out=os.path.join(root,'assets','ui')
S=1024
im=Image.new('RGBA',(S,S),(7,9,20,255))
p=im.load()
for y in range(S):
    for x in range(S):
        dx=(x-S*.5)/(S*.75); dy=(y-S*.43)/(S*.78)
        glow=max(0,1-math.sqrt(dx*dx+dy*dy))**2
        p[x,y]=(int(7+35*glow),int(9+23*glow),int(23+72*glow),255)
d=ImageDraw.Draw(im,'RGBA')
# nebula haze
haze=Image.new('RGBA',(S,S),(0,0,0,0)); hd=ImageDraw.Draw(haze)
hd.ellipse((130,90,900,850),fill=(119,72,220,65)); haze=haze.filter(ImageFilter.GaussianBlur(95)); im=Image.alpha_composite(im,haze); d=ImageDraw.Draw(im,'RGBA')
# moon
for r,a in [(290,18),(270,24),(246,34)]: d.ellipse((S//2-r,330-r,S//2+r,330+r),fill=(177,151,255,a))
d.ellipse((270,54,754,538),fill=(177,161,255,245),outline=(248,238,255,255),width=9)
d.ellipse((294,76,730,512),fill=(65,59,112,255))
# lunar craters
for x,y,r in [(390,180,26),(600,145,34),(520,320,20),(360,390,19),(660,400,25)]:
 d.ellipse((x-r,y-r,x+r,y+r),fill=(118,105,168,100),outline=(226,213,255,70),width=5)
# cathedral silhouette
for poly in [[(510,650),(510,470),(555,400),(580,470),(580,650)],[(580,650),(580,360),(630,260),(680,360),(680,650)],[(680,650),(680,445),(720,390),(760,445),(760,650)],[(440,650),(440,510),(480,455),(510,510),(510,650)]]:
 d.polygon(poly,fill=(9,10,27,255),outline=(151,128,213,230))
for x,y in [(580,260),(630,170),(720,390),(480,455)]:
 d.line((x,y,x,y-60),fill=(224,211,255,255),width=7); d.polygon([(x-14,y-40),(x,y-75),(x+14,y-40)],fill=(224,211,255,255))
# thorn crescent and circular silver rune
for box,w in [((130,105,894,870),12),((160,135,864,840),4)]: d.arc(box,25,330,fill=(224,213,255,245),width=w)
# crescent side thorn branches
for side in [0,1]:
 pts=[]
 for i in range(9):
  t=i/8; x=(180+90*t) if side==0 else (844-90*t); y=210+500*t
  d.line((x,y,x+(-55 if side==0 else 55),y-55),fill=(220,207,255,220),width=7)
  d.polygon([(x+(-55 if side==0 else 55),y-55),(x+(-76 if side==0 else 76),y-91),(x+(-38 if side==0 else 38),y-72)],fill=(220,207,255,210))
# radiant central star
star=[]
for i in range(16):
 a=-math.pi/2+i*math.pi/8; r=180 if i%4==0 else (112 if i%2==0 else 34)
 star.append((512+math.cos(a)*r,490+math.sin(a)*r))
d.polygon(star,fill=(242,229,255,245),outline=(255,255,255,255))
d.ellipse((450,428,574,552),fill=(153,105,255,100))
d.ellipse((490,468,534,512),fill=(255,255,255,255))
# rose
cx,cy=512,790
for k in range(5):
 a=k*2*math.pi/5; x=cx+58*math.cos(a); y=cy+32*math.sin(a)
 d.ellipse((x-55,y-65,x+55,y+65),fill=(123,19,69,240),outline=(255,154,200,220),width=5)
d.ellipse((cx-40,cy-42,cx+40,cy+42),fill=(235,100,159,255),outline=(255,205,228,255),width=5)
d.line((cx,cy+80,cx-18,cy+175),fill=(95,180,139,255),width=12)
d.polygon([(cx-14,cy+122),(cx-90,cy+110),(cx-45,cy+158)],fill=(55,133,105,255))
d.polygon([(cx-8,cy+145),(cx+80,cy+125),(cx+35,cy+172)],fill=(55,133,105,255))
# sparks
for x,y,r in [(215,300,7),(800,285,6),(250,610,5),(770,610,5),(512,120,7),(340,735,4),(690,735,4)]: d.ellipse((x-r,y-r,x+r,y+r),fill=(255,244,255,255))
# crop round corners transparent
mask=Image.new('L',(S,S),0); md=ImageDraw.Draw(mask); md.rounded_rectangle((10,10,S-10,S-10),radius=175,fill=255)
im.putalpha(mask)
for size,name in [(512,'reverie_icon_512.png'),(192,'reverie_icon_192.png'),(432,'reverie_icon_432.png')]:
 im.resize((size,size),Image.Resampling.LANCZOS).save(os.path.join(out,name))
print('Generated Reverie icon PNGs:', ', '.join(os.listdir(out)))

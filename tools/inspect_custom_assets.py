from PIL import Image
import os
root=r"C:\Users\quoth\Documents\Default Project\project-fantasy\assets\reverie_custom\royal_gardens"
for dp,ds,fs in os.walk(root):
    for f in fs:
        if f.lower().endswith(".png"):
            path=os.path.join(dp,f)
            im=Image.open(path)
            print(os.path.relpath(path,root), im.size, im.mode, im.getpixel((0,0)))

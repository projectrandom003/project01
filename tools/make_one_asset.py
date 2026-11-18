from PIL import Image
from pathlib import Path
root=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\assets\reverie_custom\royal_gardens")
im=Image.open(root/"garden_structures/flower_pedestal.png").convert("RGBA").crop((0,25,75,165))
# alpha trim only
bb=im.getchannel("A").getbbox()
if bb: im=im.crop(bb)
out=root/"production"; out.mkdir(exist_ok=True)
im.save(out/"flower_pedestal.png")

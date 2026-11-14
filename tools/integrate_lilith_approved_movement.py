from PIL import Image, ImageOps
from pathlib import Path
import shutil
root=Path(r'C:\Users\quoth\Documents\Default Project\project-fantasy')
char=root/'assets'/'characters'/'lilith'
pack=char/'source'/'approved_movement'/'Lilith_Movement_Art_Pack'
backup=char/'approved_movement_backup_20261113'
backup.mkdir(exist_ok=True)
for state in ('walk','run'):
    src=char/f'{state}_sheet.png'
    shutil.copy2(src, backup/f'{state}_sheet.png')
    atlas=Image.open(src).convert('RGBA')
    if atlas.size != (1536,1024): raise SystemExit(f'Unexpected {state} atlas size {atlas.size}')
    if state=='walk':
        front=Image.open(pack/'Lilith_Walk_Front_16.png').convert('RGBA')
        side=Image.open(pack/'Lilith_Walk_Side_16.png').convert('RGBA')
        updates={0:front, 7:ImageOps.mirror(front), 2:side, 6:ImageOps.mirror(side)}
    else:
        side=Image.open(pack/'Lilith_Run_Side_16.png').convert('RGBA')
        updates={2:side, 6:ImageOps.mirror(side)}
    for row,strip in updates.items():
        if strip.size!=(1536,128): raise SystemExit(f'{state} row {row} strip has {strip.size}')
        atlas.paste(strip,(0,row*128))
    atlas.save(src,optimize=True)
    print(f'UPDATED {src.name}: rows {sorted(updates)}; kept legacy rows for unsupported facings')
for state in ('walk','run'):
    im=Image.open(char/f'{state}_sheet.png').convert('RGBA')
    bg=Image.new('RGBA',im.size,(26,20,38,255)); bg.alpha_composite(im)
    bg.convert('RGB').save(pack/f'Integrated_{state}_review.jpg',quality=92)
print('BACKUPS',backup)

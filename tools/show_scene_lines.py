from pathlib import Path
d=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\scenes\world\castle_gardens\components")
for n in ["reverie_royal_wall_x.tscn","reverie_royal_wall_y.tscn","reverie_royal_tower.tscn","reverie_royal_gatehouse.tscn","reverie_royal_keep.tscn"]:
 print("\\n---",n)
 for i,l in enumerate((d/n).read_text().splitlines(),1): print(i,repr(l))

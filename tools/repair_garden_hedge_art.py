from pathlib import Path
scene=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\scenes\world\castle_gardens\components\castle_flora_assembly.tscn")
s=scene.read_text(encoding="utf-8-sig")
old='res://assets/reverie_custom/royal_gardens/production/rose_hedge_block.png'
new='res://assets/reverie_custom/royal_gardens/production/round_rose_shrub.png'
assert old in s
s=s.replace(old,new)
scene.write_text(s,encoding="utf-8")
print("Replaced rectangular hedge-block sprites with the individually illustrated round rose shrub asset.")

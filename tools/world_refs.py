from pathlib import Path
p=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\scenes\world\castle_royal_gardens.tscn")
for i,l in enumerate(p.read_text().splitlines(),1):
 if "[ext_resource" in l or "[node name=" in l or "instance=ExtResource" in l: print(i,l)

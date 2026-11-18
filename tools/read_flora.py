from pathlib import Path
p=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\scenes\world\castle_gardens\components\castle_flora_assembly.tscn")
for i,l in enumerate(p.read_text().splitlines(),1):
 if 112<=i<=132: print(i,repr(l))

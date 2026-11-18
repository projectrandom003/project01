from pathlib import Path
root=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\scenes\world")
for f in root.rglob("*.tscn"):
 s=f.read_text(encoding="utf-8-sig",errors="ignore")
 if "royal_garden_courtyard_decorations.tscn" in s or "castle_flora_assembly.tscn" in s or "reverie_royal_gardens_full_preview.tscn" in s:
  print("\\n",f)
  for line in s.splitlines():
   if "royal_garden_courtyard_decorations" in line or "castle_flora_assembly" in line or "reverie_royal_gardens_full_preview" in line: print(line)

from pathlib import Path
p=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\scenes\world\castle_gardens\components\royal_garden_isometric_layers_baked.tscn")
lines=p.read_text(encoding="utf-8-sig").splitlines()
inside=False; changed=False
for i,line in enumerate(lines):
    if line.startswith('[node name="Paths"'):
        inside=True
    elif inside and line.startswith('[node name='):
        inside=False
    if inside and line.startswith("tile_map_data = "):
        lines[i]="tile_map_data = PackedByteArray()"
        changed=True
if not changed: raise SystemExit("Could not find Paths tile data; left scene unchanged")
p.write_text("\n".join(lines)+"\n",encoding="utf-8")
print("Cleared", "Paths TileMapLayer" ,"to remove the malformed purple strip; other terrain layers untouched.")

from pathlib import Path
root=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy")
scene=root/"scenes/world/castle_gardens/components/castle_pathways.tscn"
script=root/"scripts/world/castle_gardens/components/stone_pathways.gd"
for p in (scene,script):
    b=p.with_suffix(p.suffix+".pre_road_structure_20261118.bak")
    if not b.exists(): b.write_bytes(p.read_bytes())

# A deliberate, two-cell-wide transverse avenue linking the paired fountain courts.
cross=[
(28,14),(29,13),(30,12),(31,11),(32,10),(33,9),
(29,15),(30,14),(31,13),(32,12),(33,11),(34,10)
]
# Paved landing courts at both fountains, the central fountain, and castle gate.
plaza=[
# West fountain landing
(26,16),(27,16),(26,17),(27,17),(28,15),(28,16),
# East fountain landing
(35,7),(36,7),(35,8),(36,8),(34,7),(34,8),
# Grand fountain court
(34,15),(35,15),(36,15),(34,16),(35,16),(36,16),(34,17),(35,17),(36,17),
# Castle gate arrival court
(23,6),(24,6),(25,6),(23,7),(24,7),(25,7)
]
def arr(name, cells):
    return name+" = Array[Vector2i](["+", ".join(f"Vector2i({x}, {y})" for x,y in cells)+"])"
s=script.read_text(encoding="utf-8")
if "cross_axis_cells" not in s:
    s=s.replace("@export var branch_cells: Array[Vector2i] = []","@export var branch_cells: Array[Vector2i] = []\n@export var cross_axis_cells: Array[Vector2i] = []\n@export var plaza_cells: Array[Vector2i] = []")
    s += """
\t# Formal transverse avenue and paved arrival/fountain courts.
\tfor i in range(cross_axis_cells.size()):
\t\tvar cell := cross_axis_cells[i]
\t\tvar variant := posmod(cell.x + cell.y * 2 + i, 4)
\t\tlayer.set_cell(cell, 0, Vector2i(variant, 0))
\tfor i in range(plaza_cells.size()):
\t\tvar cell := plaza_cells[i]
\t\tvar variant := posmod(cell.x * 2 + cell.y + i, 4)
\t\tlayer.set_cell(cell, 0, Vector2i(variant, 0))
"""
    script.write_text(s,encoding="utf-8")
s=scene.read_text(encoding="utf-8")
if "cross_axis_cells =" not in s:
    s=s.replace("\n[node name=\"Tiles\"", "\n"+arr("cross_axis_cells",cross)+"\n"+arr("plaza_cells",plaza)+"\n\n[node name=\"Tiles\"")
    scene.write_text(s,encoding="utf-8")
print("CROSS_AXIS_CELLS",len(cross))
print("PLAZA_CELLS",len(plaza))
print("ROAD_STRUCTURE_WRITTEN")

from pathlib import Path
root=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy")
scene=root/"scenes/world/castle_gardens/components/castle_pathways.tscn"
script=root/"scripts/world/castle_gardens/components/stone_pathways.gd"
# Generate exact isometric-grid edges for a closed rectangular garden circuit.
def segment(a,b):
    x,y=a; tx,ty=b
    dx=0 if tx==x else (1 if tx>x else -1)
    dy=0 if ty==y else (1 if ty>y else -1)
    out=[]
    while (x,y)!=(tx,ty):
        out.append((x,y)); x+=dx; y+=dy
    out.append((tx,ty))
    return out
corners=[(19,15),(34,0),(53,19),(38,34)]
perimeter=set()
for i in range(4):
    perimeter.update(segment(corners[i],corners[(i+1)%4]))
# Link the circuit into both fountain courts and the transverse avenue.
connectors=set(segment((23,19),(26,16))) | set(segment((38,4),(35,7)))
# Expand the central transverse avenue to cover the full span between the fountain landings.
cross=set(segment((26,16),(35,7)))
# A second parallel course creates a proper two-cell-wide ceremonial cross-avenue.
cross |= {(x+1,y+1) for x,y in segment((26,16),(35,7))}
plaza=set([
(26,16),(27,16),(26,17),(27,17),(28,15),(28,16),
(35,7),(36,7),(35,8),(36,8),(34,7),(34,8),
(34,15),(35,15),(36,15),(34,16),(35,16),(36,16),(34,17),(35,17),(36,17),
(23,6),(24,6),(25,6),(23,7),(24,7),(25,7)
])
# Corner widenings make the circuit read as one planned piece of masonry.
for x,y in corners:
    plaza.update([(x,y),(x+1,y),(x,y+1),(x+1,y+1)])
def arr(name,cells):
    return name+" = Array[Vector2i](["+", ".join(f"Vector2i({x}, {y})" for x,y in sorted(cells)) + "])"
s=script.read_text(encoding="utf-8")
if "perimeter_cells" not in s:
    s=s.replace("@export var plaza_cells: Array[Vector2i] = []","@export var plaza_cells: Array[Vector2i] = []\n@export var perimeter_cells: Array[Vector2i] = []\n@export var connector_cells: Array[Vector2i] = []")
    s += """
\t# One-cell-wide perimeter promenade and short radial links to the fountain courts.
\tfor i in range(perimeter_cells.size()):
\t\tvar cell := perimeter_cells[i]
\t\tvar variant := posmod(cell.x * 3 + cell.y + i, 4)
\t\tlayer.set_cell(cell, 0, Vector2i(variant, 0))
\tfor i in range(connector_cells.size()):
\t\tvar cell := connector_cells[i]
\t\tvar variant := posmod(cell.x + cell.y * 3 + i, 4)
\t\tlayer.set_cell(cell, 0, Vector2i(variant, 0))
"""
    script.write_text(s,encoding="utf-8")
s=scene.read_text(encoding="utf-8")
# Replace only generated arrays, leaving the authored spine and original branches untouched.
import re
def replace_array(text,name,cells):
    value=arr(name,cells)
    pattern=r"(?m)^"+re.escape(name)+r" = Array\[Vector2i\]\(\[.*?\]\)$"
    if re.search(pattern,text):
        return re.sub(pattern,value,text,count=1)
    return text.replace("\n[node name=\"Tiles\"", "\n"+value+"\n\n[node name=\"Tiles\"")
s=replace_array(s,"cross_axis_cells",cross)
s=replace_array(s,"plaza_cells",plaza)
s=replace_array(s,"perimeter_cells",perimeter)
s=replace_array(s,"connector_cells",connectors)
scene.write_text(s,encoding="utf-8")
print("CROSS_AXIS",len(cross),"PERIMETER_LOOP",len(perimeter),"RADIAL_CONNECTORS",len(connectors),"COURTS",len(plaza))

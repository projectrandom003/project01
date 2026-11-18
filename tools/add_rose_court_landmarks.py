from pathlib import Path
p=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\scenes\world\castle_gardens\components\castle_flora_assembly.tscn")
s=p.read_text(encoding="utf-8")
nodes=[
("WestOuterRoseCourtArch","5_arch",250,900,.72),("EastOuterRoseCourtArch","5_arch",1030,900,.72),
("WestOuterFlowerPedestal","7_pedestal",185,820,.82),("EastOuterFlowerPedestal","7_pedestal",1095,820,.82),
("WestRoseCourtPink","8_pink_shrub",210,960,.74),("WestRoseCourtViolet","13_violet_shrub",300,985,.72),
("EastRoseCourtPink","8_pink_shrub",1070,960,.74),("EastRoseCourtWhite","11_white_shrub",980,985,.72)
]
if "WestOuterRoseCourtArch" not in s:
 for name,ext,x,y,sc in nodes:
  s+=f'\n[node name="{name}" type="Sprite2D" parent="OuterGardenEnrichment"]\ntexture = ExtResource("{ext}")\nposition = Vector2({x}, {y})\nscale = Vector2({sc}, {sc})\n'
 p.write_text(s,encoding="utf-8")
print("ROSE_COURT_LANDMARKS_ADDED",len(nodes))

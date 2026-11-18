from pathlib import Path
p=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\scenes\world\castle_gardens\components\castle_pathways.tscn")
s=p.read_text(encoding="utf-8")
line=next(x for x in s.splitlines() if x.startswith("branch_cells = "))
base="branch_cells = Array[Vector2i]([Vector2i(29, 14), Vector2i(29, 15), Vector2i(28, 15), Vector2i(28, 16), Vector2i(27, 16), Vector2i(27, 17), Vector2i(28, 14), Vector2i(27, 15), Vector2i(26, 16), Vector2i(33, 12), Vector2i(33, 11), Vector2i(34, 11), Vector2i(34, 10), Vector2i(35, 10), Vector2i(35, 9), Vector2i(36, 9), Vector2i(36, 8), Vector2i(36, 7), Vector2i(34, 12), Vector2i(35, 11), Vector2i(36, 10), Vector2i(37, 9)])"
s=s.replace(line,base)
p.write_text(s,encoding="utf-8")
flora=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\scenes\world\castle_gardens\components\castle_flora_assembly.tscn")
s=flora.read_text(encoding="utf-8")
new=[
("WestParterreOuterHedge01","12_rose_hedge",120,470,.66),("WestParterreOuterHedge02","12_rose_hedge",220,470,.66),("WestParterreOuterHedge03","12_rose_hedge",320,470,.66),
("WestParterreOuterHedge04","12_rose_hedge",120,700,.66),("WestParterreOuterHedge05","12_rose_hedge",320,700,.66),
("WestParterreOuterPink","8_pink_shrub",220,535,.82),("WestParterreOuterWhite","11_white_shrub",160,620,.76),("WestParterreOuterViolet","13_violet_shrub",280,625,.78),
("EastParterreOuterHedge01","12_rose_hedge",1160,470,.66),("EastParterreOuterHedge02","12_rose_hedge",1060,470,.66),("EastParterreOuterHedge03","12_rose_hedge",960,470,.66),
("EastParterreOuterHedge04","12_rose_hedge",1160,700,.66),("EastParterreOuterHedge05","12_rose_hedge",960,700,.66),
("EastParterreOuterPink","8_pink_shrub",1060,535,.82),("EastParterreOuterWhite","11_white_shrub",1120,620,.76),("EastParterreOuterViolet","13_violet_shrub",1000,625,.78),
("WestSouthBorderPink","8_pink_shrub",130,930,.8),("WestSouthBorderViolet","13_violet_shrub",210,1000,.78),("WestSouthBorderWhite","11_white_shrub",300,1040,.8),
("EastSouthBorderPink","8_pink_shrub",1150,930,.8),("EastSouthBorderViolet","13_violet_shrub",1070,1000,.78),("EastSouthBorderWhite","11_white_shrub",980,1040,.8),
("WestNorthBorderWhite","11_white_shrub",260,250,.72),("EastNorthBorderPink","8_pink_shrub",1020,250,.74)
]
if "WestParterreOuterHedge01" not in s:
    for name,ext,x,y,sc in new:
        s+=f'\n[node name="{name}" type="Sprite2D" parent="OuterGardenEnrichment"]\ntexture = ExtResource("{ext}")\nposition = Vector2({x}, {y})\nscale = Vector2({sc}, {sc})\n'
    flora.write_text(s,encoding="utf-8")
print("REMOVED_DISCONNECTED_PATH_TILES")
print("ADDED_FORMAL_SIDE_PARRERES",len(new))

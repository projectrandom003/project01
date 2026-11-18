from pathlib import Path
p=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\scenes\world\castle_gardens\components\castle_flora_assembly.tscn")
s=p.read_text(encoding="utf-8")
nodes=[
("NorthWestWisteriaGrove","2_wisteria",90,170,.64),("NorthEastWisteriaGrove","2_wisteria",1190,170,.64),
("WestOuterBlossomGrove","3_white",90,410,.72),("EastOuterBlossomGrove","1_pink",1190,410,.72),
("WestMidPinkCanopy","1_pink",115,930,.68),("EastMidWhiteCanopy","3_white",1165,930,.68),
("WestLowerCypressGrove","4_cypress",90,1080,.62),("EastLowerCypressGrove","4_cypress",1190,1080,.62),
("NorthWestGardenViolet","13_violet_shrub",360,220,.72),("NorthWestGardenWhite","11_white_shrub",420,270,.68),
("NorthEastGardenPink","8_pink_shrub",920,220,.72),("NorthEastGardenWhite","11_white_shrub",860,270,.68),
("WestOuterPinkCluster","8_pink_shrub",105,575,.72),("WestOuterVioletCluster","13_violet_shrub",190,635,.72),
("EastOuterPinkCluster","8_pink_shrub",1175,575,.72),("EastOuterVioletCluster","13_violet_shrub",1090,635,.72),
("WestSouthWhiteCluster","11_white_shrub",120,1120,.72),("WestSouthPinkCluster","8_pink_shrub",220,1150,.72),
("EastSouthWhiteCluster","11_white_shrub",1160,1120,.72),("EastSouthPinkCluster","8_pink_shrub",1060,1150,.72)
]
if "NorthWestWisteriaGrove" not in s:
 for name,ext,x,y,sc in nodes:
  s+=f'\n[node name="{name}" type="Sprite2D" parent="OuterGardenEnrichment"]\ntexture = ExtResource("{ext}")\nposition = Vector2({x}, {y})\nscale = Vector2({sc}, {sc})\n'
 p.write_text(s,encoding="utf-8")
print("GROVE_AND_OUTER_LAWN_DETAILS_ADDED",len(nodes))

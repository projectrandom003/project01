from pathlib import Path
import re
root=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy")
comp=root/"scenes/world/castle_gardens/components"
castle=comp/"reverie_royal_gardens_castle_collection.tscn"
for p in [castle,comp/"reverie_royal_gardens_full_preview.tscn",root/"scenes/world/castle_royal_gardens.tscn"]:
    b=p.with_suffix(p.suffix+".pre_castle_fences_20261118.bak")
    if not b.exists(): b.write_bytes(p.read_bytes())
s=castle.read_text(encoding="utf-8")
changes={
'position = Vector2(640, 252)\nscale = Vector2(1.08, 1.08)':'position = Vector2(640, 252)\nscale = Vector2(1.18, 1.18)',
'position = Vector2(386, 266)\nscale = Vector2(0.55, 0.55)':'position = Vector2(374, 266)\nscale = Vector2(0.60, 0.60)',
'position = Vector2(894, 266)\nscale = Vector2(0.55, 0.55)':'position = Vector2(906, 266)\nscale = Vector2(0.60, 0.60)',
'position = Vector2(430, 370)\nscale = Vector2(0.72, 0.72)':'position = Vector2(420, 370)\nscale = Vector2(0.78, 0.78)',
'position = Vector2(850, 370)\nscale = Vector2(-0.72, 0.72)':'position = Vector2(860, 370)\nscale = Vector2(-0.78, 0.78)',
'position = Vector2(530, 345)\nscale = Vector2(0.72, 0.72)':'position = Vector2(520, 345)\nscale = Vector2(0.78, 0.78)',
'position = Vector2(750, 345)\nscale = Vector2(0.72, 0.72)':'position = Vector2(760, 345)\nscale = Vector2(0.78, 0.78)',
'position = Vector2(480, 398)\nscale = Vector2(0.72, 0.72)':'position = Vector2(470, 398)\nscale = Vector2(0.78, 0.78)',
'position = Vector2(800, 398)\nscale = Vector2(0.72, 0.72)':'position = Vector2(810, 398)\nscale = Vector2(0.78, 0.78)',
'position = Vector2(640, 448)\nscale = Vector2(0.86, 0.86)':'position = Vector2(640, 448)\nscale = Vector2(0.92, 0.92)',
}
for a,b in changes.items():
    if a not in s: raise SystemExit("Missing castle anchor: "+a)
    s=s.replace(a,b,1)
castle.write_text(s,encoding="utf-8")

# Low ornamental royal ironwork: two enclosed side-court garden beds and short path-edge rails.
fence_nodes=[]
def add(name,tex,x,y,flip=False,scale=0.82,z=0):
    fence_nodes.append(f'''[node name="{name}" type="Sprite2D" parent="FenceRuns"]
texture = ExtResource("{tex}")
position = Vector2({x}, {y})
scale = Vector2({-scale if flip else scale}, {scale})
z_index = {z}
''')
# West side-court enclosure; open on the south-east side for access from the cross avenue.
for i,(x,y) in enumerate([(250,590),(315,625),(380,660),(445,695)]):
    add(f"WestCourtNorthRail{i+1}","1_fx",x,y,False,0.84)
for i,(x,y) in enumerate([(235,665),(285,730),(335,795)]):
    add(f"WestCourtWestRail{i+1}","2_fy",x,y,False,0.84)
for i,(x,y) in enumerate([(385,790),(440,745)]):
    add(f"WestCourtSouthRail{i+1}","1_fx",x,y,True,0.80)
# East court mirrors the western geometry.
for i,(x,y) in enumerate([(1030,590),(965,625),(900,660),(835,695)]):
    add(f"EastCourtNorthRail{i+1}","1_fx",x,y,True,0.84)
for i,(x,y) in enumerate([(1045,665),(995,730),(945,795)]):
    add(f"EastCourtEastRail{i+1}","2_fy",x,y,True,0.84)
for i,(x,y) in enumerate([(895,790),(840,745)]):
    add(f"EastCourtSouthRail{i+1}","1_fx",x,y,False,0.80)
# Delicate balustrades flank the lower ceremonial promenade without blocking the route.
for i,(x,y) in enumerate([(485,880),(485,950),(485,1020)]):
    add(f"WestPromenadeBalustrade{i+1}","3_bal",x,y,False,0.78,-1)
for i,(x,y) in enumerate([(795,880),(795,950),(795,1020)]):
    add(f"EastPromenadeBalustrade{i+1}","3_bal",x,y,True,0.78,-1)

scene='''[gd_scene load_steps=4 format=3]

[ext_resource type="Texture2D" path="res://assets/reverie_pack_v01/Royal_Gardens/Architecture/royal_fence_x_2x1.png" id="1_fx"]
[ext_resource type="Texture2D" path="res://assets/reverie_pack_v01/Royal_Gardens/Architecture/royal_fence_y_1x2.png" id="2_fy"]
[ext_resource type="Texture2D" path="res://assets/reverie_pack_v01/Royal_Gardens/Architecture/royal_balustrade_x_2x1.png" id="3_bal"]

[node name="CastleGardenFences" type="Node2D"]
y_sort_enabled = true

[node name="FenceRuns" type="Node2D" parent="."]
y_sort_enabled = true

'''+''.join(fence_nodes)
(comp/"castle_garden_fence_assembly.tscn").write_text(scene,encoding="utf-8")

for path in [comp/"reverie_royal_gardens_full_preview.tscn",root/"scenes/world/castle_royal_gardens.tscn"]:
    s=path.read_text(encoding="utf-8")
    if "castle_garden_fence_assembly.tscn" not in s:
        # Insert resource using next free id based on current ext resources.
        rid="10_fences" if path.name=="reverie_royal_gardens_full_preview.tscn" else "48_fences"
        line=f'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/components/castle_garden_fence_assembly.tscn" id="{rid}"]\n'
        # after final existing ext_resource
        idx=s.find("\n\n[node name=")
        s=s[:idx+1]+line+s[idx+1:]
        if path.name=="reverie_royal_gardens_full_preview.tscn":
            anchor='[node name="GardenFloraSystem" type="Node2D" parent="."]\ny_sort_enabled = true\n[node name="Flora" parent="GardenFloraSystem" instance=ExtResource("3_flora")]\n'
            insert=anchor+'\n[node name="FenceSystem" type="Node2D" parent="."]\ny_sort_enabled = true\n[node name="GardenFences" parent="FenceSystem" instance=ExtResource("10_fences")]\n'
        else:
            anchor='[node name="Flora" parent="." unique_id=183749210 instance=ExtResource("42_flora")]\n'
            insert=anchor+'\n[node name="GardenFences" parent="." instance=ExtResource("48_fences")]\n'
        if anchor not in s: raise SystemExit("Missing insertion anchor "+path.name)
        s=s.replace(anchor,insert,1)
        path.write_text(s,encoding="utf-8")
print("CASTLE_SCALE_UPDATES",len(changes))
print("FENCE_SPRITES",len(fence_nodes))
print("FENCE_ASSEMBLY_CREATED")

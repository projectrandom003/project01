from pathlib import Path
import re
root=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy")
p=root/"scenes/world/castle_gardens/components/castle_garden_fence_assembly.tscn"
s=p.read_text(encoding="utf-8")
if "reverie_fence_tileset_32.png" in s:
    raise SystemExit("Fence tile atlas already integrated; refusing duplicate insertion")
# Backup exact existing scene.
bak=p.with_suffix(p.suffix+".pre_32px_path_fences.bak")
if not bak.exists(): bak.write_bytes(p.read_bytes())
s=s.replace("[gd_scene load_steps=4 format=3]","[gd_scene load_steps=9 format=3]",1)
anchor='[ext_resource type="Texture2D" path="res://assets/reverie_pack_v01/Royal_Gardens/Architecture/royal_balustrade_x_2x1.png" id="3_bal"]\n'
insert=anchor+'[ext_resource type="Texture2D" path="res://assets/reverie_custom/royal_gardens/production/reverie_fence_tileset_32.png" id="4_generated"]\n\n'
subs='''[sub_resource type="AtlasTexture" id="FenceStraightA"]
atlas = ExtResource("4_generated")
region = Rect2(0, 0, 32, 32)

[sub_resource type="AtlasTexture" id="FenceStraightB"]
atlas = ExtResource("4_generated")
region = Rect2(32, 0, 32, 32)

[sub_resource type="AtlasTexture" id="FenceRosePost"]
atlas = ExtResource("4_generated")
region = Rect2(0, 32, 32, 32)

[sub_resource type="AtlasTexture" id="FenceFlowerPost"]
atlas = ExtResource("4_generated")
region = Rect2(32, 32, 32, 32)

'''
if anchor not in s: raise SystemExit("Fence scene resource anchor missing")
s=s.replace(anchor,insert+subs,1)
anchor='[node name="WestCourtNorthRail1" type="Sprite2D" parent="FenceRuns"]'
group='''[node name="StonePathwayFenceSides" type="Node2D" parent="FenceRuns"]
y_sort_enabled = true
'''
nodes=[]
ys=[548,602,656,710,764,916,970,1024]
for side,x,rot,flip in [('West',526,1.570796,False),('East',754,-1.570796,True)]:
    for i,y in enumerate(ys):
        sub="FenceStraightA" if i%2==0 else "FenceStraightB"
        nodes.append(f'''[node name="{side}PathFence{i+1}" type="Sprite2D" parent="FenceRuns/StonePathwayFenceSides"]
texture = SubResource("{sub}")
position = Vector2({x}, {y})
rotation = {rot}
scale = Vector2({-1.35 if flip else 1.35}, 1.35)
z_index = -1
''')
    # ornamental rose/flower terminals bookend the path sections.
    for name,y,sub in [('UpperRosePillar',520,'FenceRosePost'),('FountainRosePillar',790,'FenceFlowerPost'),('LowerRosePillar',1070,'FenceRosePost')]:
        nodes.append(f'''[node name="{side}{name}" type="Sprite2D" parent="FenceRuns/StonePathwayFenceSides"]
texture = SubResource("{sub}")
position = Vector2({x}, {y})
rotation = {rot}
scale = Vector2({-1.35 if flip else 1.35}, 1.35)
z_index = -1
''')
if anchor not in s: raise SystemExit("Fence node anchor missing")
s=s.replace(anchor,group+''.join(nodes)+anchor,1)
p.write_text(s,encoding="utf-8")
print("GENERATED_ATLAS_INTEGRATED")
print("PATH_SIDE_SEGMENTS",len(ys)*2)
print("ORNAMENTAL_POSTS",6)
print("TOTAL_FENCE_SPRITES",44)

from pathlib import Path
root=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy")
p=root/"scenes/world/castle_royal_gardens.tscn"
s=p.read_text(encoding="utf-8")
line='[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/components/castle_garden_fence_assembly.tscn" id="48_fences"]\n'
s=s.replace(line,"")
pos=s.index('[node name="CastleRoyalGardens"')
s=s[:pos]+line+"\n"+s[pos:]
p.write_text(s,encoding="utf-8")
p=root/"scenes/world/castle_gardens/components/reverie_royal_gardens_full_preview.tscn"
s=p.read_text(encoding="utf-8").replace("[gd_scene load_steps=10 format=3]","[gd_scene load_steps=11 format=3]",1)
p.write_text(s,encoding="utf-8")
print("SCENE_RESOURCE_ORDER_FIXED")

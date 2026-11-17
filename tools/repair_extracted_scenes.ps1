$ErrorActionPreference='Stop'
$root='C:\Users\quoth\Documents\Default Project\project-fantasy'
$dir=Join-Path $root 'scenes\world\castle_gardens\components'
$main=Join-Path $root 'scenes\world\castle_royal_gardens.tscn'
$backup=Join-Path $root 'scenes\world\castle_royal_gardens.tscn.pre_full_map_nodes_20261116_205414.bak'
$enc=New-Object System.Text.UTF8Encoding($false)
$nl=[Environment]::NewLine
# Repair missing closing quotes introduced while making scene-local parent paths.
$files=@('castle_terrain_layers.tscn','castle_pathways.tscn','castle_architecture_assembly.tscn','castle_water_assembly.tscn','castle_flora_assembly.tscn','castle_props_assembly.tscn','castle_perimeter_assembly.tscn')
foreach($name in $files){
 $p=Join-Path $dir $name
 $t=Get-Content $p -Raw
 $t=[regex]::Replace($t,'parent="\.(?=[\]\s])','parent="."')
 [System.IO.File]::WriteAllText($p,$t,$enc)
}
# Rebuild Props from the untouched pre-extraction scene so every instance/resource ref is complete.
$s=Get-Content $backup -Raw
$start=[regex]::Match($s,'(?m)^\[node name="Props" type="Node2D" parent="\."[^\r\n]*\]')
$tail=$s.Substring($start.Index+$start.Length)
$end=[regex]::Match($tail,'(?m)^\[node name="Lighting" type="Node2D" parent="\."[^\r\n]*\]')
if(!$start.Success -or !$end.Success){throw 'Could not locate complete Props assembly in backup'}
$length=$start.Length+$end.Index
$block=$s.Substring($start.Index,$length)
$block=$block -replace ' unique_id=\d+',''
$block=$block -replace 'parent="Props/Furniture"','parent="Furniture"'
$block=$block -replace 'parent="Props/Lighting"','parent="Lighting"'
$block=$block -replace 'parent="Props/Statues"','parent="Statues"'
$block=$block -replace 'parent="Props"','parent="."'
$block=$block -replace 'ExtResource\("15_scene"\)','ExtResource("1_bench")'
$block=$block -replace 'ExtResource\("16_scene"\)','ExtResource("2_lantern_gold")'
$block=$block -replace 'ExtResource\("17_scene"\)','ExtResource("3_lantern_arcane")'
$block=$block -replace 'ExtResource\("18_scene"\)','ExtResource("4_statue")'
$header='[gd_scene load_steps=5 format=3]'+$nl+
'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/v02/props/stone_bench.tscn" id="1_bench"]'+$nl+
'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/v02/props/lantern_post_gold.tscn" id="2_lantern_gold"]'+$nl+
'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/v02/props/lantern_post_arcane.tscn" id="3_lantern_arcane"]'+$nl+
'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/v02/props/guardian_statue.tscn" id="4_statue"]'
[System.IO.File]::WriteAllText((Join-Path $dir 'castle_props_assembly.tscn'),$header+$nl+$nl+$block.TrimEnd()+$nl,$enc)
Write-Output 'Repaired all extracted scene parent paths and rebuilt Props assembly from the untouched source scene.'

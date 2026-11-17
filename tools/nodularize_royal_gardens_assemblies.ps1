$ErrorActionPreference = 'Stop'
$root='C:\Users\quoth\Documents\Default Project\project-fantasy'
$main=Join-Path $root 'scenes\world\castle_royal_gardens.tscn'
$dir=Join-Path $root 'scenes\world\castle_gardens\components'
$nl=[Environment]::NewLine
$source=Get-Content $main -Raw
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
Copy-Item $main "$main.pre_assemblies_$stamp.bak"

function TakeBlock([string]$text,[string]$startName,[string]$nextName) {
  $s=[regex]::Match($text,'(?m)^\[node name="' + [regex]::Escape($startName) + '"[^\r\n]*\]')
  if(!$s.Success){throw "Missing start $startName"}
  $e=[regex]::Match($text.Substring($s.Index+$s.Length),'(?m)^\[node name="' + [regex]::Escape($nextName) + '"[^\r\n]*\]')
  if(!$e.Success){throw "Missing boundary $nextName after $startName"}
  $len=$s.Length+$e.Index
  $block=$text.Substring($s.Index,$len)
  $block=$block -replace ' unique_id=\d+',''
  return @{Text=$text.Remove($s.Index,$len);Block=$block}
}
function WriteScene([string]$name,[string]$header,[string]$block) {
  $enc=New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText((Join-Path $dir $name),$header+$nl+$nl+$block.TrimEnd()+$nl,$enc)
}

# Terrain layers
$a=TakeBlock $source 'Terrain' 'TerrainBuilder'; $source=$a.Text
$b=$a.Block -replace ' unique_id=\d+',''
WriteScene 'castle_terrain_layers.tscn' '[gd_scene format=3]' $b
$source=$source.Insert($source.IndexOf('[node name="TerrainBuilder"'),'[node name="Terrain" parent="." unique_id=183749206 instance=ExtResource("38_terrain")]'+$nl+$nl)

# Pathways group
$a=TakeBlock $source 'PathwayTiles' 'Castle'; $source=$a.Text
$b=$a.Block -replace 'ExtResource\("33_promenade"\)','ExtResource("1_promenade")'
$h='[gd_scene load_steps=2 format=3]'+$nl+'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/components/royal_promenade.tscn" id="1_promenade"]'
WriteScene 'castle_pathways.tscn' $h $b
$source=$source.Insert($source.IndexOf('[node name="Castle"'),'[node name="PathwayTiles" parent="." unique_id=183749207 instance=ExtResource("39_pathways")]'+$nl+$nl)

# Castle architecture assembly
$a=TakeBlock $source 'Castle' 'Water'; $source=$a.Text
$b=$a.Block -replace 'ExtResource\("2_scene"\)','ExtResource("1_tower")' -replace 'ExtResource\("4_scene"\)','ExtResource("2_wall_y")' -replace 'ExtResource\("5_scene"\)','ExtResource("3_wall_x")' -replace 'ExtResource\("6_scene"\)','ExtResource("4_gate")' -replace 'ExtResource\("7_scene"\)','ExtResource("5_stairs")' -replace 'ExtResource\("28_architecture"\)','ExtResource("6_architecture")'
$b=$b -replace '^\[node name="Castle"[^\r\n]*\]','[node name="Castle" type="Node2D"]'
$h='[gd_scene load_steps=7 format=3]'+$nl+
'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/v02/architecture/castle_tower.tscn" id="1_tower"]'+$nl+
'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/v02/architecture/castle_wall_y.tscn" id="2_wall_y"]'+$nl+
'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/v02/architecture/castle_wall_x.tscn" id="3_wall_x"]'+$nl+
'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/v02/architecture/castle_gate_arch.tscn" id="4_gate"]'+$nl+
'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/v02/architecture/castle_stairs.tscn" id="5_stairs"]'+$nl+
'[ext_resource type="Script" path="res://scripts/world/castle_gardens/components/castle_architecture_component.gd" id="6_architecture"]'
WriteScene 'castle_architecture_assembly.tscn' $h $b
$source=$source.Insert($source.IndexOf('[node name="Water"'),'[node name="Castle" parent="." unique_id=183749208 instance=ExtResource("40_castle")]'+$nl+$nl)

# Water assembly
$a=TakeBlock $source 'Water' 'Flora'; $source=$a.Text
$b=$a.Block -replace 'ExtResource\("8_scene"\)','ExtResource("1_fountain")' -replace 'ExtResource\("20_scene"\)','ExtResource("2_water_tile")'
$h='[gd_scene load_steps=3 format=3]'+$nl+
'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/v02/water/fountain_tiered.tscn" id="1_fountain"]'+$nl+
'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/v02/water/water_tile_anim.tscn" id="2_water_tile"]'
WriteScene 'castle_water_assembly.tscn' $h $b
$source=$source.Insert($source.IndexOf('[node name="Flora"'),'[node name="Water" parent="." unique_id=183749209 instance=ExtResource("41_water")]'+$nl+$nl)

# Flora assembly
$a=TakeBlock $source 'Flora' 'Props'; $source=$a.Text
$b=$a.Block -replace 'ExtResource\("9_scene"\)','ExtResource("1_oak")' -replace 'ExtResource\("10_scene"\)','ExtResource("2_blossom")' -replace 'ExtResource\("11_scene"\)','ExtResource("3_hedge_x")' -replace 'ExtResource\("12_scene"\)','ExtResource("4_hedge_y")' -replace 'ExtResource\("13_scene"\)','ExtResource("5_bush")' -replace 'ExtResource\("14_scene"\)','ExtResource("6_flower_bed")'
$h='[gd_scene load_steps=7 format=3]'+$nl+
'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/v02/flora/tree_oak_01.tscn" id="1_oak"]'+$nl+
'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/v02/flora/tree_blossom_01.tscn" id="2_blossom"]'+$nl+
'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/v02/flora/hedge_x.tscn" id="3_hedge_x"]'+$nl+
'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/v02/flora/hedge_y.tscn" id="4_hedge_y"]'+$nl+
'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/v02/flora/bush_round.tscn" id="5_bush"]'+$nl+
'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/v02/flora/flower_bed.tscn" id="6_flower_bed"]'
WriteScene 'castle_flora_assembly.tscn' $h $b
$source=$source.Insert($source.IndexOf('[node name="Props"'),'[node name="Flora" parent="." unique_id=183749210 instance=ExtResource("42_flora")]'+$nl+$nl)

# Props assembly
$a=TakeBlock $source 'Props' 'Lighting'; $source=$a.Text
$b=$a.Block -replace 'ExtResource\("15_scene"\)','ExtResource("1_bench")' -replace 'ExtResource\("16_scene"\)','ExtResource("2_lantern_gold")' -replace 'ExtResource\("17_scene"\)','ExtResource("3_lantern_arcane")' -replace 'ExtResource\("18_scene"\)','ExtResource("4_statue")'
$h='[gd_scene load_steps=5 format=3]'+$nl+
'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/v02/props/stone_bench.tscn" id="1_bench"]'+$nl+
'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/v02/props/lantern_post_gold.tscn" id="2_lantern_gold"]'+$nl+
'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/v02/props/lantern_post_arcane.tscn" id="3_lantern_arcane"]'+$nl+
'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/v02/props/guardian_statue.tscn" id="4_statue"]'
WriteScene 'castle_props_assembly.tscn' $h $b
$source=$source.Insert($source.IndexOf('[node name="Lighting" type="Node2D" parent="." unique_id=2023837209'),'[node name="Props" parent="." unique_id=183749211 instance=ExtResource("43_props")]'+$nl+$nl)

# Perimeter wall assembly
$a=TakeBlock $source 'GardenPerimeterWalls' 'OuterRoad'; $source=$a.Text
$b=$a.Block -replace 'ExtResource\("22_perimeter_walls"\)','ExtResource("1_wall_validator")' -replace 'ExtResource\("32_wall_run"\)','ExtResource("2_wall_run")'
$h='[gd_scene load_steps=3 format=3]'+$nl+
'[ext_resource type="Script" path="res://scripts/world/castle_gardens/components/castle_perimeter_walls_component.gd" id="1_wall_validator"]'+$nl+
'[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/components/castle_perimeter_wall_run.tscn" id="2_wall_run"]'
WriteScene 'castle_perimeter_assembly.tscn' $h $b
$source=$source.Insert($source.IndexOf('[node name="OuterRoad"'),'[node name="GardenPerimeterWalls" parent="." unique_id=183749212 instance=ExtResource("44_walls")]'+$nl+$nl)

$resources=@'
[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/components/castle_terrain_layers.tscn" id="38_terrain"]
[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/components/castle_pathways.tscn" id="39_pathways"]
[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/components/castle_architecture_assembly.tscn" id="40_castle"]
[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/components/castle_water_assembly.tscn" id="41_water"]
[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/components/castle_flora_assembly.tscn" id="42_flora"]
[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/components/castle_props_assembly.tscn" id="43_props"]
[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/components/castle_perimeter_assembly.tscn" id="44_walls"]
'@
$idx=$source.IndexOf('[node name="CastleRoyalGardens"')
$source=$source.Insert($idx,$resources+$nl)
$enc=New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($main,$source.TrimStart([char]0xFEFF),$enc)
Write-Output "Extracted terrain, pathways, castle, water, flora, props and perimeter walls into seven reusable assembly scenes."

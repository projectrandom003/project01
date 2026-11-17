$ErrorActionPreference = 'Stop'
$root = 'C:\Users\quoth\Documents\Default Project\project-fantasy'
$main = Join-Path $root 'scenes\world\castle_royal_gardens.tscn'
$components = Join-Path $root 'scenes\world\castle_gardens\components'
$nl = [Environment]::NewLine
$source = Get-Content $main -Raw
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
Copy-Item $main "$main.pre_full_map_nodes_$stamp.bak"

function Extract-SceneBlock([string]$text, [string]$startName, [string]$nextRootName, [string]$sceneRoot, [string]$parentPath) {
  $start = [regex]::Match($text, '(?m)^\[node name="' + [regex]::Escape($startName) + '"[^\r\n]*\]')
  if (!$start.Success) { throw "Cannot find start node $startName" }
  $end = [regex]::Match($text.Substring($start.Index + $start.Length), '(?m)^\[node name="' + [regex]::Escape($nextRootName) + '"[^\r\n]*\]')
  if (!$end.Success) { throw "Cannot find boundary node $nextRootName after $startName" }
  $length = $start.Length + $end.Index
  $block = $text.Substring($start.Index, $length)
  $block = [regex]::Replace($block, '(?m)^\[node name="' + [regex]::Escape($startName) + '"[^\r\n]*\]' + "\r?\n", '[node name="' + $sceneRoot + '" type="Node2D"]' + $nl, 1)
  $block = $block -replace ('parent="' + [regex]::Escape($parentPath) + '"'), 'parent="."'
  $block = $block -replace ' unique_id=\d+', ''
  return @{Text=$text.Remove($start.Index,$length); Block=$block}
}

$a = Extract-SceneBlock $source 'RoyalPromenade' 'Castle' 'RoyalPromenade' 'PathwayTiles/RoyalPromenade'
$source = $a.Text
$prom = '[gd_scene load_steps=2 format=3]' + $nl + $nl + '[ext_resource type="Texture2D" path="res://assets/castle_pack_v02/environment/terrain/path_cobble_01.png" id="1_path"]' + $nl + $nl + ($a.Block -replace 'ExtResource\("21_path"\)', 'ExtResource("1_path")')
Set-Content -Path (Join-Path $components 'royal_promenade.tscn') -Value $prom -Encoding UTF8
$insert = '[node name="RoyalPromenade" parent="PathwayTiles" unique_id=183749201 instance=ExtResource("33_promenade")]' + $nl + $nl
$source = $source.Insert($source.IndexOf('[node name="Castle"'),$insert)

$a = Extract-SceneBlock $source 'OuterRoad' 'ExpansionBuilder' 'OuterRoad' 'OuterRoad'
$source = $a.Text
$road = '[gd_scene load_steps=2 format=3]' + $nl + $nl + '[ext_resource type="Texture2D" path="res://assets/castle_pack_v02/environment/terrain/path_cobble_01.png" id="1_path"]' + $nl + $nl + ($a.Block -replace 'ExtResource\("21_path"\)', 'ExtResource("1_path")')
Set-Content -Path (Join-Path $components 'outer_road.tscn') -Value $road -Encoding UTF8
$insert = '[node name="OuterRoad" parent="." unique_id=183749202 instance=ExtResource("34_outer_road")]' + $nl + 'z_index = -8' + $nl + $nl
$source = $source.Insert($source.IndexOf('[node name="ExpansionBuilder"'),$insert)

$a = Extract-SceneBlock $source 'NPCPlacement' 'MapSpawnPoints' 'NPCPlacement' 'NPCPlacement'
$source = $a.Text
$npcScene = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/castle_gardens/components/npc_placement.gd" id="1"]

[node name="NPCPlacement" type="Node2D"]
script = ExtResource("1")

[node name="GuardLeft" type="Marker2D" parent="."]
position = Vector2(544, 272)

[node name="GuardRight" type="Marker2D" parent="."]
position = Vector2(672, 336)

[node name="Gardener" type="Marker2D" parent="."]
position = Vector2(384, 448)

[node name="Visitor" type="Marker2D" parent="."]
position = Vector2(896, 448)
'@
Set-Content -Path (Join-Path $components 'npc_placement.tscn') -Value $npcScene -Encoding UTF8
$insert = '[node name="NPCPlacement" parent="." unique_id=183749203 instance=ExtResource("35_npc_placement")]' + $nl + $nl
$source = $source.Insert($source.IndexOf('[node name="MapSpawnPoints"'),$insert)

$a = Extract-SceneBlock $source 'MapSpawnPoints' 'Bounds' 'MapSpawnPoints' 'MapSpawnPoints'
$source = $a.Text
$spawnScene = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/castle_gardens/components/map_spawn_points.gd" id="1"]

[node name="MapSpawnPoints" type="Node2D"]
script = ExtResource("1")

[node name="PlayerSpawn" type="Marker2D" parent="."]
position = Vector2(551, 521)

[node name="GardenEntrySpawn" type="Marker2D" parent="."]
position = Vector2(547, 393)
'@
Set-Content -Path (Join-Path $components 'map_spawn_points.tscn') -Value $spawnScene -Encoding UTF8
$insert = '[node name="MapSpawnPoints" parent="." unique_id=183749204 instance=ExtResource("36_spawn_points")]' + $nl + $nl
$source = $source.Insert($source.IndexOf('[node name="Bounds"'),$insert)

$a = Extract-SceneBlock $source 'Bounds' 'GardenPerimeterWalls' 'Bounds' 'Bounds'
$source = $a.Text
$boundsScene = @'
[gd_scene load_steps=5 format=3]

[sub_resource type="RectangleShape2D" id="LeftShape"]
size = Vector2(32, 900)

[sub_resource type="RectangleShape2D" id="RightShape"]
size = Vector2(32, 900)

[sub_resource type="RectangleShape2D" id="TopShape"]
size = Vector2(1400, 32)

[sub_resource type="RectangleShape2D" id="BottomShape"]
size = Vector2(1400, 32)

[node name="Bounds" type="StaticBody2D"]

[node name="Left" type="CollisionShape2D" parent="."]
position = Vector2(48, 400)
shape = SubResource("LeftShape")

[node name="Right" type="CollisionShape2D" parent="."]
position = Vector2(1203, 445)
shape = SubResource("RightShape")

[node name="Top" type="CollisionShape2D" parent="."]
position = Vector2(640, 48)
shape = SubResource("TopShape")

[node name="Bottom" type="CollisionShape2D" parent="."]
position = Vector2(551, 653)
shape = SubResource("BottomShape")
'@
Set-Content -Path (Join-Path $components 'castle_world_bounds.tscn') -Value $boundsScene -Encoding UTF8
$insert = '[node name="Bounds" parent="." unique_id=183749205 instance=ExtResource("37_world_bounds")]' + $nl + $nl
$source = $source.Insert($source.IndexOf('[node name="GardenPerimeterWalls"'),$insert)

$source = $source -replace '(?m)^\[node name="(Bench[^"]*)" parent="Props"', '[node name="$1" parent="Props/Furniture"'
$source = $source -replace '(?m)^\[node name="(Lantern[^"]*)" parent="Props"', '[node name="$1" parent="Props/Lighting"'
$source = $source -replace '(?m)^\[node name="(Statue[^"]*)" parent="Props"', '[node name="$1" parent="Props/Statues"'
$propsLine = '(?m)^\[node name="Props" type="Node2D" parent="\." unique_id=752116349\]' + "\r?\n" + 'y_sort_enabled = true' + "\r?\n"
$propsInsert = '[node name="Props" type="Node2D" parent="." unique_id=752116349]' + $nl + 'y_sort_enabled = true' + $nl + $nl + '[node name="Furniture" type="Node2D" parent="Props"]' + $nl + 'y_sort_enabled = true' + $nl + $nl + '[node name="Lighting" type="Node2D" parent="Props"]' + $nl + 'y_sort_enabled = true' + $nl + $nl + '[node name="Statues" type="Node2D" parent="Props"]' + $nl + 'y_sort_enabled = true' + $nl
$source = [regex]::Replace($source,$propsLine,[System.Text.RegularExpressions.MatchEvaluator]{ param($m) $propsInsert },1)

$resourceLines = @'
[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/components/royal_promenade.tscn" id="33_promenade"]
[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/components/outer_road.tscn" id="34_outer_road"]
[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/components/npc_placement.tscn" id="35_npc_placement"]
[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/components/map_spawn_points.tscn" id="36_spawn_points"]
[ext_resource type="PackedScene" path="res://scenes/world/castle_gardens/components/castle_world_bounds.tscn" id="37_world_bounds"]
'@
$insertAt = $source.IndexOf('[node name="CastleRoyalGardens"')
$source = $source.Insert($insertAt,$resourceLines + $nl)
Set-Content -Path $main -Value $source -Encoding UTF8
Write-Output "Created component scenes for promenade and outer road; instanced NPCPlacement, MapSpawnPoints and Bounds; grouped furniture, lighting and statues. Backup: $main.pre_full_map_nodes_$stamp.bak"

$enc = New-Object System.Text.UTF8Encoding($false)
$generated = @($main,(Join-Path $components 'royal_promenade.tscn'),(Join-Path $components 'outer_road.tscn'),(Join-Path $components 'npc_placement.tscn'),(Join-Path $components 'map_spawn_points.tscn'),(Join-Path $components 'castle_world_bounds.tscn'))
foreach ($file in $generated) {
  $text = Get-Content $file -Raw
  $text = $text.TrimStart([char]0xFEFF)
  [System.IO.File]::WriteAllText($file,$text,$enc)
}
Write-Output 'Generated scenes saved as UTF-8 without BOM.'

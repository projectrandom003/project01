$ErrorActionPreference='Stop'
$root='C:\Users\quoth\Documents\Default Project\project-fantasy'
$dir=Join-Path $root 'scenes\world\castle_gardens\components'
$main=Join-Path $root 'scenes\world\castle_royal_gardens.tscn'
$enc=New-Object System.Text.UTF8Encoding($false)
$nl=[Environment]::NewLine

$replacements=@(
 @('castle_terrain_layers.tscn','parent="Terrain"','parent=".'),
 @('castle_pathways.tscn','parent="PathwayTiles"','parent=".'),
 @('castle_architecture_assembly.tscn','parent="Castle"','parent=".'),
 @('castle_water_assembly.tscn','parent="Water/FountainCourt"','parent="FountainCourt"'),
 @('castle_water_assembly.tscn','parent="Water/OuterPonds"','parent="OuterPonds"'),
 @('castle_water_assembly.tscn','parent="Water"','parent=".'),
 @('castle_flora_assembly.tscn','parent="Flora/TreeAvenue"','parent="TreeAvenue"'),
 @('castle_flora_assembly.tscn','parent="Flora/FlowerBorders"','parent="FlowerBorders"'),
 @('castle_flora_assembly.tscn','parent="Flora/HedgesAndShrubs"','parent="HedgesAndShrubs"'),
 @('castle_flora_assembly.tscn','parent="Flora/WorldPerimeter"','parent="WorldPerimeter"'),
 @('castle_flora_assembly.tscn','parent="Flora"','parent=".'),
 @('castle_perimeter_assembly.tscn','parent="GardenPerimeterWalls"','parent="."')
)
foreach($r in $replacements){
 $p=Join-Path $dir $r[0]
 $t=Get-Content $p -Raw
 $t=$t.Replace($r[1],$r[2])
 [System.IO.File]::WriteAllText($p,$t,$enc)
}

$s=Get-Content $main -Raw
$start=[regex]::Match($s,'(?m)^\[node name="Lighting" type="Node2D" parent="Props"\]')
if(!$start.Success){throw 'Props Lighting child not found'}
$end=[regex]::Match($s.Substring($start.Index),'(?m)^\[node name="Props" parent="\."')
if(!$end.Success){throw 'Props root instance boundary not found'}
$block=$s.Substring($start.Index,$end.Index)
$s=$s.Remove($start.Index,$end.Index)
[System.IO.File]::WriteAllText($main,$s,$enc)

$props=Join-Path $dir 'castle_props_assembly.tscn'
$pt=Get-Content $props -Raw
$pt=$pt.Replace('parent="Props/Furniture"','parent="Furniture"')
$pt=$pt.Replace('parent="Props/Lighting"','parent="Lighting"')
$pt=$pt.Replace('parent="Props/Statues"','parent="Statues"')
$pt=$pt.Replace('parent="Props"','parent="."')
$pt=$pt.TrimEnd()+$nl+$nl+$block
[System.IO.File]::WriteAllText($props,$pt,$enc)
Write-Output 'Repaired scene-local parent paths and moved the complete Props hierarchy into its reusable assembly scene.'

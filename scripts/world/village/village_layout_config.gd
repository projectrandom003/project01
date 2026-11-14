class_name VillageLayoutConfig
extends Resource
## Deterministic, authored-first village layout configuration.
## Major placements remain authored in scenes/data; the seed allows limited,
## repeatable variation of permitted decorative details without changing the
## designed layout.

@export var village_seed: int = 133742
@export var village_id: String = "greenward_village"
@export var display_name: String = "Whispering Glade"

## Named authored anchor points (grid/world coords resolved by the village scene).
@export var anchors: Dictionary = {}
## Authored building/landmark slots (stable positions, existing contracts preserved).
@export var building_slots: Array = []
## Tree-group definitions (authored clusters/clearings/boundary frames).
## Each: {name, purpose, trees:[{kind,world,grid,scale,variant,flip}], anchors:[...], clearings:[...]}
@export var tree_groups: Array[Dictionary] = []
## Exclusion zones (world-space circles/rects) protecting important areas.
## Each: {type:"circle", center:Vector2, radius:float} or {type:"rect", center:Vector2, size:Vector2}
@export var exclusion_zones: Array = []
## Permitted decorative variation slots (small, non-structural).
@export var decorative_variants: Array[Dictionary] = []
## Path network segments (authored connectivity).
@export var path_segments: Array[Dictionary] = []

func stable_rng(stream: String = "default") -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash("%s:%s:%d" % [village_id, stream, village_seed]))
	return rng

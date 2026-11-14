class_name ForestBiomeProfile
extends Resource
## Data-only biome composition. PackedScenes are reusable authored families;
## placement and lifetime are owned by ForestBiomeAssembler.

@export var biome_id: StringName = &"greenward_forest"
@export var tree_scenes: Array[PackedScene] = []
@export var understory_scenes: Array[PackedScene] = []
@export var ambient_scenes: Array[PackedScene] = []
@export_range(0, 64, 1) var tree_count: int = 8
@export_range(0, 128, 1) var understory_count: int = 22
@export_range(0, 64, 1) var ambient_count: int = 5
@export_range(0.0, 256.0, 1.0) var tree_min_spacing: float = 92.0
@export_range(0.0, 128.0, 1.0) var understory_min_spacing: float = 26.0
@export var bounds_inset: Vector2 = Vector2(24.0, 24.0)

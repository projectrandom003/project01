class_name BuildingConfig
extends Resource

@export var building_kind: String = ""
@export var visual_variant: int = 0
@export_range(0.1, 3.0, 0.01) var visual_scale: float = 1.0
@export var blocks_movement: bool = true
@export var collision_size: Vector2 = Vector2(72.0, 26.0)
@export var collision_offset: Vector2 = Vector2(0.0, -8.0)
@export var interaction_enabled: bool = false
@export var interaction_prompt: String = "Enter"
@export var foundation_visible: bool = true
@export var walls_visible: bool = true
@export var roof_visible: bool = true
@export var doors_visible: bool = true
@export var windows_visible: bool = true
@export var decorations_visible: bool = true
@export var lighting_visible: bool = true
@export var metadata: Dictionary = {}


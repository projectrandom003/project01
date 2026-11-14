class_name EquipmentDefinition
extends Resource
## Data-only definition for a character equipment visual.
## Art remains external; the mount scene owns presentation nodes and animation.

@export var equipment_id: StringName = &""
@export var display_name: String = ""
@export var texture: Texture2D
@export var sprite_offset: Vector2 = Vector2.ZERO
@export var sprite_scale: Vector2 = Vector2.ONE
@export var sprite_z_index: int = 0
@export var centered: bool = true
@export var flip_h: bool = false
@export var modulate: Color = Color.WHITE
@export var enabled: bool = true

class_name BuildingPart
extends Node2D
## Generic reusable building subpart container (foundation/walls/roof/doors/windows/decorations/lighting).

signal part_visibility_changed(visible_state: bool)

@export var part_type: StringName = &"generic"
@export var enabled: bool = true:
	set(value):
		enabled = value
		visible = value
		part_visibility_changed.emit(value)


func set_part_enabled(value: bool) -> void:
	enabled = value


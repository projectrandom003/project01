class_name CastleArchitectureComponent
extends Node2D
## Owns the placement transform of the authored modular castle assembly.

@export var assembly_position := Vector2(0, 144)
@export var assembly_scale := Vector2(1.10, 1.10)

func _ready() -> void:
	position = assembly_position
	scale = assembly_scale
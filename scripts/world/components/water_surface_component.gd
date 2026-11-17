class_name WaterSurfaceComponent
extends Node2D
## Reusable configurable water presentation component.

@export var water_color: Color = Color(0.25, 0.55, 0.75, 0.75)
@export var flow_speed: float = 0.4
@export var ripple_enabled: bool = true
@export var wave_amplitude: float = 1.5

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer") as AnimationPlayer


func _ready() -> void:
	if sprite != null:
		sprite.modulate = water_color
	if ripple_enabled and animation_player != null and animation_player.has_animation("ripple"):
		animation_player.play("ripple")

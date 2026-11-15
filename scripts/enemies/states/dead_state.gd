class_name EnemyDeadState
extends "res://scripts/enemies/states/enemy_state.gd"

func _ready() -> void:
	state_name = &"dead"

func enter(context: Dictionary = {}) -> void:
	super.enter(context)
	if controller != null and controller.has_method("request_animation"):
		controller.call("request_animation", &"dead")

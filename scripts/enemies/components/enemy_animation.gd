class_name EnemyAnimation
extends Node

signal animation_requested(animation_name: StringName)
signal animation_state_changed(from_state: StringName, to_state: StringName)

@export var visual_path: NodePath
var visual: Node = null
var current_state: StringName = &"idle"


func _ready() -> void:
	if not visual_path.is_empty():
		visual = get_node_or_null(visual_path)
	if visual == null:
		visual = get_parent()


func play_state(state: StringName) -> void:
	if state == current_state:
		return
	var prev := current_state
	current_state = state
	animation_state_changed.emit(prev, state)
	animation_requested.emit(state)
	if visual == null:
		return
	match state:
		&"idle":
			if "walking" in visual: visual.walking = false
			if visual.has_method("play"): visual.call("play", 0)
		&"walk", &"patrol", &"roam", &"return", &"investigate":
			if "walking" in visual: visual.walking = true
			if visual.has_method("play"): visual.call("play", 1)
		&"chase", &"run":
			if "walking" in visual: visual.walking = true
			if visual.has_method("play"): visual.call("play", 2)
		&"attack", &"cast":
			if "walking" in visual: visual.walking = false
		&"dead", &"death":
			if "walking" in visual: visual.walking = false
		_:
			pass


func set_move_direction(direction: Vector2) -> void:
	if visual != null and visual.has_method("set_move_direction"):
		visual.call("set_move_direction", direction)

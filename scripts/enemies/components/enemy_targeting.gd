class_name EnemyTargeting
extends Node

signal target_selected(target: Node)
signal target_changed(previous: Node, current: Node)
signal target_lost(target: Node)
signal target_tracked(target: Node, position: Vector2)

@export var tracking_enabled: bool = true

var current_target: Node = null
var last_known_position: Vector2 = Vector2.ZERO


func select_target(target: Node) -> void:
	if target == current_target:
		return
	var prev := current_target
	current_target = target
	if prev != null and target != prev:
		target_changed.emit(prev, target)
	if target != null:
		last_known_position = _target_pos(target)
		target_selected.emit(target)
	elif prev != null:
		target_lost.emit(prev)


func clear_target() -> void:
	if current_target != null:
		var prev := current_target
		current_target = null
		target_lost.emit(prev)


func track(_delta: float) -> Vector2:
	if not tracking_enabled or current_target == null or not is_instance_valid(current_target):
		return last_known_position
	last_known_position = _target_pos(current_target)
	target_tracked.emit(current_target, last_known_position)
	return last_known_position


func _target_pos(target: Node) -> Vector2:
	if target is Node2D:
		return (target as Node2D).global_position
	return last_known_position

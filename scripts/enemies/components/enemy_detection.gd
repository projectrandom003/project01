class_name EnemyDetection
extends Node

signal player_detected(player: Node)
signal player_lost(player: Node)
signal aggro_acquired(target: Node)
signal aggro_lost(target: Node)
signal line_of_sight_changed(has_los: bool)

@export var config: Resource
@export var detection_radius: float = 96.0
@export var aggro_radius: float = 96.0
@export var lose_aggro_radius: float = 140.0
@export var detection_enabled: bool = false
@export var line_of_sight_required: bool = false

var current_target: Node = null
var has_aggro: bool = false
var has_line_of_sight: bool = true


func _ready() -> void:
	_apply_config()


func _apply_config() -> void:
	if config == null:
		return
	detection_enabled = config.detection_enabled
	detection_radius = config.detection_radius
	aggro_radius = config.aggro_radius
	lose_aggro_radius = config.lose_aggro_radius
	line_of_sight_required = config.line_of_sight_required


func evaluate(owner_node: Node2D, player: Node2D) -> Dictionary:
	if not detection_enabled or owner_node == null or player == null or not is_instance_valid(player):
		if has_aggro:
			_clear_aggro()
		return {"detected": false, "has_aggro": has_aggro, "distance": INF}
	var dist := owner_node.global_position.distance_to(player.global_position)
	var detected := dist <= detection_radius
	var los_ok := (not line_of_sight_required) or _check_line_of_sight(owner_node, player)
	if los_ok != has_line_of_sight:
		has_line_of_sight = los_ok
		line_of_sight_changed.emit(has_line_of_sight)
	if detected and los_ok:
		if current_target != player:
			current_target = player
			player_detected.emit(player)
		if not has_aggro and dist <= aggro_radius:
			has_aggro = true
			aggro_acquired.emit(player)
	elif has_aggro and (dist > lose_aggro_radius or not los_ok):
		_clear_aggro()
	elif current_target != null and dist > detection_radius:
		var lost := current_target
		current_target = null
		player_lost.emit(lost)
	return {"detected": detected and los_ok, "has_aggro": has_aggro, "distance": dist, "los": los_ok}


func force_acquire(target: Node) -> void:
	current_target = target
	if target != null:
		player_detected.emit(target)
		if not has_aggro:
			has_aggro = true
			aggro_acquired.emit(target)


func force_lose() -> void:
	_clear_aggro()
	if current_target != null:
		var t = current_target
		current_target = null
		player_lost.emit(t)


func _clear_aggro() -> void:
	if has_aggro:
		has_aggro = false
		aggro_lost.emit(current_target)


func _check_line_of_sight(owner_node: Node2D, player: Node2D) -> bool:
	if owner_node == null or player == null or not owner_node.is_inside_tree():
		return true
	var space := owner_node.get_world_2d()
	if space == null:
		return true
	var query := PhysicsRayQueryParameters2D.create(owner_node.global_position, player.global_position)
	query.exclude = [owner_node.get_rid()]
	var result := space.direct_space_state.intersect_ray(query)
	if result.is_empty():
		return true
	return result.get("collider") == player

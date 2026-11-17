class_name GameSessionDomainComponent
extends Node
## Owns active-world identity, player location/facing and per-region saved positions.

var player_position: Vector2 = Vector2.ZERO
var has_player_position: bool = false
var player_facing: Vector2 = Vector2(0.0, 1.0)
var player_region: String = "greenward"
var active_world_id: String = "greenward"
var region_positions: Dictionary = {}
var loaded_from_save: bool = false


func reset() -> void:
	player_position = Vector2.ZERO
	has_player_position = false
	player_facing = Vector2(0.0, 1.0)
	player_region = "greenward"
	active_world_id = "greenward"
	region_positions.clear()
	loaded_from_save = false


func set_player_position(position: Vector2) -> void:
	player_position = position
	has_player_position = true
	region_positions[player_region] = {"x": position.x, "y": position.y}


func set_player_region(region_id: String) -> void:
	player_region = region_id
	active_world_id = region_id


func set_active_world(world_id: String) -> void:
	set_player_region(world_id)


func set_player_facing(facing: Vector2) -> void:
	if facing.length_squared() < 0.0001:
		return
	player_facing = facing.normalized()


func set_region_position(region_id: String, position: Vector2) -> void:
	region_positions[region_id] = {"x": position.x, "y": position.y}


func region_position(region_id: String) -> Vector2:
	var value: Variant = region_positions.get(region_id, null)
	if value is Vector2:
		return value
	if typeof(value) == TYPE_DICTIONARY:
		var data: Dictionary = value
		return Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
	return Vector2.ZERO


func has_region_position(region_id: String) -> bool:
	return region_positions.has(region_id)

class_name MapSpawnPoints
extends Node2D
## Container for player/map spawn markers (Marker2D/Node2D).

func get_spawn(name_or_default: String = "PlayerSpawn") -> Vector2:
	var n := get_node_or_null(name_or_default) as Node2D
	if n != null:
		return n.position
	for c in get_children():
		if c is Node2D:
			return (c as Node2D).position
	return Vector2.ZERO

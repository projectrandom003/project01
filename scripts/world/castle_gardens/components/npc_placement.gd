class_name NpcPlacement
extends Node2D
## Container for NPC placement markers. Marker metadata can define npc_id,
## display_name, dialogue_id, role, race, palette for optional runtime spawning.

func get_points() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for c in get_children():
		if c is Node2D:
			out.append(c as Node2D)
	return out

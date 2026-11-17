class_name CastleNPCSpawnerComponent
extends Node
## Owns marker-driven NPC creation. All identity and placement configuration
## is required on the authored NPCPlacement Marker2D.

const NPC_SCENE: PackedScene = preload("res://scenes/world/world_npc.tscn")

var world: CastleRoyalGardens


func bind(owner_world: CastleRoyalGardens) -> void:
	world = owner_world


func spawn_from_markers() -> void:
	if world == null or world.npc_placement == null or world.entities == null:
		push_error("CastleNPCSpawner requires a bound world with authored NPCPlacement and Entities.")
		return
	for marker in world.npc_placement.get_children():
		if not (marker is Marker2D):
			continue
		var marker_2d := marker as Marker2D
		var required_keys := ["npc_id", "display_name", "dialogue_id", "role", "race", "palette", "grid_position"]
		var missing: Array[String] = []
		for key in required_keys:
			if not marker_2d.has_meta(key):
				missing.append(key)
		var palette_value: Variant = marker_2d.get_meta("palette", null)
		var grid_value: Variant = marker_2d.get_meta("grid_position", null)
		if not missing.is_empty() or typeof(palette_value) != TYPE_DICTIONARY or not (grid_value is Vector2):
			push_error("NPC placement %s has incomplete authored configuration: %s." % [marker_2d.name, ", ".join(missing)])
			continue
		var npc_id := str(marker_2d.get_meta("npc_id"))
		var display_name := str(marker_2d.get_meta("display_name"))
		var dialogue_id := str(marker_2d.get_meta("dialogue_id"))
		var role := str(marker_2d.get_meta("role"))
		var race := str(marker_2d.get_meta("race"))
		var palette: Dictionary = palette_value
		if npc_id.is_empty() or display_name.is_empty() or dialogue_id.is_empty() or role.is_empty() or race.is_empty():
			push_error("NPC placement %s contains an empty identity field." % marker_2d.name)
			continue
		var npc := NPC_SCENE.instantiate() as WorldNPC
		if npc == null:
			push_error("CastleNPCSpawner could not instantiate NPC scene for marker %s." % marker_2d.name)
			continue
		npc.role = role
		npc.setup(npc_id, display_name, dialogue_id, palette, race)
		npc.position = IsoMath.grid_to_world(grid_value.x, grid_value.y)
		world.entities.add_child(npc)
		world.npcs.append(npc)

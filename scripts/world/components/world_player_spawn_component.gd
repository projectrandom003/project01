class_name WorldPlayerSpawnComponent
extends Node
## Resolves the active region's entry/save/spawn position and creates its player actor.

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player.tscn")

var world: Node2D


func _ready() -> void:
	world = get_parent() as Node2D


func spawn_player() -> Player:
	if world == null or not is_instance_valid(world):
		return null
	var region: Dictionary = world.get("region")
	var region_id := str(world.get("region_id"))
	var entry_point := str(world.get("entry_point"))
	var entities := world.get("entities") as Node2D
	if entities == null or region.is_empty():
		return null

	var player := PLAYER_SCENE.instantiate() as Player
	player.name = "Player"
	var placed := false

	# A travel entry point takes precedence over saved positions.
	if not entry_point.is_empty():
		var entry_points: Variant = region.get("entry_points", {})
		if typeof(entry_points) == TYPE_DICTIONARY and entry_points.has(entry_point):
			var grid: Variant = entry_points[entry_point]
			if typeof(grid) == TYPE_ARRAY and grid.size() == 2:
				player.position = IsoMath.grid_to_world(float(grid[0]), float(grid[1]))
				placed = true

	# Resume this region's saved position when it is safely away from the origin.
	if not placed and GameState.session_domain.player_region == region_id and GameState.session_domain.has_region_position(region_id):
		var saved_position := GameState.session_domain.region_position(region_id)
		if saved_position.length_squared() > 32.0 * 32.0:
			player.position = saved_position
			placed = true
		else:
			push_warning("[GreenwardWorld] Ignoring invalid near-origin saved spawn for %s; using region spawn." % region_id)

	# Legacy single-slot position applies only to the default Greenward region.
	if not placed and GameState.session_domain.has_player_position and region_id == "greenward":
		var legacy_position: Vector2 = GameState.session_domain.player_position
		if legacy_position.length_squared() > 32.0 * 32.0:
			player.position = legacy_position
			placed = true
		else:
			push_warning("[GreenwardWorld] Ignoring invalid near-origin legacy player position; using region spawn.")

	if not placed:
		var spawn: Array = region.get("spawn_grid", [8, 8])
		player.position = IsoMath.grid_to_world(float(spawn[0]), float(spawn[1]))

	var resolved_spawn := player.position
	entities.add_child(player)
	player.global_position = entities.to_global(resolved_spawn)
	player.reset_physics_interpolation()
	player.restore_facing(GameState.session_domain.player_facing)
	world.set("player", player)
	GameState.session_domain.set_player_region(region_id)
	GameState.session_domain.set_player_position(player.position)
	GameState.session_domain.set_region_position(region_id, player.position)
	return player

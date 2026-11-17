class_name CastlePlayerSpawnerComponent
extends Node
## Owns player instantiation and restoration for Royal Gardens.

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player.tscn")
var world: CastleRoyalGardens

func bind(owner_world: CastleRoyalGardens) -> void:
	world = owner_world

func spawn_player() -> Player:
	if world == null or world.entities == null:
		push_error("CastlePlayerSpawner requires a bound world and authored Entities layer.")
		return null
	var actor := PLAYER_SCENE.instantiate() as Player
	if actor == null:
		push_error("CastlePlayerSpawner could not instantiate Player.")
		return null
	actor.name = "Player"
	var placed := false
	if not world.entry_point.is_empty():
		var entries: Variant = ContentDB.get_region(world.region_id).get("entry_points", {})
		if typeof(entries) == TYPE_DICTIONARY and (entries as Dictionary).has(world.entry_point):
			var grid: Variant = (entries as Dictionary)[world.entry_point]
			if typeof(grid) == TYPE_ARRAY and (grid as Array).size() == 2:
				actor.position = IsoMath.grid_to_world(float(grid[0]), float(grid[1]))
				placed = true
	if not placed and GameState.session_domain.player_region == world.region_id and GameState.session_domain.has_region_position(world.region_id):
		var saved := GameState.session_domain.region_position(world.region_id)
		if saved.length_squared() > 1.0:
			actor.position = saved
			placed = true
	if not placed and GameState.session_domain.has_player_position and GameState.session_domain.player_region == world.region_id:
		actor.position = GameState.session_domain.player_position
		placed = true
	if not placed:
		actor.position = world.get_spawn_position("PlayerSpawn")
	var spawn := actor.position
	world.entities.add_child(actor)
	actor.global_position = world.entities.to_global(spawn)
	if actor.has_method("reset_physics_interpolation"):
		actor.reset_physics_interpolation()
	if actor.has_method("restore_facing"):
		actor.restore_facing(GameState.session_domain.player_facing)
	world.player = actor
	GameState.session_domain.set_player_region(world.region_id)
	GameState.session_domain.set_player_position(actor.position)
	GameState.session_domain.set_region_position(world.region_id, actor.position)
	return actor
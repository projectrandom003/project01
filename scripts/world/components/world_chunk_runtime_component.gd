class_name WorldChunkRuntimeComponent
extends Node
## Owns the per-frame player-to-chunk relationship and bounded chunk prefetch.

var world: GreenwardWorld


func configure(owner_world: GreenwardWorld) -> void:
	world = owner_world


func update_player_chunk(player_grid: Vector2) -> void:
	if world == null or world.streamer == null:
		return
	var center := world.streamer.center_chunk(player_grid)
	if center == world.current_center:
		return
	world.current_center = center
	world._update_streaming(player_grid)


func prepare_next_chunk(player_grid: Vector2) -> void:
	if world != null and world.chunk_streaming_component != null:
		world.chunk_streaming_component.prepare_one_chunk(player_grid)

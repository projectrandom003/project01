class_name WorldChunkStreamingComponent
extends Node
## Owns chunk scheduling, frame-sliced preparation and prepared-node cache cleanup.

var world: GreenwardWorld
var streamer: ChunkStreamer
var preparer: ChunkPreparer
var prepared_nodes: Dictionary = {}


func configure(owner_world: GreenwardWorld, chunk_size: int, load_radius: int) -> void:
	world = owner_world
	streamer = ChunkStreamer.new(chunk_size, load_radius)
	preparer = ChunkPreparer.new()


func update_streaming(player_grid: Vector2) -> void:
	if world == null or streamer == null:
		return
	var needed: Array = streamer.needed_chunks(player_grid)
	var needed_set: Dictionary = {}
	for coord in needed:
		needed_set[coord] = true
	for coord in world.loaded_chunks.keys():
		if not needed_set.has(coord):
			world._unload_chunk(coord)
	for coord in needed:
		if not world.loaded_chunks.has(coord):
			world._load_chunk(coord)


func prepare_one_chunk(player_grid: Vector2) -> void:
	if world == null or preparer == null or streamer == null:
		return
	# Bounded prefetch ring just outside the loaded ring.
	var ring: Array = []
	var center := streamer.center_chunk(player_grid)
	var outer := streamer.radius + 1
	for y in range(-outer, outer + 1):
		for x in range(-outer, outer + 1):
			if absi(x) <= streamer.radius and absi(y) <= streamer.radius:
				continue
			var coord := center + Vector2i(x, y)
			if not world.loaded_chunks.has(coord):
				ring.append(coord)
	preparer.request_many(ring)
	var next_coord := preparer.next_pending()
	if next_coord == ChunkPreparer.EMPTY_COORD:
		return
	if world.loaded_chunks.has(next_coord) or preparer.has_prepared(next_coord):
		return
	# Node/Multimesh construction stays on the main thread: at most one chunk per frame.
	var data := ChunkBuilder.build(
		next_coord, world.region, world.elevation, world.moisture,
		world.terrain_material, world.water_material
	)
	preparer.store(next_coord, data)
	prepared_nodes[next_coord] = data
	reconcile_prepared_cache()


func reconcile_prepared_cache() -> void:
	if world == null or prepared_nodes.is_empty() or preparer == null:
		return
	var stale: Array = []
	for coord in prepared_nodes.keys():
		if not preparer.has_prepared(coord):
			stale.append(coord)
	for coord in stale:
		world._free_chunk_data(prepared_nodes[coord])
		prepared_nodes.erase(coord)


func clear_prepared() -> void:
	if preparer == null:
		return
	for coord in prepared_nodes.keys():
		if world != null:
			world._free_chunk_data(prepared_nodes[coord])
	prepared_nodes.clear()
	preparer.clear()


func _exit_tree() -> void:
	clear_prepared()


func free_chunk_data(data: Dictionary) -> void:
	# detail is already parented to terrain, so freeing terrain releases it.
	var terrain: Node = data.get("terrain", null)
	if terrain != null and is_instance_valid(terrain) and not terrain.is_inside_tree():
		terrain.free()
	var water: Node = data.get("water", null)
	if water != null and is_instance_valid(water) and not water.is_inside_tree():
		water.free()

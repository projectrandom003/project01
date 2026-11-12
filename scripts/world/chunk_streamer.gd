class_name ChunkStreamer
extends RefCounted
## Pure chunk-selection math. The world only ever keeps a ring of chunks around
## the player; distant content is freed. Designed to scale to hundreds of
## connected areas by swapping the region generator, not the streaming logic.

var chunk_size: int = 16
var radius: int = 1


func _init(size: int = 16, load_radius: int = 1) -> void:
	chunk_size = size
	radius = load_radius


func center_chunk(player_grid: Vector2) -> Vector2i:
	return IsoMath.chunk_of_grid(player_grid, chunk_size)


func needed_chunks(player_grid: Vector2) -> Array:
	var center := center_chunk(player_grid)
	var result: Array = []
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			result.append(center + Vector2i(x, y))
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := Vector2(a - center).length_squared()
		var db := Vector2(b - center).length_squared()
		if is_equal_approx(da, db):
			return a.x < b.x
		return da < db
	)
	return result


func is_needed(chunk: Vector2i, player_grid: Vector2) -> bool:
	var center := center_chunk(player_grid)
	return absi(chunk.x - center.x) <= radius and absi(chunk.y - center.y) <= radius

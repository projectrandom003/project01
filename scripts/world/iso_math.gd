class_name IsoMath
extends RefCounted
## Isometric projection helpers. The world is a continuous 2D space; grid
## coordinates exist only for terrain, chunking and placement.

const TILE_W := 64.0
const TILE_H := 32.0


static func grid_to_world(grid_x: float, grid_y: float) -> Vector2:
	return Vector2((grid_x - grid_y) * TILE_W * 0.5, (grid_x + grid_y) * TILE_H * 0.5)


static func world_to_grid(world: Vector2) -> Vector2:
	var gx := (world.x / (TILE_W * 0.5) + world.y / (TILE_H * 0.5)) * 0.5
	var gy := (world.y / (TILE_H * 0.5) - world.x / (TILE_W * 0.5)) * 0.5
	return Vector2(gx, gy)


static func chunk_of_grid(grid: Vector2, chunk_size: int) -> Vector2i:
	return Vector2i(floori(grid.x / float(chunk_size)), floori(grid.y / float(chunk_size)))


static func chunk_origin_grid(chunk: Vector2i, chunk_size: int) -> Vector2:
	return Vector2(chunk.x * chunk_size, chunk.y * chunk_size)


static func chunk_origin_world(chunk: Vector2i, chunk_size: int) -> Vector2:
	var origin := chunk_origin_grid(chunk, chunk_size)
	return grid_to_world(origin.x, origin.y)


static func distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var length_squared := ab.length_squared()
	if length_squared <= 0.0001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(ab) / length_squared, 0.0, 1.0)
	return point.distance_to(a + ab * t)

class_name WorldNavigationComponent
extends Node2D
## Owns world-space walkability, water classification and bridge traversal data.

const DEFAULT_BRIDGE_RADIUS := 40.0

var world: Node2D
var elevation: FastNoiseLite
var bridge_positions: Array[Vector2] = []
var bridge_radius: float = DEFAULT_BRIDGE_RADIUS


func _ready() -> void:
	world = get_parent() as Node2D


func set_elevation_noise(noise: FastNoiseLite) -> void:
	elevation = noise


func add_bridge_position(grid_position: Vector2) -> void:
	bridge_positions.append(IsoMath.grid_to_world(grid_position.x, grid_position.y))


func is_water_world(world_pos: Vector2) -> bool:
	if elevation == null:
		return false
	var grid := IsoMath.world_to_grid(world_pos)
	var elevation_value := elevation.get_noise_2d(grid.x, grid.y)
	return elevation_value < get_water_level()


func is_walkable(world_pos: Vector2) -> bool:
	return not is_water_world(world_pos) or is_near_bridge(world_pos)


func is_near_bridge(world_pos: Vector2) -> bool:
	for bridge_position in bridge_positions:
		if world_pos.distance_to(bridge_position) <= bridge_radius:
			return true
	return false


func world_to_grid(world_pos: Vector2) -> Vector2:
	return IsoMath.world_to_grid(world_pos)


func get_water_level() -> float:
	if world == null:
		return -0.22
	var region: Dictionary = world.get("region")
	var biome: Variant = region.get("biome", {})
	if typeof(biome) != TYPE_DICTIONARY:
		biome = {}
	return float(biome.get("water_level", -0.22))


func get_bridge_positions() -> Array:
	return bridge_positions


func get_bridge_radius() -> float:
	return bridge_radius

class_name QuestNavigationTerritoryResolver
extends RefCounted
## Pure helpers for resolving intra-region quest sub-areas.
## Territory coordinates and radii are authored in grid space.

const TERRITORIES := {
	"greenward": [
		{ "id": "elder_hollow", "grid": Vector2(-88, 76), "radius": 14.0 },
		{ "id": "withered_estate", "grid": Vector2(116, 78), "radius": 14.0 },
	],
}


static func territory_for(region_id: String, local_pos: Vector2, step: Dictionary) -> String:
	var explicit := str(step.get("territory", step.get("subarea", "")))
	if not explicit.is_empty():
		return explicit
	var list: Variant = TERRITORIES.get(region_id, [])
	if typeof(list) != TYPE_ARRAY:
		return ""
	var pos_grid := IsoMath.world_to_grid(local_pos)
	for entry in list:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var t: Dictionary = entry
		if pos_grid.distance_to(territory_center_grid(t)) <= float(t.get("radius", 14.0)):
			return str(t.get("id", ""))
	return ""


static func in_territory(region_id: String, local_pos: Vector2, territory_id: String) -> bool:
	var list: Variant = TERRITORIES.get(region_id, [])
	if typeof(list) != TYPE_ARRAY:
		return false
	var pos_grid := IsoMath.world_to_grid(local_pos)
	for entry in list:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var t: Dictionary = entry
		if str(t.get("id", "")) != territory_id:
			continue
		return pos_grid.distance_to(territory_center_grid(t)) <= float(t.get("radius", 14.0))
	return false


static func territory_center_grid(t: Dictionary) -> Vector2:
	var grid: Variant = t.get("grid", null)
	if typeof(grid) == TYPE_VECTOR2:
		return grid
	if typeof(grid) == TYPE_ARRAY and (grid as Array).size() == 2:
		var g: Array = grid
		return Vector2(float(g[0]), float(g[1]))
	return Vector2.ZERO


static func grid_to_world_value(grid: Variant) -> Vector2:
	if typeof(grid) == TYPE_VECTOR2:
		return IsoMath.grid_to_world((grid as Vector2).x, (grid as Vector2).y)
	if typeof(grid) == TYPE_ARRAY and (grid as Array).size() == 2:
		var g: Array = grid
		return IsoMath.grid_to_world(float(g[0]), float(g[1]))
	return IsoMath.grid_to_world(8.0, 8.0)
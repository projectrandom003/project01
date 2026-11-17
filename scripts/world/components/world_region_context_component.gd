class_name WorldRegionContextComponent
extends Node
## Resolves region metadata, POI zones and player-relative area context.

var world: GreenwardWorld


func configure(owner: GreenwardWorld) -> void:
	world = owner


func environment() -> Dictionary:
	if world == null:
		return {}
	var env: Variant = world.region.get("environment", {})
	return env if typeof(env) == TYPE_DICTIONARY else {}


func current_zone() -> String:
	if world == null or world.player == null:
		return "wilderness"
	var best := ""
	var best_distance := 360.0
	for poi in world.region.get("pois", []):
		if typeof(poi) != TYPE_DICTIONARY:
			continue
		var grid: Variant = poi.get("grid", [0, 0])
		if typeof(grid) != TYPE_ARRAY or grid.size() < 2:
			continue
		var pos := IsoMath.grid_to_world(float(grid[0]), float(grid[1]))
		var distance := world.player.position.distance_to(pos)
		if distance < best_distance:
			best_distance = distance
			best = zone_for_poi(str(poi.get("type", "")), str(poi.get("name", "")))
	return best if not best.is_empty() else "wilderness"


func zone_for_poi(poi_type: String, poi_name: String) -> String:
	var name_lower := poi_name.to_lower()
	if "first tree" in name_lower:
		return "elder_sanctuary"
	if "withered estate" in name_lower:
		return "withered_estate"
	if "hollowed grove" in name_lower:
		return "corrupted_grove"
	match poi_type:
		"village": return "village"
		"boss": return "grove"
		"ruin": return "ruin"
		"shrine": return "shrine"
		"landmark": return "river"
		"dungeon": return "withered_estate"
		_:
			if "pool" in name_lower or "river" in name_lower or "water" in name_lower:
				return "river"
			return "grove"


func region_display_name() -> String:
	return str(world.region.get("name", "Greenward")) if world != null else "Greenward"


func current_area_name() -> String:
	var fallback := region_display_name()
	if world == null or world.player == null:
		return fallback
	var best := fallback
	var best_distance := 280.0
	for poi in world.region.get("pois", []):
		if typeof(poi) != TYPE_DICTIONARY:
			continue
		var grid: Variant = poi.get("grid", [0, 0])
		if typeof(grid) != TYPE_ARRAY or grid.size() < 2:
			continue
		var position := IsoMath.grid_to_world(float(grid[0]), float(grid[1]))
		var distance := world.player.position.distance_to(position)
		if distance < best_distance:
			best_distance = distance
			best = str(poi.get("name", best))
	return best

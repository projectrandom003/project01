class_name ChunkRegionLayoutResolver
extends RefCounted
## Pure deterministic layout helpers shared by chunk generation and map rendering.
## Produces path segments, clearing zones and biome transition zones in grid space.

const PATH_WIDTH := 1.0
static func _path_segments(region: Dictionary) -> Array:
	# Trails connect meaningful destinations only. NPCs and tiny POIs do not
	# generate separate spokes; each route meanders like a worn woodland track.
	var spawn_grid: Array = region.get("spawn_grid", [8, 8])
	var village := Vector2(float(spawn_grid[0]), float(spawn_grid[1]))
	var segments: Array = []
	for poi in region.get("pois", []):
		var poi_type := str(poi.get("type", ""))
		if poi_type not in ["boss", "ruin", "dungeon", "landmark", "shrine"]:
			continue
		var grid: Array = poi.get("grid", [0, 0])
		if grid.size() != 2:
			continue
		var destination := Vector2(float(grid[0]), float(grid[1]))
		var direction := destination - village
		if direction.length_squared() < 0.01:
			continue
		var perpendicular := direction.normalized().orthogonal()
		var phase := float(absi(str(poi.get("id", "")).hash()) % 997) / 997.0 * TAU
		var previous := village
		for step in range(1, 7):
			var t := float(step) / 6.0
			var broad_curve := sin(t * PI) * sin(t * TAU * 1.15 + phase) * 1.15
			var small_wander := sin(t * TAU * 2.2 + phase * 0.7) * 0.28
			var point := village.lerp(destination, t) + perpendicular * (broad_curve + small_wander)
			# The final segment must terminate exactly on the POI; a residual
			# lateral wobble here leaves the trail visibly short of its destination.
			if step == 6:
				point = destination
			segments.append([previous, point])
			previous = point

	# Also connect the village to region portals, so the main travel corridor
	# is visible and readable before players reach the distant boss branches.
	var entry_points: Dictionary = region.get("entry_points", {})
	for connection in region.get("connections", []):
		var via := str(connection.get("via", ""))
		var portal_grid: Variant = entry_points.get(via, [])
		if typeof(portal_grid) != TYPE_ARRAY or portal_grid.size() != 2:
			continue
		var portal_destination := Vector2(float(portal_grid[0]), float(portal_grid[1]))
		var portal_direction := portal_destination - village
		if portal_direction.length_squared() < 0.01:
			continue
		var portal_perpendicular := portal_direction.normalized().orthogonal()
		var portal_previous := village
		var portal_phase := float(absi(via.hash()) % 997) / 997.0 * TAU
		for step in range(1, 7):
			var t := float(step) / 6.0
			var curve := sin(t * PI) * sin(t * TAU * 1.1 + portal_phase) * 0.65
			var point := village.lerp(portal_destination, t) + portal_perpendicular * curve
			if step == 6:
				point = portal_destination
			segments.append([portal_previous, point])
			portal_previous = point
	return segments


static func _clearings(region: Dictionary) -> Array:
	var result: Array = []
	var radius := float(region.get("clearing_radius", 4.0))
	for poi in region.get("pois", []):
		var grid: Array = poi.get("grid", [0, 0])
		var poi_radius := radius
		if str(poi.get("type", "")) in ["boss", "ruin", "dungeon"]:
			poi_radius = maxf(2.2, radius * 0.55)
		result.append({ "center": Vector2(float(grid[0]), float(grid[1])), "radius": poi_radius })
	return result


static func _boss_zones(region: Dictionary) -> Array:
	# The First Tree and Withered Estate have distinct ground palettes and
	# local prop ecology, fading naturally into the surrounding Greenward.
	var result: Array = []
	for poi in region.get("pois", []):
		var poi_id := str(poi.get("id", ""))
		if poi_id not in ["elder_hollow", "withered_estate"]:
			continue
		var grid: Array = poi.get("grid", [0, 0])
		var center := Vector2(float(grid[0]), float(grid[1]))
		if poi_id == "elder_hollow":
			result.append({
				"id": "elder", "center": center, "radius": 28.0,
				"strength": 0.34, "color": Color("#4f704b")
			})
		else:
			result.append({
				"id": "matron", "center": center, "radius": 28.0,
				"strength": 0.38, "color": Color("#70536d")
			})
	return result


static func _in_clearing(grid: Vector2, clearings: Array) -> bool:
	for clearing in clearings:
		if grid.distance_to(clearing.center) <= float(clearing.radius):
			return true
	return false


static func _near_path(grid: Vector2, paths: Array) -> bool:
	# Path width varies slightly with a deterministic per-tile hash (no RNG),
	# so routes read as hand-laid rather than a uniform ribbon.
	var width := PATH_WIDTH + (_tile_hash(int(round(grid.x)), int(round(grid.y))) - 0.5) * 0.5
	for segment in paths:
		if IsoMath.distance_to_segment(grid, segment[0], segment[1]) <= width:
			return true
	return false



static func _tile_hash(gx: int, gy: int) -> float:
	# Deterministic integer hash in [0, 1); bounded to avoid int64 overflow.
	var n := absi((gx * 73856093) ^ (gy * 19349663)) % 2147483647
	n = (n * 48271) % 2147483647
	return float(n) / 2147483647.0
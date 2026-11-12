class_name RegionGraph
extends RefCounted
## Pure region-graph helper: definitions, connection/travel validation and the
## LOGICAL world-coordinate space for the region map.
##
## PURE: no nodes, no SceneTree, no file I/O and NO autoload references. Every
## method is deterministic and defensive (unknown ids resolve to safe defaults
## and never crash), which makes this class trivially headless-testable.
##
## WORLD COORDINATE SPACE (LOGICAL): each region may declare `world_origin`, a
## Vector2 in a shared "global/world" coordinate space. It exists ONLY to give
## the region MAP a logical layout: `local_to_world_position` /
## `world_to_local_position` translate a region's local world position into that
## shared space and back, and `region_at_world_position` picks the region whose
## origin is nearest. This is used for travel validation and (future) map UI.
##
## IMPORTANT: it does NOT change chunk streaming. Each region KEEPS its own
## local IsoMath grid<->world projection, so ChunkStreamer / ChunkBuilder stay
## byte-for-byte compatible. `world_position_of_grid` merely OFFSETS a local
## IsoMath.grid_to_world() result by the region's logical origin.

const DEFAULT_REGION := "greenward"
const CONNECTION_KINDS := ["gate", "bridge", "portal", "path"]
const ENTRY_GRID_FALLBACK := Vector2(8.0, 8.0)

var regions: Dictionary = {}


func _init(p_regions: Dictionary = {}) -> void:
	regions = p_regions.duplicate(true)


# ------------------------------------------------------------------ accessors

func region_ids() -> Array[String]:
	var result: Array[String] = []
	for raw_id in regions.keys():
		result.append(str(raw_id))
	return result


func has_region(id: String) -> bool:
	return regions.has(id) and typeof(regions.get(id, null)) == TYPE_DICTIONARY


func definition(id: String) -> Dictionary:
	var def: Variant = regions.get(id, null)
	if typeof(def) == TYPE_DICTIONARY:
		return def
	return {}


func region_name(id: String) -> String:
	var name_value := str(definition(id).get("name", ""))
	return name_value if not name_value.is_empty() else id


func entry_points(id: String) -> Dictionary:
	var eps: Variant = definition(id).get("entry_points", {})
	if typeof(eps) == TYPE_DICTIONARY:
		return eps
	return {}


func entry_grid(id: String, point_id: String) -> Vector2:
	var eps := entry_points(id)
	if eps.has(point_id):
		return _pair(eps[point_id], ENTRY_GRID_FALLBACK)
	# Fall back to spawn_grid, then a fixed default.
	return _pair(definition(id).get("spawn_grid", null), ENTRY_GRID_FALLBACK)


func connections_from(id: String) -> Array:
	var conns: Variant = definition(id).get("connections", [])
	if typeof(conns) == TYPE_ARRAY:
		return conns
	return []


func connection(id: String, connection_id: String) -> Dictionary:
	for entry in connections_from(id):
		if typeof(entry) == TYPE_DICTIONARY and str(entry.get("id", "")) == connection_id:
			return entry
	return {}


func can_travel(from_id: String, to_id: String) -> bool:
	if from_id == to_id or not has_region(from_id) or not has_region(to_id):
		return false
	for entry in connections_from(from_id):
		if typeof(entry) == TYPE_DICTIONARY and str(entry.get("to", "")) == to_id:
			return true
	return false


func resolve_transition(from_id: String, connection_id: String) -> Dictionary:
	var result := {
		"valid": false,
		"from": from_id,
		"to": "",
		"via": "",
		"entry": "",
		"from_grid": ENTRY_GRID_FALLBACK,
		"to_grid": ENTRY_GRID_FALLBACK,
		"kind": "",
		"label": "",
		"error": "",
	}
	var conn := connection(from_id, connection_id)
	if conn.is_empty():
		result["error"] = "unknown connection '%s' in region '%s'" % [connection_id, from_id]
		return result

	var to := str(conn.get("to", ""))
	var via := str(conn.get("via", ""))
	var entry := str(conn.get("entry", ""))
	result["to"] = to
	result["via"] = via
	result["entry"] = entry
	result["kind"] = str(conn.get("kind", ""))
	result["label"] = str(conn.get("label", ""))

	if to.is_empty() or not has_region(to):
		result["error"] = "references missing region '%s'" % to
		return result
	if to == from_id:
		result["error"] = "region connection cannot target itself"
		return result
	if via.is_empty() or not entry_points(from_id).has(via):
		result["error"] = "dangling 'via' entry point '%s' in region '%s'" % [via, from_id]
		return result
	if entry.is_empty() or not entry_points(to).has(entry):
		result["error"] = "dangling 'entry' point '%s' in region '%s'" % [entry, to]
		return result

	result["from_grid"] = entry_grid(from_id, via)
	result["to_grid"] = entry_grid(to, entry)
	result["valid"] = true
	return result


# -------------------------------------------------------- world coordinate space

func world_origin(id: String) -> Vector2:
	return _pair(definition(id).get("world_origin", null), Vector2.ZERO)


func local_to_world_position(id: String, local_world: Vector2) -> Vector2:
	return world_origin(id) + local_world


func world_to_local_position(id: String, world_pos: Vector2) -> Vector2:
	return world_pos - world_origin(id)


func world_position_of_grid(id: String, grid: Vector2) -> Vector2:
	return world_origin(id) + IsoMath.grid_to_world(grid.x, grid.y)


func region_at_world_position(world_pos: Vector2) -> String:
	var best := ""
	var best_distance := INF
	for raw_id in regions.keys():
		var rid := str(raw_id)
		var d := world_pos.distance_to(world_origin(rid))
		if d < best_distance:
			best_distance = d
			best = rid
	return best if not best.is_empty() else DEFAULT_REGION


# ------------------------------------------------------------------- misc data

func spawn_grid(id: String) -> Vector2:
	return _pair(definition(id).get("spawn_grid", null), ENTRY_GRID_FALLBACK)


func spawns(id: String) -> Array:
	var value: Variant = definition(id).get("spawns", [])
	if typeof(value) == TYPE_ARRAY:
		return value
	return []


func environment(id: String) -> Dictionary:
	var value: Variant = definition(id).get("environment", {})
	if typeof(value) == TYPE_DICTIONARY:
		return value
	return {}


func load_radius(id: String) -> int:
	return int(definition(id).get("load_radius", 1))


# --------------------------------------------------------------- validation

func validate() -> Array[String]:
	return validate_definitions(regions)


func summary() -> Dictionary:
	var ids := region_ids()
	var connection_count := 0
	var origins: Dictionary = {}
	for raw_id in ids:
		var rid := str(raw_id)
		connection_count += connections_from(rid).size()
		origins[rid] = world_origin(rid)
	return {
		"region_count": ids.size(),
		"regions": ids,
		"default_region": DEFAULT_REGION,
		"connection_count": connection_count,
		"world_origins": origins,
		"validation_errors": validate(),
	}


## Pure, static graph validation (identical contract to
## ContentValidator.validate_region_graph). Returns [] for the shipped data.
static func validate_definitions(regions: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var ROOT := "greenward"

	# Duplicate region ids (Dictionary keys are unique by construction).
	var seen_ids: Dictionary = {}
	for raw_id in regions.keys():
		var rid := str(raw_id)
		if seen_ids.has(rid):
			errors.append("duplicate region id '%s'" % rid)
		seen_ids[rid] = true
		if typeof(regions[raw_id]) != TYPE_DICTIONARY:
			errors.append("region '%s' definition must be an object" % rid)

	var graph: Dictionary = {}
	for raw_id in regions.keys():
		var rid := str(raw_id)
		var def: Variant = regions[raw_id]
		var targets: Array = []
		if typeof(def) == TYPE_DICTIONARY:
			var d: Dictionary = def
			var eps := _entry_point_ids(d)
			var conns: Variant = d.get("connections", [])
			if typeof(conns) == TYPE_ARRAY:
				for index in conns.size():
					var conn: Variant = conns[index]
					if typeof(conn) != TYPE_DICTIONARY:
						errors.append("region '%s' connection[%d] must be an object" % [rid, index])
						continue
					var c: Dictionary = conn
					var to := str(c.get("to", ""))
					var via := str(c.get("via", ""))
					var entry := str(c.get("entry", ""))
					if to.is_empty():
						errors.append("region '%s' connection[%d] missing 'to'" % [rid, index])
						continue
					if to == rid:
						errors.append("region '%s' connection cannot target itself" % rid)
						continue
					if not regions.has(to):
						errors.append("region '%s' references missing region '%s'" % [rid, to])
						continue
					if via.is_empty() or not eps.has(via):
						errors.append("region '%s' has dangling 'via' entry point '%s'" % [rid, via])
					var dest_eps := _entry_point_ids(regions.get(to, null))
					if entry.is_empty() or not dest_eps.has(entry):
						errors.append("region '%s' has dangling 'entry' point '%s' in region '%s'" % [rid, entry, to])
					targets.append(to)
		graph[rid] = targets

	var reachable: Dictionary = {}
	if regions.has(ROOT):
		var queue: Array = [ROOT]
		reachable[ROOT] = true
		while not queue.is_empty():
			var cur := str(queue.pop_front())
			for raw_next in graph.get(cur, []):
				var next_id := str(raw_next)
				if regions.has(next_id) and not reachable.has(next_id):
					reachable[next_id] = true
					queue.append(next_id)
	for raw_id in regions.keys():
		var rid := str(raw_id)
		if not reachable.has(rid):
			errors.append("region '%s' is unreachable from '%s'" % [rid, ROOT])
	return errors


# --------------------------------------------------------------------- helpers

static func _entry_point_ids(def: Variant) -> Dictionary:
	var result: Dictionary = {}
	if typeof(def) != TYPE_DICTIONARY:
		return result
	var eps: Variant = def.get("entry_points", {})
	if typeof(eps) == TYPE_DICTIONARY:
		for raw_key in eps.keys():
			result[str(raw_key)] = true
	return result


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


static func _pair(value: Variant, fallback: Vector2) -> Vector2:
	if typeof(value) != TYPE_ARRAY:
		return fallback
	var arr: Array = value
	if arr.size() != 2:
		return fallback
	if not _is_number(arr[0]) or not _is_number(arr[1]):
		return fallback
	return Vector2(float(arr[0]), float(arr[1]))

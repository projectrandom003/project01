class_name RegionPathPlanner
extends RefCounted
## Pure, deterministic multi-hop region route planner.
##
## Plans travel over RegionGraph connections only (portal/path/gate/bridge). It
## never computes or implies straight-line distance between unrelated
## region-local coordinates. Used by quest/navigation resolution so routing is
## region-aware and shared.
##
## PURE with respect to scene state: no nodes, no SceneTree, no file I/O and no
## autoload references. A RegionGraph (or compatible graph-like object exposing
## has_region/region_ids/connections_from/connection/resolve_transition/
## local_to_world_position/world_origin) is supplied by the caller.

const DEFAULT_MAX_HOPS := 16


## Returns the shortest valid route (fewest hops, deterministic) from
## from_region to to_region as an Array of hop Dictionaries, or an empty Array
## when the regions are identical, unknown, or no valid route exists.
##
## Each hop contains: from, to, connection_id, via, entry, kind, label,
## from_grid, to_grid, and (when resolvable) portal_local_pos / entry_local_pos
## in the respective region-local world space (IsoMath grid -> world), plus
## portal_logical_pos / entry_logical_pos in logical map space.
static func find_path(from_region: String, to_region: String, graph: Object,
		max_hops: int = DEFAULT_MAX_HOPS) -> Array:
	var result: Array = []
	if graph == null or not _has_region(graph, from_region) or not _has_region(graph, to_region):
		return result
	if from_region == to_region:
		return result

	var queue: Array[String] = [from_region]
	var visited: Dictionary = { from_region: true }
	# parent[to] = { "from": prev, "conn": connection_dict }
	var parent: Dictionary = {}

	while not queue.is_empty():
		var current: String = str(queue.pop_front())
		var depth := _path_depth(current, from_region, parent)
		if depth >= max_hops:
			continue
		for entry in _connections_from(graph, current):
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var conn: Dictionary = entry
			var next_id := str(conn.get("to", ""))
			var conn_id := str(conn.get("id", ""))
			if next_id.is_empty() or visited.has(next_id):
				continue
			# Only traverse connections that resolve to a valid transition and a
			# known destination. This keeps routing consistent with travel rules.
			if not _has_region(graph, next_id):
				continue
			var resolved := _resolve_transition(graph, current, conn_id)
			if resolved.is_empty() or not bool(resolved.get("valid", false)):
				continue
			visited[next_id] = true
			parent[next_id] = { "from": current, "conn": conn, "resolved": resolved }
			if next_id == to_region:
				return _build_path(parent, from_region, to_region, graph)
			queue.append(next_id)
	return result


## Returns the first hop of find_path(), or an empty Dictionary if none.
static func next_hop(from_region: String, to_region: String, graph: Object,
		max_hops: int = DEFAULT_MAX_HOPS) -> Dictionary:
	var path := find_path(from_region, to_region, graph, max_hops)
	if path.is_empty():
		return {}
	var hop: Variant = path[0]
	return hop if typeof(hop) == TYPE_DICTIONARY else {}


## True when a valid route exists (or regions are identical and known).
static func is_reachable(from_region: String, to_region: String, graph: Object,
		max_hops: int = DEFAULT_MAX_HOPS) -> bool:
	if graph == null:
		return false
	if from_region == to_region:
		return _has_region(graph, from_region)
	return not find_path(from_region, to_region, graph, max_hops).is_empty()


static func _build_path(parent: Dictionary, from_region: String, to_region: String, graph: Object) -> Array:
	var reverse: Array = []
	var cursor := to_region
	while cursor != from_region and parent.has(cursor):
		var step: Dictionary = parent[cursor]
		var prev := str(step.get("from", ""))
		var conn: Dictionary = step.get("conn", {})
		var resolved: Dictionary = step.get("resolved", {})
		reverse.append(_make_hop(prev, cursor, conn, resolved, graph))
		cursor = prev
		if cursor.is_empty():
			break
	reverse.reverse()
	return reverse


static func _make_hop(from_region: String, to_region: String, conn: Dictionary,
		resolved: Dictionary, graph: Object) -> Dictionary:
	var via := str(resolved.get("via", conn.get("via", "")))
	var entry := str(resolved.get("entry", conn.get("entry", "")))
	var from_grid: Vector2 = resolved.get("from_grid", _fallback_grid())
	var to_grid: Vector2 = resolved.get("to_grid", _fallback_grid())
	var portal_local := IsoMath.grid_to_world(from_grid.x, from_grid.y)
	var entry_local := IsoMath.grid_to_world(to_grid.x, to_grid.y)
	return {
		"from": from_region,
		"to": to_region,
		"connection_id": str(conn.get("id", resolved.get("via", ""))),
		"via": via,
		"entry": entry,
		"kind": str(conn.get("kind", resolved.get("kind", ""))),
		"label": str(conn.get("label", resolved.get("label", ""))),
		"from_grid": from_grid,
		"to_grid": to_grid,
		"portal_local_pos": portal_local,
		"entry_local_pos": entry_local,
		"portal_logical_pos": _local_to_world(graph, from_region, portal_local),
		"entry_logical_pos": _local_to_world(graph, to_region, entry_local),
	}


static func _path_depth(node: String, root: String, parent: Dictionary) -> int:
	var depth := 0
	var cursor := node
	while cursor != root and parent.has(cursor):
		depth += 1
		cursor = str(parent[cursor].get("from", ""))
		if cursor.is_empty():
			break
	return depth


static func _connections_from(graph: Object, region_id: String) -> Array:
	if graph.has_method("connections_from"):
		var value: Variant = graph.call("connections_from", region_id)
		if typeof(value) == TYPE_ARRAY:
			return value
	return []


static func _has_region(graph: Object, region_id: String) -> bool:
	if graph.has_method("has_region"):
		return bool(graph.call("has_region", region_id))
	return false


static func _resolve_transition(graph: Object, from_id: String, connection_id: String) -> Dictionary:
	if graph.has_method("resolve_transition"):
		var value: Variant = graph.call("resolve_transition", from_id, connection_id)
		if typeof(value) == TYPE_DICTIONARY:
			return value
	return {}


static func _local_to_world(graph: Object, region_id: String, local_pos: Vector2) -> Vector2:
	if graph.has_method("local_to_world_position"):
		var value: Variant = graph.call("local_to_world_position", region_id, local_pos)
		if typeof(value) == TYPE_VECTOR2:
			return value
	if graph.has_method("world_origin"):
		var origin: Variant = graph.call("world_origin", region_id)
		if typeof(origin) == TYPE_VECTOR2:
			return origin + local_pos
	return local_pos


static func _fallback_grid() -> Vector2:
	return Vector2(8.0, 8.0)

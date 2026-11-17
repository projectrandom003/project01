class_name RegionGraphValidator
extends RefCounted
## Pure cross-region graph checks; no scene tree, autoloads or file I/O.

static func entry_point_ids(region_def: Variant) -> Dictionary:
	var result: Dictionary = {}
	if typeof(region_def) != TYPE_DICTIONARY:
		return result
	var eps: Variant = region_def.get("entry_points", {})
	if typeof(eps) == TYPE_DICTIONARY:
		for raw_key in eps.keys():
			result[str(raw_key)] = true
	return result


## Pure cross-region graph validation: missing regions, self-loops, dangling
## via/entry points, duplicate region ids (Dictionary keys are unique by
## construction, but checked anyway) and UNREACHABLE regions from "greenward"
## (BFS over `connections`). No nodes, no SceneTree, no file I/O, no autoloads.
## Returns [] for the shipped data. Kept self-contained (does not depend on
## RegionGraph) because ContentValidator is loaded by ContentDB at every boot.
static func validate_region_graph(regions: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var ROOT := "greenward"

	# Duplicate region ids (cannot occur in a Dictionary, but verify anyway).
	var seen_ids: Dictionary = {}
	for raw_id in regions.keys():
		var rid := str(raw_id)
		if seen_ids.has(rid):
			errors.append("regions â†’ %s: duplicate region id" % rid)
		seen_ids[rid] = true
		if typeof(regions[raw_id]) != TYPE_DICTIONARY:
			errors.append("regions â†’ %s: region definition must be an object" % rid)

	# Build adjacency from valid edges and collect per-edge problems.
	var graph: Dictionary = {}
	for raw_id in regions.keys():
		var rid := str(raw_id)
		var def: Variant = regions[raw_id]
		var targets: Array = []
		if typeof(def) == TYPE_DICTIONARY:
			var d: Dictionary = def
			var eps := entry_point_ids(d)
			var conns: Variant = d.get("connections", [])
			if typeof(conns) == TYPE_ARRAY:
				for index in conns.size():
					var conn: Variant = conns[index]
					if typeof(conn) != TYPE_DICTIONARY:
						errors.append("regions â†’ %s.connections[%d]: expected an object" % [rid, index])
						continue
					var c: Dictionary = conn
					var to := str(c.get("to", ""))
					var via := str(c.get("via", ""))
					var entry := str(c.get("entry", ""))
					if to.is_empty():
						errors.append("regions â†’ %s.connections[%d]: missing 'to'" % [rid, index])
						continue
					if to == rid:
						errors.append("regions â†’ %s.connections[%d]: region connection cannot target itself" % [rid, index])
						continue
					if not regions.has(to):
						errors.append("regions â†’ %s.connections[%d]: references missing region '%s'" % [rid, index, to])
						continue
					if via.is_empty() or not eps.has(via):
						errors.append("regions â†’ %s.connections[%d]: dangling 'via' entry point '%s'" % [rid, index, via])
					var dest_eps := entry_point_ids(regions.get(to, null))
					if entry.is_empty() or not dest_eps.has(entry):
						errors.append("regions â†’ %s.connections[%d]: dangling 'entry' point '%s' in region '%s'" % [rid, index, entry, to])
					targets.append(to)
		graph[rid] = targets

	# BFS reachability from the default region over the valid edges.
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
			var def: Variant = regions.get(raw_id, {})
			if typeof(def) == TYPE_DICTIONARY and bool((def as Dictionary).get("standalone", false)):
				continue
			errors.append("regions â†’ %s: region is unreachable from '%s'" % [rid, ROOT])
	return errors



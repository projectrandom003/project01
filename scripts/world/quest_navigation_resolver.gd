class_name QuestNavigationResolver
extends RefCounted
## Shared, region-aware quest navigation resolver (single source of truth).
##
## ADDITIVE: this module does not rewire HUD/minimap/map/world marker consumers
## and does not change GameState's existing public behavior. It provides a
## resolved navigation target with registration, caching, region-path planning
## (via RegionPathPlanner/RegionGraph), and territory-aware same-region rules.
##
## IMPORTANT: for cross-region objectives it NEVER produces a straight-line
## distance/direction between unrelated region-local coordinates; instead it
## returns a route/next-hop toward the target region. Elder Hollow and the
## Withered Estate are territories within Greenward (not separate region IDs).
##
## Live-target preference: when a valid registered live target exists for the
## active objective in the player's current region, it is used; otherwise the
## resolver falls back to the authored/static step destination.

signal navigation_target_changed(resolved: Dictionary)

const STATUS_NONE := "none"
const STATUS_SAME_REGION := "same_region"
const STATUS_SAME_REGION_OTHER_TERRITORY := "same_region_other_territory"
const STATUS_OTHER_REGION := "other_region"
const STATUS_UNREACHABLE := "unreachable"
const STATUS_COMPLETE := "complete"

# Known intra-region territories (region_id -> Array of {id, grid, radius}).
# Elder Hollow and Withered Estate are territories within Greenward, not
# separate region IDs.
const TERRITORIES := {
	"greenward": [
		{ "id": "elder_hollow", "grid": Vector2(-88, 76), "radius": 14.0 },
		{ "id": "withered_estate", "grid": Vector2(116, 78), "radius": 14.0 },
	],
}

var _registry: Dictionary = {} # id -> provider Dictionary
var _cache: Dictionary = {}
var _cache_valid: bool = false
var _last_player_region: String = ""
var _last_tracked_quest: String = ""
var _last_step_index: int = -1
var _last_step_progress: int = -1

static var _shared: QuestNavigationResolver = null


## Single shared owner for navigation resolution (HUD/minimap/map/marker should
## consume this instance rather than creating independent resolvers).
static func shared() -> QuestNavigationResolver:
	if _shared == null:
		_shared = QuestNavigationResolver.new()
	return _shared


# ---------------------------------------------------------------- registration

## Register (or replace) a live/anchored navigation target provider.
## Provider keys (all optional, defensive): region_id, territory_id,
## local_pos (Vector2) or pos_getter (Callable -> Vector2), valid (bool or
## Callable -> bool), quest_id, objective_id/target, kind, label, node.
func register_nav_target(target_id: String, provider: Dictionary) -> void:
	if target_id.is_empty():
		return
	# Shallow-copy to avoid mutating caller while preserving object/callable refs.
	_registry[target_id] = provider.duplicate(false)
	_invalidate()


func unregister_nav_target(target_id: String) -> void:
	if target_id.is_empty() or not _registry.has(target_id):
		return
	_registry.erase(target_id)
	_invalidate()


func clear_registry() -> void:
	if _registry.is_empty():
		return
	_registry.clear()
	_invalidate()


func invalidate() -> void:
	_invalidate()


# ------------------------------------------------------------------- resolution

## Resolve and return the current navigation target for the tracked quest.
## Pure relative to provided arguments + registries; reads autoloads when
## available. Does not mutate quest progress/save state.
##
## Freshness: target identity and routes are cached where appropriate, but live
## target position and player position are ALWAYS resolved fresh so distance and
## direction are never stale for moving targets/players.
func get_resolved_target(player_region: String = "", player_local_pos: Variant = null,
		graph: Object = null) -> Dictionary:
	var gs := _game_state()
	var db := _content_db()
	var current_region := player_region
	if current_region.is_empty() and gs != null:
		current_region = str(gs.player_region)
	if current_region.is_empty():
		current_region = "greenward"
	var player_pos := _resolve_player_pos(player_local_pos, gs)
	var region_graph := _resolve_graph(graph, db)

	var tracked := _tracked_quest(gs)
	if tracked.is_empty():
		return _cache_and_maybe_emit(_empty_result(STATUS_NONE, current_region, "No tracked quest"))

	var state := _quest_state(gs, tracked)
	if state == "complete":
		return _cache_and_maybe_emit(_result_base(tracked, STATUS_COMPLETE, current_region, current_region, Vector2.ZERO, {
			"valid": false,
			"label": "Quest complete",
		}))

	var definition: Dictionary = _quest_def(db, tracked)
	if definition.is_empty():
		return _cache_and_maybe_emit(_empty_result(STATUS_NONE, current_region, "Unknown quest"))

	var step: Dictionary = _quest_step(gs, tracked)
	if step.is_empty():
		return _cache_and_maybe_emit(_result_base(tracked, STATUS_COMPLETE, current_region, current_region, Vector2.ZERO, {
			"valid": false,
			"label": "Quest complete",
		}))

	var target_region := _quest_region(definition, db)
	var target_local := _authored_target_local(step, definition, target_region, db)
	var objective_kind := str(step.get("type", ""))
	var live_source := ""

	# Always resolve live/registered target position fresh (moving targets).
	var live := _select_live_target(tracked, step, current_region, player_pos)
	if not live.is_empty():
		target_local = live.get("local_pos", target_local)
		if str(live.get("region_id", target_region)) != "":
			target_region = str(live.get("region_id", target_region))
		live_source = str(live.get("id", "live"))

	var target_territory := _territory_for(target_region, target_local, step)
	var same_region := target_region == current_region
	var status := STATUS_SAME_REGION
	if not same_region:
		status = STATUS_OTHER_REGION
	elif not target_territory.is_empty() and not _in_territory(current_region, player_pos, target_territory):
		# Same region, different territory/sub-area (e.g. village vs Elder Hollow).
		status = STATUS_SAME_REGION_OTHER_TERRITORY

	var resolved := _result_base(tracked, status, current_region, target_region, target_local, {
		"valid": true,
		"objective_kind": objective_kind,
		"step_index": _quest_step_index(gs, tracked),
		"step_progress": _quest_step_progress(gs, tracked),
		"step_text": str(step.get("text", "")),
		"quest_name": str(definition.get("name", tracked)),
		"target_territory_id": target_territory,
		"live_source": live_source,
		"label": str(step.get("text", str(definition.get("name", tracked)))),
	})

	if same_region:
		# Same navigable region frame (including intra-Greenward territories):
		# local distance/direction are meaningful and MUST be computed fresh.
		var delta := target_local - player_pos
		resolved["same_frame"] = true
		resolved["same_region"] = true
		resolved["distance"] = delta.length()
		resolved["direction"] = delta.normalized() if delta.length_squared() > 0.000001 else Vector2.ZERO
		resolved["route"] = []
		resolved["next_hop"] = {}
		resolved["cross_region_distance"] = null
	else:
		# Cross-region: NEVER provide straight-line distance/direction between
		# unrelated region-local coordinates. Provide a region route instead.
		resolved["same_frame"] = false
		resolved["same_region"] = false
		resolved["distance"] = null
		resolved["direction"] = Vector2.ZERO
		resolved["cross_region_distance"] = null
		var route: Array = RegionPathPlanner.find_path(current_region, target_region, region_graph)
		resolved["route"] = route
		if route.is_empty():
			resolved["status"] = STATUS_UNREACHABLE
			resolved["valid"] = false
			resolved["next_hop"] = {}
			resolved["label"] = "Objective in %s (unreachable)" % _region_name(db, target_region)
		else:
			var hop: Dictionary = route[0]
			resolved["next_hop"] = hop
			resolved["label"] = "Travel to %s" % _region_name(db, str(hop.get("to", target_region)))

	resolved["target_logical_pos"] = _local_to_world(region_graph, target_region, target_local)
	resolved["player_logical_pos"] = _local_to_world(region_graph, current_region, player_pos)
	resolved["player_local_pos"] = player_pos
	return _cache_and_maybe_emit(resolved)


## Force recompute on next get (or emit if desired by caller pattern).
func refresh(player_region: String = "", player_local_pos: Variant = null, graph: Object = null) -> Dictionary:
	_cache_valid = false
	return get_resolved_target(player_region, player_local_pos, graph)


# ------------------------------------------------------------------- internals

func _invalidate() -> void:
	_cache_valid = false


func _cache_and_maybe_emit(resolved: Dictionary) -> Dictionary:
	var changed := not _cache_valid or not _results_equivalent(_cache, resolved)
	_cache = resolved.duplicate(true)
	_cache_valid = true
	_last_tracked_quest = str(resolved.get("quest_id", ""))
	_last_player_region = str(resolved.get("player_region", ""))
	_last_step_index = int(resolved.get("step_index", -1))
	_last_step_progress = int(resolved.get("step_progress", -1))
	if changed:
		navigation_target_changed.emit(_cache.duplicate(true))
	return _cache.duplicate(true)


static func _results_equivalent(a: Dictionary, b: Dictionary) -> bool:
	if a.is_empty() or b.is_empty():
		return a.is_empty() and b.is_empty()
	# Distance/direction are intentionally fresh each resolve (moving targets/
	# player), so they are excluded from cache identity/route equivalence.
	var keys := ["quest_id", "status", "player_region", "target_region_id", "same_frame",
		"same_region", "target_territory_id", "live_source", "step_index", "step_progress", "label"]
	for key in keys:
		if a.get(key, null) != b.get(key, null):
			return false
	var ra: Variant = a.get("route", [])
	var rb: Variant = b.get("route", [])
	if (ra as Array).size() != (rb as Array).size():
		return false
	# Route identity: compare hop endpoints/connection ids.
	for i in (ra as Array).size():
		var ha: Dictionary = (ra as Array)[i] if typeof((ra as Array)[i]) == TYPE_DICTIONARY else {}
		var hb: Dictionary = (rb as Array)[i] if typeof((rb as Array)[i]) == TYPE_DICTIONARY else {}
		if str(ha.get("from", "")) != str(hb.get("from", "")) or str(ha.get("to", "")) != str(hb.get("to", "")) or str(ha.get("connection_id", "")) != str(hb.get("connection_id", "")):
			return false
	var ta: Variant = a.get("target_local_pos", Vector2.ZERO)
	var tb: Variant = b.get("target_local_pos", Vector2.ZERO)
	if typeof(ta) == TYPE_VECTOR2 and typeof(tb) == TYPE_VECTOR2:
		if (ta as Vector2).distance_to(tb as Vector2) > 0.5:
			return false
	return true


func _result_base(quest_id: String, status: String, player_region: String,
		target_region: String, target_local: Vector2, extra: Dictionary) -> Dictionary:
	var out := {
		"quest_id": quest_id,
		"valid": bool(extra.get("valid", false)),
		"status": status,
		"player_region": player_region,
		"target_region_id": target_region,
		"target_local_pos": target_local,
		"target_logical_pos": Vector2.ZERO,
		"target_territory_id": str(extra.get("target_territory_id", "")),
		"same_region": target_region == player_region,
		"same_frame": target_region == player_region,
		"distance": null,
		"direction": Vector2.ZERO,
		"cross_region_distance": null,
		"route": [],
		"next_hop": {},
		"objective_kind": str(extra.get("objective_kind", "")),
		"step_index": int(extra.get("step_index", -1)),
		"step_progress": int(extra.get("step_progress", -1)),
		"step_text": str(extra.get("step_text", "")),
		"quest_name": str(extra.get("quest_name", quest_id)),
		"live_source": str(extra.get("live_source", "")),
		"label": str(extra.get("label", "")),
		"player_local_pos": Vector2.ZERO,
		"player_logical_pos": Vector2.ZERO,
	}
	return out


func _empty_result(status: String, player_region: String, label: String) -> Dictionary:
	var out := _result_base("", status, player_region, player_region, Vector2.ZERO, {
		"valid": false,
		"label": label,
	})
	out["same_frame"] = false
	out["same_region"] = true
	return out


func _select_live_target(quest_id: String, step: Dictionary, player_region: String, player_pos: Vector2) -> Dictionary:
	if str(step.get("type", "")) != "kill":
		return {}
	var target_id := str(step.get("target", ""))
	var best: Dictionary = {}
	var best_distance := INF

	# Registered providers first (explicit, cache-friendly integration point).
	for reg_id in _registry.keys():
		var provider: Variant = _registry.get(reg_id)
		if typeof(provider) != TYPE_DICTIONARY:
			continue
		var p: Dictionary = provider
		if not _provider_valid(p):
			continue
		var p_quest := str(p.get("quest_id", ""))
		var p_obj := str(p.get("objective_id", p.get("target", "")))
		if not p_quest.is_empty() and p_quest != quest_id:
			continue
		if not p_obj.is_empty() and p_obj != target_id:
			continue
		var p_region := str(p.get("region_id", player_region))
		if p_region != player_region:
			continue
		var p_pos := _provider_pos(p)
		var d := player_pos.distance_to(p_pos)
		if d < best_distance:
			best_distance = d
			best = { "id": str(reg_id), "local_pos": p_pos, "region_id": p_region }

	# Fallback: scan live roaming monsters only when no valid explicit provider
	# was registered. Explicit registration is the authoritative integration
	# seam and must not be silently overridden by a scene-tree scan.
	if best.is_empty():
		var tree: SceneTree = Engine.get_main_loop() as SceneTree
		if tree != null:
			for node in tree.get_nodes_in_group("interactables"):
				if not is_instance_valid(node) or not (node is RoamingMonster):
					continue
				var monster := node as RoamingMonster
				if monster.defeated or not monster.visible:
					continue
				var visual_id := str(monster.visual_definition.get("id", ""))
				if monster.group_id != target_id and visual_id != target_id:
					continue
				var d := player_pos.distance_to(monster.global_position)
				if d < best_distance:
					best_distance = d
					best = { "id": "live:" + str(monster.get_instance_id()), "local_pos": monster.global_position, "region_id": player_region }
	return best


static func _provider_valid(provider: Dictionary) -> bool:
	# Validate referenced node independently of `valid`: a freed/invalid or
	# out-of-tree node must reject the provider even if `valid` is true.
	if provider.has("node"):
		var node: Variant = provider.get("node", null)
		if node == null or not is_instance_valid(node):
			return false
		if node is Node and not (node as Node).is_inside_tree():
			return false
	var v: Variant = provider.get("valid", true)
	if typeof(v) == TYPE_BOOL:
		return bool(v)
	if v is Callable:
		var c: Callable = v
		if c.is_valid():
			return bool(c.call())
		return false
	return true


static func _provider_pos(provider: Dictionary) -> Vector2:
	# A referenced Node2D is the live source of truth. Static local_pos/position
	# values are only fallbacks for providers without a positional node.
	var node: Variant = provider.get("node", null)
	if node is Node2D and is_instance_valid(node) and (node as Node2D).is_inside_tree():
		return (node as Node2D).global_position
	var getter: Variant = provider.get("pos_getter", null)
	if getter is Callable:
		var c: Callable = getter
		if c.is_valid():
			var value: Variant = c.call()
			if typeof(value) == TYPE_VECTOR2:
				return value
	var pos: Variant = provider.get("local_pos", provider.get("position", Vector2.ZERO))
	if typeof(pos) == TYPE_VECTOR2:
		return pos
	return Vector2.ZERO


func _authored_target_local(step: Dictionary, definition: Dictionary, target_region: String, db: Object) -> Vector2:
	var grid: Variant = step.get("grid", null)
	if typeof(grid) == TYPE_ARRAY and (grid as Array).size() == 2:
		var g: Array = grid
		return IsoMath.grid_to_world(float(g[0]), float(g[1]))
	var region_def: Dictionary = _region_def(db, target_region)
	var spawn: Variant = region_def.get("spawn_grid", [8, 8])
	if typeof(spawn) == TYPE_ARRAY and (spawn as Array).size() == 2:
		var s: Array = spawn
		return IsoMath.grid_to_world(float(s[0]), float(s[1]))
	return IsoMath.grid_to_world(8.0, 8.0)


func _quest_region(definition: Dictionary, db: Object) -> String:
	var rid := str(definition.get("region", "greenward"))
	if rid.is_empty():
		return "greenward"
	return rid


func _territory_for(region_id: String, local_pos: Vector2, step: Dictionary) -> String:
	# Explicit territory on step takes precedence (future-proof, optional).
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
		var center_grid := _territory_center_grid(t)
		var radius_tiles := float(t.get("radius", 14.0))
		# radius is in grid tiles; compare in grid space.
		if pos_grid.distance_to(center_grid) <= radius_tiles:
			return str(t.get("id", ""))
	return ""


static func _in_territory(region_id: String, local_pos: Vector2, territory_id: String) -> bool:
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
		var center_grid := _territory_center_grid(t)
		var radius_tiles := float(t.get("radius", 14.0))
		return pos_grid.distance_to(center_grid) <= radius_tiles
	return false


static func _territory_center_grid(t: Dictionary) -> Vector2:
	var grid: Variant = t.get("grid", null)
	if typeof(grid) == TYPE_VECTOR2:
		return grid
	if typeof(grid) == TYPE_ARRAY and (grid as Array).size() == 2:
		var g: Array = grid
		return Vector2(float(g[0]), float(g[1]))
	return Vector2.ZERO


static func _grid_to_world_value(grid: Variant) -> Vector2:
	if typeof(grid) == TYPE_VECTOR2:
		return IsoMath.grid_to_world((grid as Vector2).x, (grid as Vector2).y)
	if typeof(grid) == TYPE_ARRAY and (grid as Array).size() == 2:
		var g: Array = grid
		return IsoMath.grid_to_world(float(g[0]), float(g[1]))
	return IsoMath.grid_to_world(8.0, 8.0)


func _resolve_graph(graph: Object, db: Object) -> Object:
	if graph != null:
		return graph
	var regions: Dictionary = {}
	if db != null and "regions" in db:
		var r: Variant = db.get("regions")
		if typeof(r) == TYPE_DICTIONARY:
			regions = r
	return RegionGraph.new(regions)


static func _local_to_world(graph: Object, region_id: String, local_pos: Vector2) -> Vector2:
	if graph != null and graph.has_method("local_to_world_position"):
		var value: Variant = graph.call("local_to_world_position", region_id, local_pos)
		if typeof(value) == TYPE_VECTOR2:
			return value
	return local_pos


static func _region_name(db: Object, region_id: String) -> String:
	if db != null and db.has_method("get_region"):
		var def: Variant = db.call("get_region", region_id)
		if typeof(def) == TYPE_DICTIONARY:
			var name := str((def as Dictionary).get("name", ""))
			if not name.is_empty():
				return name
	return region_id


static func _region_def(db: Object, region_id: String) -> Dictionary:
	if db != null and db.has_method("get_region"):
		var def: Variant = db.call("get_region", region_id)
		if typeof(def) == TYPE_DICTIONARY:
			return def
	return {}


static func _quest_def(db: Object, quest_id: String) -> Dictionary:
	if db != null and db.has_method("get_quest"):
		var def: Variant = db.call("get_quest", quest_id)
		if typeof(def) == TYPE_DICTIONARY:
			return def
	return {}


static func _tracked_quest(gs: Object) -> String:
	if gs == null:
		return ""
	if gs.has_method("tracked_quest"):
		return str(gs.call("tracked_quest"))
	return ""


static func _quest_state(gs: Object, quest_id: String) -> String:
	if gs == null:
		return "not_started"
	if gs.has_method("quest_state"):
		return str(gs.call("quest_state", quest_id))
	return "not_started"


static func _quest_step(gs: Object, quest_id: String) -> Dictionary:
	if gs == null:
		return {}
	if gs.has_method("quest_step"):
		var value: Variant = gs.call("quest_step", quest_id)
		if typeof(value) == TYPE_DICTIONARY:
			return value
	return {}


static func _quest_step_index(gs: Object, quest_id: String) -> int:
	if gs != null and gs.has_method("quest_step_index"):
		return int(gs.call("quest_step_index", quest_id))
	return -1


static func _quest_step_progress(gs: Object, quest_id: String) -> int:
	if gs != null and "quests" in gs:
		var quests: Variant = gs.get("quests")
		if typeof(quests) == TYPE_DICTIONARY:
			var entry: Variant = (quests as Dictionary).get(quest_id, {})
			if typeof(entry) == TYPE_DICTIONARY:
				return int((entry as Dictionary).get("progress", 0))
	return 0


func _resolve_player_pos(player_local_pos: Variant, gs: Object) -> Vector2:
	if typeof(player_local_pos) == TYPE_VECTOR2:
		return player_local_pos
	if gs != null and gs.has_method("_find_player_position"):
		return gs.call("_find_player_position")
	if gs != null and "has_player_position" in gs and bool(gs.get("has_player_position")) and "player_position" in gs:
		var p: Variant = gs.get("player_position")
		if typeof(p) == TYPE_VECTOR2:
			return p
	return Vector2.ZERO


static func _content_db() -> Object:
	var ml: SceneTree = Engine.get_main_loop() as SceneTree
	if ml == null:
		return null
	var root := ml.root
	if root == null:
		return null
	return root.get_node_or_null("ContentDB")


static func _game_state() -> Object:
	var ml: SceneTree = Engine.get_main_loop() as SceneTree
	if ml == null:
		return null
	var root := ml.root
	if root == null:
		return null
	return root.get_node_or_null("GameState")

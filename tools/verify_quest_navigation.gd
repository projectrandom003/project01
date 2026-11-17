extends Node
## Focused verification for Milestone 1: RegionPathPlanner + QuestNavigationResolver.
## Additive, isolated check (does not modify existing systems or consumers).
## STATE-SAFE: snapshots/restores all modified runtime state and does not call
## queue_save()/save_now() or allow save timers to persist test-only data.

var failures: int = 0


func _ready() -> void:
	_test_region_path_planner()
	await _test_quest_navigation_resolver()
	print("[quest_nav] %s" % ("OK" if failures == 0 else "FAILED (%d)" % failures))
	get_tree().quit(0 if failures == 0 else 1)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("[quest_nav] PASS " + label)
	else:
		failures += 1
		printerr("[quest_nav] FAIL " + label + ("" if detail.is_empty() else " - " + detail))


func _snapshot_quest(qid: String) -> Dictionary:
	return {
		"present": GameState.quests.has(qid),
		"value": GameState.quests[qid].duplicate(true) if GameState.quests.has(qid) and typeof(GameState.quests[qid]) == TYPE_DICTIONARY else GameState.quests.get(qid, null),
	}


func _restore_quest(qid: String, snap: Dictionary) -> void:
	if bool(snap.get("present", false)):
		var v: Variant = snap.get("value", null)
		if typeof(v) == TYPE_DICTIONARY:
			GameState.quests[qid] = (v as Dictionary).duplicate(true)
		else:
			GameState.quests[qid] = v
	else:
		GameState.quests.erase(qid)


func _test_region_path_planner() -> void:
	# Synthetic multi-hop graph: A -> B -> C -> D, plus A -> E (dead end to D)
	var regions := {
		"A": {
			"world_origin": [0.0, 0.0],
			"entry_points": { "start": [0, 0], "to_b": [10, 0], "to_e": [0, 10] },
			"connections": [
				{ "id": "ab", "to": "B", "via": "to_b", "entry": "from_a", "kind": "path", "label": "To B" },
				{ "id": "ae", "to": "E", "via": "to_e", "entry": "from_a", "kind": "path", "label": "To E" },
			],
		},
		"B": {
			"world_origin": [1000.0, 0.0],
			"entry_points": { "from_a": [0, 0], "to_c": [10, 0] },
			"connections": [
				{ "id": "ba", "to": "A", "via": "from_a", "entry": "to_b", "kind": "path", "label": "To A" },
				{ "id": "bc", "to": "C", "via": "to_c", "entry": "from_b", "kind": "path", "label": "To C" },
			],
		},
		"C": {
			"world_origin": [2000.0, 0.0],
			"entry_points": { "from_b": [0, 0], "to_d": [10, 0] },
			"connections": [
				{ "id": "cb", "to": "B", "via": "from_b", "entry": "to_c", "kind": "path", "label": "To B" },
				{ "id": "cd", "to": "D", "via": "to_d", "entry": "from_c", "kind": "path", "label": "To D" },
			],
		},
		"D": {
			"world_origin": [3000.0, 0.0],
			"entry_points": { "from_c": [0, 0] },
			"connections": [
				{ "id": "dc", "to": "C", "via": "from_c", "entry": "to_d", "kind": "path", "label": "To C" },
			],
		},
		"E": {
			"world_origin": [0.0, 1000.0],
			"entry_points": { "from_a": [0, 0] },
			"connections": [
				{ "id": "ea", "to": "A", "via": "from_a", "entry": "to_e", "kind": "path", "label": "To A" },
			],
		},
		"Z": {
			"world_origin": [9000.0, 9000.0],
			"entry_points": { "start": [0, 0] },
			"connections": [],
		},
	}
	var graph := RegionGraph.new(regions)

	var path_ad: Array = RegionPathPlanner.find_path("A", "D", graph)
	_check("multi-hop route A->D found", path_ad.size() == 3, "hops=%d" % path_ad.size())
	if path_ad.size() == 3:
		_check("hop1 A->B", str(path_ad[0].get("from")) == "A" and str(path_ad[0].get("to")) == "B")
		_check("hop2 B->C", str(path_ad[1].get("from")) == "B" and str(path_ad[1].get("to")) == "C")
		_check("hop3 C->D", str(path_ad[2].get("from")) == "C" and str(path_ad[2].get("to")) == "D")
		_check("hop carries connection id", str(path_ad[0].get("connection_id")) == "ab")
		_check("hop carries portal local pos", typeof(path_ad[0].get("portal_local_pos")) == TYPE_VECTOR2)

	var same: Array = RegionPathPlanner.find_path("A", "A", graph)
	_check("same-region path empty", same.is_empty())

	var unreachable: Array = RegionPathPlanner.find_path("A", "Z", graph)
	_check("unreachable region returns empty path", unreachable.is_empty())
	_check("is_reachable false for unreachable", not RegionPathPlanner.is_reachable("A", "Z", graph))
	_check("is_reachable true for connected", RegionPathPlanner.is_reachable("A", "D", graph))

	var next: Dictionary = RegionPathPlanner.next_hop("A", "D", graph)
	_check("next_hop is first hop", str(next.get("to", "")) == "B")

	# Determinism: repeated calls equal.
	var path_ad2: Array = RegionPathPlanner.find_path("A", "D", graph)
	var deterministic := path_ad.size() == path_ad2.size()
	if deterministic:
		for i in path_ad.size():
			if str(path_ad[i].get("connection_id")) != str(path_ad2[i].get("connection_id")):
				deterministic = false
	_check("path finding deterministic", deterministic)

	# Real shipped graph sanity (greenward <-> moonpetal_hollow).
	var real_graph := RegionGraph.new(ContentDB.regions)
	var real_path: Array = RegionPathPlanner.find_path("greenward", "moonpetal_hollow", real_graph)
	_check("real graph greenward->moonpetal_hollow routed", real_path.size() == 1, "hops=%d" % real_path.size())
	var real_back: Array = RegionPathPlanner.find_path("moonpetal_hollow", "greenward", real_graph)
	_check("real graph return route exists", real_back.size() == 1, "hops=%d" % real_back.size())


func _test_quest_navigation_resolver() -> void:
	# Snapshot exact runtime state so the user's save/runtime remains unchanged.
	var prev_tracked := GameState.tracked_quest()
	var prev_region := str(GameState.player_region)
	var prev_has_pos := bool(GameState.has_player_position)
	var prev_pos := GameState.player_position
	var prev_rp: Variant = GameState.region_positions.duplicate(true) if typeof(GameState.region_positions) == TYPE_DICTIONARY else {}
	var prev_tracked_flag_present := GameState.flags.has("tracked_quest")
	var prev_tracked_flag: Variant = GameState.flags.get("tracked_quest", null)
	var quest_ids := ["glade_whisper", "elder_memory", "matron_bloom", "_test_moon_quest", "_test_unreach_quest"]
	var quest_snaps: Dictionary = {}
	for qid in quest_ids:
		quest_snaps[qid] = _snapshot_quest(qid)
	var had_moon := ContentDB.quests.has("_test_moon_quest")
	var prev_moon: Variant = ContentDB.quests.get("_test_moon_quest", null)
	var had_unreach := ContentDB.quests.has("_test_unreach_quest")
	var prev_unreach: Variant = ContentDB.quests.get("_test_unreach_quest", null)
	var had_z := ContentDB.regions.has("isolated_z")
	var prev_z: Variant = ContentDB.regions.get("isolated_z", null)

	# Prevent any save timer from persisting temporary test data (no save calls).
	var save_timer: Timer = GameState.get("_save_timer") if "_save_timer" in GameState else null
	var save_timer_was_stopped := true
	if save_timer != null:
		save_timer_was_stopped = save_timer.is_stopped()
		save_timer.stop()
	var autosave_timer: Timer = GameState.get("_autosave_timer") if "_autosave_timer" in GameState else null
	var autosave_timer_was_stopped := true
	if autosave_timer != null:
		autosave_timer_was_stopped = autosave_timer.is_stopped()
		autosave_timer.stop()

	var resolver := QuestNavigationResolver.new()
	resolver.clear_registry()

	# Use a known active quest in greenward (glade_whisper) without GameState.set_tracked_quest (avoids queue_save).
	if not GameState.quests.has("glade_whisper") or typeof(GameState.quests["glade_whisper"]) != TYPE_DICTIONARY:
		GameState.quests["glade_whisper"] = { "state": "active", "step": 1, "progress": 0 }
	else:
		GameState.quests["glade_whisper"]["state"] = "active"
		GameState.quests["glade_whisper"]["step"] = 1
		GameState.quests["glade_whisper"]["progress"] = 0
	GameState.flags["tracked_quest"] = "glade_whisper"
	GameState.player_region = "greenward"
	var player_pos := IsoMath.grid_to_world(8.0, 8.0)

	# Same-region target.
	var r_same := resolver.get_resolved_target("greenward", player_pos)
	_check("same-region resolved valid", bool(r_same.get("valid", false)) and str(r_same.get("status")) in [QuestNavigationResolver.STATUS_SAME_REGION, QuestNavigationResolver.STATUS_SAME_REGION_OTHER_TERRITORY], "status=%s valid=%s" % [str(r_same.get("status")), str(r_same.get("valid"))])
	_check("same-region has distance", r_same.get("distance", null) != null)
	_check("same-region has direction vector", typeof(r_same.get("direction")) == TYPE_VECTOR2)
	_check("same-region same_frame true", bool(r_same.get("same_frame", false)))
	_check("same-region route empty", (r_same.get("route", []) as Array).is_empty())

	# Freshness: moving player position changes distance without invalidation.
	var r_moved := resolver.get_resolved_target("greenward", player_pos + Vector2(200, 0))
	var d1: float = float(r_same.get("distance", -1.0))
	var d2: float = float(r_moved.get("distance", -1.0))
	_check("distance fresh for moved player", absf(d1 - d2) > 1.0, "d1=%.2f d2=%.2f" % [d1, d2])

	# Two remote Greenward territories (same region_id, different territories).
	# Elder Hollow: grid [-88,76], radius 14 tiles (grid-space comparison).
	GameState.quests["elder_memory"] = { "state": "active", "step": 0, "progress": 0 }
	GameState.flags["tracked_quest"] = "elder_memory"
	var r_elder := resolver.get_resolved_target("greenward", IsoMath.grid_to_world(8.0, 8.0))
	_check("Elder Hollow target in greenward", str(r_elder.get("target_region_id")) == "greenward")
	_check("Elder Hollow territory detected", str(r_elder.get("target_territory_id")) == "elder_hollow", "territory=%s" % str(r_elder.get("target_territory_id")))
	_check("Elder Hollow same-region guidance (no cross-region route)", bool(r_elder.get("same_region", false)) and (r_elder.get("route", []) as Array).is_empty())
	_check("Elder Hollow distance is local", r_elder.get("distance", null) != null)
	# Boundary/radius behavior (grid tiles): inside and on-edge in territory, outside not.
	var elder_center := Vector2(-88, 76)
	_check("Elder Hollow center in territory (grid)", str(resolver._territory_for("greenward", IsoMath.grid_to_world(elder_center.x, elder_center.y), {})) == "elder_hollow")
	_check("Elder Hollow edge in territory (14 tiles)", str(resolver._territory_for("greenward", IsoMath.grid_to_world(elder_center.x + 14.0, elder_center.y), {})) == "elder_hollow")
	_check("Elder Hollow outside radius not in territory", str(resolver._territory_for("greenward", IsoMath.grid_to_world(elder_center.x + 15.0, elder_center.y), {})) != "elder_hollow")
	_check("Elder Hollow _in_territory matches boundary", resolver._in_territory("greenward", IsoMath.grid_to_world(elder_center.x + 7.0, elder_center.y + 7.0), "elder_hollow") and not resolver._in_territory("greenward", IsoMath.grid_to_world(elder_center.x + 20.0, elder_center.y), "elder_hollow"))

	# Withered Estate / Fallen Matron: grid [116,78]
	GameState.quests["matron_bloom"] = { "state": "active", "step": 0, "progress": 0 }
	GameState.flags["tracked_quest"] = "matron_bloom"
	var r_matron := resolver.get_resolved_target("greenward", IsoMath.grid_to_world(8.0, 8.0))
	_check("Withered Estate target in greenward", str(r_matron.get("target_region_id")) == "greenward")
	_check("Withered Estate territory detected", str(r_matron.get("target_territory_id")) == "withered_estate", "territory=%s" % str(r_matron.get("target_territory_id")))
	_check("Withered Estate same-region guidance", bool(r_matron.get("same_region", false)) and (r_matron.get("route", []) as Array).is_empty())
	_check("Withered Estate distance is local", r_matron.get("distance", null) != null)
	var estate_center := Vector2(116, 78)
	_check("Withered Estate center in territory (grid)", str(resolver._territory_for("greenward", IsoMath.grid_to_world(estate_center.x, estate_center.y), {})) == "withered_estate")
	_check("Withered Estate edge in territory (14 tiles)", str(resolver._territory_for("greenward", IsoMath.grid_to_world(estate_center.x, estate_center.y + 14.0), {})) == "withered_estate")
	_check("Withered Estate outside radius not in territory", str(resolver._territory_for("greenward", IsoMath.grid_to_world(estate_center.x, estate_center.y + 15.0), {})) != "withered_estate")
	_check("Withered Estate _in_territory matches boundary", resolver._in_territory("greenward", IsoMath.grid_to_world(estate_center.x - 10.0, estate_center.y + 5.0), "withered_estate") and not resolver._in_territory("greenward", IsoMath.grid_to_world(estate_center.x - 20.0, estate_center.y), "withered_estate"))

	# Cross-region navigation (synthetic quest/region; in-memory ContentDB restored).
	ContentDB.quests["_test_moon_quest"] = {
		"name": "Moon Test", "region": "moonpetal_hollow",
		"steps": [ { "type": "talk", "target": "x", "grid": [12, 12], "text": "Go to pool" } ]
	}
	GameState.quests["_test_moon_quest"] = { "state": "active", "step": 0, "progress": 0 }
	GameState.flags["tracked_quest"] = "_test_moon_quest"
	GameState.player_region = "greenward"
	var r_cross := resolver.get_resolved_target("greenward", IsoMath.grid_to_world(8.0, 8.0))
	_check("cross-region status other_region", str(r_cross.get("status")) == QuestNavigationResolver.STATUS_OTHER_REGION, "status=%s" % str(r_cross.get("status")))
	_check("cross-region same_frame false", not bool(r_cross.get("same_frame", true)))
	_check("cross-region distance suppressed", r_cross.get("distance", "x") == null, "distance=%s" % str(r_cross.get("distance")))
	_check("cross-region direction zero", (r_cross.get("direction", Vector2.ONE) as Vector2) == Vector2.ZERO)
	_check("cross-region route provided", (r_cross.get("route", []) as Array).size() >= 1, "route=%s" % str(r_cross.get("route")))
	var nh: Dictionary = r_cross.get("next_hop", {})
	_check("cross-region next hop targets moonpetal_hollow", str(nh.get("to", "")) == "moonpetal_hollow", "to=%s" % str(nh.get("to")))
	_check("cross-region label guides travel", str(r_cross.get("label", "")).find("Travel") != -1 or str(r_cross.get("label", "")).find("Moonpetal") != -1, "label=%s" % str(r_cross.get("label")))

	# Unreachable cross-region (synthetic).
	ContentDB.quests["_test_unreach_quest"] = {
		"name": "Far Test", "region": "isolated_z",
		"steps": [ { "type": "talk", "target": "x", "grid": [0, 0], "text": "Go" } ]
	}
	ContentDB.regions["isolated_z"] = { "name": "Isolated Z", "world_origin": [9000.0, 9000.0], "spawn_grid": [0,0], "entry_points": {"s":[0,0]}, "connections": [] }
	GameState.quests["_test_unreach_quest"] = { "state": "active", "step": 0, "progress": 0 }
	GameState.flags["tracked_quest"] = "_test_unreach_quest"
	GameState.player_region = "greenward"
	var r_unreach := resolver.get_resolved_target("greenward", player_pos)
	_check("unreachable cross-region marked unreachable", str(r_unreach.get("status")) == QuestNavigationResolver.STATUS_UNREACHABLE, "status=%s" % str(r_unreach.get("status")))
	_check("unreachable has no misleading distance", r_unreach.get("distance", "x") == null)
	_check("unreachable route empty", (r_unreach.get("route", []) as Array).is_empty())

	# Live-target registration, unregistration, fallback, and freshness.
	GameState.flags["tracked_quest"] = "glade_whisper"
	GameState.quests["glade_whisper"] = { "state": "active", "step": 1, "progress": 0 }
	GameState.player_region = "greenward"
	resolver.clear_registry()
	var live_pos := IsoMath.grid_to_world(20.0, 20.0)
	resolver.register_nav_target("live_moss_1", {
		"quest_id": "glade_whisper",
		"objective_id": "mossling",
		"region_id": "greenward",
		"local_pos": live_pos,
		"valid": true,
	})
	var r_live := resolver.get_resolved_target("greenward", player_pos)
	_check("registered live target preferred", str(r_live.get("live_source")) == "live_moss_1", "live=%s" % str(r_live.get("live_source")))
	_check("registered live target position used", (r_live.get("target_local_pos", Vector2.ZERO) as Vector2).distance_to(live_pos) < 0.1)

	# Move live target (fresh position).
	var moved_live_pos := IsoMath.grid_to_world(30.0, 10.0)
	resolver.register_nav_target("live_moss_1", {
		"quest_id": "glade_whisper",
		"objective_id": "mossling",
		"region_id": "greenward",
		"local_pos": moved_live_pos,
		"valid": true,
	})
	var r_live_moved := resolver.get_resolved_target("greenward", player_pos)
	_check("live target position fresh after update", (r_live_moved.get("target_local_pos", Vector2.ZERO) as Vector2).distance_to(moved_live_pos) < 0.1, "pos=%s" % str(r_live_moved.get("target_local_pos")))

	# Unregister -> fallback to authored destination.
	resolver.unregister_nav_target("live_moss_1")
	var r_fallback := resolver.get_resolved_target("greenward", player_pos)
	_check("fallback after unregister (no live source)", str(r_fallback.get("live_source", "")) == "", "live=%s" % str(r_fallback.get("live_source")))
	_check("fallback uses authored target pos", (r_fallback.get("target_local_pos", Vector2.ZERO) as Vector2).distance_to(IsoMath.grid_to_world(4.0, 6.0)) < 0.1, "pos=%s expected=%s" % [str(r_fallback.get("target_local_pos")), str(IsoMath.grid_to_world(4.0, 6.0))])

	# Cache invalidation: step change affects resolved identity.
	resolver.register_nav_target("live_moss_1", {
		"quest_id": "glade_whisper",
		"objective_id": "mossling",
		"region_id": "greenward",
		"local_pos": moved_live_pos,
		"valid": true,
	})
	var before_step := resolver.get_resolved_target("greenward", player_pos)
	GameState.quests["glade_whisper"]["step"] = 2
	GameState.quests["glade_whisper"]["progress"] = 0
	resolver.invalidate()
	var after_step := resolver.get_resolved_target("greenward", player_pos)
	_check("cache invalidation reflects step change", int(before_step.get("step_index", -1)) != int(after_step.get("step_index", -2)) or str(before_step.get("live_source", "")) != str(after_step.get("live_source", "x")), "before=%s after=%s" % [str(before_step.get("step_index")), str(after_step.get("step_index"))])

	# Provider validity regressions: valid:true must be rejected if referenced node freed/invalid/out-of-tree.
	# Restore the kill objective after the cache test advanced glade_whisper to its talk step.
	GameState.quests["glade_whisper"]["step"] = 1
	GameState.quests["glade_whisper"]["progress"] = 0
	resolver.clear_registry()
	var node_live_pos := IsoMath.grid_to_world(25.0, 25.0)
	var valid_node := Node2D.new()
	add_child(valid_node)
	await get_tree().process_frame
	valid_node.global_position = node_live_pos
	resolver.register_nav_target("node_live", {
		"quest_id": "glade_whisper",
		"objective_id": "mossling",
		"region_id": "greenward",
		"node": valid_node,
		"local_pos": node_live_pos,
		"valid": true,
	})
	var r_node_live := resolver.get_resolved_target("greenward", player_pos)
	_check("valid live provider with in-tree node accepted", str(r_node_live.get("live_source")) == "node_live", "live=%s" % str(r_node_live.get("live_source")))
	# Node movement must be read live, not from a stale registration-time position.
	valid_node.global_position += Vector2(96.0, 48.0)
	resolver.invalidate()
	var r_node_moved := resolver.get_resolved_target("greenward", player_pos)
	_check("referenced Node2D position refreshed after movement", (r_node_moved.get("target_local_pos", Vector2.ZERO) as Vector2).distance_to(valid_node.global_position) < 0.1, "pos=%s expected=%s" % [str(r_node_moved.get("target_local_pos")), str(valid_node.global_position)])
	# Node outside tree -> rejected (fallback).
	remove_child(valid_node)
	resolver.invalidate()
	var r_node_out := resolver.get_resolved_target("greenward", player_pos)
	_check("provider with out-of-tree node rejected (valid:true)", str(r_node_out.get("live_source", "")) != "node_live", "live=%s" % str(r_node_out.get("live_source")))
	# Re-accepted when back in tree.
	add_child(valid_node)
	await get_tree().process_frame
	valid_node.global_position = node_live_pos
	resolver.invalidate()
	var r_node_back := resolver.get_resolved_target("greenward", player_pos)
	_check("provider re-accepted when node back in tree", str(r_node_back.get("live_source")) == "node_live", "live=%s" % str(r_node_back.get("live_source")))

	# A closer scene-scan monster must not override an explicit registered provider.
	var nearby_monster := preload("res://scenes/world/roaming_monster.tscn").instantiate() as RoamingMonster
	nearby_monster.setup("mossling", player_pos + Vector2(1.0, 1.0), { "id": "mossling", "name": "Test Mossling" }, false)
	add_child(nearby_monster)
	resolver.invalidate()
	var r_registered_priority := resolver.get_resolved_target("greenward", player_pos)
	_check("explicit registered provider wins over closer scene-scan monster", str(r_registered_priority.get("live_source")) == "node_live", "live=%s" % str(r_registered_priority.get("live_source")))
	nearby_monster.free()
	await get_tree().process_frame

	# Freed node -> rejected.
	remove_child(valid_node)
	valid_node.free()
	await get_tree().process_frame
	resolver.invalidate()
	var r_node_freed := resolver.get_resolved_target("greenward", player_pos)
	_check("provider with freed node rejected (valid:true)", str(r_node_freed.get("live_source", "")) != "node_live", "live=%s" % str(r_node_freed.get("live_source")))

	# Restore all modified state (including keys originally absent) and no saves.
	resolver.clear_registry()
	if had_moon:
		ContentDB.quests["_test_moon_quest"] = prev_moon
	else:
		ContentDB.quests.erase("_test_moon_quest")
	if had_unreach:
		ContentDB.quests["_test_unreach_quest"] = prev_unreach
	else:
		ContentDB.quests.erase("_test_unreach_quest")
	if had_z:
		ContentDB.regions["isolated_z"] = prev_z
	else:
		ContentDB.regions.erase("isolated_z")
	for qid in quest_ids:
		_restore_quest(qid, quest_snaps.get(qid, { "present": false, "value": null }))

	GameState.player_region = prev_region
	GameState.has_player_position = prev_has_pos
	GameState.player_position = prev_pos
	GameState.region_positions = prev_rp.duplicate(true) if typeof(prev_rp) == TYPE_DICTIONARY else {}
	if prev_tracked_flag_present:
		GameState.flags["tracked_quest"] = prev_tracked_flag
	else:
		GameState.flags.erase("tracked_quest")

	if save_timer != null and not save_timer_was_stopped:
		save_timer.start()
	if autosave_timer != null and not autosave_timer_was_stopped:
		autosave_timer.start()
	# Intentionally no GameState.queue_save()/save_now(): runtime state restored to snapshot.
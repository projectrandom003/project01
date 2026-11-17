extends SceneTree
## Headless acceptance check for the Royal Gardens expansion + boss zone.
## Run: godot --headless --path . -s tools/verify_reverie_expansion.gd

var failures: Array[String] = []
var db: Node = null
var checks: int = 0


func _init() -> void:
	await process_frame
	db = root.get_node_or_null("/root/ContentDB")
	_check_content()
	_check_routes()
	await _check_worlds()
	_check_assets()
	print("=== REVERIE EXPANSION VERIFICATION ===")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	for f in failures:
		print("  FAIL: ", f)
	if failures.is_empty():
		print("RESULT: PASS")
	else:
		print("RESULT: FAIL")
	quit(1 if failures.size() > 0 else 0)


func ok(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)


func _check_content() -> void:
	var zone: Dictionary = db.get_region("gothic_castle_boss_zone")
	ok(not zone.is_empty(), "boss zone region exists")
	ok(bool(zone.get("standalone", false)), "boss zone is standalone (graph-safe)")
	ok(zone.get("entry_points", {}).has("royal_gate"), "boss zone royal_gate entry point")
	ok((zone.get("connections", []) as Array).size() == 1, "boss zone has return connection")
	var castle: Dictionary = db.get_region("castle_royal_gardens")
	ok(castle.get("entry_points", {}).has("boss_path"), "castle boss_path entry point")
	var route_found := false
	for c in castle.get("connections", []):
		var d: Dictionary = c
		if str(d.get("to", "")) == "gothic_castle_boss_zone" and str(d.get("via", "")) == "boss_path":
			route_found = true
	ok(route_found, "castle -> boss zone connection via boss_path")
	for spawn in zone.get("spawns", []):
		var s: Dictionary = spawn
		ok(not db.get_enemy_group(str(s.get("group", ""))).is_empty(),
				"spawn group exists: %s" % str(s.get("group", "")))
	for quest_id in ["royal_road_supplies", "blight_purification", "baltoria_summoning"]:
		var q: Dictionary = db.get_quest(quest_id)
		ok(not q.is_empty(), "quest exists: " + quest_id)
		for step in q.get("steps", []):
			var st: Dictionary = step
			ok(st.get("type", "") in ["talk", "kill"], "quest step type valid: " + quest_id)
	var boss_quest: Dictionary = db.get_quest("baltoria_summoning")
	ok(str(boss_quest.get("requires", "")) == "blight_purification", "boss quest requires side quest")
	var gatekeeper: Dictionary = db.get_dialogue("arena_gatekeeper")
	ok(not gatekeeper.is_empty() and gatekeeper.get("start") == "locked", "arena gatekeeper starts locked")
	ok(not db.get_enemy("baltoria") == null, "baltoria enemy exists")
	ok(not db.get_enemy_group("baltoria_encounter").is_empty(), "baltoria encounter group exists")
	ok(bool(db.get_enemy_group("baltoria_encounter").get("boss", false)), "baltoria group is a boss")
	for item_id in ["gothic_shard", "blight_resin", "royal_seal"]:
		ok(db.get_item(item_id) != null, "reward material exists: " + item_id)


func _check_routes() -> void:
	var path_cells: Dictionary = ReverieRouteData.all_path_cells()
	ok(path_cells.size() > 70, "main route + branches have enough tiles (%d)" % path_cells.size())
	var main := ReverieRouteData.main_cells()
	ok(main.size() > 60, "main route length %d cells" % main.size())
	# Four-neighbour flood fill from the royal gate.
	var visited := {}
	var queue: Array[Vector2i] = [Vector2i(0, 0)]
	visited[Vector2i(0, 0)] = true
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for delta in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next: Vector2i = cell + delta
			if path_cells.has(next) and not visited.has(next):
				visited[next] = true
				queue.append(next)
	for cell in main:
		ok(visited.has(cell), "main route connected: %s" % str(cell))
	for endpoint in [Vector2i(18, -10), Vector2i(38, 18), Vector2i(52, -14)]:
		ok(visited.has(endpoint), "branch endpoint reachable: %s" % str(endpoint))
	ok(ReverieRouteData.castle_wall_cells().size() > 30, "castle wall ring is closed and substantial")
	ok(ReverieRouteData.in_arena(ReverieRouteData.ARENA_CENTER), "arena centre inside arena bounds")


func _check_worlds() -> void:
	var zone_scene := load("res://scenes/world/gothic_castle_boss_zone.tscn") as PackedScene
	ok(zone_scene != null, "boss zone scene loads")
	if zone_scene == null:
		return
	var zone = zone_scene.instantiate()
	root.add_child(zone)
	await process_frame
	await process_frame
	var report: Dictionary = zone.call("visual_standards_report")
	ok(int(report.get("tiles", 0)) > 3000, "ground covers the full authored area (%s tiles)" % str(report.get("tiles", 0)))
	ok((zone.call("get_world_npcs") as Array).size() == 3, "three expansion NPCs spawned")
	ok((zone.call("get_world_monsters") as Array).size() == 4, "four encounters spawned")
	# Every route/branch cell must have a ground tile sprite.
	var ground = zone.get_node("Terrain/Ground")
	var tile_names := {}
	for child in ground.get_children():
		tile_names[child.name] = true
	for cell in ReverieRouteData.all_path_cells():
		var prefix := "Tile_%d_%d_" % [cell.x, cell.y]
		var found := false
		for name in tile_names:
			if str(name).begins_with(prefix):
				found = true
				break
		ok(found, "path tile rendered at %s" % str(cell))
	# Portals, gathering nodes and collision.
	var entities = zone.get_node("Entities")
	var portal_count := 0
	var gather_count := 0
	var monster_count := 0
	for c in entities.get_children():
		var script = c.get_script()
		var sn := str(script.get_global_name()) if script != null else ""
		if sn == "RegionPortal":
			portal_count += 1
			ok(str(c.get("target_region")) == "castle_royal_gardens", "zone portal returns to Royal Gardens")
		if sn == "InteractiveProp":
			gather_count += 1
		if c.get("group_id") != null and sn != "WorldNPC" and sn != "RegionPortal" and sn != "InteractiveProp":
			monster_count += 1
	ok(portal_count == 1, "zone has one return portal")
	ok(gather_count == 7, "zone has seven material/treasure nodes")
	ok(monster_count == 4, "zone has four world monsters")
	var solid := _count_collision(zone.get_node("Castle"))
	ok(solid > 20, "castle walls/towers have real collision footprints (%d)" % solid)
	var arena_solid := _count_collision(zone.get_node("Arena"))
	ok(arena_solid > 10, "arena boundary has collision (%d)" % arena_solid)
	zone.queue_free()
	await process_frame

	var castle_scene := load("res://scenes/world/castle_royal_gardens.tscn") as PackedScene
	ok(castle_scene != null, "Royal Gardens scene still loads")
	if castle_scene != null:
		var cw = castle_scene.instantiate()
		root.add_child(cw)
		await process_frame
		await process_frame
		ok((cw.call("get_world_npcs") as Array).size() == 4, "existing castle NPCs preserved")
		var exp = cw.get_node("ExpansionBuilder")
		ok(exp != null and exp.get_child_count() >= 3, "castle expansion layers built")
		var exp_portal := 0
		for layer in exp.get_children():
			for child in layer.get_children():
				var script = child.get_script()
				if script != null and str(script.get_global_name()) == "RegionPortal":
					exp_portal += 1
					ok(str(child.get("target_region")) == "gothic_castle_boss_zone", "castle portal targets boss zone")
		ok(exp_portal == 1, "castle has one expansion portal")
		cw.queue_free()
		await process_frame


func _check_assets() -> void:
	var f := FileAccess.open("res://assets/reverie_pack_v01/manifest.json", FileAccess.READ)
	ok(f != null, "pack manifest exists")
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	var assets: Array = data.get("assets", [])
	ok(assets.size() == 200, "all 200 delivered assets imported (%d)" % assets.size())
	var checked := 0
	for a in assets:
		var d: Dictionary = a
		var path := "res://assets/reverie_pack_v01/" + str(d.get("file", ""))
		ok(ResourceLoader.exists(path), "asset exists: %s" % str(d.get("id", "")))
		var piece := "res://scenes/world/reverie_pack/%s/%s/%s.tscn" % [
				str(d.get("category", "")), str(d.get("subfolder", "")), str(d.get("id", ""))]
		ok(ResourceLoader.exists(piece), "piece scene exists: %s" % str(d.get("id", "")))
		checked += 1
	print("asset records checked: ", checked)



func _count_collision(node: Node) -> int:
	var count := 0
	if node is CollisionShape2D and (node as CollisionShape2D).shape != null:
		count += 1
	for child in node.get_children():
		count += _count_collision(child)
	return count

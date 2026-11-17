extends Node2D
## Renders the canonical live GreenwardWorld/village and saves screenshots.
## Uses actual runtime lighting/streaming state where possible (not exposure-only).

const WORLD_SCENE: PackedScene = preload("res://scenes/world/greenward_world.tscn")

var _shots: Array[Dictionary] = []
var _out_dir: String = "res://.godot_tmp_village_captures"

func _ready() -> void:
	# Optional: `Godot ... res://tools/capture_village.tscn -- --out res://<folder>`
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if str(args[i]) == "--out" and i + 1 < args.size():
			_out_dir = str(args[i + 1])
	_out_dir = ProjectSettings.globalize_path(_out_dir)
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var world = WORLD_SCENE.instantiate()
	add_child(world)
	# Wait for world initialization/streaming.
	for i in 40:
		await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	var cam := _find_camera(world)
	if cam == null:
		cam = Camera2D.new()
		add_child(cam)
		cam.make_current()
	cam.enabled = true
	cam.make_current()

	# Daytime baseline (ensure runtime state, not a forced fake tint).
	await _set_day(world)
	await _capture(cam, "01_village_overview", Vector2(0, 260), 0.85)
	await _capture(cam, "02_entrance", Vector2(300, 250), 1.35)
	await _capture(cam, "03_central_square", Vector2(0, 256), 1.55)
	await _capture(cam, "04_market", Vector2(120, 320), 1.55)
	await _capture(cam, "05_residential_north", Vector2(60, 170), 1.35)
	await _capture(cam, "06_elder_civic", Vector2(-100, 200), 1.5)
	await _capture(cam, "07_shrine_riverside", Vector2(-240, 290), 1.45)
	await _capture(cam, "12_gate_close", Vector2(320, 256), 1.8)

	# Live depth sorting: player crossing in front of / behind real village trees,
	# buildings and a quest NPC (actual renderer, actual canonical world nodes).
	await _capture_live_crossings(world, player, cam)
	# Return player to the square so subsequent framing is not affected by crossing teleports.
	if player != null and is_instance_valid(player):
		player.global_position = Vector2(0, 260)

	# Actual nighttime state (canvas tint + village/world lights via runtime hooks).
	await _set_night(world)
	await _capture(cam, "08_village_night", Vector2(0, 260), 0.9)
	await _capture(cam, "09_village_night_square", Vector2(0, 256), 1.45)

	# Restore day for readable remote approach framing, keep zones distant/separate.
	await _set_day(world)

	# Remote approaches: move player to load streamed terrain, then frame useful views.
	# Elder Hollow / Ancient Sanctuary (remote NW) and Fallen Matron / Withered Estate (remote SE).
	var elder_center := _grid_to_world(Vector2(-88, 76))
	var estate_center := _grid_to_world(Vector2(116, 78))
	var village_center := Vector2(0, 256)

	var elder_approach := elder_center.lerp(village_center, 0.18) # approach from village side
	await _prepare_remote_view(world, player, cam, elder_approach)
	await _capture(cam, "10_approach_elder_hollow", elder_approach, 0.6)

	var estate_approach := estate_center.lerp(village_center, 0.18)
	await _prepare_remote_view(world, player, cam, estate_approach)
	await _capture(cam, "11_approach_withered_estate", estate_approach, 0.6)

	# Return player/camera near village (leave world in a sane state).
	if player != null and is_instance_valid(player):
		player.global_position = village_center
		for i in 8:
			await get_tree().process_frame

	print("---")
	print("[village_capture] saved %d screenshots to %s" % [_shots.size(), _out_dir])
	for s in _shots:
		print("[village_capture] %s" % s.path)
	get_tree().quit(0)

func _capture_live_crossings(world: Node, player: Node, cam: Camera2D) -> void:
	var tree := _find_live_tree(world, Vector2(-40, 140))
	print("[village_capture] crossing tree=" + (str(tree.name) if tree != null else "MISSING"))
	await _capture_crossing(cam, player, tree, "13_live_tree_player_behind", "14_live_tree_player_front", 1.7)
	var building := _find_live_building(world, "home_nw")
	print("[village_capture] crossing building=" + (str(building.name) if building != null else "MISSING"))
	await _capture_crossing(cam, player, building, "15_live_building_player_behind", "16_live_building_player_front", 1.7)
	var elder := _find_live_npc(world, "elder_maelin")
	print("[village_capture] crossing npc=" + (str(elder.name) if elder != null else "MISSING"))
	await _capture_crossing(cam, player, elder, "17_live_npc_player_behind", "18_live_npc_player_front", 1.8)

func _find_live_tree(world: Node, near: Vector2) -> Node2D:
	# Prefer authored village trees (stable world-space anchors); streamed trees
	# are chunk-local and only used as a fallback.
	var best: Node2D = null
	var best_d := INF
	for n in world.find_children("*", "Node2D", true, false):
		var node := n as Node2D
		if node == null or not node.has_meta("village_tree_group"):
			continue
		var d := node.global_position.distance_to(near)
		if d < best_d:
			best_d = d
			best = node
	if best != null:
		return best
	# Authored landmark trees in the live world are Sprite2D props with a tree texture.
	var tree_textures := []
	for kind in ["ancient_tree", "glade_tree", "willow_tree", "birch_tree"]:
		var tex := ProceduralArt.prop_texture(kind, 0)
		if tex != null:
			tree_textures.append(tex)
	for n in world.find_children("*", "Sprite2D", true, false):
		var sprite := n as Sprite2D
		if sprite == null or sprite.texture == null:
			continue
		if not tree_textures.has(sprite.texture):
			continue
		var d2 := sprite.global_position.distance_to(near)
		if d2 < best_d:
			best_d = d2
			best = sprite
	if best != null:
		return best
	for n in world.find_children("*", "Node2D", true, false):
		var node := n as Node2D
		if node == null or not (node.has_method("setup") and String(node.name).to_lower().contains("tree")):
			continue
		var d := node.global_position.distance_to(near)
		if d < best_d:
			best_d = d
			best = node
	return best

func _find_live_building(world: Node, slot_id: String) -> Node2D:
	for n in world.find_children("*", "Node2D", true, false):
		if n is Node2D and str(n.get_meta("slot_id", "")) == slot_id:
			return n as Node2D
	return null

func _find_live_npc(world: Node, npc_id: String) -> Node2D:
	for n in world.find_children("*", "WorldNPC", true, false):
		if n is Node2D and str(n.get("npc_id")) == npc_id:
			return n as Node2D
	return null

func _capture_crossing(cam: Camera2D, player: Node, anchor: Node2D, label_behind: String, label_front: String, zoom: float) -> void:
	if anchor == null or not is_instance_valid(anchor):
		print("[village_capture] SKIP crossing (anchor missing): " + label_behind)
		return
	var center := anchor.global_position
	cam.global_position = center
	cam.zoom = Vector2.ONE * zoom
	# Smaller Y => drawn before the anchor => tree/building/NPC overlaps the player.
	if player != null and is_instance_valid(player):
		player.global_position = center + Vector2(-4, -36)
	await _capture_at_current(cam, label_behind)
	# Larger Y => drawn after the anchor => player overlaps the tree/building/NPC.
	if player != null and is_instance_valid(player):
		player.global_position = center + Vector2(4, 36)
	await _capture_at_current(cam, label_front)

func _capture_at_current(cam: Camera2D, label: String) -> void:
	for i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	var path := _out_dir.path_join(label + ".png")
	if img != null:
		img.save_png(path)
		_shots.append({"label": label, "path": path})
		print("[village_capture] " + path)
	else:
		print("[village_capture] FAILED " + label)

func _grid_to_world(g: Vector2) -> Vector2:
	# Mirror IsoMath.grid_to_world (TILE_W=64,TILE_H=32) without hard dependency.
	return Vector2((g.x - g.y) * 32.0, (g.x + g.y) * 16.0)

func _prepare_remote_view(world: Node, player: Node, cam: Camera2D, pos: Vector2) -> void:
	if player != null and is_instance_valid(player):
		# Teleport player so chunk streaming loads terrain around the remote approach.
		player.global_position = pos
	for i in 60:
		await get_tree().process_frame
	cam.global_position = pos
	cam.make_current()

func _set_day(world: Node) -> void:
	var dn := world.get_node_or_null("DayNight")
	if dn != null:
		dn.time_of_day = 0.50 # Noon
		dn.day_length_seconds = 999999.0
		if dn.has_method("_apply"):
			dn._apply()
	var modulate := world.get_node_or_null("DayNight") as CanvasModulate
	if modulate == null:
		modulate = world.get_node_or_null("CanvasModulate") as CanvasModulate
	if modulate:
		modulate.color = Color(1, 1, 1, 1)
	_apply_runtime_lighting(world, false)
	for i in 8:
		await get_tree().process_frame

func _set_night(world: Node) -> void:
	var dn := world.get_node_or_null("DayNight")
	if dn != null:
		dn.time_of_day = 0.02 # Midnight
		dn.day_length_seconds = 999999.0
		if dn.has_method("_apply"):
			dn._apply()
	var modulate := world.get_node_or_null("DayNight") as CanvasModulate
	if modulate == null:
		modulate = world.get_node_or_null("CanvasModulate") as CanvasModulate
	if modulate:
		# Clearly darker ambient while preserving readable contrast.
		modulate.color = Color(0.36, 0.42, 0.62, 1.0)
	_apply_runtime_lighting(world, true)
	for i in 10:
		await get_tree().process_frame

func _apply_runtime_lighting(world: Node, is_night: bool) -> void:
	if world.has_method("_apply_atmosphere"):
		world._apply_atmosphere()
	if world.has_method("_apply_village_day_phase"):
		world._apply_village_day_phase("Midnight" if is_night else "Noon")
	else:
		var village := world.get_node_or_null("Village")
		if village != null and village.has_method("apply_day_phase"):
			village.apply_day_phase(is_night, 1.35 if is_night else 0.55)

func _find_camera(root: Node) -> Camera2D:
	var player = root.get_tree().get_first_node_in_group("player") if root.is_inside_tree() else null
	if player != null:
		for c in player.find_children("*", "Camera2D", true, false):
			return c as Camera2D
		if player.has_node("Camera2D"):
			return player.get_node("Camera2D") as Camera2D
	for c in root.find_children("*", "Camera2D", true, false):
		return c as Camera2D
	return null

func _capture(cam: Camera2D, label: String, pos: Vector2, zoom: float) -> void:
	cam.global_position = pos
	cam.zoom = Vector2.ONE * zoom
	for i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	var path := _out_dir.path_join(label + ".png")
	if img != null:
		img.save_png(path)
		_shots.append({"label": label, "path": path})
		print("[village_capture] " + path)
	else:
		print("[village_capture] FAILED " + label)
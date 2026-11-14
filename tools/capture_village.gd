extends Node2D
## Renders the canonical live GreenwardWorld/village and saves screenshots.
## Uses actual runtime lighting/streaming state where possible (not exposure-only).

const WORLD_SCENE: PackedScene = preload("res://scenes/world/greenward_world.tscn")

var _shots: Array[Dictionary] = []
var _out_dir: String = "res://.godot_tmp_village_captures"

func _ready() -> void:
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
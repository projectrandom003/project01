extends Node2D
## Actual-renderer gameplay QA for Greenward village (lightweight, guaranteed to finish).

const WORLD_SCENE: PackedScene = preload("res://scenes/world/greenward_world.tscn")

var _out_dir := ""
var _shots: Array[String] = []
var _issues: Array[String] = []
var _passes: Array[String] = []
var world = null
var player = null
var cam: Camera2D = null

func _ready() -> void:
	_out_dir = ProjectSettings.globalize_path("res://.godot_tmp_village_qa")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	world = WORLD_SCENE.instantiate()
	add_child(world)
	for i in 35:
		await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	cam = _find_camera()
	if player == null:
		_fail("player not found")
	else:
		_pass("player present")
	if cam == null:
		cam = Camera2D.new(); add_child(cam); cam.make_current()
	cam.enabled = true
	cam.make_current()

	var tour := [
		{"name":"spawn_center", "pos": Vector2(0, 256)},
		{"name":"entrance", "pos": Vector2(300, 256)},
		{"name":"central_square", "pos": Vector2(0, 256)},
		{"name":"market", "pos": Vector2(120, 320)},
		{"name":"residential_north", "pos": Vector2(40, 170)},
		{"name":"elder_civic", "pos": Vector2(-90, 200)},
		{"name":"shrine_riverside", "pos": Vector2(-220, 300)},
		{"name":"residential_south", "pos": Vector2(-20, 330)},
		{"name":"return_square", "pos": Vector2(0, 256)},
	]
	for stop in tour:
		if player:
			player.global_position = stop.pos
		cam.global_position = stop.pos
		for i in 6:
			await get_tree().process_frame
		await _shot(str(stop.name))
		_pass("visited " + str(stop.name))

	await _check_npcs_and_interactables()
	await _check_depth_sort_runtime()
	await _capture_day_night()
	_finish()

func _find_camera() -> Camera2D:
	if player != null:
		var c := player.get_node_or_null("Camera2D") as Camera2D
		if c: return c
		for n in player.find_children("*", "Camera2D", true, false):
			return n as Camera2D
	for n in world.find_children("*", "Camera2D", true, false):
		return n as Camera2D
	return null

func _check_npcs_and_interactables() -> void:
	var found_npcs: Array = []
	for n in get_tree().root.find_children("*", "WorldNPC", true, false):
		found_npcs.append(n)
	_pass("NPCs present in world: %d" % found_npcs.size())
	var interactables := get_tree().get_nodes_in_group("interactables") if get_tree().has_group("interactables") else []
	_pass("interactables in group: %d" % interactables.size())
	for nid in ["elder_maelin", "merchant_sera", "wanderer_pip"]:
		var ok := false
		for n in found_npcs:
			if "npc_id" in n and str(n.npc_id) == nid:
				ok = true
				break
		if ok:
			_pass("quest NPC present: " + nid)
		else:
			_fail("quest NPC missing: " + nid)

func _check_depth_sort_runtime() -> void:
	var entities := world.get_node_or_null("Entities") as Node2D
	if entities == null:
		_fail("Entities container missing")
		return
	_pass("Entities y_sort_enabled=" + str(entities.y_sort_enabled))
	var nested := 0
	for c in entities.get_children():
		if c is Node2D and (c as Node2D).y_sort_enabled:
			nested += 1
	if nested == 0:
		_pass("no nested y-sort containers among direct Entities children")
	else:
		_fail("nested y-sort containers in Entities: %d" % nested)

func _capture_day_night() -> void:
	await _set_day_runtime()
	if player: player.global_position = Vector2(0, 256)
	if cam: cam.global_position = Vector2(0, 256)
	await _shot("day_overview_final")
	await _set_night_runtime()
	if player: player.global_position = Vector2(0, 256)
	if cam: cam.global_position = Vector2(0, 256)
	await _shot("night_overview_final")
	_pass("runtime day/night states applied for captures")

func _set_day_runtime() -> void:
	var dn: Node = world.get_node_or_null("DayNight")
	if dn != null:
		dn.set("time_of_day", 0.50)
		if dn.has_method("_apply"): dn.call("_apply")
	if world.has_method("_apply_atmosphere"): world.call("_apply_atmosphere")
	if world.has_method("_apply_village_day_phase"): world.call("_apply_village_day_phase", "Noon")
	for i in 6: await get_tree().process_frame

func _set_night_runtime() -> void:
	var dn: Node = world.get_node_or_null("DayNight")
	if dn != null:
		dn.set("time_of_day", 0.02)
		if dn.has_method("_apply"): dn.call("_apply")
	if world.has_method("_apply_atmosphere"): world.call("_apply_atmosphere")
	if world.has_method("_apply_village_day_phase"): world.call("_apply_village_day_phase", "Midnight")
	for i in 8: await get_tree().process_frame

func _shot(label: String) -> void:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	if img == null:
		_fail("capture failed: " + label)
		return
	var path := _out_dir.path_join(label + ".png")
	img.save_png(path)
	_shots.append(path)
	print("[qa_capture] " + path)

func _pass(msg: String) -> void:
	_passes.append(msg)
	print("[qa] PASS " + msg)

func _fail(msg: String) -> void:
	_issues.append(msg)
	print("[qa] FAIL " + msg)

func _finish() -> void:
	print("---")
	print("[qa] passes=%d issues=%d shots=%d dir=%s" % [_passes.size(), _issues.size(), _shots.size(), _out_dir])
	for i in _issues:
		print("[qa] ISSUE: " + i)
	get_tree().quit(0 if _issues.is_empty() else 1)
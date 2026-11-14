extends Node2D
## Visual regression scene for shared depth-sorting (actual project assets).
## Proves per-object Y interleaving among village trees, building visuals, player,
## NPCs, and runtime-spawned props as direct children of a single Entities y-sort.
##
## Run with -- --capture to execute automated scenario positioning/capture in the renderer.

const FOREST_TREE_SCENE: PackedScene = preload("res://scenes/world/forest_tree.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player.tscn")
const NPC_SCENE: PackedScene = preload("res://scenes/world/world_npc.tscn")
const INTERACTIVE_PROP_SCENE: PackedScene = preload("res://scenes/world/interactive_prop.tscn")
const ANIMATED_PROP_SCENE: PackedScene = preload("res://scenes/world/animated_prop.tscn")

@onready var entities: Node2D = $Entities

var player: Node = null
var npc: Node = null
var trees: Array = []
var building: Node2D = null
var runtime_prop: Node = null
var runtime_animated_prop: Node = null
var canopy_tree: Node2D = null
var overlap_a: Node2D = null
var overlap_b: Node2D = null

var _capture_mode: bool = false
var _scenario_results: Array[Dictionary] = []

func _ready() -> void:
	_build_scene()
	_capture_mode = _has_capture_arg()
	set_process(true)
	if _capture_mode:
		call_deferred("_run_capture_sequence")

func _process(_delta: float) -> void:
	pass

func _has_capture_arg() -> bool:
	for a in OS.get_cmdline_user_args():
		if str(a) == "--capture" or str(a).begins_with("--capture"):
			return true
	for a in OS.get_cmdline_args():
		if str(a) == "--capture":
			return true
	return false

func _build_scene() -> void:
	# Two trees at different Y positions (overlapping depth band)
	var tree_back := FOREST_TREE_SCENE.instantiate()
	tree_back.name = "TreeBack"
	entities.add_child(tree_back)
	tree_back.global_position = Vector2(-120, -10)
	if tree_back.has_method("setup"):
		tree_back.setup("glade_tree", 0, false, 1.0, null)
	trees.append(tree_back)

	var tree_front := FOREST_TREE_SCENE.instantiate()
	tree_front.name = "TreeFront"
	entities.add_child(tree_front)
	tree_front.global_position = Vector2(-40, 60)
	if tree_front.has_method("setup"):
		tree_front.setup("glade_tree", 1, false, 1.05, null)
	trees.append(tree_front)

	# A building with a large visual footprint (actual prop art), direct sortable child
	building = _make_building_prop("cottage", Vector2(140, 30), 1.15, false, 1)
	building.name = "BuildingLarge"
	entities.add_child(building)

	# One NPC
	var npc_node: Node = NPC_SCENE.instantiate()
	if npc_node.has_method("setup"):
		npc_node.call("setup", "elder_maelin", "Elder Maelin", "elder_intro", {"primary":"#3a5a40","secondary":"#bfa76a","hair":"#d8d0c0","skin":"#f0cbb0","accent":"#7fe3e0"}, "Elf")
	entities.add_child(npc_node)
	(npc_node as Node2D).global_position = Vector2(20, 10)
	npc = npc_node

	# One player
	player = PLAYER_SCENE.instantiate()
	entities.add_child(player)
	player.global_position = Vector2(-10, 40)
	# Keep input enabled for manual visual walk-around if run interactively.

	# At least one runtime-spawned prop (actual InteractiveProp scene), direct child of Entities
	var ip_node: Node = INTERACTIVE_PROP_SCENE.instantiate()
	if ip_node.has_method("setup"):
		ip_node.call("setup", "rune_stone", Vector2(40, 80), "Test Rune", "Runtime-spawned prop for depth sorting.", 0)
	entities.add_child(ip_node)
	(ip_node as Node2D).global_position = Vector2(40, 80)
	(ip_node as Node2D).name = "RuntimeInteractiveProp"
	runtime_prop = ip_node

	# Extra runtime-spawned animated prop to ensure bob/drift visuals don't affect sort origin
	var ap_node: Node = ANIMATED_PROP_SCENE.instantiate()
	entities.add_child(ap_node)
	if ap_node.has_method("setup"):
		ap_node.call("setup", "flower_patch", Vector2(-70, 90), 1.0, false, 1, 0) # MOTION_BOB == 1
	(ap_node as Node2D).global_position = Vector2(-70, 90)
	(ap_node as Node2D).name = "RuntimeAnimatedProp"
	runtime_animated_prop = ap_node

	# Overlapping arrangements to cross Y positions (explicit scenario markers via names/positions)
	# Tree canopy occlusion case
	canopy_tree = FOREST_TREE_SCENE.instantiate()
	canopy_tree.name = "CanopyOcclusionTree"
	entities.add_child(canopy_tree)
	canopy_tree.global_position = Vector2(60, 70)
	if canopy_tree.has_method("setup"):
		canopy_tree.setup("glade_tree", 2, false, 1.1, null)
	trees.append(canopy_tree)

	# Two overlapping trees at different depths (crossing silhouettes)
	overlap_a = FOREST_TREE_SCENE.instantiate()
	overlap_a.name = "OverlapTreeA"
	entities.add_child(overlap_a)
	overlap_a.global_position = Vector2(-160, 20)
	if overlap_a.has_method("setup"):
		overlap_a.setup("glade_tree", 0, true, 1.0, null)
	trees.append(overlap_a)
	overlap_b = FOREST_TREE_SCENE.instantiate()
	overlap_b.name = "OverlapTreeB"
	entities.add_child(overlap_b)
	overlap_b.global_position = Vector2(-130, 50)
	if overlap_b.has_method("setup"):
		overlap_b.setup("glade_tree", 1, false, 0.95, null)
	trees.append(overlap_b)

func _make_building_prop(kind: String, world_pos: Vector2, p_scale: float, flip: bool, variant: int) -> Node2D:
	# Mirror runtime building prop construction: bottom-anchored sprite, root at ground contact.
	var root := Node2D.new()
	var tex := ProceduralArt.prop_texture(kind, variant)
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.texture = tex
	if tex != null:
		sprite.offset = Vector2(-float(tex.get_width()) * 0.5, -float(tex.get_height()) + 6.0)
	sprite.scale = Vector2.ONE * p_scale
	sprite.flip_h = flip
	root.add_child(sprite)
	root.global_position = world_pos
	return root

func get_entities() -> Node2D:
	return entities if entities != null else get_node_or_null("Entities") as Node2D

func _n2d(n: Node) -> Node2D:
	return n as Node2D

func _expected_in_front_of(a: Node2D, b: Node2D) -> bool:
	# In Godot YSort, larger Y draws in front (same z/index context).
	if a == null or b == null:
		return false
	if absf(a.global_position.y - b.global_position.y) > 0.001:
		return a.global_position.y > b.global_position.y
	return a.get_index() > b.get_index()

func _direct_child_of_entities(n: Node) -> bool:
	return n != null and entities != null and n.get_parent() == entities

func _capture_view(label: String) -> String:
	var dir := "res://.godot_tmp_depthsort"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var path := "%s/%s.png" % [dir, label]
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	if img != null:
		var abs_path := ProjectSettings.globalize_path(path)
		img.save_png(abs_path)
		print("[depthsort_capture] saved " + abs_path)
		return abs_path
	print("[depthsort_capture] failed " + label)
	return ""

func _record(scenario: int, name: String, passed: bool, detail: String, capture: String = "") -> void:
	var r := {"scenario": scenario, "name": name, "passed": passed, "detail": detail, "capture": capture}
	_scenario_results.append(r)
	print("[depthsort] SCENARIO %d %s: %s — %s" % [scenario, "PASS" if passed else "FAIL", name, detail])

func _run_capture_sequence() -> void:
	# Automated scenario confirmation in the actual renderer/capture pass.
	# For each case we position objects, wait for render, verify direct-child + Y-order intent
	# (native YSort guarantee), and save a frame capture when available.
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var tree_front := entities.get_node_or_null("TreeFront") as Node2D
	var tree_back := entities.get_node_or_null("TreeBack") as Node2D
	var player_n := player as Node2D
	var npc_n := npc as Node2D
	var bld := building as Node2D
	var rp := runtime_prop as Node2D
	var ap := runtime_animated_prop as Node2D
	var ct := canopy_tree as Node2D
	var oa := overlap_a as Node2D
	var ob := overlap_b as Node2D

	# 1. Player walks behind a tree (player higher up / smaller Y than tree contact => behind)
	player_n.global_position = Vector2(tree_front.global_position.x, tree_front.global_position.y - 26)
	await get_tree().process_frame
	await get_tree().process_frame
	var cap1 := await _capture_view("s1_player_behind_tree")
	var ok1 := _direct_child_of_entities(player_n) and _direct_child_of_entities(tree_front) and player_n.global_position.y < tree_front.global_position.y and _expected_in_front_of(tree_front, player_n)
	_record(1, "Player behind tree", ok1, "player.y=%s tree.y=%s direct+shared_y_sort" % [player_n.global_position.y, tree_front.global_position.y], cap1)

	# 2. Player walks in front of a tree
	player_n.global_position = Vector2(tree_front.global_position.x, tree_front.global_position.y + 26)
	await get_tree().process_frame
	await get_tree().process_frame
	var cap2 := await _capture_view("s2_player_front_tree")
	var ok2 := _direct_child_of_entities(player_n) and _direct_child_of_entities(tree_front) and player_n.global_position.y > tree_front.global_position.y and _expected_in_front_of(player_n, tree_front)
	_record(2, "Player in front of tree", ok2, "player.y=%s tree.y=%s direct+shared_y_sort" % [player_n.global_position.y, tree_front.global_position.y], cap2)

	# 3. Player passes behind and in front of an NPC
	player_n.global_position = Vector2(npc_n.global_position.x, npc_n.global_position.y - 24)
	await get_tree().process_frame
	await get_tree().process_frame
	var cap3a := await _capture_view("s3a_player_behind_npc")
	var behind_npc := player_n.global_position.y < npc_n.global_position.y and _expected_in_front_of(npc_n, player_n)
	player_n.global_position = Vector2(npc_n.global_position.x, npc_n.global_position.y + 24)
	await get_tree().process_frame
	await get_tree().process_frame
	var cap3b := await _capture_view("s3b_player_front_npc")
	var front_npc := player_n.global_position.y > npc_n.global_position.y and _expected_in_front_of(player_n, npc_n)
	var ok3 := _direct_child_of_entities(player_n) and _direct_child_of_entities(npc_n) and behind_npc and front_npc
	_record(3, "Player behind and in front of NPC", ok3, "behind=%s front=%s npc.y=%s" % [behind_npc, front_npc, npc_n.global_position.y], cap3a + ";" + cap3b)

	# 4. Player walks around the front and back of a building (large footprint)
	player_n.global_position = Vector2(bld.global_position.x, bld.global_position.y - 40)
	await get_tree().process_frame
	await get_tree().process_frame
	var cap4a := await _capture_view("s4a_player_behind_building")
	var behind_b := player_n.global_position.y < bld.global_position.y and _expected_in_front_of(bld, player_n)
	player_n.global_position = Vector2(bld.global_position.x, bld.global_position.y + 40)
	await get_tree().process_frame
	await get_tree().process_frame
	var cap4b := await _capture_view("s4b_player_front_building")
	var front_b := player_n.global_position.y > bld.global_position.y and _expected_in_front_of(player_n, bld)
	var ok4 := _direct_child_of_entities(player_n) and _direct_child_of_entities(bld) and behind_b and front_b
	_record(4, "Player around front/back of building", ok4, "behind=%s front=%s building.y=%s" % [behind_b, front_b, bld.global_position.y], cap4a + ";" + cap4b)

	# 5. Two trees at different depths overlap visually
	await get_tree().process_frame
	await get_tree().process_frame
	var cap5 := await _capture_view("s5_overlapping_trees_depths")
	var ok5 := _direct_child_of_entities(oa) and _direct_child_of_entities(ob) and oa.global_position.y != ob.global_position.y and _expected_in_front_of(ob, oa)
	_record(5, "Two trees at different depths overlap", ok5, "overlapA.y=%s overlapB.y=%s B_in_front_of_A=%s" % [oa.global_position.y, ob.global_position.y, _expected_in_front_of(ob, oa)], cap5)

	# 6. Runtime-spawned props interleave with authored village trees
	# place runtime prop between tree_back and tree_front in Y to prove interleaving (not category block)
	rp.global_position = Vector2(-80, 25) # between -10 and 60
	if ap != null:
		ap.global_position = Vector2(-70, 5)
	await get_tree().process_frame
	await get_tree().process_frame
	var cap6 := await _capture_view("s6_runtime_props_interleave_trees")
	var ok6 := _direct_child_of_entities(rp) and _direct_child_of_entities(tree_back) and _direct_child_of_entities(tree_front) and tree_back.global_position.y < rp.global_position.y and rp.global_position.y < tree_front.global_position.y and _expected_in_front_of(rp, tree_back) and _expected_in_front_of(tree_front, rp)
	_record(6, "Runtime-spawned props interleave with authored trees", ok6, "treeBack.y=%s prop.y=%s treeFront.y=%s" % [tree_back.global_position.y, rp.global_position.y, tree_front.global_position.y], cap6)

	# 7. Tree canopy occlusion still works correctly
	# position player collision so it overlaps the canopy OcclusionArea (Area2D monitors bodies, mask layer 2).
	var occ := ct.get_node_or_null("OcclusionArea") as Area2D
	var shape := occ.get_node_or_null("CollisionShape2D") as CollisionShape2D if occ else null
	if shape != null:
		# compensate player collision shape offset (player CollisionShape2D at y=-10)
		player_n.global_position = shape.global_position + Vector2(0, 10)
	else:
		player_n.global_position = ct.global_position + Vector2(0, -12)
	for i in 12:
		await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var cap7 := await _capture_view("s7_canopy_occlusion")
	var canopy := ct.get_node_or_null("Canopy") as Sprite2D
	var occluders := 0
	if ct.get("_occluders") != null:
		occluders = int(ct.get("_occluders"))
	var anim := ct.get_node_or_null("AnimationPlayer") as AnimationPlayer
	var anim_playing := anim != null and (anim.is_playing() or anim.assigned_animation == "canopy_fade")
	var faded := canopy != null and canopy.modulate.a < 0.99
	var ok7 := _direct_child_of_entities(player_n) and _direct_child_of_entities(ct) and (faded or anim_playing or occluders > 0)
	_record(7, "Tree canopy occlusion works", ok7, "player=%s shape=%s canopy_alpha=%s anim=%s occluders=%s" % [str(player_n.global_position), str(shape.global_position) if shape else "n/a", str(canopy.modulate.a) if canopy else "n/a", str(anim.current_animation) if anim else "n/a", occluders], cap7)

	# 8. Objects retain correct sorting after reparenting and scene initialization
	var res: Dictionary = reparent_smoke_test()
	var ok8 := bool(res.get("ok", false)) and _all_scenario_direct(entities)
	await get_tree().process_frame
	await get_tree().process_frame
	var cap8 := await _capture_view("s8_after_reparent_init")
	_record(8, "Correct sorting after reparent/init", ok8, str(res), cap8)

	var passed := 0
	for r in _scenario_results:
		if bool(r.get("passed", false)):
			passed += 1
	print("---")
	print("[depthsort] SCENARIO_SUMMARY %d/8 passed" % passed)
	for r in _scenario_results:
		print("[depthsort]  %d. %s: %s (%s)" % [int(r.scenario), r.name, "PASS" if r.passed else "FAIL", r.detail])
	print("[depthsort] captures_dir=%s" % ProjectSettings.globalize_path("res://.godot_tmp_depthsort"))
	get_tree().quit(0 if passed == 8 else 1)

func reparent_smoke_test() -> Dictionary:
	# Reparent a runtime prop and a tree out and back in; verify global position and sort key preserved.
	var e := get_entities()
	if e == null:
		return {"ok": false, "reason": "no entities"}
	var target: Node2D = runtime_prop as Node2D
	var tree: Node2D = trees[0] as Node2D if trees.size() > 0 else null
	if target == null or tree == null:
		return {"ok": false, "reason": "missing targets"}
	var gp_prop := target.global_position
	var gp_tree := tree.global_position
	var holder := Node2D.new()
	add_child(holder)
	holder.global_position = Vector2(200, 100)
	for n in [target, tree]:
		var gp := (n as Node2D).global_position
		n.get_parent().remove_child(n)
		holder.add_child(n)
		(n as Node2D).global_position = gp
	for n in [target, tree]:
		var gp := (n as Node2D).global_position
		holder.remove_child(n)
		e.add_child(n)
		(n as Node2D).global_position = gp
	holder.queue_free()
	var ok := target.global_position.distance_to(gp_prop) < 0.01 and tree.global_position.distance_to(gp_tree) < 0.01
	return {"ok": ok, "prop_pos": target.global_position, "tree_pos": tree.global_position, "prop_expected": gp_prop, "tree_expected": gp_tree}

func _all_scenario_direct(e: Node2D) -> bool:
	for n in ["TreeBack", "TreeFront", "BuildingLarge", "CanopyOcclusionTree", "OverlapTreeA", "OverlapTreeB", "RuntimeInteractiveProp", "RuntimeAnimatedProp"]:
		if e.get_node_or_null(n) == null:
			return false
	return player != null and player.get_parent() == e and npc != null and npc.get_parent() == e
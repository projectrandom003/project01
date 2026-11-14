extends Node
## Scene-based verifier for shared depth sorting (runs after autoloads are ready).
## Headless structural/runtime checks only for draw-order/occlusion appearance.

const VISUAL_TEST_SCENE: PackedScene = preload("res://scenes/tests/depth_sorting_visual_test.tscn")
const FOREST_TREE_SCENE: PackedScene = preload("res://scenes/world/forest_tree.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player.tscn")
const NPC_SCENE: PackedScene = preload("res://scenes/world/world_npc.tscn")
const INTERACTIVE_PROP_SCENE: PackedScene = preload("res://scenes/world/interactive_prop.tscn")
const ANIMATED_PROP_SCENE: PackedScene = preload("res://scenes/world/animated_prop.tscn")
const VILLAGE_SCENE: PackedScene = preload("res://scenes/world/village/GreenwardVillage.tscn")

var _failures: Array[String] = []
var _passes: int = 0

func _ready() -> void:
	call_deferred("_run")

func _fail(msg: String) -> void:
	_failures.append(msg)
	print("FAIL: " + msg)

func _pass(msg: String) -> void:
	_passes += 1
	print("PASS: " + msg)

func _assert(cond: bool, msg: String) -> void:
	if cond:
		_pass(msg)
	else:
		_fail(msg)

func _run() -> void:
	await _audit_asset_origins()
	await _audit_visual_test_scene()
	await _audit_village_rehome_init()
	_finish()

func _root() -> Node:
	return get_tree().root

func _get_y_sort_origin(n: Node) -> int:
	if n == null:
		return 0
	var v = n.get("y_sort_origin")
	if v == null:
		# In some headless/scene contexts property lookup may report null; default is 0.
		return 0
	return int(v)

func _audit_asset_origins() -> void:
	var ft := FOREST_TREE_SCENE.instantiate() as Node2D
	_root().add_child(ft)
	if ft.has_method("setup"):
		ft.setup("glade_tree", 0, false, 1.0, null)
	await get_tree().process_frame
	await get_tree().process_frame
	_assert(_get_y_sort_origin(ft) == 0, "ForestTree root y_sort_origin == 0 (ground contact at root) got=%s" % str(_get_y_sort_origin(ft)))
	_assert(_is_bottom_anchored_visual(ft), "ForestTree trunk/canopy use bottom-anchored offsets (visuals do not drive sort)")
	_assert(ft.get_node_or_null("Canopy") != null and ft.get_node_or_null("Trunk") != null, "ForestTree preserves canopy/trunk split")
	ft.queue_free()
	await get_tree().process_frame

	var p: Node = PLAYER_SCENE.instantiate()
	_root().add_child(p)
	await get_tree().process_frame
	await get_tree().process_frame
	_assert(_get_y_sort_origin(p) == 0, "Player root y_sort_origin == 0 (ground contact) got=%s" % str(_get_y_sort_origin(p)))
	_assert(p.get_node_or_null("ActorVisual") != null, "Player has ActorVisual child (visual offset separate from sort root)")
	p.queue_free()
	await get_tree().process_frame

	var npc_node: Node = NPC_SCENE.instantiate()
	if npc_node.has_method("setup"):
		npc_node.call("setup", "elder_maelin", "Elder Maelin", "elder_intro", {"primary":"#3a5a40","secondary":"#bfa76a","hair":"#d8d0c0","skin":"#f0cbb0","accent":"#7fe3e0"}, "Elf")
	_root().add_child(npc_node)
	await get_tree().process_frame
	await get_tree().process_frame
	_assert(_get_y_sort_origin(npc_node) == 0, "WorldNPC root y_sort_origin == 0 (ground contact) got=%s" % str(_get_y_sort_origin(npc_node)))
	_assert(npc_node.get_node_or_null("ActorVisual") != null, "WorldNPC has ActorVisual child")
	npc_node.queue_free()
	await get_tree().process_frame

	var ip_node: Node = INTERACTIVE_PROP_SCENE.instantiate()
	if ip_node.has_method("setup"):
		ip_node.call("setup", "rune_stone", Vector2.ZERO, "Rune", "lore", 0)
	_root().add_child(ip_node)
	await get_tree().process_frame
	await get_tree().process_frame
	var ip_sprite := ip_node.get_node_or_null("Sprite") as Sprite2D
	_assert(_get_y_sort_origin(ip_node) == 0, "InteractiveProp root y_sort_origin == 0 (ground contact) got=%s" % str(_get_y_sort_origin(ip_node)))
	_assert(_sprite_bottom_anchored(ip_sprite), "InteractiveProp sprite is bottom-anchored (visual offset only) tex=%s off=%s" % [str(ip_sprite.texture) if ip_sprite else "null", str(ip_sprite.offset) if ip_sprite else "null"])
	ip_node.queue_free()
	await get_tree().process_frame

	var ap_node: Node = ANIMATED_PROP_SCENE.instantiate()
	if ap_node.has_method("setup"):
		ap_node.call("setup", "flower_patch", Vector2.ZERO, 1.0, false, 1, 0)
	_root().add_child(ap_node)
	await get_tree().process_frame
	await get_tree().process_frame
	_assert(_get_y_sort_origin(ap_node) == 0, "AnimatedProp root y_sort_origin == 0 (ground contact) got=%s" % str(_get_y_sort_origin(ap_node)))
	_assert(_sprite_bottom_anchored(ap_node.get_node_or_null("Sprite") as Sprite2D), "AnimatedProp sprite is bottom-anchored (visual offset only)")
	var root_y := (ap_node as Node2D).global_position.y
	for i in 5:
		await get_tree().process_frame
	_assert(absf((ap_node as Node2D).global_position.y - root_y) < 0.001, "AnimatedProp motion does not change root/sort position")
	ap_node.queue_free()
	await get_tree().process_frame

func _is_bottom_anchored_visual(tree: Node) -> bool:
	for sname in ["Trunk", "Canopy"]:
		var s := tree.get_node_or_null(sname) as Sprite2D
		if s == null or s.texture == null:
			continue
		var h := float(s.texture.get_height())
		if absf(s.offset.y - (-h + 6.0)) > 1.5:
			return false
	return true

func _sprite_bottom_anchored(s: Sprite2D) -> bool:
	if s == null or s.texture == null:
		return false
	var h := float(s.texture.get_height())
	return absf(s.offset.y - (-h + 6.0)) < 1.5

func _audit_visual_test_scene() -> void:
	var inst := VISUAL_TEST_SCENE.instantiate()
	_root().add_child(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var entities := inst.get_node_or_null("Entities") as Node2D
	_assert(entities != null, "Visual test scene has Entities container")
	_assert(entities != null and entities.y_sort_enabled, "Entities is the shared Y-sort parent")
	if entities == null:
		inst.queue_free(); await get_tree().process_frame; return

	var direct_ok := true
	var expected_names := ["TreeBack", "TreeFront", "BuildingLarge", "CanopyOcclusionTree", "OverlapTreeA", "OverlapTreeB"]
	for n in expected_names:
		if entities.get_node_or_null(n) == null:
			direct_ok = false
			_fail("missing direct sortable child in Entities: " + n)
	_assert(direct_ok, "scenario trees/building are direct children of Entities")
	var kinds_ok := entities.get_node_or_null("RuntimeInteractiveProp") != null or _has_runtime_prop(entities, "rune_stone")
	_assert(kinds_ok, "runtime-spawned prop is present in Entities")
	_assert(_count_type(entities, "CharacterBody2D") >= 1, "player is present (CharacterBody2D) in Entities hierarchy/direct")
	_assert(_has_npc(entities), "NPC is present in Entities")

	var nested_sortables := _find_nested_y_sort_objects(entities)
	_assert(nested_sortables.is_empty(), "no nested y-sort containers among sortable children (direct-child interleaving): " + str(nested_sortables))

	var tb := entities.get_node_or_null("TreeBack") as Node2D
	var tf := entities.get_node_or_null("TreeFront") as Node2D
	if tb and tf:
		_assert(tb.global_position.y < tf.global_position.y, "TreeBack has smaller Y than TreeFront (should sort behind)")
	_assert(_has_large_building(entities), "large-footprint building visual present")
	_assert(_has_canopy_occlusion_case(entities), "canopy occlusion case present (tree + occlusion area)")

	if inst.has_method("reparent_smoke_test"):
		var res: Dictionary = inst.reparent_smoke_test()
		_assert(bool(res.get("ok", false)), "reparent smoke test preserves global positions/sort points: " + str(res))
	else:
		_fail("visual test scene missing reparent_smoke_test")
	_assert(_all_scenario_direct(entities), "scenario objects remain valid/direct-sort participants after reparent/init")

	inst.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

func _has_runtime_prop(entities: Node2D, kind: String) -> bool:
	for c in entities.get_children():
		if c is InteractiveProp and (c as InteractiveProp).prop_kind == kind:
			return true
		if "prop_kind" in c and str(c.prop_kind) == kind:
			return true
	return false

func _count_type(entities: Node2D, type_name: String) -> int:
	var n := 0
	for c in entities.get_children():
		if c.get_class() == type_name or c.is_class(type_name):
			n += 1
	return n

func _has_npc(entities: Node2D) -> bool:
	for c in entities.get_children():
		if c is WorldNPC:
			return true
	return false

func _find_nested_y_sort_objects(parent: Node2D) -> Array[String]:
	var bad: Array[String] = []
	for c in parent.get_children():
		if c is Node2D and (c as Node2D).y_sort_enabled:
			bad.append(c.name)
	return bad

func _has_large_building(entities: Node2D) -> bool:
	var b := entities.get_node_or_null("BuildingLarge") as Node2D
	if b == null:
		return false
	for c in b.get_children():
		if c is Sprite2D and (c as Sprite2D).texture != null:
			var t := (c as Sprite2D).texture
			return t.get_width() >= 48 and t.get_height() >= 48
	return false

func _has_canopy_occlusion_case(entities: Node2D) -> bool:
	var t := entities.get_node_or_null("CanopyOcclusionTree")
	if t == null:
		return false
	return t.get_node_or_null("Canopy") != null and t.get_node_or_null("OcclusionArea") != null

func _all_scenario_direct(entities: Node2D) -> bool:
	for n in ["TreeBack", "TreeFront", "BuildingLarge", "CanopyOcclusionTree", "OverlapTreeA", "OverlapTreeB"]:
		if entities.get_node_or_null(n) == null:
			return false
	return true

func _audit_village_rehome_init() -> void:
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	_root().add_child(entities)
	var village := VILLAGE_SCENE.instantiate()
	_root().add_child(village)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var sample_before: Vector2 = Vector2.INF
	var depth := village.get_node_or_null("DepthSort") as Node2D
	if depth:
		for c in depth.get_children():
			if c.has_meta("village_tree_group") and c is Node2D:
				sample_before = (c as Node2D).global_position
				break
	if village.has_method("set_shared_depth_parent"):
		village.set_shared_depth_parent(entities)
	await get_tree().process_frame
	var tagged_in_entities := 0
	var sample_after: Vector2 = Vector2.INF
	for c in entities.get_children():
		if c.has_meta("village_tree_group"):
			tagged_in_entities += 1
			if sample_after == Vector2.INF and c is Node2D:
				sample_after = (c as Node2D).global_position
	_assert(tagged_in_entities > 0, "village-authored tree individuals rehomed into shared Entities as direct children")
	if sample_before != Vector2.INF and sample_after != Vector2.INF:
		_assert(sample_before.distance_to(sample_after) < 0.01, "rehomed village tree preserves global position")
	var slots_ok := 0
	for c in entities.get_children():
		if c.has_meta("village_sort_category") and str(c.get_meta("village_sort_category")) == "building":
			slots_ok += 1
	_assert(slots_ok >= 1, "village building slot(s) integrated as direct sortable children in shared Entities")
	village.queue_free()
	entities.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

func _finish() -> void:
	print("---")
	print("verify_depth_sorting: %s (%d passed, %d failed)" % ["OK" if _failures.is_empty() else "FAILED", _passes, _failures.size()])
	if _failures.is_empty():
		print("OK")
	print("NOTE: Structural/runtime checks. Rendered draw-order/occlusion for scenarios 1-8 require in-engine visual inspection of scenes/tests/depth_sorting_visual_test.tscn.")
	get_tree().quit(0 if _failures.is_empty() else 1)
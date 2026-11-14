extends SceneTree

const VILLAGE_SCENE: PackedScene = preload("res://scenes/environment/village/village_environment.tscn")
const ANCHOR_SCENE: PackedScene = preload("res://scenes/environment/village/village_anchor.tscn")
const PROP_SCENE: PackedScene = preload("res://scenes/environment/forest/forest_prop.tscn")

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var village := VILLAGE_SCENE.instantiate() as ModularVillageEnvironment
	root.add_child(village)
	await process_frame
	_check(village != null, "village composition root instantiates")
	_check(village.get_node_or_null("PathNetwork") != null, "path layer exists")
	_check(village.get_node_or_null("Buildings").y_sort_enabled, "buildings use y-sort")
	_check(village.get_node_or_null("TreeGroups").y_sort_enabled, "tree groups use y-sort")
	_check(village.get_node_or_null("NPCs").y_sort_enabled, "NPCs use y-sort")
	var path: Node2D = village.add_path(PackedVector2Array([Vector2.ZERO, Vector2(80, 20), Vector2(140, 90)]), 38.0)
	_check(path != null, "authored path segment instantiates")
	var surface := path.get_node("Surface") as Line2D if path != null else null
	_check(surface != null and surface.points.size() == 3, "path geometry reaches surface node")
	_check(surface != null and is_equal_approx(surface.width, 38.0), "path width is configurable")
	var anchor := ANCHOR_SCENE.instantiate() as VillagePlacementAnchor
	anchor.anchor_id = &"north_oak"
	anchor.anchor_role = "tree"
	anchor.scene_to_place = PROP_SCENE
	anchor.position = Vector2(240, 120)
	village.add_child(anchor)
	_check(anchor.resolve_variant(712) == anchor.resolve_variant(712), "anchor variant is deterministic")
	_check(village.build_from_anchors() == 1, "authored anchor builds one instance")
	_check(village.tree_groups.get_child_count() == 1, "tree anchor routes to tree layer")
	_check(village.tree_groups.get_child(0).position == anchor.position, "authored anchor position is preserved")
	village.clear_generated()
	await process_frame
	_check(village.paths.get_child_count() == 0, "generated path layer clears")
	_check(village.tree_groups.get_child_count() == 0, "generated tree layer clears")
	print("[modular_village] %s — %d checks, %d failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("[modular_village] FAIL: " + label)

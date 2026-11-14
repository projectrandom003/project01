extends SceneTree

const ROOT_SCENE: PackedScene = preload("res://scenes/world/village/VillageEnvironment.tscn")
const PATH_SCENE: PackedScene = preload("res://scenes/world/village/VillagePathSegment.tscn")
const LIGHT_SCENE: PackedScene = preload("res://scenes/world/village/VillageLightSource.tscn")
const TREE_GROUP_SCENE: PackedScene = preload("res://scenes/world/village/TreeGroup.tscn")
const BUILDING_SLOT_SCENE: PackedScene = preload("res://scenes/world/village/VillageBuildingSlot.tscn")
const LAYOUT_RESOURCE: Resource = preload("res://resources/data/village/greenward_village_layout.tres")

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var village := ROOT_SCENE.instantiate() as VillageEnvironment
	root.add_child(village)
	await process_frame
	_check(village != null, "canonical VillageEnvironment instantiates")
	for node_name in ["Ground", "PathNetwork", "DepthSort", "Logic", "Lighting", "AmbientEffects"]:
		_check(village.get_node_or_null(node_name) != null, "canonical hierarchy contains " + node_name)
	for logical_group in [village.buildings, village.tree_groups, village.vegetation, village.furniture, village.npcs, village.interactive_locations]:
		_check(logical_group != null, "logical group alias resolves to an authored node")
	_check(village.depth_sort.y_sort_enabled, "shared visual depth-sort layer is y-sorted")
	_check(village.path_network.get_node_or_null("EntranceDistrict") == null, "base environment stays reusable; district composition belongs to GreenwardVillage")
	var layout := LAYOUT_RESOURCE as VillageLayoutConfig
	_check(layout != null, "Greenward layout resource has expected class")
	_check(layout != null and layout.anchors.has("village_entrance") and layout.anchors.has("central_square"), "layout defines entrance and central square")
	var rng_a: RandomNumberGenerator = layout.stable_rng("tree_decor")
	var rng_b: RandomNumberGenerator = layout.stable_rng("tree_decor")
	_check(rng_a.randi() == rng_b.randi(), "layout RNG is repeatable for a stream")
	var path := PATH_SCENE.instantiate() as VillagePathSegment
	_check(path != null, "path scene uses path component script")
	_check(path.traversable, "path defaults to traversable")
	_check(path.get_node_or_null("Visual/Surface") is Polygon2D, "path has Polygon2D surface child")
	_check(path.get_node_or_null("Visual/Edge") is Line2D, "path has Line2D edge child")
	var light := LIGHT_SCENE.instantiate() as VillageLightSource
	light.night_only = true
	village.lighting.add_child(light)
	light.set_phase_energy(0.35, true)
	await process_frame
	var point_light := light.get_node("PointLight2D") as PointLight2D
	_check(point_light.enabled and is_equal_approx(point_light.energy, light.base_energy * 0.35), "night phase applies configured light energy")
	light.set_phase_energy(0.8, false)
	_check(not point_light.enabled, "night-only light disables during day")
	var tree_group := TREE_GROUP_SCENE.instantiate()
	_check(tree_group.get_node_or_null("Anchors") != null, "tree group provides anchor node")
	_check(tree_group.get_node_or_null("Clearings") != null, "tree group provides clearing node")
	var building_slot := BUILDING_SLOT_SCENE.instantiate()
	var building_component: Node2D = building_slot.get_node_or_null("Building") as Node2D
	_check(building_component != null, "building slot instances reusable node-authored building component")
	_check(building_component != null and building_component.get_node_or_null("Visual/Sprite") is Sprite2D, "building visual is an authored Sprite2D child")
	_check(building_component != null and building_component.get_node_or_null("Collision") is Node2D, "building exposes dedicated collision node")
	_check(building_component != null and building_component.get_node_or_null("Interaction") is Area2D, "building interaction uses an Area2D node")
	_check(building_component != null and building_component.get_node_or_null("Interaction/CollisionShape") is CollisionShape2D, "building interaction shape is an authored collision child")
	_check(building_component != null and building_component.get_node_or_null("Animation") is AnimationPlayer, "building owns an AnimationPlayer node")
	if building_component != null:
		building_component.set("interaction_enabled", true)
		var interaction_area := building_component.get_node("Interaction") as Area2D
		var interaction_shape := building_component.get_node("Interaction/CollisionShape") as CollisionShape2D
		_check(interaction_area.monitoring, "interaction toggle enables Area2D monitoring")
		_check(not interaction_shape.disabled, "interaction toggle enables authored shape")
		building_component.set("interaction_enabled", false)
		_check(not interaction_area.monitoring, "interaction toggle disables Area2D monitoring")
	print("[village_phase1_scaffold] %s — %d checks, %d failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	village.queue_free()
	path.free()
	tree_group.free()
	building_slot.free()
	await process_frame
	quit(0 if failures == 0 else 1)

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("[village_phase1_scaffold] FAIL: " + label)



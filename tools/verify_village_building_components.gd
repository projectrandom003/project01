extends Node
## Regression test: authored village building slots own their rendered components.

const VILLAGE_SCENE: PackedScene = preload("res://scenes/world/village/GreenwardVillage.tscn")
const EXPECTED := {
	"HomeNW": [&"home_nw", "cottage", 0, 0.96, false],
	"HomeNE": [&"home_ne", "hut", 1, 0.94, true],
	"HomeSW": [&"home_sw", "cottage", 1, 0.94, false],
	"HomeSE": [&"home_se", "hut", 2, 0.92, false],
	"Well": [&"well", "well", 1, 1.08, false],
	"MarketStall": [&"market_stall", "market_stall", 0, 0.92, false],
	"Shrine": [&"shrine", "shrine", 0, 1.02, false],
}

var checks := 0
var failures := 0

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var village := VILLAGE_SCENE.instantiate() as Node2D
	add_child(village)
	await get_tree().process_frame
	for slot_name in EXPECTED:
		var spec: Array = EXPECTED[slot_name]
		var slot := village.get_node_or_null("DepthSort/" + slot_name) as Node2D
		_check(slot != null, slot_name + " slot exists")
		if slot == null:
			continue
		var building := slot.get_node_or_null("Building") as Node2D
		_check(building != null, slot_name + " owns Building child")
		if building == null:
			continue
		_check(building.get_script() != null and building.get_script().resource_path.ends_with("village_building_component.gd"), slot_name + " uses reusable component script")
		_check(building.get("building_id") == spec[0], slot_name + " stable building ID")
		_check(building.get("building_kind") == spec[1], slot_name + " visual kind")
		_check(building.get("visual_variant") == spec[2], slot_name + " original variant preserved")
		_check(is_equal_approx(float(building.get("visual_scale")), float(spec[3])), slot_name + " original scale preserved")
		_check(building.get("visual_flip_h") == spec[4], slot_name + " original facing preserved")
		var sprite := building.get_node_or_null("Visual/Sprite") as Sprite2D
		_check(sprite != null and sprite.texture != null, slot_name + " generates its building texture")
		if sprite != null:
			_check(sprite.texture != null and not sprite.centered, slot_name + " retains bottom-anchored sprite")
		_check(slot.get_node_or_null("Building/Collision") is Node2D, slot_name + " owns collision authoring node")
		var body := slot.get_node_or_null("Building/Collision/StaticBody2D") as StaticBody2D
		_check(body != null, slot_name + " owns a StaticBody2D footprint")
		if body != null:
			_check(body.collision_layer == 1 and body.collision_mask == 0, slot_name + " uses world-obstacle collision layer")
		var solid := slot.get_node_or_null("Building/Collision/StaticBody2D/CollisionShape") as CollisionShape2D
		_check(solid != null and not solid.disabled, slot_name + " has an enabled authored collision shape")
		if solid != null and solid.shape is RectangleShape2D:
			_check((solid.shape as RectangleShape2D).size.is_equal_approx(building.get("collision_size")), slot_name + " collision dimensions match inspector settings")
		_check(slot.get_node_or_null("Building/Interaction") is Area2D, slot_name + " owns interaction Area2D")
		_check(building is Interactable, slot_name + " participates in the shared Interactable system")
		if building is Interactable:
			var interactable := building as Interactable
			_check(not interactable.can_interact(), slot_name + " remains non-interactive until explicitly enabled")
			_check(interactable.prompt == "Enter", slot_name + " exposes the configured interaction prompt")
			_check(is_equal_approx(interactable.interaction_radius, 96.0), slot_name + " uses the configured detection radius")
		_check(building.has_signal("interaction_requested"), slot_name + " exposes an interaction event")
		_check(slot.get_node_or_null("Building/Animation") is AnimationPlayer, slot_name + " owns AnimationPlayer")
	var test_building := village.get_node("DepthSort/HomeNW/Building") as VillageBuildingComponent
	var interaction_count := [0]
	test_building.interaction_requested.connect(func(): interaction_count[0] += 1)
	test_building.interaction_enabled = true
	_check(test_building.can_interact(), "explicitly enabled building enters the shared interaction flow")
	_check(get_tree().get_nodes_in_group("interactables").has(test_building), "enabled building is discoverable by the player's interactable scan")
	test_building.interact()
	_check(interaction_count[0] == 1, "building interaction emits exactly one interaction event")
	test_building.interaction_enabled = false
	_check(not test_building.can_interact(), "building can be safely disabled after interaction")
	for legacy_name in ["HomeNWVisual", "HomeNEVisual", "HomeSWVisual", "HomeSEVisual", "WellVisual", "MarketStallVisual", "ShrineVisual"]:
		_check(village.get_node_or_null("DepthSort/" + legacy_name) == null, legacy_name + " legacy duplicate removed")
	print("[village_building_components] %s — %d checks, %d failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	village.queue_free()
	await get_tree().process_frame
	get_tree().quit(0 if failures == 0 else 1)

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("[village_building_components] FAIL: " + label)

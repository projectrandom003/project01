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
	var obstacle_sizes := {
		"VillageGateProp": Vector2(112, 24), "EntranceSign": Vector2(16, 14),
		"SquareBenchA": Vector2(42, 14), "SquareBenchB": Vector2(42, 14),
		"MarketCart": Vector2(52, 26), "MarketCrateA": Vector2(26, 20),
		"MarketBarrelA": Vector2(22, 20), "MarketSign": Vector2(16, 14),
		"MarketStallB": Vector2(62, 24), "ElderBanner": Vector2(16, 22),
		"ElderBench": Vector2(42, 14), "ResidentialFenceNW1": Vector2(48, 12),
		"ResidentialFenceNW2": Vector2(48, 12), "ResidentialBenchNE": Vector2(38, 13),
		"ResidentialBushNE": Vector2(26, 16), "ResidentialFenceSW": Vector2(46, 12),
		"ResidentialBarrelSE": Vector2(22, 20), "ResidentialCrateSE": Vector2(26, 20),
	}
	var prop_shape_ids: Array[int] = []
	for prop_name in obstacle_sizes:
		var prop := village.get_node_or_null("DepthSort/" + prop_name) as VillageProp
		_check(prop != null, prop_name + " is an authored reusable village prop")
		if prop == null:
			continue
		_check(prop.blocks_movement, prop_name + " blocks player movement")
		var prop_body := prop.get_node_or_null("Collision/StaticBody2D") as StaticBody2D
		_check(prop_body != null and prop_body.collision_layer == 1 and prop_body.collision_mask == 0, prop_name + " uses world obstacle collision layer")
		var prop_shape := prop.get_node_or_null("Collision/StaticBody2D/CollisionShape") as CollisionShape2D
		_check(prop_shape != null and not prop_shape.disabled, prop_name + " has enabled collision shape")
		if prop_shape != null and prop_shape.shape is RectangleShape2D:
			_check((prop_shape.shape as RectangleShape2D).size.is_equal_approx(obstacle_sizes[prop_name]), prop_name + " has its individual authored footprint")
			prop_shape_ids.append(prop_shape.shape.get_instance_id())
	_check(prop_shape_ids.size() == obstacle_sizes.size(), "all obstacle props own independent rectangle resources")
	var unique_prop_shape_ids := {}
	for shape_id in prop_shape_ids:
		unique_prop_shape_ids[shape_id] = true
	_check(unique_prop_shape_ids.size() == obstacle_sizes.size(), "obstacle prop collision resources are not shared")
	for decorative_name in ["SquareFlowersA", "SquareFlowersB", "ResidentialGardenNW", "ResidentialGardenSW", "ShrineBloomA", "ShrineBloomB", "RiversideReedsA", "RiversideReedsB", "RiversideLantern"]:
		var decorative := village.get_node_or_null("DepthSort/" + decorative_name) as VillageProp
		_check(decorative != null and not decorative.blocks_movement, decorative_name + " remains non-blocking decoration")
	var physics_player := CharacterBody2D.new()
	physics_player.name = "CollisionRegressionPlayer"
	physics_player.collision_layer = 2
	physics_player.collision_mask = 1
	var player_shape := CollisionShape2D.new()
	var player_capsule := CapsuleShape2D.new()
	player_capsule.radius = 9.0
	player_capsule.height = 22.0
	player_shape.shape = player_capsule
	player_shape.position = Vector2(0, -10)
	physics_player.add_child(player_shape)
	village.add_child(physics_player)
	await get_tree().physics_frame
	for prop_name in obstacle_sizes:
		var obstacle := village.get_node("DepthSort/" + prop_name) as VillageProp
		_check_movement_blocked(physics_player, obstacle, obstacle.collision_size, obstacle.collision_offset, prop_name)
	_check_movement_blocked(physics_player, village.get_node("DepthSort/HomeNW/Building") as VillageBuildingComponent, Vector2(96, 30), Vector2(0, -8), "northwest cottage")
	var flowers := village.get_node("DepthSort/SquareFlowersA") as VillageProp
	physics_player.global_position = flowers.global_position + Vector2(-60, 4)
	var flower_collision := KinematicCollision2D.new()
	var flower_blocked := physics_player.test_move(physics_player.global_transform, Vector2(120, 0), flower_collision)
	_check(not flower_blocked, "decorative flower cluster does not block player movement")
	physics_player.queue_free()
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

func _check_movement_blocked(body: CharacterBody2D, obstacle: Node2D, footprint: Vector2, offset: Vector2, label: String) -> void:
	body.global_position = obstacle.global_position + Vector2(-60.0, offset.y + 10.0)
	var collision := KinematicCollision2D.new()
	var blocked := body.test_move(body.global_transform, Vector2(120.0, 0.0), collision)
	_check(blocked, label + " physically blocks a layer-2 player moving through it")
	if blocked:
		_check(collision.get_collider() is StaticBody2D, label + " collision resolves against its StaticBody2D")
		_check(collision.get_travel().length() < 120.0, label + " stops movement before the obstacle")

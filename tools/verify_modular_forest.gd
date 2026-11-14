extends SceneTree

const ENVIRONMENT_SCENE := preload("res://scenes/environment/forest/forest_environment.tscn")
const ROCK_SCENE := preload("res://scenes/environment/forest/forest_rock.tscn")
const LOG_SCENE := preload("res://scenes/environment/forest/forest_fallen_log.tscn")
const WILLOW_SCENE := preload("res://scenes/environment/forest/forest_willow_tree.tscn")
const BIRCH_SCENE := preload("res://scenes/environment/forest/forest_birch_tree.tscn")
const PINE_SCENE := preload("res://scenes/environment/forest/forest_pine_tree.tscn")
const BLOSSOM_SCENE := preload("res://scenes/environment/forest/forest_blossom_tree.tscn")
const DEAD_TREE_SCENE := preload("res://scenes/environment/forest/forest_dead_tree.tscn")
const SHRUB_SCENE := preload("res://scenes/environment/forest/forest_shrub.tscn")
const BERRY_SCENE := preload("res://scenes/environment/forest/forest_berry_bush.tscn")
const FLOWER_SCENE := preload("res://scenes/environment/forest/forest_flower_patch.tscn")
const MUSHROOM_SCENE := preload("res://scenes/environment/forest/forest_mushroom_patch.tscn")
const FERN_SCENE := preload("res://scenes/environment/forest/forest_fern_patch.tscn")
const REED_SCENE := preload("res://scenes/environment/forest/forest_reed_patch.tscn")
const CRYSTAL_SCENE := preload("res://scenes/environment/forest/forest_crystal_cluster.tscn")
const RUNE_SCENE := preload("res://scenes/environment/forest/forest_rune_stone.tscn")
const GREENWARD_PROFILE := preload("res://resources/environment/forest/greenward_forest.tres")
const MOONPETAL_PROFILE := preload("res://resources/environment/forest/moonpetal_hollow.tres")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var environment := ENVIRONMENT_SCENE.instantiate() as ModularForestEnvironment
	root.add_child(environment)
	await process_frame
	_check(environment != null, "environment scene instantiates")
	_check(environment.get_node_or_null("WorldObjects") != null, "shared world-object layer exists")
	_check(environment.get_node_or_null("GroundDetails") != null, "ground-detail layer exists")
	_check(environment.get_node_or_null("Ambient") != null, "ambient layer exists")
	var ground_detail := Node2D.new()
	environment.add_ground_detail(ground_detail)
	_check(ground_detail.is_in_group("forest_ground_details"), "ground details attach to their dedicated layer")
	var packed_ground := PackedScene.new()
	var ground_root := Node2D.new()
	_check(packed_ground.pack(ground_root) == OK, "test ground chunk packs")
	ground_root.free()
	var attached_ground := environment.add_ground_chunk(packed_ground)
	_check(attached_ground != null and attached_ground.is_in_group("forest_ground_chunks"), "ground chunk scene attaches to ground layer")

	var fern := environment.add_prop("fern", Vector2(20, 30), 0.9, 1, true)
	await process_frame
	_check(fern != null, "vegetation prop instantiates")
	_check(fern.get_node("Visual").texture != null, "prop receives ProceduralArt texture")
	_check(fern.get_node("AnimationPlayer").is_playing(), "vegetation AnimationPlayer sway starts")
	_check(fern.is_in_group("forest_vegetation"), "vegetation category is tagged by group")
	_check(fern.get_node("Visual").material is ShaderMaterial, "vegetation receives shared wind shader material")

	var rock := environment.add_obstacle("moss_rock", Vector2(60, 30), Vector2(44, 18))
	await process_frame
	_check(rock != null, "obstacle instantiates")
	_check(rock.get_node("StaticBody2D/CollisionShape2D").shape is RectangleShape2D, "obstacle owns physics shape")
	_check((rock.get_node("StaticBody2D/CollisionShape2D").shape as RectangleShape2D).size == Vector2(44, 18), "obstacle collision size is independent and configured")
	_check(rock.is_in_group("forest_obstacles"), "obstacle category is tagged by group")

	var log := environment.add_fallen_log(Vector2(80, 30))
	await process_frame
	_check(log.get_node_or_null("LogBody") is Polygon2D, "fallen log uses authored node geometry")
	_check(log.get_node_or_null("StaticBody2D/CollisionShape2D") != null, "fallen log has independent collision")

	var tree := environment.add_tree("glade_tree", Vector2(100, 30), 0.8, 0, false)
	await process_frame
	_check(tree != null, "existing ForestTree scene can be composed by new environment")
	_check(tree.get_node("Canopy") != null and tree.get_node("OcclusionArea") != null, "tree keeps canopy and occlusion nodes")
	_check(tree.is_in_group("forest_trees"), "tree category is tagged by group")
	_check(tree.get_node("Canopy").material is ShaderMaterial, "tree canopy receives shared wind shader material")
	_check(environment.get_node("WorldObjects").y_sort_enabled, "all object types share one Y-sort parent")

	var tree_families := [
		[WILLOW_SCENE, "willow_tree"], [BIRCH_SCENE, "birch_tree"],
		[PINE_SCENE, "pine_tree"], [BLOSSOM_SCENE, "blossom_tree"],
		[DEAD_TREE_SCENE, "dead_tree"]
	]
	for family in tree_families:
		var tree_variant := (family[0] as PackedScene).instantiate() as ForestTree
		_check(tree_variant != null and tree_variant.prop_kind == str(family[1]), "tree family %s is a reusable ForestTree scene" % str(family[1]))
		environment.get_node("WorldObjects").add_child(tree_variant)
		await process_frame
		_check(tree_variant.get_node("Canopy").texture != null, "tree family %s loads canopy artwork" % str(family[1]))

	var ground_families := [
		[SHRUB_SCENE, "bush"], [BERRY_SCENE, "berry_bush"],
		[FLOWER_SCENE, "flower_cluster"], [MUSHROOM_SCENE, "glow_mushroom"],
		[FERN_SCENE, "fern"], [REED_SCENE, "reeds"],
		[CRYSTAL_SCENE, "crystal_cluster"], [RUNE_SCENE, "rune_stone"]
	]
	for family in ground_families:
		var family_prop := (family[0] as PackedScene).instantiate() as ModularForestProp
		_check(family_prop != null and family_prop.prop_kind == str(family[1]), "ground family %s uses reusable prop base" % str(family[1]))
		environment.get_node("WorldObjects").add_child(family_prop)
		await process_frame
		_check(family_prop.get_node("Visual").texture != null, "ground family %s loads its procedural/authored texture" % str(family[1]))

	var stump := environment.add_stump(Vector2(130, 30))
	var roots := environment.add_root_cluster(Vector2(150, 30))
	_check(stump.get_node_or_null("StaticBody2D/CollisionShape2D") != null, "stump has independent collision")
	_check(roots.get_node_or_null("StaticBody2D/CollisionShape2D") != null, "root cluster has independent collision")
	var glow_bloom := environment.add_prop("spirit_bloom", Vector2(165, 42), 1.0, 0, false, "vegetation")
	var firefly := environment.add_firefly(Vector2(180, -20))
	await process_frame
	_check(firefly.get_node("Sprite").texture != null, "ambient firefly loads procedural sprite")
	_check((firefly.get_node("AnimationPlayer") as AnimationPlayer).is_playing(), "ambient firefly hover animation starts")
	_check(float(firefly.self_modulate.a) > 0.5, "fireflies are active at night")
	_check(glow_bloom.is_in_group("forest_glowing"), "magical bloom is registered for night glow")
	_check(glow_bloom.get_node("Visual").material is ShaderMaterial, "magical vegetation still receives wind")
	environment.set_time_of_day(0.50)
	await process_frame
	_check(not firefly.visible, "fireflies fade out during daytime")
	_check(glow_bloom.get_node("Visual").self_modulate.is_equal_approx(Color.WHITE), "magical bloom glow fades during daytime")
	environment.set_time_of_day(0.96)
	await process_frame
	_check(firefly.visible and float(firefly.self_modulate.a) > 0.9, "fireflies wake up again at night")
	_check(not glow_bloom.get_node("Visual").self_modulate.is_equal_approx(Color.WHITE), "magical bloom glow returns at night")

	var rock_variant := ROCK_SCENE.instantiate() as ModularForestObstacle
	_check(rock_variant != null and rock_variant.prop_kind == "moss_rock", "specialized rock scene inherits obstacle")
	rock_variant.free()

	_check(GREENWARD_PROFILE is ForestBiomeProfile, "Greenward biome profile loads as typed Resource")
	_check(MOONPETAL_PROFILE is ForestBiomeProfile, "Moonpetal biome profile loads as typed Resource")
	environment.clear_generated()
	await process_frame
	var first_scatter := ForestBiomeAssembler.populate(environment, GREENWARD_PROFILE,
		Rect2(Vector2.ZERO, Vector2(640, 480)), 77821)
	_check(int(first_scatter.get("trees", 0)) > 0, "biome assembler places tree scenes")
	_check(int(first_scatter.get("understory", 0)) > 0, "biome assembler places understory scenes")
	_check(int(first_scatter.get("ambient", 0)) == GREENWARD_PROFILE.ambient_count, "biome assembler places configured ambient scenes")
	var first_positions: Array = first_scatter.get("tree_positions", [])
	environment.clear_generated()
	await process_frame
	var second_scatter := ForestBiomeAssembler.populate(environment, GREENWARD_PROFILE,
		Rect2(Vector2.ZERO, Vector2(640, 480)), 77821)
	_check(first_positions == second_scatter.get("tree_positions", []), "biome scatter is deterministic for identical seed and bounds")
	environment.clear_generated()
	await process_frame
	var moonpetal_scatter := ForestBiomeAssembler.populate(environment, MOONPETAL_PROFILE,
		Rect2(Vector2.ZERO, Vector2(640, 480)), 99117)
	_check(int(moonpetal_scatter.get("trees", 0)) > 0, "Moonpetal biome profile generates its own tree family")
	_check(int(moonpetal_scatter.get("understory", 0)) > 0, "Moonpetal biome profile generates its own magical understory")

	environment.clear_generated()
	await process_frame
	_check(environment.get_node("WorldObjects").get_child_count() == 0, "generated objects clear without deleting layer roots")
	_check(environment.get_node("Ground").get_child_count() == 0, "generated ground chunks clear without deleting ground root")
	environment.free()
	await process_frame
	await process_frame

	if failures.is_empty():
		print("[modular_forest] PASS — 71 checks")
	else:
		for failure in failures:
			push_error("[modular_forest] " + failure)
		print("[modular_forest] FAILED — %d checks" % failures.size())
	quit(0 if failures.is_empty() else 1)


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

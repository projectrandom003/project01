extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var entrance: Node2D = load("res://scenes/world/castle_gardens/components/castle_entrance.tscn").instantiate() as Node2D
	root.add_child(entrance)
	entrance.call("build_default", Vector2.ZERO)
	assert(entrance.get_node("Visuals").get_child_count() > 0)
	assert(entrance.get_node("Collisions").get_child_count() == 2)

	var exterior: Node2D = load("res://scenes/world/castle_gardens/components/castle_exterior.tscn").instantiate() as Node2D
	root.add_child(exterior)
	exterior.call("build_default", Vector2.ZERO)
	assert(exterior.get_node("Visuals").get_child_count() > 0)
	assert(exterior.get_node("Collisions").get_child_count() > 0)

	var props: Node2D = load("res://scenes/world/castle_gardens/components/decorative_props.tscn").instantiate() as Node2D
	root.add_child(props)
	props.call("add_bench", Vector2.ZERO)
	props.call("add_lantern", Vector2(32, 0))
	props.call("add_urn", Vector2(64, 0))
	assert(props.get_node("PropInstances").get_child_count() == 3)

	var fountain: Node2D = load("res://scenes/world/castle_gardens/components/garden_fountain.tscn").instantiate() as Node2D
	root.add_child(fountain)
	await process_frame
	assert(fountain.get_node("Sprite").texture != null)
	assert(fountain.get_node("Body/CollisionShape2D").shape != null)

	var hedges: Node2D = load("res://scenes/world/castle_gardens/components/garden_hedges.tscn").instantiate() as Node2D
	root.add_child(hedges)
	await process_frame
	hedges.call("add_hedge", Vector2.ZERO)
	assert(hedges.get_node("HedgeInstances").get_child_count() == 1)

	var garden: Node2D = load("res://scenes/world/castle_gardens/components/royal_garden.tscn").instantiate() as Node2D
	root.add_child(garden)
	garden.call("build_symmetrical", Vector2.ZERO)
	assert(garden.get_node("FlowerBeds").get_child_count() == 8)
	assert(garden.get_node("UrnPlanters").get_child_count() == 6)
	assert(garden.get_node("Collisions").get_child_count() == 6)

	var pathways: Node2D = load("res://scenes/world/castle_gardens/components/stone_pathways.tscn").instantiate() as Node2D
	root.add_child(pathways)
	await process_frame
	pathways.call("add_path_tile", Vector2.ZERO)
	assert(pathways.get_node("Tiles").get_child_count() == 1)

	var water: Node2D = load("res://scenes/world/castle_gardens/components/water_features.tscn").instantiate() as Node2D
	root.add_child(water)
	water.call("add_pond", Vector2.ZERO)
	water.call("add_waterfall", Vector2(32, 0))
	water.call("add_bridge", Vector2(64, 0))
	assert(water.get_node("WaterVisuals").get_child_count() == 3)

	print("CASTLE GARDEN COMPONENT SMOKE: PASS")
	quit(0)

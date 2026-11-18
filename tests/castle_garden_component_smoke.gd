extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _assert_sprite_tree(node: Node, label: String) -> int:
	var count := 0
	for child in node.get_children():
		if child is Sprite2D:
			var sprite := child as Sprite2D
			if sprite.texture == null:
				push_error(label + ": sprite has no texture: " + str(sprite.get_path()))
				return -1
			count += 1
		var nested := _assert_sprite_tree(child, label)
		if nested < 0:
			return -1
		count += nested
	return count

func _assert_mirrored_sprite_pair(parent: Node, west_name: String, east_name: String) -> bool:
	var west := parent.get_node_or_null(west_name) as Sprite2D
	var east := parent.get_node_or_null(east_name) as Sprite2D
	if west == null or east == null:
		push_error("Missing mirrored garden sprites: %s / %s" % [west_name, east_name])
		return false
	if not is_equal_approx(west.position.x + east.position.x, 1280.0):
		push_error("Garden sprite pair is not centered symmetrically: %s / %s" % [west_name, east_name])
		return false
	if not is_equal_approx(west.position.y, east.position.y) or not west.scale.is_equal_approx(east.scale):
		push_error("Garden sprite pair has mismatched vertical placement or scale: %s / %s" % [west_name, east_name])
		return false
	return true


func _load_assembly(path: String, min_sprites: int) -> bool:
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Could not load assembly: " + path)
		return false
	var instance := packed.instantiate()
	if instance == null:
		push_error("Could not instantiate assembly: " + path)
		return false
	root.add_child(instance)
	var sprite_count := _assert_sprite_tree(instance, path)
	instance.queue_free()
	if sprite_count < min_sprites:
		push_error("Too few illustrated sprites in %s: %d < %d" % [path, sprite_count, min_sprites])
		return false
	return true

func _assert_path_connectivity() -> bool:
	var remaining := {}
	var path_cells: Array[Vector2i] = []
	for gx in range(CastleLayout.GRID_MIN.x, CastleLayout.GRID_MAX.x + 1):
		for gy in range(CastleLayout.GRID_MIN.y, CastleLayout.GRID_MAX.y + 1):
			if CastleLayout.is_path(gx, gy):
				var cell := Vector2i(gx, gy)
				path_cells.append(cell)
				remaining[cell] = true
	if path_cells.is_empty():
		push_error("Royal Gardens has no walkable path cells")
		return false
	var queue: Array[Vector2i] = [path_cells[0]]
	remaining.erase(path_cells[0])
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for step in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var neighbour: Vector2i = cell + step
			if remaining.has(neighbour):
				remaining.erase(neighbour)
				queue.append(neighbour)
	if not remaining.is_empty():
		push_error("Royal Gardens path network has %d disconnected cells: %s" % [remaining.size(), str(remaining.keys())])
		return false
	for pond_cell in CastleLayout.POND_LEFT + CastleLayout.POND_RIGHT:
		if CastleLayout.is_path(pond_cell.x, pond_cell.y):
			push_error("Royal Gardens path overlaps a reflecting pond cell: %s" % str(pond_cell))
			return false
	print("ROYAL GARDENS ROUTE CONNECTIVITY: PASS (%d cells, 1 component)" % path_cells.size())
	return true


func _run() -> void:
	if not _assert_path_connectivity():
		quit(1)
		return
	var checks := [
		["res://scenes/world/castle_gardens/components/reverie_royal_gardens_castle_collection.tscn", 8],
		["res://scenes/world/castle_gardens/components/castle_flora_assembly.tscn", 18],
		["res://scenes/world/castle_gardens/components/castle_props_assembly.tscn", 6],
		["res://scenes/world/castle_gardens/components/castle_water_assembly.tscn", 1],
		["res://scenes/world/castle_gardens/components/castle_garden_fence_assembly.tscn", 30],
		["res://scenes/world/castle_gardens/components/castle_road_surface_assembly.tscn", 0]
	]
	for check in checks:
		if not _load_assembly(check[0], check[1]):
			quit(1)
			return

	# Fountain beds must share the same local coordinate frame as the fountain court.
	var flora_scene := load("res://scenes/world/castle_gardens/components/castle_flora_assembly.tscn") as PackedScene
	var flora_check := flora_scene.instantiate()
	var beds := flora_check.get_node_or_null("FountainFlowerbeds") as Node2D
	if beds == null or beds.position != Vector2.ZERO or beds.scale != Vector2.ONE:
		push_error("Fountain flowerbeds are offset from the fountain court coordinate frame")
		flora_check.free()
		quit(1)
		return
	var signature_trees := flora_check.get_node_or_null("SignatureTrees")
	if signature_trees == null:
		push_error("Missing signature tree assembly")
		flora_check.free()
		quit(1)
		return
	for pair in [["PinkBlossomWest", "PinkBlossomEast"], ["WisteriaNorthWest", "WisteriaNorthEast"], ["WhiteBlossomSouthWest", "WhiteBlossomSouthEast"], ["CypressWest", "CypressEast"]]:
		if not _assert_mirrored_sprite_pair(signature_trees, pair[0], pair[1]):
			flora_check.free()
			quit(1)
			return
	var gazebo := flora_check.get_node_or_null("RoseArchitecture/RoyalGazebo") as Sprite2D
	if gazebo == null or not gazebo.visible:
		push_error("Royal gazebo is missing or hidden")
		flora_check.free()
		quit(1)
		return
	for accent_name in ["WestOuterRoseCourtArch", "EastOuterRoseCourtArch", "WestOuterFlowerPedestal", "EastOuterFlowerPedestal", "WestRoseCourtPink", "WestRoseCourtViolet", "EastRoseCourtPink", "EastRoseCourtWhite"]:
		var accent := flora_check.get_node_or_null("OuterGardenEnrichment/" + accent_name) as Sprite2D
		if accent == null or not accent.visible:
			push_error("Missing visible outer garden framing accent: " + accent_name)
			flora_check.free()
			quit(1)
			return
	var outer_bloom := flora_check.get_node_or_null("OuterGardenEnrichment")
	for pair in [["WestRoseCourtPink", "EastRoseCourtPink"], ["WestRoseCourtViolet", "EastRoseCourtWhite"]]:
		if not _assert_mirrored_sprite_pair(outer_bloom, pair[0], pair[1]):
			flora_check.free()
			quit(1)
			return
	flora_check.free()
	print("FOUNTAIN FLOWERBED ALIGNMENT: PASS")
	print("ROYAL GARDENS FLORA SYMMETRY AND GAZEBO: PASS")

	# The hand-authored road ribbons must remain separate, textured polygon nodes.
	var road_scene := load("res://scenes/world/castle_gardens/components/castle_road_surface_assembly.tscn") as PackedScene
	if road_scene == null:
		push_error("Royal Gardens road assembly failed to load")
		quit(1)
		return
	var road_check := road_scene.instantiate()
	for road_name in ["CentralGrandPromenade", "WestFountainGardenLoop", "EastFountainGardenLoop", "GrandFountainParterreLoop", "WestLowerGateWalk", "EastLowerGateWalk"]:
		var road_piece := road_check.get_node_or_null(road_name) as Polygon2D
		if road_piece == null or road_piece.polygon.size() < 3 or road_piece.texture == null:
			push_error("Missing or invalid hand-authored road polygon: " + road_name)
			road_check.free()
			quit(1)
			return
	road_check.free()
	print("ROYAL GARDENS ROAD ASSEMBLY: PASS")

	var world := load("res://scenes/world/castle_royal_gardens.tscn") as PackedScene
	if world == null:
		push_error("Royal Gardens world scene failed to load")
		quit(1)
		return
	var world_instance := world.instantiate()
	if world_instance == null:
		push_error("Royal Gardens world scene failed to instantiate")
		quit(1)
		return
	root.add_child(world_instance)
	for node_name in ["RoyalCastleArchitecture", "Flora", "Props", "Water", "PathwayTiles", "GardenFences"]:
		if world_instance.get_node_or_null(node_name) == null:
			push_error("Missing world assembly: " + node_name)
			world_instance.queue_free()
			quit(1)
			return
	var fences := world_instance.get_node_or_null("GardenFences")
	var west_path_rail := fences.get_node_or_null("FenceRuns/StonePathwayFenceSides/WestPathFence1") as Sprite2D if fences != null else null
	var east_path_rail := fences.get_node_or_null("FenceRuns/StonePathwayFenceSides/EastPathFence1") as Sprite2D if fences != null else null
	var entrance_gate := fences.get_node_or_null("FrontPerimeterFence/GrandFrontEntranceGate") as Sprite2D if fences != null else null
	if west_path_rail == null or east_path_rail == null or entrance_gate == null or not entrance_gate.visible:
		push_error("Royal Gardens fence focal pieces are missing or hidden")
		world_instance.queue_free()
		quit(1)
		return
	if not is_equal_approx(west_path_rail.position.x + east_path_rail.position.x, 1280.0) or not is_equal_approx(absf(west_path_rail.scale.x), absf(east_path_rail.scale.x)):
		push_error("Promenade fence rails are no longer mirrored")
		world_instance.queue_free()
		quit(1)
		return
	if west_path_rail.texture == null or not west_path_rail.texture.resource_path.contains("fence_ornate_straight_a_32x32.png"):
		push_error("Promenade fences are not using the custom ornate fence artwork")
		world_instance.queue_free()
		quit(1)
		return
	if entrance_gate.texture == null or not entrance_gate.texture.resource_path.contains("grand_ornate_gate.png"):
		push_error("Grand entrance is not using the custom ornate gate artwork")
		world_instance.queue_free()
		quit(1)
		return
	world_instance.queue_free()
	print("CASTLE GARDEN ASSET-FIRST SMOKE: PASS")
	quit(0)

extends SceneTree

func _initialize() -> void:
	var packed := load("res://scenes/world/castle_gardens/components/reverie_royal_gardens_castle_collection.tscn") as PackedScene
	if packed == null:
		push_error("ROYAL_CASTLE_COLLECTION_LOAD_FAILED")
		quit(1)
		return
	var scene := packed.instantiate()
	if scene == null:
		push_error("ROYAL_CASTLE_COLLECTION_INSTANTIATE_FAILED")
		quit(1)
		return
	var required := ["CastleKeep", "WestFlankTower", "EastFlankTower", "GrandGatehouse", "WestCorner", "EastCorner", "NorthWestWall", "NorthEastWall", "WestSideWall", "EastSideWall"]
	for piece in required:
		if scene.get_node_or_null(piece) == null:
			push_error("Missing asset-based architecture piece: " + piece)
			scene.free()
			quit(1)
			return
	var tower_count := 0
	var wall_count := 0
	var corner_count := 0
	for child in scene.get_children():
		if String(child.name).contains("Tower"):
			tower_count += 1
		if String(child.name).contains("Wall"):
			wall_count += 1
		if String(child.name).contains("Corner"):
			corner_count += 1
	if tower_count != 2 or wall_count != 4 or corner_count != 2:
		push_error("Unexpected castle composition towers=%d walls=%d corners=%d" % [tower_count, wall_count, corner_count])
		scene.free()
		quit(1)
		return
	scene.free()
	print("REVERIE_ROYAL_CASTLE_COLLECTION_OK asset_based=true towers=", tower_count, " walls=", wall_count, " corners=", corner_count, " gatehouse=1 keep=1")
	quit(0)

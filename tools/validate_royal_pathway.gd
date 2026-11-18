extends SceneTree
func _initialize() -> void:
	var packed := load("res://scenes/world/castle_gardens/components/royal_garden_isometric_layers_baked.tscn") as PackedScene
	if packed == null:
		push_error("Terrain scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	var paths := scene.get_node("Paths") as TileMapLayer
	if paths == null or paths.get_used_cells().size() != 65:
		push_error("Expected 65 custom path atlas cells; got " + str(paths.get_used_cells().size() if paths else -1))
		quit(1)
		return
	for cell in paths.get_used_cells():
		if paths.get_cell_source_id(cell) != 0:
			push_error("Path cell has unexpected atlas source")
			quit(1)
			return
		var atlas := paths.get_cell_atlas_coords(cell)
		if atlas.y != 0 or atlas.x < 0 or atlas.x > 3:
			push_error("Path cell uses non-path atlas tile " + str(atlas))
			quit(1)
			return
	var flora := load("res://scenes/world/castle_gardens/components/castle_flora_assembly.tscn") as PackedScene
	var fi := flora.instantiate()
	var bad := 0
	for n in fi.find_children("*","Sprite2D",true,false):
		var sp := n as Sprite2D
		if sp.texture == null: bad += 1
		if sp.texture and sp.texture.resource_path.ends_with("rose_hedge_block.png"):
			bad += 1
	if bad > 0:
		push_error("Flora contains missing texture or rectangular hedge blocks")
		quit(1)
		return
	print("ROYAL_GARDEN_PATH_AND_FLORA_QA PASS path_cells=", paths.get_used_cells().size(), " custom_atlas=true rectangular_hedge_blocks=0")
	scene.free()
	fi.free()
	quit(0)

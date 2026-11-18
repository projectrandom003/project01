extends SceneTree
func _initialize():
	var packed = load("res://scenes/world/castle_gardens/components/royal_garden_isometric_layers_baked.tscn") as PackedScene
	var scene = packed.instantiate()
	var paths = scene.get_node("Paths") as TileMapLayer
	print("PATH CELLS ", paths.get_used_cells().size())
	for c in paths.get_used_cells():
		print("PATH ", c, " atlas ", paths.get_cell_atlas_coords(c), " alt ", paths.get_cell_alternative_tile(c))
	var water = scene.get_node("Water") as TileMapLayer
	print("WATER CELLS ", water.get_used_cells().size())
	for c in water.get_used_cells():
		print("WATER ", c, " atlas ", water.get_cell_atlas_coords(c))
	quit()

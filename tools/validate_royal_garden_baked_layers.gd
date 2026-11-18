extends SceneTree

func _initialize() -> void:
	call_deferred("_validate")


func _is_expected_path(gx: int, gy: int) -> bool:
	var diff := gx - gy
	var total := gx + gy
	if abs(diff - 20) <= 1 and total >= -10 and total <= 50:
		return true
	if total == 33 and diff >= 13 and diff <= 27:
		return true
	if gx >= 13 and gx <= 20 and gy >= -7 and gy <= -2:
		return true
	return diff >= 18 and diff <= 22 and total >= 19 and total <= 26


func _validate() -> void:
	var packed := load("res://scenes/world/castle_gardens/components/royal_garden_isometric_layers_baked.tscn") as PackedScene
	var config_scene := load("res://scenes/world/castle_gardens/components/castle_terrain_configuration.tscn") as PackedScene
	if packed == null or config_scene == null:
		push_error("Baked scene or source configuration did not load.")
		quit(1)
		return
	var root := packed.instantiate() as Node2D
	var config := config_scene.instantiate() as Node2D
	var ground := root.get_node("BaseGround") as TileMapLayer
	var variation := root.get_node("GroundVariation") as TileMapLayer
	var paths := root.get_node("Paths") as TileMapLayer
	var water := root.get_node("Water") as TileMapLayer
	var flowers := root.get_node("FlowerDetails") as TileMapLayer
	var min_grid: Vector2i = config.get_meta("ground_min")
	var max_grid: Vector2i = config.get_meta("ground_max")
	var expected_cells := 0
	var expected_paths := 0
	var expected_water := 0
	for gy in range(min_grid.y, max_grid.y + 1):
		for gx in range(min_grid.x, max_grid.x + 1):
			if not CastleLayout.covers_screen_rect(gx, gy):
				continue
			expected_cells += 1
			var cell := Vector2i(gx, gy)
			if ground.get_cell_source_id(cell) != 0:
				push_error("Missing ground cell at %s" % cell)
				quit(1)
				return
			if CastleLayout.is_pond(gx, gy):
				expected_water += 1
				if water.get_cell_source_id(cell) != 0 or water.get_cell_atlas_coords(cell) != Vector2i(0, 2):
					push_error("Missing water cell at %s" % cell)
					quit(1)
					return
			elif _is_expected_path(gx, gy):
				expected_paths += 1
				if paths.get_cell_source_id(cell) != 0 or paths.get_cell_atlas_coords(cell) != Vector2i(2, 0):
					push_error("Missing path cell at %s" % cell)
					quit(1)
					return
	if ground.get_used_cells().size() != expected_cells or variation.get_used_cells().size() != 44 or flowers.get_used_cells().size() != 6:
		push_error("Unexpected baked ground/variation/flower counts.")
		quit(1)
		return
	var allowed_variants: Array[Vector2i] = [Vector2i(1, 0), Vector2i(3, 0), Vector2i(0, 1), Vector2i(1, 1)]
	for cell in variation.get_used_cells():
		if ground.get_cell_source_id(cell) != 0 or paths.get_cell_source_id(cell) != -1 or water.get_cell_source_id(cell) != -1:
			push_error("Ground variation overlaps a missing ground cell, path, or pond at %s" % cell)
			quit(1)
			return
		if not allowed_variants.has(variation.get_cell_atlas_coords(cell)):
			push_error("Unexpected grass variation atlas tile at %s" % cell)
			quit(1)
			return
	if paths.get_used_cells().size() != expected_paths or water.get_used_cells().size() != expected_water:
		push_error("Unexpected baked path/water counts.")
		quit(1)
		return
	for layer_name in ["Hedges", "Vegetation", "Foreground"]:
		if root.get_node_or_null(layer_name) == null:
			push_error("Missing authored layer: " + layer_name)
			quit(1)
			return
	var dx := ground.map_to_local(Vector2i(1, 0)) - ground.map_to_local(Vector2i(0, 0))
	var dy := ground.map_to_local(Vector2i(0, 1)) - ground.map_to_local(Vector2i(0, 0))
	if dx.distance_to(Vector2(32, 16)) > 0.1 or dy.distance_to(Vector2(-32, 16)) > 0.1:
		push_error("Baked TileMapLayer no longer matches IsoMath projection.")
		quit(1)
		return
	print("ROYAL_GARDEN_BAKED_SCENE_OK ground=%d variations=%d paths=%d water=%d flowers=%d layers=8 iso_projection=matched" % [expected_cells, variation.get_used_cells().size(), expected_paths, expected_water, flowers.get_used_cells().size()])
	root.free()
	config.free()
	quit(0)

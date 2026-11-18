extends SceneTree

const PREVIEW_PATH := "res://scenes/world/castle_gardens/components/royal_garden_isometric_layers.tscn"
const OUTPUT_PATH := "res://scenes/world/castle_gardens/components/royal_garden_isometric_layers_baked.tscn"
const CONFIG_PATH := "res://scenes/world/castle_gardens/components/castle_terrain_configuration.tscn"

func _initialize() -> void:
	call_deferred("_bake")


func _is_courtyard_path(gx: int, gy: int) -> bool:
	var diff := gx - gy
	var total := gx + gy
	# Three-cell-wide royal promenade, continuous from the castle forecourt to the south gate.
	if abs(diff - 20) <= 1 and total >= -10 and total <= 50:
		return true
	# One cross-courtyard connector links the two reflecting pools to the promenade.
	if total == 33 and diff >= 13 and diff <= 27:
		return true
	# Compact castle forecourt, aligned to the castle entrance.
	if gx >= 13 and gx <= 20 and gy >= -7 and gy <= -2:
		return true
	# Fountain apron gives each pool a small stone landing without paving the lawn.
	if diff >= 18 and diff <= 22 and total >= 19 and total <= 26:
		return true
	return false


func _bake() -> void:
	var packed := load(PREVIEW_PATH) as PackedScene
	var config_scene := load(CONFIG_PATH) as PackedScene
	if packed == null or config_scene == null:
		push_error("Could not load the isometric layer scene or terrain configuration.")
		quit(1)
		return
	var layers := packed.instantiate() as Node2D
	var config := config_scene.instantiate() as Node2D
	var ground := layers.get_node("BaseGround") as TileMapLayer
	var variation := layers.get_node("GroundVariation") as TileMapLayer
	var paths := layers.get_node("Paths") as TileMapLayer
	var water := layers.get_node("Water") as TileMapLayer
	var flowers := layers.get_node("FlowerDetails") as TileMapLayer
	ground.clear()
	variation.clear()
	paths.clear()
	water.clear()
	flowers.clear()
	var min_grid: Vector2i = config.get_meta("ground_min")
	var max_grid: Vector2i = config.get_meta("ground_max")
	var ground_count := 0
	var path_count := 0
	var water_count := 0
	var variation_count := 0
	for gy in range(min_grid.y, max_grid.y + 1):
		for gx in range(min_grid.x, max_grid.x + 1):
			if not CastleLayout.covers_screen_rect(gx, gy):
				continue
			var cell := Vector2i(gx, gy)
			ground.set_cell(cell, 0, Vector2i(0, 0))
			ground_count += 1
			if CastleLayout.is_pond(gx, gy):
				water.set_cell(cell, 0, Vector2i(0, 2))
				water_count += 1
			elif _is_courtyard_path(gx, gy):
				paths.set_cell(cell, 0, Vector2i(2, 0))
				path_count += 1
			# Sparse, baked-in lawn variation uses the authored grass atlas cells.
			# It deliberately avoids paths, ponds, and the central castle footprint.
			if not CastleLayout.is_pond(gx, gy) and not _is_courtyard_path(gx, gy):
				if gx <= 6 or gx >= 50 or gy >= 27:
					var seed_value: int = absi(gx * 73856093 ^ gy * 19349663)
					if seed_value % 23 == 0:
						var variants: Array[Vector2i] = [Vector2i(1, 0), Vector2i(3, 0), Vector2i(0, 1), Vector2i(1, 1)]
						variation.set_cell(cell, 0, variants[seed_value % variants.size()])
						variation_count += 1
	var marker_index := 0
	var flower_coords := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(0, 1), Vector2i(1, 1)]
	for marker in config.get_children():
		if not marker.has_meta("grid_position"):
			continue
		var grid_position: Vector2 = marker.get_meta("grid_position")
		var cell := Vector2i(roundi(grid_position.x), roundi(grid_position.y))
		flowers.set_cell(cell, 0, flower_coords[marker_index % flower_coords.size()])
		marker_index += 1
	var output := PackedScene.new()
	var pack_error := output.pack(layers)
	if pack_error != OK:
		push_error("Could not pack the baked isometric layers.")
		layers.free()
		config.free()
		quit(1)
		return
	var save_error := ResourceSaver.save(output, OUTPUT_PATH)
	if save_error != OK:
		push_error("Could not save the baked isometric layer scene.")
		layers.free()
		config.free()
		quit(1)
		return
	print("ROYAL_GARDEN_ISOMETRIC_BAKE_OK ground=%d variations=%d paths=%d water=%d flower_markers=%d" % [ground_count, variation_count, path_count, water_count, marker_index])
	layers.free()
	config.free()
	quit(0)


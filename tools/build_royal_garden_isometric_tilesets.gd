extends SceneTree

const TERRAIN_DIR := "res://assets/environment/castle_gardens/terrain/"

func _initialize() -> void:
	call_deferred("_build")

func _build() -> void:
	var atlases := {
		"ground": "royal_garden_ground_atlas_32x32.png",
		"paths_water": "royal_garden_paths_water_atlas_32x32.png",
		"vegetation": "royal_garden_vegetation_atlas_32x32.png"
	}
	for key in atlases:
		var texture := load(TERRAIN_DIR + atlases[key]) as Texture2D
		if texture == null or texture.get_width() != 128 or texture.get_height() != 128:
			push_error("Expected 128x128 atlas for " + key)
			quit(1)
			return
		var tileset := TileSet.new()
		tileset.tile_size = Vector2i(64, 32)
		tileset.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
		tileset.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
		var source := TileSetAtlasSource.new()
		source.texture = texture
		source.texture_region_size = Vector2i(32, 32)
		for y in range(4):
			for x in range(4):
				source.create_tile(Vector2i(x, y))
				var data := source.get_tile_data(Vector2i(x, y), 0)
				data.texture_origin = Vector2i(16, 0)
		tileset.add_source(source, 0)
		var output: String = TERRAIN_DIR + "royal_garden_" + key + "_isometric_tileset.tres"
		var error := ResourceSaver.save(tileset, output)
		if error != OK:
			push_error("Could not save " + output)
			quit(1)
			return
		print("ISOMETRIC_TILESET_OK key=%s cell=64x32 atlas=32x32 tiles=16" % key)
	print("ISOMETRIC_TILESET_BUILD_COMPLETE")
	quit(0)

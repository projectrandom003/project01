extends SceneTree

func _initialize() -> void:
	call_deferred("_build_tileset")

func _build_tileset() -> void:
	var texture_path := "res://assets/environment/castle_gardens/terrain/royal_garden_ground_atlas_32x32.png"
	var output_path := "res://assets/environment/castle_gardens/terrain/royal_garden_ground_tileset.tres"
	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_error("Royal Garden ground atlas could not be loaded: " + texture_path)
		quit(1)
		return
	if texture.get_width() != 128 or texture.get_height() != 128:
		push_error("Expected a 128x128 atlas containing sixteen 32x32 cells.")
		quit(1)
		return
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(32, 32)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(32, 32)
	for y in range(4):
		for x in range(4):
			atlas.create_tile(Vector2i(x, y))
	tileset.add_source(atlas, 0)
	var error := ResourceSaver.save(tileset, output_path)
	if error != OK:
		push_error("Could not save Royal Garden TileSet. Error: %s" % error)
		quit(1)
		return
	print("ROYAL_GARDEN_TILESET_CREATED path=%s cells=16 cell_size=32x32" % output_path)
	quit(0)

extends SceneTree
func _initialize() -> void:
	call_deferred("_build")
func _build() -> void:
	var texture := load("res://assets/environment/castle_gardens/terrain/royal_garden_vegetation_atlas_32x32.png") as Texture2D
	if texture == null or texture.get_width() != 128 or texture.get_height() != 128:
		push_error("Vegetation atlas must be 128x128.")
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
	var err := ResourceSaver.save(tileset, "res://assets/environment/castle_gardens/terrain/royal_garden_vegetation_tileset.tres")
	if err != OK:
		push_error("Saving vegetation TileSet failed: %s" % err)
		quit(1)
		return
	print("VEGETATION_TILESET_CREATED tiles=16 cell=32x32")
	quit(0)

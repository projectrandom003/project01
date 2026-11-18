extends SceneTree
func _initialize() -> void:
	call_deferred("_validate")
func _validate() -> void:
	var packed := load("res://scenes/world/castle_gardens/components/royal_garden_isometric_layers.tscn") as PackedScene
	if packed == null:
		push_error("Isometric layer scene failed to load.")
		quit(1)
		return
	var root := packed.instantiate() as Node2D
	var expected := ["BaseGround", "GroundVariation", "Paths", "Water", "FlowerDetails", "Hedges", "Vegetation", "Foreground"]
	for layer_name in expected:
		var layer := root.get_node_or_null(layer_name) as TileMapLayer
		if layer == null or layer.tile_set == null:
			push_error("Missing configured TileMapLayer: " + layer_name)
			root.free()
			quit(1)
			return
		if layer.tile_set.tile_size != Vector2i(64, 32) or layer.tile_set.tile_shape != TileSet.TILE_SHAPE_ISOMETRIC:
			push_error("Incorrect isometric TileSet geometry: " + layer_name)
			root.free()
			quit(1)
			return
	var ground := root.get_node("BaseGround") as TileMapLayer
	var dx := ground.map_to_local(Vector2i(1, 0)) - ground.map_to_local(Vector2i(0, 0))
	var dy := ground.map_to_local(Vector2i(0, 1)) - ground.map_to_local(Vector2i(0, 0))
	if dx.distance_to(Vector2(32, 16)) > 0.1 or dy.distance_to(Vector2(-32, 16)) > 0.1:
		push_error("TileMap isometric projection differs from IsoMath: dx=%s dy=%s" % [dx, dy])
		root.free()
		quit(1)
		return
	print("ROYAL_GARDEN_ISOMETRIC_LAYERS_OK layers=8 tile=64x32 projection=IsoMath")
	root.free()
	quit(0)

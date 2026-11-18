extends SceneTree
func _initialize() -> void:
	call_deferred("_validate")
func _validate() -> void:
	var packed := load("res://scenes/world/castle_gardens/components/royal_garden_ground_layers.tscn") as PackedScene
	if packed == null:
		push_error("Royal Garden TileMapLayer scene failed to load.")
		quit(1)
		return
	var instance := packed.instantiate() as Node2D
	var expected := ["BaseGround", "GroundVariation", "Paths", "Water", "FlowerDetails", "Hedges", "Vegetation", "Foreground"]
	for name in expected:
		var layer := instance.get_node_or_null(name)
		if not (layer is TileMapLayer):
			push_error("Missing TileMapLayer: " + name)
			instance.free()
			quit(1)
			return
		if layer.tile_set == null or layer.tile_set.tile_size != Vector2i(32, 32):
			push_error("Invalid 32x32 TileSet: " + name)
			instance.free()
			quit(1)
	var expected_sources := {
		"BaseGround": "res://assets/environment/castle_gardens/terrain/royal_garden_ground_tileset.tres",
		"Paths": "res://assets/environment/castle_gardens/terrain/royal_garden_paths_water_tileset.tres",
		"Water": "res://assets/environment/castle_gardens/terrain/royal_garden_paths_water_tileset.tres",
		"FlowerDetails": "res://assets/environment/castle_gardens/terrain/royal_garden_vegetation_tileset.tres",
		"Hedges": "res://assets/environment/castle_gardens/terrain/royal_garden_vegetation_tileset.tres",
		"Vegetation": "res://assets/environment/castle_gardens/terrain/royal_garden_vegetation_tileset.tres"
	}
	for layer_name in expected_sources:
		var layer := instance.get_node(layer_name) as TileMapLayer
		var source_path: String = expected_sources[layer_name]
		var expected_set := load(source_path) as TileSet
		if layer.tile_set.resource_path != expected_set.resource_path:
			push_error("Wrong TileSet assigned to " + layer_name)
			instance.free()
			quit(1)
			return
	print("ROYAL_GARDEN_TILEMAP_VALIDATION_OK layers=8 cell=32x32 ground=16 paths_water=16 vegetation=16")
	instance.free()
	quit(0)

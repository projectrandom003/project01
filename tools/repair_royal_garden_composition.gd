extends SceneTree

func _initialize() -> void:
	var scene_path := "res://scenes/world/castle_gardens/components/royal_garden_isometric_layers_baked.tscn"
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("Could not load garden terrain")
		quit(1)
		return
	var scene := packed.instantiate()
	var paths := scene.get_node("Paths") as TileMapLayer
	if paths == null:
		push_error("Missing Paths TileMapLayer")
		quit(1)
		return
	# Remove the three parallel strips from the previous layout.
	paths.clear()
	# Rebuild a single, narrow, centered ceremonial path using the dedicated
	# isometric stone-path atlas. A single tile column avoids the three-track look.
	for y in range(5, 27):
		paths.set_cell(Vector2i(24, y), 0, Vector2i((y - 5) % 4, 0), 0)
	var out := PackedScene.new()
	var err := out.pack(scene)
	if err != OK:
		push_error("Could not pack repaired terrain: " + str(err))
		quit(1)
		return
	err = ResourceSaver.save(out, scene_path)
	if err != OK:
		push_error("Could not save repaired terrain: " + str(err))
		quit(1)
		return
	print("GARDEN_PATH_REPAIRED: one centered path column, cells=", paths.get_used_cells().size())
	scene.free()
	quit(0)

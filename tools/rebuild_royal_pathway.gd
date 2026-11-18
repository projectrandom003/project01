extends SceneTree

func _initialize() -> void:
	var path := "res://scenes/world/castle_gardens/components/royal_garden_isometric_layers_baked.tscn"
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Could not load royal garden terrain scene")
		quit(1)
		return
	var scene := packed.instantiate()
	var layer := scene.get_node("Paths") as TileMapLayer
	if layer == null or layer.tile_set == null:
		push_error("Paths layer or approved path tileset missing")
		quit(1)
		return
	layer.clear()
	# 64x32 isometric tile coordinates. A three-tile-wide ceremonial
	# promenade follows the diagonal from the castle gate toward the forecourt.
	for step in range(19):
		var center := Vector2i(23 + step, 4 + step)
		var cells := [
			center + Vector2i(-1, 1),
			center,
			center + Vector2i(1, -1)
		]
		for j in range(cells.size()):
			var atlas := Vector2i((step + j) % 4, 0)
			layer.set_cell(cells[j], 0, atlas, 0)
	# Widen the arrival apron in front of the castle using the same authored atlas.
	for step in range(4):
		for across in range(-2, 3):
			var cell := Vector2i(23 + step + across, 4 + step - across)
			layer.set_cell(cell, 0, Vector2i((step + across + 8) % 4, 0), 0)
	var result := ResourceSaver.save(PackedScene.new(), "user://unused.tscn")
	var out := PackedScene.new()
	var pack_result := out.pack(scene)
	if pack_result != OK:
		push_error("Failed to pack garden terrain scene: " + str(pack_result))
		scene.free()
		quit(1)
		return
	var save_result := ResourceSaver.save(out, path)
	if save_result != OK:
		push_error("Failed to save garden terrain scene: " + str(save_result))
		scene.free()
		quit(1)
		return
	print("ROYAL_PATHWAY_REBUILT cells=", layer.get_used_cells().size(), " using approved isometric stone atlas")
	scene.free()
	quit(0)

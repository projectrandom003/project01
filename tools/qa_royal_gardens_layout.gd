extends SceneTree
func _initialize():
	var packed := load("res://scenes/world/castle_gardens/components/reverie_royal_gardens_full_preview.tscn") as PackedScene
	if packed == null:
		push_error("Preview scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	var path := scene.get_node_or_null("PathwaySystem/RoyalPathways/Tiles") as TileMapLayer
	var water := scene.get_node_or_null("GardenWaterSystem/Water/FountainCourt")
	if path == null or water == null:
		push_error("Missing pathway TileMapLayer or water fountain court")
		quit(1)
		return
	var cells := path.get_used_cells()
	print("PATH_CELL_COUNT=", cells.size())
	print("PATH_ATLAS_COORDS=", path.get_cell_atlas_coords(cells[0]) if cells.size() > 0 else Vector2i(-1,-1))
	var coords := []
	for cell in cells:
		coords.append(path.map_to_local(cell))
	coords.sort_custom(func(a,b): return a.y < b.y)
	if coords.size() > 1:
		var dx := []
		for i in range(1, coords.size()):
			if abs(coords[i].y - coords[i-1].y) < 0.01:
				dx.append(abs(coords[i].x-coords[i-1].x))
		print("PATH_SCREEN_BOUNDS=", coords[0], " -> ", coords[-1])
		print("PATH_HORIZONTAL_TILE_SPACING=", dx)
	print("FOUNTAIN_COUNT=", water.get_child_count())
	for child in water.get_children():
		if child is Sprite2D:
			print("FOUNTAIN ", child.name, " pos=", child.position, " texture=", child.texture.get_size() if child.texture else Vector2.ZERO)
	print("WATER_ZONE_COUNT=", scene.get_node("GardenWaterSystem/Water/WaterZones").get_child_count())
	quit(0)

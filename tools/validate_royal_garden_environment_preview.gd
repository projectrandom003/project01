extends SceneTree

func _initialize() -> void:
	call_deferred("_validate")


func _validate() -> void:
	var packed := load("res://scenes/world/castle_gardens/components/royal_garden_environment_preview.tscn") as PackedScene
	if packed == null:
		push_error("Combined garden preview failed to load.")
		quit(1)
		return
	var preview := packed.instantiate() as Node2D
	var layers := preview.get_node_or_null("GroundLayers") as Node2D
	var decor := preview.get_node_or_null("CourtyardDecorations") as Node2D
	if layers == null or decor == null:
		push_error("Preview requires ground layers and courtyard decoration groups.")
		preview.free()
		quit(1)
		return
	var ground := layers.get_node("BaseGround") as TileMapLayer
	var variation := layers.get_node("GroundVariation") as TileMapLayer
	var paths := layers.get_node("Paths") as TileMapLayer
	if ground.get_used_cells().size() != 2929 or variation.get_used_cells().size() != 0 or paths.get_used_cells().size() != 133:
		push_error("Preview ground, variation, or promenade layout is incorrect.")
		preview.free()
		quit(1)
		return
	var expected_groups := ["Fountains", "Seating", "Lighting", "Flowerbeds", "FloweringShrubs", "HedgeBorders", "Architecture", "Trees"]
	for group_name in expected_groups:
		var group := decor.get_node_or_null(group_name) as Node2D
		if group == null or group.get_child_count() == 0:
			push_error("Missing or empty courtyard node group: " + group_name)
			preview.free()
			quit(1)
			return
	if decor.get_node("Fountains").get_child_count() != 2 or decor.get_node("Seating").get_child_count() != 4:
		push_error("Fountain or seating composition count mismatch.")
		preview.free()
		quit(1)
		return
	if decor.get_node("Lighting").get_child_count() != 6 or decor.get_node("Trees").get_child_count() != 10:
		push_error("Lighting or tree composition count mismatch.")
		preview.free()
		quit(1)
		return
	if decor.get_node("Architecture").get_child_count() != 38:
		push_error("Architecture perimeter or gate composition count mismatch.")
		preview.free()
		quit(1)
		return
	print("ROYAL_GARDEN_ENVIRONMENT_PREVIEW_OK ground=2929 variations=0 promenade=133 fountains=2 benches=4 lanterns=6 flowers=8 shrubs=6 hedges=4 trees=10 architecture=38 modular_groups=8")
	preview.free()
	quit(0)





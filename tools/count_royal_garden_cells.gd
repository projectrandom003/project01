extends SceneTree
func _initialize() -> void:
	var config := load("res://scenes/world/castle_gardens/components/castle_terrain_configuration.tscn") as PackedScene
	var node := config.instantiate()
	var min_grid: Vector2i = node.get_meta("ground_min")
	var max_grid: Vector2i = node.get_meta("ground_max")
	var count := 0
	for y in range(min_grid.y, max_grid.y + 1):
		for x in range(min_grid.x, max_grid.x + 1):
			if CastleLayout.covers_screen_rect(x, y):
				count += 1
	print("ROYAL_GARDEN_COVERAGE cells=%d bounds=%s..%s" % [count, min_grid, max_grid])
	node.free()
	quit(0)

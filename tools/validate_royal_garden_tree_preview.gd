extends SceneTree
func _initialize() -> void:
	call_deferred("_check")
func _check() -> void:
	var packed := load("res://scenes/world/castle_gardens/components/royal_garden_tree_preview.tscn") as PackedScene
	if packed == null:
		push_error("Tree preview scene failed to load.")
		quit(1)
		return
	var preview := packed.instantiate()
	var count := 0
	for child in preview.get_children():
		if child is Node2D and child.get_node_or_null("Sprite2D") is Sprite2D:
			count += 1
	if count != 3:
		push_error("Expected three modular tree instances; found %d" % count)
		preview.free()
		quit(1)
		return
	print("ROYAL_GARDEN_TREE_PREVIEW_OK variants=3 scene_instances=3")
	preview.free()
	quit(0)

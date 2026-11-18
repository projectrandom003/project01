extends SceneTree
func _initialize() -> void:
	call_deferred("_validate")
func _validate() -> void:
	var paths := [
		"res://scenes/world/castle_gardens/components/royalgardenblossomtree.tscn",
		"res://scenes/world/castle_gardens/components/royalgardenbroadleaftree.tscn",
		"res://scenes/world/castle_gardens/components/royalgardenevergreentree.tscn"
	]
	for path in paths:
		var packed := load(path) as PackedScene
		if packed == null:
			push_error("Tree scene failed to load: " + path)
			quit(1)
			return
		var tree := packed.instantiate() as Node2D
		var sprite := tree.get_node_or_null("Sprite2D") as Sprite2D
		var body := tree.get_node_or_null("StaticBody2D") as StaticBody2D
		var shape := tree.get_node_or_null("StaticBody2D/CollisionShape2D") as CollisionShape2D
		if sprite == null or sprite.texture == null or sprite.texture.get_width() != 96 or sprite.texture.get_height() != 128:
			push_error("Tree sprite must be 96x128: " + path)
			tree.free()
			quit(1)
			return
		if body == null or shape == null or shape.shape == null:
			push_error("Tree trunk collision missing: " + path)
			tree.free()
			quit(1)
			return
		tree.free()
	print("ROYAL_GARDEN_TREE_VALIDATION_OK trees=3 sprite=96x128 cells=3x4 collision=present")
	quit(0)

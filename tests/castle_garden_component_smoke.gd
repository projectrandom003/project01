extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _assert_sprite_tree(node: Node, label: String) -> int:
	var count := 0
	for child in node.get_children():
		if child is Sprite2D:
			var sprite := child as Sprite2D
			if sprite.texture == null:
				push_error(label + ": sprite has no texture: " + str(sprite.get_path()))
				return -1
			count += 1
		var nested := _assert_sprite_tree(child, label)
		if nested < 0:
			return -1
		count += nested
	return count

func _load_assembly(path: String, min_sprites: int) -> bool:
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Could not load assembly: " + path)
		return false
	var instance := packed.instantiate()
	if instance == null:
		push_error("Could not instantiate assembly: " + path)
		return false
	root.add_child(instance)
	var sprite_count := _assert_sprite_tree(instance, path)
	instance.queue_free()
	if sprite_count < min_sprites:
		push_error("Too few illustrated sprites in %s: %d < %d" % [path, sprite_count, min_sprites])
		return false
	return true

func _run() -> void:
	var checks := [
		["res://scenes/world/castle_gardens/components/reverie_royal_gardens_castle_collection.tscn", 8],
		["res://scenes/world/castle_gardens/components/castle_flora_assembly.tscn", 18],
		["res://scenes/world/castle_gardens/components/castle_props_assembly.tscn", 6],
		["res://scenes/world/castle_gardens/components/castle_water_assembly.tscn", 1]
	]
	for check in checks:
		if not _load_assembly(check[0], check[1]):
			quit(1)
			return

	var world := load("res://scenes/world/castle_royal_gardens.tscn") as PackedScene
	if world == null:
		push_error("Royal Gardens world scene failed to load")
		quit(1)
		return
	var world_instance := world.instantiate()
	if world_instance == null:
		push_error("Royal Gardens world scene failed to instantiate")
		quit(1)
		return
	root.add_child(world_instance)
	for node_name in ["RoyalCastleArchitecture", "Flora", "Props", "Water"]:
		if world_instance.get_node_or_null(node_name) == null:
			push_error("Missing world assembly: " + node_name)
			world_instance.queue_free()
			quit(1)
			return
	world_instance.queue_free()
	print("CASTLE GARDEN ASSET-FIRST SMOKE: PASS")
	quit(0)

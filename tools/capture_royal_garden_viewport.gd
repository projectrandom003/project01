extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed := load("res://scenes/world/castle_gardens/components/reverie_royal_gardens_full_preview.tscn") as PackedScene
	assert(packed != null)
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	var path := "res://artifacts/qa/royal_gardens_true_viewport_20261118.png"
	var err := image.save_png(path)
	print("VIEWPORT_CAPTURE=", path, " SIZE=", image.get_size(), " ERROR=", err)
	quit(0 if err == OK else 1)

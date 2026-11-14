extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed := load("res://scenes/characters/playable_roster_preview.tscn") as PackedScene
	if packed == null:
		push_error("Roster preview scene failed to load")
		quit(1)
		return
	var instance := packed.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame
	var image := root.get_viewport().get_texture().get_image()
	var output := "C:/Users/quoth/Documents/Default Project/project-fantasy/character_roster_preview.png"
	var error := image.save_png(output)
	print("[roster_preview_capture] size=%s error=%d" % [image.get_size(), error])
	quit(0 if error == OK else 1)

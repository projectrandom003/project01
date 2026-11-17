extends Node
## Multi-aspect-ratio visual-layout contract for the live title screen.

var failures: int = 0

func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("[title-layout] PASS " + label)
	else:
		failures += 1
		push_error("[title-layout] FAIL " + label + (": " + detail if not detail.is_empty() else ""))


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var menu_scene := preload("res://scenes/ui/main_menu.tscn")
	var test_sizes: Array[Vector2] = [
		Vector2(1280, 720),
		Vector2(1920, 1080),
		Vector2(2560, 1600),
		Vector2(3440, 1440),
		Vector2(1024, 768)
	]
	for target_size in test_sizes:
		var menu := menu_scene.instantiate() as MainMenu
		add_child(menu)
		await get_tree().process_frame
		menu.set_anchors_preset(Control.PRESET_TOP_LEFT)
		menu.size = target_size
		menu._layout_art_menu()
		var art := menu.get_node("ReverieTitleArtwork") as TextureRect
		var backdrop := menu.get_node("ReverieTitleArtworkBackdrop") as TextureRect
		var expected_aspect := art.texture.get_width() / float(art.texture.get_height())
		var actual_aspect := art.size.x / art.size.y
		var label_size := "%dx%d" % [int(target_size.x), int(target_size.y)]
		_check(label_size + " keeps complete title-art aspect", absf(actual_aspect - expected_aspect) < 0.002, "actual=%.4f expected=%.4f" % [actual_aspect, expected_aspect])
		_check(label_size + " fits artwork inside viewport", art.position.x >= -0.5 and art.position.y >= -0.5 and art.position.x + art.size.x <= target_size.x + 0.5 and art.position.y + art.size.y <= target_size.y + 0.5)
		_check(label_size + " retains a full-bleed backdrop", backdrop.anchor_right == 1.0 and backdrop.anchor_bottom == 1.0)
		var names := ["ContinueButton", "NewJourneyButton", "LoadGameButton", "SettingsButton", "ExtrasButton", "QuitGameButton"]
		var previous_bottom := -INF
		for node_name in names:
			var button := menu.get_node(node_name) as Button
			var rect := Rect2(button.position, button.size)
			_check(label_size + " " + node_name + " stays inside artwork", rect.position.x >= art.position.x - 0.5 and rect.position.y >= art.position.y - 0.5 and rect.end.x <= art.position.x + art.size.x + 0.5 and rect.end.y <= art.position.y + art.size.y + 0.5)
			_check(label_size + " " + node_name + " has positive hitbox", rect.size.x > 0.0 and rect.size.y > 0.0)
			_check(label_size + " " + node_name + " does not overlap previous row", rect.position.y >= previous_bottom - 0.5)
			previous_bottom = rect.end.y
		menu.queue_free()
		await get_tree().process_frame
	if failures == 0:
		print("[title-layout] OK — five aspect ratios, six live buttons, full artwork preserved.")
		get_tree().quit(0)
	else:
		push_error("[title-layout] FAILED (%d)" % failures)
		get_tree().quit(1)

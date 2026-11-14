extends Node

func _ready() -> void:
	var menu_scene := load("res://scenes/ui/main_menu.tscn") as PackedScene
	if menu_scene == null:
		push_error("[menu-ui] Missing main_menu.tscn.")
		get_tree().quit(1)
		return
	var main := menu_scene.instantiate() as MainMenu
	if main == null:
		push_error("[menu-ui] Failed to instantiate main menu scene.")
		get_tree().quit(1)
		return
	main.size = Vector2(1280, 720)
	add_child(main)
	await get_tree().process_frame
	var required := ["ContinueButton", "NewJourneyButton", "LoadGameButton", "SettingsButton", "ExtrasButton", "QuitGameButton"]
	for node_name in required:
		var btn := main.get_node_or_null(node_name) as Button
		if btn == null:
			push_error("[menu-ui] Missing menu button: " + node_name)
			get_tree().quit(1)
			return
	if main.get_node_or_null("ReverieTitleArtwork") == null:
		push_error("[menu-ui] Missing title artwork node.")
		get_tree().quit(1)
		return

	var pause_scene := load("res://scenes/ui/pause_menu.tscn") as PackedScene
	if pause_scene == null:
		push_error("[menu-ui] Missing pause_menu.tscn.")
		get_tree().quit(1)
		return
	var pause := pause_scene.instantiate() as PauseMenu
	if pause == null:
		push_error("[menu-ui] Failed to instantiate pause menu scene.")
		get_tree().quit(1)
		return
	pause.size = Vector2(1280, 720)
	add_child(pause)
	await get_tree().process_frame
	if pause._reset_button == null:
		push_error("[menu-ui] Pause menu did not build its journey overview.")
		get_tree().quit(1)
		return
	print("[menu-ui] OK - title menu scene and pause menu instantiated with expected controls.")
	get_tree().quit(0)

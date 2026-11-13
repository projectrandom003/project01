extends Node

func _ready() -> void:
	var main := MainMenu.new()
	main.size = Vector2(1280, 720)
	add_child(main)
	await get_tree().process_frame
	if main._play_button == null or main._party_visuals.is_empty():
		push_error("[menu-ui] Main menu did not build its navigation and party showcase.")
		get_tree().quit(1)
		return
	for visual in main._party_visuals:
		print("[menu-ui] Party art: ", visual.character_art_report())

	var pause := PauseMenu.new()
	pause.size = Vector2(1280, 720)
	add_child(pause)
	await get_tree().process_frame
	if pause._reset_button == null:
		push_error("[menu-ui] Pause menu did not build its journey overview.")
		get_tree().quit(1)
		return
	print("[menu-ui] OK — title menu, animated party showcase and organized pause menu instantiated.")
	get_tree().quit(0)

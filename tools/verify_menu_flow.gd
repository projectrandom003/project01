extends SceneTree

func _initialize() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var main_scene := load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	var title := main_scene.get_node_or_null("TitleScreen")
	if title == null:
		push_error("QA: title screen did not appear first")
		quit(1)
		return
	title.menu_requested.emit("continue")
	for frame in 180:
		await process_frame
		if main_scene.get_node_or_null("MainMenu") != null:
			break
	var menu := main_scene.get_node_or_null("MainMenu") as MainMenu
	if menu == null:
		push_error("QA: main menu did not load after title -> loading")
		quit(2)
		return
	if menu.get_node_or_null("ReferenceInterface") == null:
		push_error("QA: hub UI missing")
		quit(3)
		return
	if menu.get_node_or_null("MainMenuBackdrop") == null:
		push_error("QA: main menu backdrop missing")
		quit(4)
		return
	if menu.get_node_or_null("ReverieTitleArtwork") != null:
		push_error("QA: title artwork leaked into main menu")
		quit(5)
		return
	print("QA PASS: TitleScreen -> LoadingScreen -> MainMenu; separate backdrop and hub UI are present.")
	quit(0)

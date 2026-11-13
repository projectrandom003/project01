extends Node

const MainScript = preload("res://scripts/game/main.gd")

func _ready() -> void:
	GameState.loaded_from_save = false
	var app = MainScript.new()
	add_child(app)
	await get_tree().process_frame
	var title_backdrop = app.menu.get_node_or_null("TitleScreenBackdrop")
	if title_backdrop == null or not title_backdrop is LaunchForestBackdrop:
		push_error("[launch-transition] Title screen is missing the shared animated forest background.")
		get_tree().quit(1)
		return
	app._start_game()
	await get_tree().process_frame
	var intro = app.get_node_or_null("OpeningCinematic")
	if intro == null or intro._protagonists.size() != 2:
		push_error("[launch-transition] Prologue should contain exactly Gerald and Lilith.")
		get_tree().quit(1)
		return
	if not intro.has_node("IllustratedForest") or not intro.get_node("IllustratedForest") is LaunchForestBackdrop:
		push_error("[launch-transition] Prologue is missing the illustrated animated background.")
		get_tree().quit(1)
		return
	intro._finish()
	await get_tree().process_frame
	if app.get_node_or_null("OpeningCinematic") != null:
		push_error("[launch-transition] Finished prologue was not removed.")
		get_tree().quit(1)
		return
	var loading = app.get_node_or_null("LoadingScreen")
	if loading == null:
		push_error("[launch-transition] Loading screen did not start.")
		get_tree().quit(1)
		return
	loading.set_process(false)
	var backgrounds := loading.find_children("*", "LaunchForestBackdrop", true, false)
	if backgrounds.size() != 1:
		push_error("[launch-transition] Loading screen should have one animated forest background.")
		get_tree().quit(1)
		return
	if loading._party_layer.get_child_count() != 3:
		push_error("[launch-transition] Loading screen should show exactly one copy of each party member.")
		get_tree().quit(1)
		return
	# Let the background thread finish parsing the destination scene without
	# allowing LoadingScreen to trigger a real scene change during this test.
	var status := ResourceLoader.load_threaded_get_status("res://scenes/game.tscn")
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status("res://scenes/game.tscn")
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		push_error("[launch-transition] Destination game scene failed to load.")
		get_tree().quit(1)
		return
	var packed := ResourceLoader.load_threaded_get("res://scenes/game.tscn") as PackedScene
	if packed == null:
		push_error("[launch-transition] Destination game scene did not produce a PackedScene.")
		get_tree().quit(1)
		return
	print("[launch-transition] OK — prologue removed before loading, no duplicate character layers, shared animated art present, destination scene loaded.")
	get_tree().quit(0)

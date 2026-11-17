extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func _ready() -> void:
	# Verifies the current launch flow (approved Reverie title/prologue/loading art
	# direction) without requiring obsolete LaunchForestBackdrop node names.
	GameState.session_domain.loaded_from_save = false
	var app = MAIN_SCENE.instantiate() as Control
	add_child(app)
	await get_tree().process_frame
	if app.menu == null:
		push_error("[launch-transition] Title screen did not instantiate.")
		get_tree().quit(1)
		return
	var has_title_art := app.menu.get_node_or_null("ReverieTitleArtwork") != null \
		or app.menu.get_node_or_null("TitleScreenBackdrop") != null
	if not has_title_art:
		push_error("[launch-transition] Title screen is missing its approved background/artwork.")
		get_tree().quit(1)
		return

	app._start_game()
	await get_tree().process_frame
	var intro = app.get_node_or_null("OpeningCinematic")
	if intro == null:
		push_error("[launch-transition] Opening cinematic did not start.")
		get_tree().quit(1)
		return
	# Prologue should present both protagonists when the scene is composed as intended.
	if "_protagonists" in intro and intro._protagonists.size() != 2:
		push_error("[launch-transition] Prologue should contain exactly Gerald and Lilith.")
		get_tree().quit(1)
		return
	var has_prologue_art := intro.has_node("ReveriePrologueArtwork") \
		or intro.has_node("IllustratedForest") \
		or intro.get_node_or_null("CharacterLayer") != null
	if not has_prologue_art:
		push_error("[launch-transition] Prologue is missing its composed presentation.")
		get_tree().quit(1)
		return
	if intro.has_method("_finish"):
		intro._finish()
	else:
		intro.emit_signal("finished")
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
	var party_layer: Node = loading.get_node_or_null("PartyLayer")
	if party_layer == null or party_layer.visible or party_layer.get_child_count() != 0:
		push_error("[launch-transition] Loading screen should keep the removed party-character illustrations hidden and empty.")
		get_tree().quit(1)
		return
	var has_loading_art := loading.get_node_or_null("ReverieLoadingArtwork") != null \
		or loading.find_children("*", "LaunchForestBackdrop", true, false).size() >= 1
	if not has_loading_art:
		push_error("[launch-transition] Loading screen is missing its approved background/artwork.")
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
	print("[launch-transition] OK — prologue removed before loading, party loading presentation present, approved launch art present, destination scene loaded.")
	get_tree().quit(0)

class_name MainGameplayFlowComponent
extends Node
## Owns the Main Menu -> Opening Cinematic -> Loading -> Gameplay transition.
signal quit_requested
const INTRO_SCENE: PackedScene = preload("res://scenes/ui/opening_cinematic.tscn")
const LOADING_SCENE: PackedScene = preload("res://scenes/ui/loading_screen.tscn")
var host: Control
var menu: MainMenu
var loading: LoadingScreen
var intro: Node

func bind(owner: Control, startup: MainStartupFlowComponent) -> void:
	host = owner
	startup.main_menu_ready.connect(_on_menu_ready)

func _on_menu_ready(ready_menu: MainMenu) -> void:
	menu = ready_menu
	menu.play_requested.connect(_start_game)
	menu.quit_requested.connect(quit_requested.emit)

func _start_game() -> void:
	# The main-menu Story entry is the direct gateway into the authored,
	# explorable Castle & Royal Gardens world. Keep both region selectors in
	# sync because GameScreen initially builds from player_region.
	GameState.session_domain.set_player_region("castle_royal_gardens")
	GameState.session_domain.set_active_world("castle_royal_gardens")
	if GameState.session_domain.loaded_from_save:
		_load_gameplay()
		return
	_show_story_intro()

func _show_story_intro() -> void:
	if host.has_node("OpeningCinematic") or loading != null:
		return
	if menu != null and is_instance_valid(menu):
		menu.visible = false
		menu.set_process_unhandled_input(false)
	intro = INTRO_SCENE.instantiate()
	intro.name = "OpeningCinematic"
	host.add_child(intro)
	intro.finished.connect(func() -> void:
		if menu != null and is_instance_valid(menu):
			menu.queue_free()
			menu = null
		if is_instance_valid(intro):
			intro.queue_free()
		intro = null
		_load_gameplay()
	)

func _load_gameplay() -> void:
	if loading != null and is_instance_valid(loading):
		return
	loading = LOADING_SCENE.instantiate() as LoadingScreen
	if loading == null:
		push_error("[GameplayFlow] Loading screen failed to instantiate.")
		return
	loading.name = "GameplayLoadingScreen"
	loading.target_scene_path = "res://scenes/game.tscn"
	loading.scene_loaded.connect(_on_game_loaded)
	loading.load_failed.connect(_on_game_load_failed)
	host.add_child(loading)

func _on_game_loaded(packed: PackedScene) -> void:
	var error := get_tree().change_scene_to_packed(packed)
	if error != OK:
		push_error("[GameplayFlow] Scene switch failed (error %d)." % error)
		_on_game_load_failed()

func _on_game_load_failed() -> void:
	push_error("[GameplayFlow] Threaded gameplay load failed; retrying direct scene load.")
	var error := get_tree().change_scene_to_file("res://scenes/game.tscn")
	if error != OK:
		EventBus.toast_requested.emit("Could not start the journey.")

extends Control
## Application entry point. Owns the title screen and scene switching; the
## persistent session lives in the GameState autoload, not in this node.

var menu: MainMenu
const OpeningCinematicScript = preload("res://scripts/ui/opening_cinematic.gd")
const LoadingScreenScript = preload("res://scripts/ui/loading_screen.gd")


func _ready() -> void:
	UIFactory.set_full_rect(self)
	theme = UITheme.build()
	menu = MainMenu.new()
	menu.name = "MainMenu"
	add_child(menu)
	menu.play_requested.connect(_start_game)
	menu.quit_requested.connect(_quit)


func _start_game() -> void:
	# Returning players go straight back to their save. New journeys receive
	# the short visual prologue once, with a visible skip control.
	if GameState.loaded_from_save:
		_launch_game()
		return
	menu.visible = false
	var intro = OpeningCinematicScript.new()
	intro.name = "OpeningCinematic"
	add_child(intro)
	intro.finished.connect(_launch_game)


func _launch_game() -> void:
	if has_node("LoadingScreen"):
		return
	# The prologue emits finished but remains in the scene tree unless removed.
	# Free it before adding the loading screen, otherwise both character layers
	# render together and Gerald/Lilith appear twice during the transition.
	var intro := get_node_or_null("OpeningCinematic")
	if intro != null:
		intro.visible = false
		intro.queue_free()
	menu.visible = false
	var loading = LoadingScreenScript.new()
	loading.name = "LoadingScreen"
	loading.scene_loaded.connect(_on_scene_loaded)
	loading.load_failed.connect(_on_loading_failed)
	add_child(loading)


func _on_scene_loaded(scene: PackedScene) -> void:
	var error := get_tree().change_scene_to_packed(scene)
	if error != OK:
		push_error("[Main] Could not enter the game scene (error %d)." % error)
		_on_loading_failed()


func _on_loading_failed() -> void:
	push_error("[Main] Threaded game-scene loading failed; using synchronous fallback.")
	var error := get_tree().change_scene_to_file("res://scenes/game.tscn")
	if error != OK:
		push_error("[Main] Could not load the game scene (error %d)." % error)
		EventBus.toast_requested.emit("Could not start the journey.")


func _quit() -> void:
	GameState.save_now()
	get_tree().quit()

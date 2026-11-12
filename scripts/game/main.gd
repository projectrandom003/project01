extends Control
## Application entry point. Owns the title screen and scene switching; the
## persistent session lives in the GameState autoload, not in this node.

var menu: MainMenu


func _ready() -> void:
	UIFactory.set_full_rect(self)
	theme = UITheme.build()
	menu = MainMenu.new()
	menu.name = "MainMenu"
	add_child(menu)
	menu.play_requested.connect(_start_game)
	menu.quit_requested.connect(_quit)


func _start_game() -> void:
	var error := get_tree().change_scene_to_file("res://scenes/game.tscn")
	if error != OK:
		push_error("[Main] Could not load the game scene (error %d)." % error)
		EventBus.toast_requested.emit("Could not start the journey.")


func _quit() -> void:
	GameState.save_now()
	get_tree().quit()

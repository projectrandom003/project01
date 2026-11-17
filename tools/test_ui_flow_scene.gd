extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	assert(packed != null, "Main scene failed to load")
	var host := packed.instantiate() as Control
	add_child(host)
	await get_tree().process_frame
	assert(host.has_node("StartupFlow"), "StartupFlow node missing")
	assert(host.has_node("GameplayFlow"), "GameplayFlow node missing")
	var startup := host.get_node("StartupFlow") as MainStartupFlowComponent
	startup.call("_on_title_action", "continue")
	await get_tree().create_timer(3.0).timeout
	assert(host.has_node("MainMenu"), "MainMenu did not appear after LoadingScreen")
	assert(not host.has_node("LoadingScreen"), "LoadingScreen remained visible after transition")
	var menu := host.get_node("MainMenu") as MainMenu
	assert(menu.has_node("Navigation") and menu.has_node("Skin") and menu.has_node("Overlays"), "Main menu components missing")
	print("UI FLOW TEST PASSED: Title -> Loading -> Main Menu; all node components bound.")
	get_tree().quit(0)

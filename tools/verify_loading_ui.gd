extends Node

func _ready() -> void:
	var loading := LoadingScreen.new()
	loading.size = Vector2(1280, 720)
	loading.scene_loaded.connect(_on_loaded)
	loading.load_failed.connect(_on_failed)
	add_child(loading)

func _on_loaded(scene: PackedScene) -> void:
	if scene == null:
		push_error("[loading-ui] Threaded loader returned an empty scene.")
		get_tree().quit(1)
		return
	print("[loading-ui] OK — animated loading interface reached the packed game scene.")
	get_tree().quit(0)

func _on_failed() -> void:
	push_error("[loading-ui] Threaded game-scene load failed.")
	get_tree().quit(1)

extends Node

const LOADING_SCENE := "res://scenes/ui/loading_screen.tscn"

func _ready() -> void:
	var packed := load(LOADING_SCENE) as PackedScene
	if packed == null:
		push_error("[loading-ui] Could not load the authored loading-screen scene.")
		get_tree().quit(1)
		return

	var loading := packed.instantiate() as LoadingScreen
	if loading == null:
		push_error("[loading-ui] Authored scene root is not a LoadingScreen.")
		get_tree().quit(1)
		return

	if loading.get_node_or_null("LiveArtworkProgressFill") == null:
		push_error("[loading-ui] Missing authored progress bar.")
		get_tree().quit(1)
		return

	if loading.get_node_or_null("ReverieLoadingArtwork") == null:
		push_error("[loading-ui] Missing authored loading artwork.")
		get_tree().quit(1)
		return

	loading.set_deferred("size", Vector2(1280, 720))
	loading.scene_loaded.connect(_on_loaded)
	loading.load_failed.connect(_on_failed)
	add_child(loading)

func _on_loaded(scene: PackedScene) -> void:
	if scene == null:
		push_error("[loading-ui] Threaded loader returned an empty scene.")
		get_tree().quit(1)
		return
	print("[loading-ui] OK — authored loading screen, artwork, progress bar and threaded game-scene load verified.")
	get_tree().quit(0)

func _on_failed() -> void:
	push_error("[loading-ui] Threaded game-scene load failed.")
	get_tree().quit(1)

class_name LoadingScreen
extends Control
## Animated, art-led loading interstitial. The scene loads on a worker thread;
## the screen stays visible briefly so the transition never flashes.

signal scene_loaded(scene: PackedScene)
signal load_failed

const SCENE_PATH := "res://scenes/game.tscn"
const MINIMUM_DISPLAY := 1.15
const LORE_LINES := [
	"The First Tree remembers every name spoken beneath its branches.",
	"Some paths lead home. Others lead to the truth.",
	"Not every spirit wishes to be found.",
	"Even the quietest glade has a story beneath its roots."
]

var _elapsed := 0.0
var _lore_elapsed := 0.0
var _lore_index := 0
var _progress := 0.0
var _request_failed := false
var _emitted := false
var _progress_bar: ProgressBar
var _progress_label: Label
var _lore_label: Label
var _party_layer: Node2D

func _ready() -> void:
	UIFactory.set_full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Artwork and the live progress fill are authored in loading_screen.tscn.
	_progress_bar = get_node("LiveArtworkProgressFill") as ProgressBar
	_progress_label = null
	var artwork := get_node("ReverieLoadingArtwork") as TextureRect
	if artwork.texture == null:
		artwork.visible = false
		var fallback := LaunchForestBackdrop.new()
		UIFactory.set_full_rect(fallback)
		add_child(fallback)
	_party_layer = get_node("PartyLayer") as Node2D
	_build_party()

	var error := ResourceLoader.load_threaded_request(SCENE_PATH, "PackedScene", true)
	if error != OK and error != ERR_BUSY:
		_request_failed = true

func _process(delta: float) -> void:
	if _emitted:
		return
	_elapsed += delta
	var actual_progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(SCENE_PATH, actual_progress)
	if not actual_progress.is_empty():
		_progress = maxf(_progress, float(actual_progress[0]) * 100.0)
	# Keep the bar moving gently even while the engine is resolving resources.
	_progress = maxf(_progress, minf(82.0, _elapsed * 38.0))
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		_progress = 100.0
	if _progress_bar != null:
		_progress_bar.value = _progress
	if _progress_label != null:
		_progress_label.text = "LOADING...  %d%%" % int(_progress)

	if _elapsed < MINIMUM_DISPLAY:
		return
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed := ResourceLoader.load_threaded_get(SCENE_PATH) as PackedScene
		if packed != null:
			_emitted = true
			scene_loaded.emit(packed)
		else:
			_emitted = true
			load_failed.emit()
	elif status == ResourceLoader.THREAD_LOAD_FAILED or _request_failed:
		_emitted = true
		load_failed.emit()

func _build_party() -> void:
	var ids: Array[String] = []
	for instance in GameState.party_instances():
		ids.append(str(instance.char_id))
	if ids.is_empty():
		for starter_id in ["gerald", "lilith", "kael"]:
			ids.append(starter_id)
	for i in range(mini(ids.size(), 3)):
		var definition: CharacterDef = ContentDB.get_character(ids[i])
		if definition == null:
			continue
		var visual := ActorVisual.new()
		visual.visual_scale = 2.35
		visual.facing = 1.0
		visual.setup(definition.palette, ActorVisual.Kind.HUMAN, definition.id, definition.race, definition.element)
		visual.configure_character(definition.id)
		visual.position = Vector2(0, 0)
		_party_layer.add_child(visual)
		visual.set_meta("party_slot", i)
	_party_layer.set_process(true)
	resized.connect(_layout_party)
	call_deferred("_layout_party")

func _layout_party() -> void:
	if _party_layer == null:
		return
	var visuals := _party_layer.get_children()
	var count := visuals.size()
	for i in range(count):
		var visual := visuals[i] as ActorVisual
		visual.position = Vector2(size.x * 0.16 + float(i) * minf(size.x * 0.085, 102.0), size.y * 0.84)

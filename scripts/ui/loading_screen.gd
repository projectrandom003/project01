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

	# The loading illustration already contains the logo, title, and ornate
	# progress-frame. Keep those pixels unobstructed and bind only the live fill
	# to the exact inner track of the artwork.
	var artwork := TextureRect.new()
	artwork.name = "ReverieLoadingArtwork"
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var loading_texture := load("res://assets/ui/backgrounds/reverie_loading_screen.jpg") as Texture2D
	if loading_texture != null:
		artwork.texture = loading_texture
		UIFactory.set_full_rect(artwork)
		add_child(artwork)
	else:
		var backdrop := LaunchForestBackdrop.new()
		UIFactory.set_full_rect(backdrop)
		add_child(backdrop)

	_progress_label = Label.new()
	_progress_label.name = "LiveLoadingCaption"
	_progress_label.text = "LOADING...  0%"
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_size_override("font_size", 19)
	_progress_label.add_theme_color_override("font_color", Color("#f5e9f3"))
	_progress_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.04, 0.95))
	_progress_label.add_theme_constant_override("shadow_offset_x", 1)
	_progress_label.add_theme_constant_override("shadow_offset_y", 2)
	_progress_label.anchor_left = 0.36
	_progress_label.anchor_right = 0.64
	_progress_label.anchor_top = 0.735
	_progress_label.anchor_bottom = 0.785
	add_child(_progress_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.name = "LiveArtworkProgressFill"
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 100.0
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false
	_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_bar.anchor_left = 0.276
	_progress_bar.anchor_right = 0.704
	_progress_bar.anchor_top = 0.812
	_progress_bar.anchor_bottom = 0.833
	var track := StyleBoxFlat.new()
	track.bg_color = Color("#171020")
	track.set_corner_radius_all(5)
	track.content_margin_left = 0
	track.content_margin_right = 0
	track.content_margin_top = 0
	track.content_margin_bottom = 0
	_progress_bar.add_theme_stylebox_override("background", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#d9a0d8")
	fill.set_corner_radius_all(5)
	fill.shadow_color = Color(0.88, 0.43, 0.78, 0.65)
	fill.shadow_size = 5
	fill.content_margin_left = 0
	fill.content_margin_right = 0
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	_progress_bar.add_theme_stylebox_override("fill", fill)
	add_child(_progress_bar)

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

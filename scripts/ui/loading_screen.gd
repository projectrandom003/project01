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
	var backdrop := LaunchForestBackdrop.new()
	UIFactory.set_full_rect(backdrop)
	add_child(backdrop)

	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.045, 0.22)
	UIFactory.set_full_rect(shade)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	_party_layer = Node2D.new()
	_party_layer.z_index = 2
	add_child(_party_layer)
	_build_party()

	var header := UIFactory.vbox(3)
	header.position = Vector2(34, 30)
	header.add_child(UIFactory.heading("REVERIE", 27, UITheme.GOLD_BRIGHT))
	header.add_child(UIFactory.label("AETHERIA  /  GREENWARD", 10, UITheme.TEAL))
	add_child(header)

	var panel := UIFactory.panel(Color(0.025, 0.045, 0.075, 0.91), Color(0.72, 0.67, 0.52, 0.32), 14, 1, 18, true)
	panel.anchor_left = 0.47
	panel.anchor_right = 0.97
	panel.anchor_top = 0.78
	panel.anchor_bottom = 0.97
	panel.offset_left = 0
	panel.offset_right = 0
	panel.offset_top = 0
	panel.offset_bottom = 0
	panel.z_index = 5
	add_child(panel)
	var column := UIFactory.vbox(7)
	panel.add_child(column)
	column.add_child(UIFactory.label("ENTERING THE WHISPERING GLADE", 9, UITheme.TEAL))
	_lore_label = UIFactory.label(LORE_LINES[0], 13, UITheme.TEXT)
	_lore_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_lore_label)
	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 100.0
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size = Vector2(0, 12)
	column.add_child(_progress_bar)
	_progress_label = UIFactory.label("Preparing the world  ·  0%", 9, UITheme.TEXT_FAINT)
	column.add_child(_progress_label)

	var error := ResourceLoader.load_threaded_request(SCENE_PATH, "PackedScene", true)
	if error != OK and error != ERR_BUSY:
		_request_failed = true

func _process(delta: float) -> void:
	if _emitted:
		return
	_elapsed += delta
	_lore_elapsed += delta
	if _lore_elapsed >= 3.8:
		_lore_elapsed = 0.0
		_lore_index = (_lore_index + 1) % LORE_LINES.size()
		_lore_label.text = LORE_LINES[_lore_index]

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
		_progress_label.text = "Preparing the world  ·  %d%%" % int(_progress)

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

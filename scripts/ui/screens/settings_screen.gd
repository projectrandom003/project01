class_name SettingsScreen
extends OverlayScreen
## In-game settings overlay. Applies and persists audio/display settings via a
## user:// ConfigFile and provides controls reference/rebinding where supported.

const CONFIG_PATH := "user://settings.cfg"
const SETTINGS_LAYOUT_SCENE: PackedScene = preload("res://scenes/ui/components/settings_screen_layout.tscn")
const SECTION_AUDIO := "audio"
const SECTION_DISPLAY := "display"
const SECTION_CONTROLS := "controls"

const REBINDABLE_ACTIONS := [
	["move_up", "Move Up"],
	["move_down", "Move Down"],
	["move_left", "Move Left"],
	["move_right", "Move Right"],
	["interact", "Interact"],
	["open_menu", "Menu / Pause"],
	["open_inventory", "Inventory"],
	["open_quests", "Quest Log"],
	["open_gacha", "Summon"],
	["open_collection", "Roster"],
]

var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _fullscreen_check: CheckButton
var _resolution_option: OptionButton
var _apply_button: Button
var _cancel_button: Button
var _defaults_button: Button
var _controls_box: VBoxContainer
var _columns_layout: GridContainer
@onready var _controls_component: SettingsControlsComponent = $Controls as SettingsControlsComponent
@onready var _persistence_component: SettingsPersistenceComponent = $Persistence as SettingsPersistenceComponent

var _working: Dictionary = {}
var _saved: Dictionary = {}
var _capturing_action: String = ""
var _capture_button: Button = null
var _dirty: bool = false
static var _project_default_input_events: Dictionary = {}
var _default_input_events: Dictionary = {}


func _ready() -> void:
	_controls_component.bind(self)
	_persistence_component.bind(self)
	super._ready()

func _init() -> void:
	screen_title = "Settings"
	screen_subtitle = "Audio, display, controls, and general"


func _update_columns_layout() -> void:
	if _columns_layout == null:
		return
	_set_columns_for_width(float(DisplayServer.window_get_size().x))


func _set_columns_for_width(viewport_width: float) -> void:
	if _columns_layout != null:
		# Stack the settings sections on narrow windows; retain two columns on desktop.
		_columns_layout.columns = 1 if viewport_width < 1000.0 else 2


func _build_content() -> void:
	# Capture project defaults once so Cancel and legacy settings can restore
	# real InputEvents, not merely their display labels.
	if _project_default_input_events.is_empty():
		for pair in REBINDABLE_ACTIONS:
			var action := str(pair[0])
			_project_default_input_events[action] = InputMap.action_get_events(action).duplicate(true)
	_default_input_events = _project_default_input_events.duplicate(true)
	_saved = _load_config()
	_working = _saved.duplicate(true)

	var layout := SETTINGS_LAYOUT_SCENE.instantiate() as VBoxContainer
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var settings_scroll := ScrollContainer.new()
	settings_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	settings_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	settings_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content.add_child(settings_scroll)
	settings_scroll.add_child(layout)
	_columns_layout = layout.get_node("Columns") as GridContainer
	_update_columns_layout()
	if not get_window().size_changed.is_connected(_update_columns_layout):
		get_window().size_changed.connect(_update_columns_layout)
	_master_slider = layout.get_node("Columns/Left/MasterSlider") as HSlider
	_music_slider = layout.get_node("Columns/Left/MusicSlider") as HSlider
	_sfx_slider = layout.get_node("Columns/Left/SFXSlider") as HSlider
	_fullscreen_check = layout.get_node("Columns/Left/FullscreenCheck") as CheckButton
	_resolution_option = layout.get_node("Columns/Left/ResolutionRow/ResolutionOption") as OptionButton
	_controls_box = layout.get_node("Columns/Right/ControlsScroll/ControlsBox") as VBoxContainer
	_defaults_button = layout.get_node("Footer/DefaultsButton") as Button
	_cancel_button = layout.get_node("Footer/CancelButton") as Button
	_apply_button = layout.get_node("Footer/ApplyButton") as Button

	_master_slider.value = clampf(float(_working.get("master_volume", 1.0)), 0.0, 1.0)
	_music_slider.value = clampf(float(_working.get("music_volume", 1.0)), 0.0, 1.0)
	_sfx_slider.value = clampf(float(_working.get("sfx_volume", 1.0)), 0.0, 1.0)
	_fullscreen_check.button_pressed = bool(_working.get("fullscreen", false))
	_populate_resolutions(str(_working.get("resolution", _current_resolution_string())))

	_master_slider.value_changed.connect(func(_v: float) -> void: _mark_dirty())
	_music_slider.value_changed.connect(func(_v: float) -> void: _mark_dirty())
	_sfx_slider.value_changed.connect(func(_v: float) -> void: _mark_dirty())
	_fullscreen_check.toggled.connect(func(v: bool) -> void:
		_working["fullscreen"] = v
		_mark_dirty()
	)
	_resolution_option.item_selected.connect(func(_idx: int) -> void:
		_working["resolution"] = _resolution_option.get_item_text(_resolution_option.selected)
		_mark_dirty()
	)
	_defaults_button.pressed.connect(_restore_defaults)
	_apply_button.pressed.connect(_apply)
	_cancel_button.pressed.connect(_cancel)
	_rebuild_controls()
	_apply_runtime(_saved, false)


func _populate_resolutions(current: String) -> void:
	_resolution_option.clear()
	var options := ["1280x720", "1600x900", "1920x1080", "2560x1440"]
	var screen_size := DisplayServer.screen_get_size()
	var screen_str := "%dx%d" % [screen_size.x, screen_size.y]
	if not options.has(screen_str):
		options.append(screen_str)
	var found := -1
	for i in options.size():
		_resolution_option.add_item(options[i])
		if options[i] == current:
			found = i
	if found >= 0:
		_resolution_option.select(found)
	else:
		_resolution_option.add_item(current)
		_resolution_option.select(_resolution_option.item_count - 1)


func _current_resolution_string() -> String:
	var size := DisplayServer.window_get_size()
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		size = DisplayServer.screen_get_size()
	return "%dx%d" % [size.x, size.y]


func _rebuild_controls() -> void:
	if _controls_component != null:
		_controls_component.rebuild_controls()

func _binding_label(action: String, saved_controls: Dictionary, defaults: Dictionary) -> String:
	return _controls_component.binding_label(action, saved_controls, defaults) if _controls_component != null else "Unbound"

func _default_controls() -> Dictionary:
	return _controls_component.default_controls() if _controls_component != null else {}

func _begin_capture(action: String, button: Button, label_text: String) -> void:
	if _controls_component != null:
		_controls_component.begin_capture(action, button, label_text)

func _unhandled_input(event: InputEvent) -> void:
	if _controls_component != null and _controls_component.handle_event(event):
		return
	super._unhandled_input(event)

func _assign_event(action: String, event: InputEvent) -> void:
	if _controls_component != null:
		_controls_component.assign_event(action, event)

func _mark_dirty() -> void:
	_dirty = true


func _collect_working_from_ui() -> Dictionary:
	return _persistence_component.collect_working_from_ui() if _persistence_component != null else _working.duplicate(true)

func _apply() -> void:
	if _persistence_component != null:
		_persistence_component.apply()

func _cancel() -> void:
	if _persistence_component != null:
		_persistence_component.cancel()

func _restore_defaults() -> void:
	if _persistence_component != null:
		_persistence_component.restore_defaults()

func _apply_runtime(settings: Dictionary, persist_controls: bool) -> void:
	if _persistence_component != null:
		_persistence_component.apply_runtime(settings, persist_controls)

func _set_bus_volume(bus_name: String, linear: float) -> void:
	if _persistence_component != null:
		_persistence_component.set_bus_volume(bus_name, linear)

func _parse_resolution(text: String) -> Vector2i:
	return _persistence_component.parse_resolution(text) if _persistence_component != null else DisplayServer.window_get_size()

func _default_settings() -> Dictionary:
	return _persistence_component.default_settings() if _persistence_component != null else {}

func _load_config() -> Dictionary:
	return _persistence_component.load_config() if _persistence_component != null else {}

func _save_config(settings: Dictionary) -> void:
	if _persistence_component != null:
		_persistence_component.save_config(settings)

func _serialize_event(event: InputEvent) -> Dictionary:
	return _controls_component.serialize_event(event) if _controls_component != null else {}

func _deserialize_event(data: Dictionary) -> InputEvent:
	return _controls_component.deserialize_event(data) if _controls_component != null else null

func _apply_controls(controls: Dictionary) -> void:
	if _controls_component != null:
		_controls_component.apply_controls(controls)

func close_screen() -> void:
	# Cancel/discard on close to avoid accidental partial state; Apply persists.
	_apply_runtime(_saved, true)
	super.close_screen()

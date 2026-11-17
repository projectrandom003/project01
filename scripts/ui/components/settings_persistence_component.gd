class_name SettingsPersistenceComponent
extends Node
## Owns staged settings, ConfigFile persistence and runtime audio/display application.

var screen: SettingsScreen


func bind(owner_screen: SettingsScreen) -> void:
	screen = owner_screen

func collect_working_from_ui() -> Dictionary:
	var d := screen._working.duplicate(true)
	d["master_volume"] = screen._master_slider.value if screen._master_slider else float(screen._saved.get("master_volume", 1.0))
	d["music_volume"] = screen._music_slider.value if screen._music_slider else float(screen._saved.get("music_volume", 1.0))
	d["sfx_volume"] = screen._sfx_slider.value if screen._sfx_slider else float(screen._saved.get("sfx_volume", 1.0))
	d["fullscreen"] = screen._fullscreen_check.button_pressed if screen._fullscreen_check else bool(screen._saved.get("fullscreen", false))
	d["resolution"] = screen._resolution_option.get_item_text(screen._resolution_option.selected) if screen._resolution_option and screen._resolution_option.selected >= 0 else str(screen._saved.get("resolution", screen._current_resolution_string()))
	return d



func apply() -> void:
	screen._working = collect_working_from_ui()
	apply_runtime(screen._working, true)
	save_config(screen._working)
	screen._saved = screen._working.duplicate(true)
	screen._dirty = false
	EventBus.toast_requested.emit("Settings applied.")



func cancel() -> void:
	screen._working = screen._saved.duplicate(true)
	apply_runtime(screen._saved, true)
	screen.close_screen()



func restore_defaults() -> void:
	# Defaults are staged like every other edit; Apply commits them, Cancel
	# restores the previously saved configuration.
	screen._working = default_settings()
	# Rebuild UI to reflect defaults
	if screen._master_slider: screen._master_slider.value = float(screen._working.master_volume)
	if screen._music_slider: screen._music_slider.value = float(screen._working.music_volume)
	if screen._sfx_slider: screen._sfx_slider.value = float(screen._working.sfx_volume)
	if screen._fullscreen_check: screen._fullscreen_check.button_pressed = bool(screen._working.fullscreen)
	if screen._resolution_option: screen._populate_resolutions(str(screen._working.resolution))
	screen._rebuild_controls()
	screen._mark_dirty()
	EventBus.toast_requested.emit("Settings restored to defaults.")



func apply_runtime(settings: Dictionary, persist_controls: bool) -> void:
	var master := clampf(float(settings.get("master_volume", 1.0)), 0.0, 1.0)
	var music := clampf(float(settings.get("music_volume", 1.0)), 0.0, 1.0)
	var sfx := clampf(float(settings.get("sfx_volume", 1.0)), 0.0, 1.0)
	set_bus_volume("Master", master)
	if AudioServer.get_bus_index("Music") >= 0:
		set_bus_volume("Music", music)
	if AudioServer.get_bus_index("SFX") >= 0:
		set_bus_volume("SFX", sfx)
	var fullscreen := bool(settings.get("fullscreen", false))
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var res := parse_resolution(str(settings.get("resolution", screen._current_resolution_string())))
		if res.x >= 640 and res.y >= 360:
			DisplayServer.window_set_size(res)
	screen._controls_component.apply_controls(settings.get("controls", {}))



func set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var db := linear_to_db(maxf(linear, 0.001))
	AudioServer.set_bus_volume_db(idx, db)



func parse_resolution(text: String) -> Vector2i:
	var parts := text.split("x")
	if parts.size() != 2:
		return DisplayServer.window_get_size()
	return Vector2i(int(parts[0]), int(parts[1]))



func default_settings() -> Dictionary:
	return {
		"master_volume": 1.0,
		"music_volume": 1.0,
		"sfx_volume": 1.0,
		"fullscreen": false,
		"resolution": "1280x720",
		"controls": {},
	}



func load_config() -> Dictionary:
	var cfg := ConfigFile.new()
	var err := cfg.load(SettingsScreen.CONFIG_PATH)
	var defaults := default_settings()
	if err != OK:
		return defaults
	for key in ["master_volume", "music_volume", "sfx_volume"]:
		defaults[key] = float(cfg.get_value(SettingsScreen.SECTION_AUDIO, key, defaults[key]))
	for key in ["fullscreen", "resolution"]:
		defaults[key] = cfg.get_value(SettingsScreen.SECTION_DISPLAY, key, defaults[key])
	var controls: Dictionary = defaults.get("controls", {})
	if cfg.has_section(SettingsScreen.SECTION_CONTROLS):
		for key in cfg.get_section_keys(SettingsScreen.SECTION_CONTROLS):
			controls[key] = cfg.get_value(SettingsScreen.SECTION_CONTROLS, key, "")
	defaults["controls"] = controls
	return defaults



func save_config(settings: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SettingsScreen.SECTION_AUDIO, "master_volume", float(settings.get("master_volume", 1.0)))
	cfg.set_value(SettingsScreen.SECTION_AUDIO, "music_volume", float(settings.get("music_volume", 1.0)))
	cfg.set_value(SettingsScreen.SECTION_AUDIO, "sfx_volume", float(settings.get("sfx_volume", 1.0)))
	cfg.set_value(SettingsScreen.SECTION_DISPLAY, "fullscreen", bool(settings.get("fullscreen", false)))
	cfg.set_value(SettingsScreen.SECTION_DISPLAY, "resolution", str(settings.get("resolution", "1280x720")))
	var controls: Dictionary = settings.get("controls", {})
	for key in controls.keys():
		cfg.set_value(SettingsScreen.SECTION_CONTROLS, str(key), controls[key])
	var save_error := cfg.save(SettingsScreen.CONFIG_PATH)
	if save_error != OK:
		push_error("[Settings] Could not save settings.cfg (error %d)." % save_error)



class_name MainMenu
extends Control
## Art-forward title screen. The party stands in the world scene; navigation is
## deliberately short and consistent instead of presenting the cast as cards.

signal play_requested
signal quit_requested

const STARTERS := ["gerald", "lilith", "kael"]

var _play_button: Button
var _reset_button: Button
var _summary_label: Label
var _party_names_label: Label
var _party_layer: Node2D
var _party_visuals: Array[ActorVisual] = []
var _reset_armed: bool = false

func _ready() -> void:
	UIFactory.set_full_rect(self)
	theme = UITheme.build()

	var artwork := TextureRect.new()
	artwork.name = "ReverieTitleArtwork"
	artwork.texture = load("res://assets/ui/backgrounds/reverie_title_screen.jpg") as Texture2D
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIFactory.set_full_rect(artwork)
	add_child(artwork)

	var shade := ColorRect.new()
	shade.name = "TitleArtworkReadabilityShade"
	shade.color = Color(0.012, 0.009, 0.028, 0.08)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIFactory.set_full_rect(shade)
	add_child(shade)

	# Six live hit areas are aligned to the six illustrated menu plaques.
	# Their faces retain the artwork's dark glass / filigree character.
	var menu_specs := [
		{"name": "ContinueButton", "text": "CONTINUE", "y": 0.475, "accent": Color("#f0d5f5"), "action": "continue"},
		{"name": "NewJourneyButton", "text": "▤   NEW JOURNEY", "y": 0.552, "accent": Color("#d9b9e7"), "action": "new"},
		{"name": "LoadGameButton", "text": "♜   LOAD GAME", "y": 0.628, "accent": Color("#d9b9e7"), "action": "load"},
		{"name": "SettingsButton", "text": "⚙   SETTINGS", "y": 0.700, "accent": Color("#d9b9e7"), "action": "settings"},
		{"name": "ExtrasButton", "text": "✥   EXTRAS", "y": 0.772, "accent": Color("#d9b9e7"), "action": "extras"},
		{"name": "QuitGameButton", "text": "✧   QUIT", "y": 0.844, "accent": Color("#c5b7d8"), "action": "quit"},
	]
	for spec in menu_specs:
		var button := Button.new()
		button.name = str(spec.name)
		button.text = str(spec.text)
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size", 17)
		button.add_theme_color_override("font_color", Color("#f0e5f3"))
		button.add_theme_color_override("font_hover_color", Color("#ffffff"))
		button.add_theme_color_override("font_pressed_color", Color("#fff0dc"))
		_style_ornate_menu_button(button, spec.accent, str(spec.action) == "continue")
		if str(spec.action) == "continue" or str(spec.action) == "load":
			button.disabled = not SaveService.has_save()
		button.set_meta("menu_action", str(spec.action))
		button.pressed.connect(_on_menu_action.bind(str(spec.action)))
		add_child(button)
		if spec.action == "continue":
			_play_button = button
		if spec.action == "new":
			_reset_button = button
	continue_button_focus()
	resized.connect(_layout_art_menu)
	_layout_art_menu()

func _layout_art_menu() -> void:
	# Coordinates are normalized to the 16:9 reference artwork. Each live
	# button occupies exactly one painted plaque, rather than a shared panel.
	var rows := [0.475, 0.552, 0.628, 0.700, 0.772, 0.844]
	var names := ["ContinueButton", "NewJourneyButton", "LoadGameButton", "SettingsButton", "ExtrasButton", "QuitGameButton"]
	for i in range(names.size()):
		var button := get_node_or_null(names[i]) as Button
		if button == null:
			continue
		button.set_anchors_preset(Control.PRESET_TOP_LEFT)
		button.anchor_left = 0.505
		button.anchor_right = 0.704
		button.anchor_top = rows[i] - 0.030
		button.anchor_bottom = rows[i] + 0.030
		button.offset_left = 0
		button.offset_right = 0
		button.offset_top = 0
		button.offset_bottom = 0


func continue_button_focus() -> void:
	if _play_button != null:
		_play_button.grab_focus()


func _on_menu_action(action: String) -> void:
	match action:
		"continue":
			_on_play()
		"new":
			_on_new_journey()
		"load":
			if SaveService.has_save():
				GameState.loaded_from_save = true
				_on_play()
			else:
				EventBus.toast_requested.emit("No saved journey found. Begin a new journey first.")
		"settings":
			_show_settings()
		"extras":
			_show_extras()
		"quit":
			quit_requested.emit()


func _on_new_journey() -> void:
	if GameState.loaded_from_save and not _reset_armed:
		_reset_armed = true
		_reset_button.text = "CONFIRM NEW JOURNEY?"
		_reset_button.add_theme_color_override("font_color", Color("#ffb7c5"))
		EventBus.toast_requested.emit("Select New Journey again to erase the current save.")
		return
	if GameState.loaded_from_save:
		GameState.reset_progress()
		GameState.loaded_from_save = false
	_reset_armed = false
	_on_play()


func _show_settings() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Settings"
	dialog.dialog_text = "Adjust your journey's presentation."
	var content := UIFactory.vbox(12)
	content.custom_minimum_size = Vector2(340, 0)
	var audio_label := UIFactory.label("MASTER VOLUME", 11, UITheme.GOLD_BRIGHT)
	content.add_child(audio_label)
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.01
	var master_bus := AudioServer.get_bus_index("Master")
	volume.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus)) if master_bus >= 0 else 1.0
	volume.value_changed.connect(func(value: float) -> void:
		if master_bus >= 0:
			AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(value, 0.001)))
	)
	content.add_child(volume)
	var fullscreen := CheckButton.new()
	fullscreen.text = "Fullscreen"
	fullscreen.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen.toggled.connect(func(enabled: bool) -> void:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)
	)
	content.add_child(fullscreen)
	dialog.add_child(content)
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()


func _show_extras() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Reverie — Extras"
	dialog.dialog_text = "A story of two souls.\n\nCreated with love for dark fantasy, forgotten memories, and the bond between Gerald and Lilith.\n\nREVERIE  •  v0.2.1"
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()

func _build_navigation(layout: HBoxContainer) -> void:
	var panel := UIFactory.panel(Color(0.012, 0.018, 0.038, 0.78), Color(0.78, 0.68, 0.48, 0.34), 22, 1, 30, true)
	panel.custom_minimum_size = Vector2(390, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(panel)

	var column := UIFactory.vbox(15)
	panel.add_child(column)
	column.add_child(UIFactory.label("✦     A DARK FANTASY RPG     ✦", 10, UITheme.GOLD_BRIGHT))

	var title := UIFactory.heading("REVERIE", 54, Color("#f0e6d1"))
	title.add_theme_color_override("font_outline_color", Color("#080b18"))
	title.add_theme_constant_override("outline_size", 6)
	column.add_child(title)

	var subtitle := UIFactory.label("WHERE MEMORY BECOMES MYTH", 10, Color("#c6ad7c"))
	subtitle.add_theme_constant_override("letter_spacing", 3)
	column.add_child(subtitle)
	column.add_child(UIFactory.separator())
	column.add_child(UIFactory.wrapped(
		"Some promises outlive the ones who made them.\nA brother. A sister. A world that has not forgotten.",
		15,
		Color("#d0d0d4")
	))
	column.add_child(UIFactory.spacer())
	_play_button = UIFactory.button("Continue the Journey" if GameState.loaded_from_save else "Begin the Journey", true)
	_play_button.custom_minimum_size = Vector2(0, 58)
	_play_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_play_button.pressed.connect(_on_play)
	column.add_child(_play_button)

	var journey_note := UIFactory.label("ENTER THE WHISPERING GLADE", 9, Color("#9d9ba8"))
	journey_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(journey_note)
	column.add_child(UIFactory.separator())

	_reset_button = UIFactory.button("Reset Journey", false, true)
	_reset_button.custom_minimum_size = Vector2(0, 42)
	_reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reset_button.pressed.connect(_on_reset)
	column.add_child(_reset_button)

	var quit := UIFactory.button("Quit", false, true)
	quit.custom_minimum_size = Vector2(0, 38)
	quit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quit.pressed.connect(func() -> void: quit_requested.emit())
	column.add_child(quit)
	column.add_child(UIFactory.spacer())

	var controls := UIFactory.label("WASD / ARROWS  MOVE     •     E  INTERACT", 9, Color("#898b9a"))
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(controls)
	var build := UIFactory.label("REVERIE     •     v0.2.1     •     OFFLINE STORY", 8, Color("#777987"))
	build.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(build)

func _build_scene_copy(layout: HBoxContainer) -> void:
	var right := UIFactory.vbox(10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(right)

	var eyebrow := UIFactory.label("A TALE OF TWO SOULS", 10, Color("#d7c18f"))
	eyebrow.add_theme_constant_override("letter_spacing", 2)
	right.add_child(eyebrow)
	right.add_child(UIFactory.label("The Whispering Glade", 24, Color("#f0e8d8")))
	right.add_child(UIFactory.label("THE FIRST CHAPTER", 9, Color("#b7b0a4")))
	right.add_child(UIFactory.spacer())

	var party_heading := UIFactory.label("YOUR COMPANIONS", 9, Color("#d7c18f"))
	party_heading.add_theme_constant_override("letter_spacing", 2)
	right.add_child(party_heading)
	_party_names_label = UIFactory.label("", 15, Color("#f0e8d8"))
	right.add_child(_party_names_label)
	_summary_label = UIFactory.label("", 10, Color("#c4b58e"))
	right.add_child(_summary_label)

func _build_party_showcase() -> void:
	if _party_layer == null:
		return
	for child in _party_layer.get_children():
		child.queue_free()
	_party_visuals.clear()
	var ids: Array[String] = []
	for instance in GameState.party_instances():
		ids.append(str(instance.char_id))
	if ids.is_empty():
		for starter_id in STARTERS:
			ids.append(starter_id)
	for character_id in ids:
		var definition: CharacterDef = ContentDB.get_character(character_id)
		if definition == null:
			continue
		var visual := ActorVisual.new()
		visual.name = "Party_" + character_id
		visual.visual_scale = 2.8
		visual.facing = -1.0
		visual.setup(definition.palette, ActorVisual.Kind.HUMAN, definition.id, definition.race, definition.element)
		# Reuse the exact registered playable art and idle animation sheets.
		visual.configure_character(character_id)
		_party_layer.add_child(visual)
		_party_visuals.append(visual)

func _layout_party() -> void:
	if _party_layer == null or _party_visuals.is_empty():
		return
	var count := _party_visuals.size()
	var spacing := minf(size.x * 0.125, 150.0)
	var center_x := size.x * 0.70
	for i in range(count):
		var visual := _party_visuals[i]
		visual.position = Vector2(center_x + (float(i) - float(count - 1) * 0.5) * spacing, size.y * 0.82)
		visual.z_index = i

func _refresh_summary() -> void:
	if _play_button != null:
		_play_button.text = "✧   CONTINUE   ✧" if GameState.loaded_from_save else "✧   BEGIN JOURNEY   ✧"
	if _summary_label == null:
		return
	var profile: Dictionary = GameState.profile
	var party_names: Array[String] = []
	for instance in GameState.party_instances():
		var definition: CharacterDef = ContentDB.get_character(instance.char_id)
		if definition != null:
			party_names.append(definition.display_name)
	if _party_names_label != null:
		_party_names_label.text = "  ·  ".join(party_names) if not party_names.is_empty() else "No party selected"
	_summary_label.text = "Lv %d   ·   %d collected   ·   %s gold   ·   %s crystals" % [
		int(profile.get("level", 1)),
		GameState.unique_owned_count(),
		UIFactory.number(GameState.currency("gold")),
		UIFactory.number(GameState.currency("crystals")),
	]
	if _play_button != null:
		_play_button.text = "✧   CONTINUE   ✧" if GameState.loaded_from_save else "✧   BEGIN JOURNEY   ✧"

func _style_ornate_menu_button(button: Button, accent: Color, primary: bool) -> void:
	# The dark glass face masks the illustration's printed lettering while the
	# live hitbox sits precisely over the matching plaque and icon.
	var normal_bg := Color("#100d1c")
	var hover_bg := Color("#25182d")
	var pressed_bg := Color("#33203b")
	var edge := Color(accent.r, accent.g, accent.b, 0.92)
	button.add_theme_stylebox_override("normal", UITheme.style(normal_bg, edge, 18, 1, 10))
	button.add_theme_stylebox_override("hover", UITheme.style(hover_bg, Color("#fff0ff"), 18, 2, 10, true))
	button.add_theme_stylebox_override("pressed", UITheme.style(pressed_bg, Color("#fff0dc"), 18, 2, 10))
	button.add_theme_stylebox_override("disabled", UITheme.style(Color("#100d1c"), Color("#51445d"), 18, 1, 10))
	button.add_theme_stylebox_override("focus", UITheme.style(hover_bg, Color("#fff0d8"), 18, 2, 10))
	button.add_theme_color_override("font_color", Color("#fff0fa") if primary else Color("#e0d1e8"))
	button.add_theme_color_override("font_hover_color", Color("#ffffff"))
	button.add_theme_color_override("font_pressed_color", Color("#fff0dc"))
	button.add_theme_color_override("font_disabled_color", Color("#82788c"))
	button.flat = false


func _on_play() -> void:
	play_requested.emit()

func _on_reset() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset_button.text = "✦  CONFIRM NEW JOURNEY  ✦"
		_reset_button.add_theme_color_override("font_color", UITheme.DANGER)
		return
	GameState.reset_progress()
	GameState.loaded_from_save = false
	_reset_armed = false
	_reset_button.text = "❖   NEW JOURNEY   ❖"
	_reset_button.add_theme_color_override("font_color", UITheme.DANGER)
	_build_party_showcase()
	_refresh_summary()
	_layout_party()
	EventBus.toast_requested.emit("Journey reset. A new story begins.")

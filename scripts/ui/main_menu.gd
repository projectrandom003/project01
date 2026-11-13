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

	# The generated title artwork already contains the REVERIE logo and chapter
	# illustration. Keep those as art, while replacing its painted menu with
	# real Godot controls in the same visual area.
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
	shade.color = Color(0.012, 0.009, 0.028, 0.12)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIFactory.set_full_rect(shade)
	add_child(shade)

	# Cover the concept image's non-interactive painted menu and place live
	# buttons over it. Save/reset/play/quit continue to use the existing signals.
	var menu_panel := UIFactory.panel(Color(0.008, 0.006, 0.018, 0.0), Color(0.78, 0.58, 0.68, 0.0), 0, 0, 8, false)
	menu_panel.name = "LiveMenuPanel"
	menu_panel.anchor_left = 0.495
	menu_panel.anchor_right = 0.735
	menu_panel.anchor_top = 0.385
	menu_panel.anchor_bottom = 0.895
	menu_panel.offset_left = 0
	menu_panel.offset_right = 0
	menu_panel.offset_top = 0
	menu_panel.offset_bottom = 0
	add_child(menu_panel)

	var column := UIFactory.vbox(12)
	menu_panel.add_child(column)
	var continue_button := UIFactory.button("✧   CONTINUE   ✧" if GameState.loaded_from_save else "✧   BEGIN JOURNEY   ✧", false)
	_style_ornate_menu_button(continue_button, Color("#e9c6f3"), true)
	continue_button.name = "ContinueJourneyButton"
	continue_button.custom_minimum_size = Vector2(0, 54)
	continue_button.add_theme_font_size_override("font_size", 19)
	continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	continue_button.focus_mode = Control.FOCUS_ALL
	continue_button.tooltip_text = "Continue your saved adventure" if GameState.loaded_from_save else "Begin a new adventure"
	continue_button.pressed.connect(_on_play)
	_play_button = continue_button
	column.add_child(continue_button)
	var reset := UIFactory.button("❖   NEW JOURNEY   ❖", false)
	_style_ornate_menu_button(reset, Color("#c6a6cf"), false)
	reset.name = "ResetJourneyButton"
	reset.custom_minimum_size = Vector2(0, 50)
	reset.add_theme_font_size_override("font_size", 17)
	reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset.focus_mode = Control.FOCUS_ALL
	reset.tooltip_text = "Start a new journey. Press again to confirm and erase the current save."
	reset.pressed.connect(_on_reset)
	_reset_button = reset
	column.add_child(reset)
	var quit := UIFactory.button("✥   QUIT   ✥", false)
	_style_ornate_menu_button(quit, Color("#b4a6c8"), false)
	quit.name = "QuitGameButton"
	quit.custom_minimum_size = Vector2(0, 48)
	quit.add_theme_font_size_override("font_size", 17)
	quit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quit.focus_mode = Control.FOCUS_ALL
	quit.tooltip_text = "Close Reverie"
	quit.pressed.connect(func() -> void: quit_requested.emit())
	column.add_child(quit)
	continue_button.grab_focus()

	var hint := UIFactory.label("A  S T O R Y  O F  T W O  S O U L S", 8, Color("#b9a8c8"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)

	resized.connect(_layout_art_menu)
	_layout_art_menu()

func _layout_art_menu() -> void:
	var panel := get_node_or_null("LiveMenuPanel") as Control
	if panel == null:
		return
	# Keep the panel aligned with the illustrated menu on common widescreen
	# layouts, while preserving a usable minimum width on smaller windows.
	var panel_width := clampf(size.x * 0.24, 330.0, 410.0)
	var panel_height := clampf(size.y * 0.45, 360.0, 430.0)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(size.x * 0.505, size.y * 0.405)
	panel.size = Vector2(panel_width, panel_height)

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
	# The title artwork has its own painted labels beneath the live controls.
	# Keep the ornate button faces fully opaque so those labels never bleed through.
	var normal_bg := Color(0.018, 0.012, 0.035, 1.0)
	var hover_bg := Color(0.075, 0.045, 0.105, 1.0)
	var pressed_bg := Color(0.12, 0.075, 0.15, 1.0)
	button.add_theme_stylebox_override("normal", UITheme.style(normal_bg, Color(accent.r, accent.g, accent.b, 0.68), 7, 1, 16))
	button.add_theme_stylebox_override("hover", UITheme.style(hover_bg, Color(accent.r, accent.g, accent.b, 1.0), 7, 2, 16, true))
	button.add_theme_stylebox_override("pressed", UITheme.style(pressed_bg, Color(accent.r, accent.g, accent.b, 1.0), 7, 2, 16))
	button.add_theme_stylebox_override("focus", UITheme.style(Color(0.08, 0.05, 0.12, 0.85), Color("#fff0d8"), 7, 2, 16))
	button.add_theme_color_override("font_color", Color("#f1e5f1") if primary else Color("#d7c7dd"))
	button.add_theme_color_override("font_hover_color", Color("#ffffff"))
	button.add_theme_color_override("font_pressed_color", Color("#fff0dc"))
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

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

	var backdrop := LaunchForestBackdrop.new()
	backdrop.name = "TitleScreenBackdrop"
	UIFactory.set_full_rect(backdrop)
	add_child(backdrop)
	var shade := ColorRect.new()
	shade.name = "TitleArtworkReadabilityShade"
	shade.color = Color(0.015, 0.012, 0.035, 0.22)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIFactory.set_full_rect(shade)
	add_child(shade)

	_party_layer = Node2D.new()
	_party_layer.name = "PartyShowcase"
	_party_layer.z_index = 2
	add_child(_party_layer)
	_build_party_showcase()

	var margin := UIFactory.margin(34)
	UIFactory.set_full_rect(margin)
	margin.z_index = 4
	add_child(margin)
	var layout := UIFactory.hbox(26)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(layout)

	_build_navigation(layout)
	_build_scene_copy(layout)
	resized.connect(_layout_party)
	_refresh_summary()
	_layout_party()

func _build_navigation(layout: HBoxContainer) -> void:
	var panel := UIFactory.panel(Color(0.025, 0.045, 0.075, 0.90), Color(0.72, 0.67, 0.52, 0.30), 18, 1, 26, true)
	panel.custom_minimum_size = Vector2(390, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(panel)

	var column := UIFactory.vbox(13)
	panel.add_child(column)
	column.add_child(UIFactory.label("AETHERIA  /  GREENWARD", 10, UITheme.TEAL))
	var title := UIFactory.heading("PROJECT\nFANTASY", 43, UITheme.GOLD_BRIGHT)
	title.add_theme_color_override("font_outline_color", Color("#050914"))
	title.add_theme_constant_override("outline_size", 5)
	column.add_child(title)
	column.add_child(UIFactory.wrapped(
		"A world that remembers. A promise that refuses to fade.",
		14,
		UITheme.TEXT_DIM
	))
	column.add_child(UIFactory.separator())

	_play_button = UIFactory.button("Begin Journey", true)
	_play_button.custom_minimum_size = Vector2(0, 54)
	_play_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_play_button.pressed.connect(_on_play)
	column.add_child(_play_button)

	var journey_note := UIFactory.label("STORY  ·  EXPLORATION  ·  TURN-BASED COMBAT", 9, UITheme.TEXT_FAINT)
	journey_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(journey_note)
	column.add_child(UIFactory.separator())

	_reset_button = UIFactory.button("Reset Journey", false, true)
	_reset_button.custom_minimum_size = Vector2(0, 42)
	_reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reset_button.pressed.connect(_on_reset)
	column.add_child(_reset_button)

	var quit := UIFactory.button("Quit Game")
	quit.custom_minimum_size = Vector2(0, 42)
	quit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quit.pressed.connect(func() -> void: quit_requested.emit())
	column.add_child(quit)
	column.add_child(UIFactory.spacer())

	column.add_child(UIFactory.wrapped(
		"WASD / arrows to move  ·  E to interact  ·  C roster  ·  G summon  ·  I inventory  ·  Q quests  ·  Esc menu",
		10,
		UITheme.TEXT_FAINT
	))
	column.add_child(UIFactory.label("GODOT 4.7  ·  OFFLINE STORY BUILD", 9, UITheme.TEXT_FAINT))

func _build_scene_copy(layout: HBoxContainer) -> void:
	var right := UIFactory.vbox(8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(right)
	right.add_child(UIFactory.label("THE LOST SIBLINGS  /  THEIR ALLY", 11, UITheme.GOLD_BRIGHT))
	right.add_child(UIFactory.label("The Whispering Glade", 20, UITheme.TEXT))
	right.add_child(UIFactory.label("A first step into a much older story", 11, UITheme.TEXT_DIM))
	right.add_child(UIFactory.spacer())
	right.add_child(UIFactory.label("YOUR PARTY", 9, UITheme.TEXT_FAINT))
	_party_names_label = UIFactory.label("", 14, UITheme.TEXT)
	right.add_child(_party_names_label)
	_summary_label = UIFactory.label("", 11, UITheme.GOLD)
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
	if GameState.loaded_from_save:
		_play_button.text = "Continue Journey"
	else:
		_play_button.text = "Begin Journey"

func _on_play() -> void:
	play_requested.emit()

func _on_reset() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset_button.text = "Press again to erase save"
		_reset_button.add_theme_color_override("font_color", UITheme.DANGER)
		return
	GameState.reset_progress()
	GameState.loaded_from_save = false
	_reset_armed = false
	_reset_button.text = "Reset Journey"
	_reset_button.add_theme_color_override("font_color", UITheme.DANGER)
	_build_party_showcase()
	_refresh_summary()
	_layout_party()
	EventBus.toast_requested.emit("Journey reset. A new story begins.")

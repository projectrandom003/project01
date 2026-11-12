class_name MainMenu
extends Control
## Title screen. It only emits intent; main.gd owns scene switching so the menu
## can be tested without changing scenes.

signal play_requested
signal quit_requested

const STARTERS := ["mira_sol", "kael", "bramble"]

var _play_button: Button
var _reset_button: Button
var _summary_label: Label
var _reset_armed: bool = false


func _ready() -> void:
	UIFactory.set_full_rect(self)
	theme = UITheme.build()

	var backdrop := MainBackdrop.new()
	backdrop.name = "Backdrop"
	UIFactory.set_full_rect(backdrop)
	add_child(backdrop)

	var margin := UIFactory.margin(26)
	UIFactory.set_full_rect(margin)
	add_child(margin)

	var center := CenterContainer.new()
	margin.add_child(center)

	var panel := UIFactory.panel(Color(0.035, 0.055, 0.095, 0.86), Color(UITheme.GOLD.r, UITheme.GOLD.g, UITheme.GOLD.b, 0.28), 22, 1, 34, true)
	panel.custom_minimum_size = Vector2(1060, 0)
	center.add_child(panel)

	var root := UIFactory.vbox(14)
	panel.add_child(root)

	_build_header(root)
	root.add_child(UIFactory.separator())
	_build_body(root)
	root.add_child(UIFactory.separator())
	_build_footer(root)

	_refresh_summary()


func _build_header(root: VBoxContainer) -> void:
	var header := UIFactory.hbox(18)
	root.add_child(header)

	var titles := UIFactory.vbox(2)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := UIFactory.heading("PROJECT FANTASY", 52, UITheme.GOLD_BRIGHT)
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.06, 0.95))
	title.add_theme_constant_override("outline_size", 7)
	titles.add_child(title)
	titles.add_child(UIFactory.label("AETHERIA  ·  AN ORIGINAL ANIME-FANTASY MMORPG", 13, UITheme.TEAL))
	header.add_child(titles)

	var version := UIFactory.vbox(2)
	version.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var chip := UIFactory.chip("VERTICAL SLICE 0.1.0", UITheme.GOLD)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_END
	version.add_child(chip)
	var status := UIFactory.label("Offline · single-player", 10, UITheme.TEXT_FAINT)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version.add_child(status)
	header.add_child(version)


func _build_body(root: VBoxContainer) -> void:
	var body := UIFactory.hbox(26)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	var left := UIFactory.vbox(10)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(left)

	left.add_child(UIFactory.wrapped(
		"The Whispering Glade is waking from a dream it should not be having. "
		+ "Walk the streamed isometric forests of Greenward, gather bonds through "
		+ "summoning, and face the Hollowed Guardian beneath the roots.",
		14,
		UITheme.TEXT_DIM
	))

	var features := UIFactory.grid(2, 8)
	features.add_child(_feature("Streamed isometric world", "Chunked terrain, props, water and a day/night cycle.", UITheme.TEAL))
	features.add_child(_feature("Turn-based battles", "Elemental weaknesses, status effects, ultimates and boss phases.", UITheme.DANGER))
	features.add_child(_feature("Summoning & collection", "Data-driven banners, pity, awakening and ascension.", UITheme.VIOLET))
	features.add_child(_feature("Original content", "Twelve characters, six enemy types, two story quests.", UITheme.GREEN))
	left.add_child(features)

	_summary_label = UIFactory.label("", 12, UITheme.GOLD)
	left.add_child(_summary_label)

	var actions := UIFactory.hbox(10)
	left.add_child(actions)
	_play_button = UIFactory.button("Begin Journey", true)
	_play_button.custom_minimum_size = Vector2(220, 48)
	_play_button.pressed.connect(_on_play)
	actions.add_child(_play_button)
	_reset_button = UIFactory.button("Reset Journey", false, true)
	_reset_button.custom_minimum_size = Vector2(180, 48)
	_reset_button.pressed.connect(_on_reset)
	actions.add_child(_reset_button)
	var quit := UIFactory.button("Quit")
	quit.custom_minimum_size = Vector2(120, 48)
	quit.pressed.connect(func() -> void: quit_requested.emit())
	actions.add_child(quit)

	left.add_child(UIFactory.wrapped(
		"Controls: WASD / arrows to move  ·  Shift to sprint  ·  E / Space to interact  ·  "
		+ "C roster  ·  G summon  ·  I inventory  ·  Q quests  ·  Esc pause. "
		+ "Touch devices get a virtual joystick automatically.",
		10,
		UITheme.TEXT_FAINT
	))

	var right := UIFactory.vbox(8)
	right.custom_minimum_size = Vector2(430, 0)
	body.add_child(right)
	right.add_child(UIFactory.label("FIRST BONDS", 10, UITheme.TEXT_FAINT))
	var row := UIFactory.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_child(row)
	for character_id in STARTERS:
		var definition: CharacterDef = ContentDB.get_character(character_id)
		if definition == null:
			continue
		row.add_child(_starter_card(definition))
	right.add_child(UIFactory.wrapped(
		"Three travelers answer the glade's call. Summon more with Crystals earned "
		+ "through quests and battles.",
		10,
		UITheme.TEXT_FAINT
	))


func _feature(title: String, description: String, color: Color) -> PanelContainer:
	var panel := UIFactory.panel(Color("#0b1220"), Color(color.r, color.g, color.b, 0.24), 8, 1, 9)
	var box := UIFactory.vbox(2)
	box.add_child(UIFactory.label(title, 12, color))
	box.add_child(UIFactory.wrapped(description, 10, UITheme.TEXT_DIM))
	panel.add_child(box)
	return panel


func _starter_card(definition: CharacterDef) -> PanelContainer:
	var color := UITheme.rarity_color(definition.rarity)
	var panel := UIFactory.panel(Color("#0a101c"), Color(color.r, color.g, color.b, 0.42), 10, 1, 8)
	panel.custom_minimum_size = Vector2(128, 196)
	var box := UIFactory.vbox(3)
	panel.add_child(box)
	var portrait := PortraitView.new()
	portrait.custom_minimum_size = Vector2(112, 128)
	portrait.setup_character(definition)
	box.add_child(portrait)
	var name_label := UIFactory.label(definition.display_name, 12, UITheme.TEXT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(name_label)
	var sub := UIFactory.label("%s · %s" % [definition.role, definition.element.capitalize()], 9, UITheme.TEXT_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(sub)
	var rarity := UIFactory.label(definition.rarity.capitalize(), 9, color)
	rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(rarity)
	return panel


func _build_footer(root: VBoxContainer) -> void:
	var footer := UIFactory.hbox(10)
	root.add_child(footer)
	footer.add_child(UIFactory.wrapped(
		"Placeholder procedural art. All characters, names and lore are original. "
		+ "No multiplayer, trading or server-authoritative economy exists in this build.",
		10,
		UITheme.TEXT_FAINT
	))
	footer.add_child(UIFactory.spacer())
	var godot := UIFactory.label("Godot 4.7 · GDScript", 10, UITheme.TEXT_FAINT)
	godot.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.add_child(godot)


func _refresh_summary() -> void:
	if _summary_label == null:
		return
	var profile: Dictionary = GameState.profile
	var party_names: Array = []
	for instance in GameState.party_instances():
		var definition: CharacterDef = ContentDB.get_character(instance.char_id)
		if definition != null:
			party_names.append(definition.display_name)
	_summary_label.text = "Lv %d  ·  %d characters  ·  %s gold  ·  %s crystals  ·  Party: %s" % [
		int(profile.get("level", 1)),
		GameState.unique_owned_count(),
		UIFactory.number(GameState.currency("gold")),
		UIFactory.number(GameState.currency("crystals")),
		", ".join(party_names) if not party_names.is_empty() else "none",
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
		_reset_button.text = "Press again to erase"
		_reset_button.add_theme_color_override("font_color", UITheme.DANGER)
		return
	GameState.reset_progress()
	GameState.loaded_from_save = false
	_reset_armed = false
	_reset_button.text = "Reset Journey"
	_reset_button.add_theme_color_override("font_color", UITheme.DANGER)
	_refresh_summary()
	EventBus.toast_requested.emit("Journey reset. A new story begins.")

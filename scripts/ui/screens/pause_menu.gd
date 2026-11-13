class_name PauseMenu
extends OverlayScreen
## Organized in-game hub: compact navigation rail plus a useful journey overview.

signal main_menu_requested
signal reset_requested
signal navigate_requested(screen_id: String)

var _reset_armed: bool = false
var _reset_button: Button

func _init() -> void:
	screen_title = "Journey"
	screen_subtitle = "Your adventure is paused"

func _build_content() -> void:
	var split := UIFactory.hbox(18)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(split)

	# Left navigation rail.
	var nav_panel := UIFactory.panel(Color("#0a1320"), Color(0.60, 0.68, 0.78, 0.20), 12, 1, 14)
	nav_panel.custom_minimum_size = Vector2(236, 0)
	split.add_child(nav_panel)
	var nav := UIFactory.vbox(8)
	nav_panel.add_child(nav)
	nav.add_child(UIFactory.label("DESTINATIONS", 9, UITheme.TEXT_FAINT))
	nav.add_child(_nav_button("Character Roster", "collection", UITheme.VIOLET))
	nav.add_child(_nav_button("Inventory", "inventory", UITheme.GOLD))
	nav.add_child(_nav_button("Summon", "gacha", UITheme.TEAL))
	nav.add_child(_nav_button("Quest Log", "quests", UITheme.GREEN))
	nav.add_child(_nav_button("World Map", "map", UITheme.DANGER))
	nav.add_child(UIFactory.spacer())
	var resume_side := UIFactory.button("Resume Adventure", true)
	resume_side.custom_minimum_size = Vector2(0, 44)
	resume_side.pressed.connect(close_screen)
	nav.add_child(resume_side)

	# Right overview column.
	var overview := UIFactory.vbox(12)
	overview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(overview)

	var profile: Dictionary = GameState.profile
	var region: Dictionary = ContentDB.get_region(GameState.player_region)
	var region_name := str(region.get("name", GameState.player_region.capitalize()))
	overview.add_child(UIFactory.heading(str(profile.get("name", "Wanderer")), 27, UITheme.GOLD_BRIGHT))
	overview.add_child(UIFactory.label(
		"LEVEL %d   ·   %d CHARACTERS   ·   %d IN PARTY   ·   %s" % [
			int(profile.get("level", 1)),
			GameState.unique_owned_count(),
			GameState.party.size(),
			region_name.to_upper(),
		],
		10,
		UITheme.TEXT_FAINT
	))

	var summary := UIFactory.grid(4, 8)
	summary.add_child(_summary_card("Gold", UIFactory.number(GameState.currency("gold")), UITheme.GOLD))
	summary.add_child(_summary_card("Crystals", UIFactory.number(GameState.currency("crystals")), UITheme.TEAL))
	summary.add_child(_summary_card("Active Quests", str(GameState.active_quests().size()), UITheme.VIOLET))
	summary.add_child(_summary_card("Region", region_name, UITheme.GREEN))
	overview.add_child(summary)

	var objective := UIFactory.panel(Color("#0b1722"), Color(0.76, 0.68, 0.42, 0.28), 10, 1, 12)
	var objective_box := UIFactory.vbox(4)
	objective.add_child(objective_box)
	objective_box.add_child(UIFactory.label("CURRENT OBJECTIVE", 9, UITheme.TEXT_FAINT))
	var tracked := GameState.tracked_quest()
	if not tracked.is_empty() and GameState.quest_state(tracked) == "active":
		var quest: Dictionary = ContentDB.get_quest(tracked)
		var step := GameState.quest_step(tracked)
		objective_box.add_child(UIFactory.heading(str(quest.get("name", tracked)), 17, UITheme.GOLD_BRIGHT))
		objective_box.add_child(UIFactory.wrapped(str(step.get("text", "Continue your journey")), 11, UITheme.TEXT_DIM))
	else:
		objective_box.add_child(UIFactory.label("No tracked objective", 15, UITheme.TEXT))
		objective_box.add_child(UIFactory.wrapped("Open the Quest Log to choose a story chapter or side quest.", 11, UITheme.TEXT_DIM))
	var objective_actions := UIFactory.hbox(8)
	var quest_button := UIFactory.button("Quest Log", false)
	quest_button.custom_minimum_size = Vector2(120, 34)
	quest_button.pressed.connect(func() -> void: navigate_requested.emit("quests"))
	objective_actions.add_child(quest_button)
	var map_button := UIFactory.button("World Map", false)
	map_button.custom_minimum_size = Vector2(120, 34)
	map_button.pressed.connect(func() -> void: navigate_requested.emit("map"))
	objective_actions.add_child(map_button)
	objective_box.add_child(objective_actions)
	overview.add_child(objective)

	var party_header := UIFactory.label("YOUR PARTY", 9, UITheme.TEXT_FAINT)
	overview.add_child(party_header)
	var party_row := UIFactory.hbox(12)
	party_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	for instance in GameState.party_instances():
		var definition: CharacterDef = ContentDB.get_character(instance.char_id)
		if definition == null:
			continue
		var member := UIFactory.vbox(3)
		member.custom_minimum_size = Vector2(92, 0)
		var portrait := PortraitView.new()
		portrait.custom_minimum_size = Vector2(82, 86)
		portrait.setup_character(definition)
		member.add_child(portrait)
		var member_name := UIFactory.label(definition.display_name, 10, UITheme.TEXT)
		member_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		member.add_child(member_name)
		var level := int(instance.level)
		var level_label := UIFactory.label("Lv. %d" % level, 9, UITheme.TEXT_FAINT)
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		member.add_child(level_label)
		party_row.add_child(member)
	overview.add_child(party_row)
	overview.add_child(UIFactory.spacer())

	var footer := UIFactory.hbox(8)
	var save := UIFactory.button("Save Now", false)
	save.custom_minimum_size = Vector2(112, 40)
	save.pressed.connect(_save_now)
	footer.add_child(save)
	var title := UIFactory.button("Return to Title", false)
	title.custom_minimum_size = Vector2(150, 40)
	title.pressed.connect(func() -> void: main_menu_requested.emit())
	footer.add_child(title)
	footer.add_child(UIFactory.spacer())
	_reset_button = UIFactory.button("Reset Journey", false, true)
	_reset_button.custom_minimum_size = Vector2(130, 40)
	_reset_button.pressed.connect(_reset_pressed)
	footer.add_child(_reset_button)
	overview.add_child(footer)
	overview.add_child(UIFactory.label("Progress saves locally. Reset permanently erases this device's save.", 9, UITheme.TEXT_FAINT))

func _nav_button(title: String, screen_id: String, color: Color) -> Button:
	var button := UIFactory.button(title + "   ›", false)
	button.custom_minimum_size = Vector2(0, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_color_override("font_color", color)
	button.pressed.connect(func() -> void: navigate_requested.emit(screen_id))
	return button

func _summary_card(title: String, value: String, color: Color) -> PanelContainer:
	var card := UIFactory.panel(Color("#0d1524"), Color(color.r, color.g, color.b, 0.24), 7, 1, 8)
	var box := UIFactory.vbox(2)
	box.add_child(UIFactory.label(title.to_upper(), 8, UITheme.TEXT_FAINT))
	box.add_child(UIFactory.label(value, 16, color))
	card.add_child(box)
	return card

func _save_now() -> void:
	GameState.save_now()
	EventBus.toast_requested.emit("Progress saved.")

func _reset_pressed() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset_button.text = "Confirm Erase"
		_reset_button.add_theme_color_override("font_color", UITheme.DANGER)
		return
	reset_requested.emit()

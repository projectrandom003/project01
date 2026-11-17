class_name PauseMenu
extends OverlayScreen
## Organized in-game hub: compact navigation rail plus a useful journey overview.

signal main_menu_requested
signal reset_requested
signal navigate_requested(screen_id: String)

const PAUSE_PARTY_MEMBER_SCENE: PackedScene = preload("res://scenes/ui/components/pause_party_member.tscn")
const PAUSE_LAYOUT_SCENE: PackedScene = preload("res://scenes/ui/components/pause_menu_layout.tscn")

var _reset_armed: bool = false
var _reset_button: Button


func _init() -> void:
	screen_title = "Journey"
	screen_subtitle = "Your adventure is paused"


func _build_content() -> void:
	var layout := PAUSE_LAYOUT_SCENE.instantiate() as HBoxContainer
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(layout)

	var nav := layout.get_node("NavigationPanel/Navigation") as VBoxContainer
	var nav_actions := {
		"RosterButton": ["collection", UITheme.VIOLET],
		"InventoryButton": ["inventory", UITheme.GOLD],
		"SummonButton": ["gacha", UITheme.TEAL],
		"QuestsButton": ["quests", UITheme.GREEN],
		"MapButton": ["map", UITheme.DANGER],
		"SettingsButton": ["settings", UITheme.GOLD_BRIGHT],
	}
	for button_name in nav_actions:
		var button := nav.get_node_or_null(button_name) as Button
		if button == null:
			continue
		var action: Array = nav_actions[button_name]
		button.add_theme_color_override("font_color", action[1])
		button.add_theme_stylebox_override("normal", UITheme.style(Color("#111a2d"), Color(0.60, 0.68, 0.78, 0.16), 8, 1, 10))
		_connect_navigation(button, str(action[0]))
	var resume_button := nav.get_node("ResumeButton") as Button
	resume_button.add_theme_stylebox_override("normal", UITheme.style(Color("#2a2415"), UITheme.GOLD, 8, 1, 10))
	resume_button.pressed.connect(close_screen)

	var profile: Dictionary = GameState.profile
	var region: Dictionary = ContentDB.get_region(GameState.session_domain.player_region)
	var region_name := str(region.get("name", GameState.session_domain.player_region.capitalize()))
	var overview := layout.get_node("Overview") as VBoxContainer
	var profile_name := overview.get_node("ProfileName") as Label
	profile_name.text = str(profile.get("name", "Wanderer"))
	profile_name.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT)
	var profile_meta := overview.get_node("ProfileMeta") as Label
	profile_meta.text = "LEVEL %d   ·   %d CHARACTERS   ·   %d IN PARTY   ·   %s" % [
		int(profile.get("level", 1)),
		GameState.roster_domain.unique_owned_count(),
		GameState.roster_domain.party.size(),
		region_name.to_upper(),
	]

	_set_summary(overview, "GoldSummary", "Gold", UIFactory.number(GameState.inventory_domain.currency("gold")), UITheme.GOLD)
	_set_summary(overview, "CrystalsSummary", "Crystals", UIFactory.number(GameState.inventory_domain.currency("crystals")), UITheme.TEAL)
	_set_summary(overview, "QuestsSummary", "Active Quests", str(GameState.quest_domain.active_quests().size()), UITheme.VIOLET)
	_set_summary(overview, "RegionSummary", "Region", region_name, UITheme.GREEN)

	var objective := overview.get_node("ObjectivePanel/ObjectiveContent") as VBoxContainer
	var tracked := GameState.quest_domain.tracked_quest()
	var has_objective := not tracked.is_empty() and GameState.quest_domain.quest_state(tracked) == "active"
	if has_objective:
		var quest: Dictionary = ContentDB.get_quest(tracked)
		var step := GameState.quest_domain.quest_step(tracked)
		var quest_name := objective.get_node("QuestName") as Label
		quest_name.text = str(quest.get("name", tracked))
		quest_name.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT)
		quest_name.visible = true
		var quest_text := objective.get_node("QuestText") as Label
		quest_text.text = str(step.get("text", "Continue your journey"))
		quest_text.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		quest_text.visible = true
	else:
		objective.get_node("NoObjective").visible = true
		objective.get_node("NoObjectiveHint").visible = true
		(objective.get_node("NoObjectiveHint") as Label).add_theme_color_override("font_color", UITheme.TEXT_DIM)

	var quest_button := objective.get_node("ObjectiveActions/QuestButton") as Button
	quest_button.pressed.connect(func() -> void: navigate_requested.emit("quests"))
	var map_button := objective.get_node("ObjectiveActions/ObjectiveMapButton") as Button
	map_button.pressed.connect(func() -> void: navigate_requested.emit("map"))

	var party_row := overview.get_node("PartyRow") as HBoxContainer
	for instance in GameState.roster_domain.party_instances():
		var definition: CharacterDef = ContentDB.get_character(instance.char_id)
		if definition == null:
			continue
		var member := PAUSE_PARTY_MEMBER_SCENE.instantiate() as VBoxContainer
		member.setup(definition, int(instance.level))
		party_row.add_child(member)

	var footer := overview.get_node("Footer") as HBoxContainer
	var save_button := footer.get_node("SaveButton") as Button
	save_button.pressed.connect(_save_now)
	var title_button := footer.get_node("TitleButton") as Button
	title_button.pressed.connect(func() -> void: main_menu_requested.emit())
	_reset_button = footer.get_node("ResetButton") as Button
	_reset_button.add_theme_color_override("font_color", UITheme.DANGER)
	_reset_button.add_theme_stylebox_override("normal", UITheme.style(Color("#2a1420"), Color("#6b2a3c"), 8, 1, 10))
	_reset_button.pressed.connect(_reset_pressed)


func _connect_navigation(button: Button, screen_id: String) -> void:
	button.pressed.connect(func() -> void: navigate_requested.emit(screen_id))


func _set_summary(overview: VBoxContainer, node_name: String, title: String, value: String, color: Color) -> void:
	var card := overview.get_node("SummaryGrid/" + node_name) as PanelContainer
	var title_label := card.get_node("Content/Title") as Label
	var value_label := card.get_node("Content/Value") as Label
	title_label.text = title.to_upper()
	title_label.add_theme_color_override("font_color", UITheme.TEXT_FAINT)
	value_label.text = value
	value_label.add_theme_color_override("font_color", color)


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

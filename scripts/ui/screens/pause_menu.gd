class_name PauseMenu
extends OverlayScreen
## In-game pause menu. The world is suspended by GameScreen while this is open,
## so nothing here touches gameplay state except explicit save/reset actions.

signal main_menu_requested
signal reset_requested

var _reset_armed: bool = false
var _reset_button: Button


func _init() -> void:
	screen_title = "Paused"
	screen_subtitle = "The glade waits for you"


func _build_content() -> void:
	var split := UIFactory.hbox(16)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(split)

	var left := UIFactory.vbox(10)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(left)

	var profile: Dictionary = GameState.profile
	var name_label := UIFactory.heading(str(profile.get("name", "Wanderer")), 30, UITheme.GOLD_BRIGHT)
	left.add_child(name_label)
	left.add_child(UIFactory.label(
		"Adventurer level %d  ·  %d characters collected  ·  %d in party" % [
			int(profile.get("level", 1)),
			GameState.unique_owned_count(),
			GameState.party.size(),
		],
		12,
		UITheme.TEXT_DIM
	))
	left.add_child(UIFactory.separator())

	var summary := UIFactory.grid(2, 8)
	summary.add_child(_summary_card("Gold", UIFactory.number(GameState.currency("gold")), UITheme.GOLD))
	summary.add_child(_summary_card("Crystals", UIFactory.number(GameState.currency("crystals")), UITheme.TEAL))
	summary.add_child(_summary_card("Active quests", str(GameState.active_quests().size()), UITheme.VIOLET))
	summary.add_child(_summary_card("Location", "Greenward", UITheme.GREEN))
	left.add_child(summary)

	left.add_child(UIFactory.wrapped(
		"Progress is saved locally after every meaningful action. This slice is offline and "
		+ "single-player; gacha, currency and rewards will become server-authoritative in Phase 12.",
		11,
		UITheme.TEXT_FAINT
	))
	left.add_child(UIFactory.spacer(false))

	var actions := UIFactory.vbox(8)
	actions.custom_minimum_size = Vector2(320, 0)
	split.add_child(actions)

	var resume := UIFactory.button("Resume", true)
	resume.pressed.connect(close_screen)
	actions.add_child(resume)

	var save := UIFactory.button("Save now")
	save.pressed.connect(_save_now)
	actions.add_child(save)

	var title := UIFactory.button("Return to Title")
	title.pressed.connect(func() -> void: main_menu_requested.emit())
	actions.add_child(title)

	actions.add_child(UIFactory.separator())

	_reset_button = UIFactory.button("Reset Journey", false, true)
	_reset_button.pressed.connect(_reset_pressed)
	actions.add_child(_reset_button)
	actions.add_child(UIFactory.wrapped(
		"Reset erases the local save, roster, party, inventory and quest progress.",
		10,
		UITheme.TEXT_FAINT
	))


func _summary_card(title: String, value: String, color: Color) -> PanelContainer:
	var card := UIFactory.panel(Color("#0d1524"), Color(color.r, color.g, color.b, 0.28), 8, 1, 10)
	var box := UIFactory.vbox(2)
	box.add_child(UIFactory.label(title.to_upper(), 9, UITheme.TEXT_FAINT))
	box.add_child(UIFactory.label(value, 20, color))
	card.add_child(box)
	return card


func _save_now() -> void:
	GameState.save_now()
	EventBus.toast_requested.emit("Progress saved.")


func _reset_pressed() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset_button.text = "Press again to erase everything"
		_reset_button.add_theme_color_override("font_color", UITheme.DANGER)
		return
	reset_requested.emit()

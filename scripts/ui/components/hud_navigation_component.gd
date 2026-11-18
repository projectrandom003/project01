class_name HUDNavigationComponent
extends Node
## Owns HUD navigation button styling, intent wiring and return confirmation.

var hud: HUD


func bind(owner_hud: HUD) -> void:
	hud = owner_hud


func configure() -> void:
	if hud == null:
		return
	_configure_action("ActionStack/SummonButton", "SUMMON", UITheme.GOLD_BRIGHT, "gacha", true)
	_configure_action("ActionStack/RosterButton", "ROSTER", UITheme.VIOLET, "collection")
	_configure_action("ActionStack/InventoryButton", "INVENTORY", UITheme.TEAL, "inventory")
	_configure_action("ActionStack/QuestsButton", "QUESTS", UITheme.GOLD, "quests")
	_configure_action("ActionStack/MapButton", "WORLD MAP", UITheme.TEAL_DIM, "map")
	var menu_button := hud.get_node_or_null("ActionStack/MenuButton") as Button
	if menu_button != null:
		menu_button.text = "MENU"
		_style_button(menu_button, UITheme.DANGER)
		menu_button.pressed.connect(func() -> void: hud.menu_requested.emit())
	var title_button := hud.get_node_or_null("TopBar/TopRow/MainMenuButton") as Button
	if title_button != null:
		_style_button(title_button, UITheme.GOLD_BRIGHT, true)
		title_button.custom_minimum_size = Vector2(132, 42)
		title_button.tooltip_text = "Save your journey and return to the title screen"
		title_button.pressed.connect(_confirm_return_to_title)


func _configure_action(path: String, label: String, accent: Color, screen_id: String, primary: bool = false) -> void:
	var button := hud.get_node_or_null(path) as Button
	if button == null:
		return
	button.text = label
	_style_button(button, accent, primary)
	button.pressed.connect(func() -> void: hud.screen_requested.emit(screen_id))


func _style_button(button: Button, accent: Color, primary: bool = false) -> void:
	button.custom_minimum_size = Vector2(138.0, 40.0)
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", Color("#e9e5f0"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", accent.lightened(0.22))
	button.add_theme_color_override("font_disabled_color", UITheme.TEXT_FAINT)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_stylebox_override("normal", UITheme.style(Color("#090d19").lerp(accent, 0.055 if primary else 0.025), Color(accent.r, accent.g, accent.b, 0.68), 9, 1, 12, true))
	button.add_theme_stylebox_override("hover", UITheme.style(Color("#1a2034").lerp(accent, 0.12), accent.lightened(0.16), 9, 2, 12, true))
	button.add_theme_stylebox_override("pressed", UITheme.style(Color("#080b15").lerp(accent, 0.16), accent, 9, 2, 12))
	button.add_theme_stylebox_override("disabled", UITheme.style(Color("#0b0e18"), UITheme.BORDER_SOFT, 9, 1, 12))
	button.add_theme_stylebox_override("focus", UITheme.style(Color("#171b2b"), UITheme.GOLD_BRIGHT, 9, 2, 12, true))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _confirm_return_to_title() -> void:
	var confirmation := ConfirmationDialog.new()
	confirmation.title = "Return to Main Menu?"
	confirmation.dialog_text = "Your current journey will be saved before returning to the title screen."
	confirmation.ok_button_text = "Save & Return"
	confirmation.cancel_button_text = "Stay in World"
	confirmation.confirmed.connect(func() -> void:
		hud.return_to_title_requested.emit()
		confirmation.queue_free()
	)
	confirmation.canceled.connect(confirmation.queue_free)
	hud.add_child(confirmation)
	confirmation.popup_centered()

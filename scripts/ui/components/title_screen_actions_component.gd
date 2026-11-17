class_name TitleScreenActionsComponent
extends Node
## Owns title-page input, button states and title-only dialogs.

signal menu_requested(action: String)
signal quit_requested

const BUTTON_ACTIONS := {
	"ContinueButton": "continue", "NewJourneyButton": "new", "LoadGameButton": "load",
	"SettingsButton": "settings", "ExtrasButton": "extras", "QuitGameButton": "quit"
}
var screen: Control

func bind(owner: Control) -> void:
	screen = owner
	for button_name in BUTTON_ACTIONS:
		var button := screen.get_node_or_null(button_name) as Button
		if button == null:
			push_error("[TitleActions] Missing authored hit target: %s" % button_name)
			continue
		var action: String = BUTTON_ACTIONS[button_name]
		button.tooltip_text = action.capitalize()
		button.pressed.connect(_on_action.bind(action))
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_stylebox_override("normal", _transparent_style())
		button.add_theme_stylebox_override("hover", _hover_style())
		button.add_theme_stylebox_override("pressed", _pressed_style())
		button.add_theme_stylebox_override("focus", _hover_style())
		button.text = ""
	refresh_save_actions()

func refresh_save_actions() -> void:
	if screen == null:
		return
	var has_save := SaveService.has_save()
	var continue_button := screen.get_node_or_null("ContinueButton") as Button
	var load_button := screen.get_node_or_null("LoadGameButton") as Button
	if continue_button != null:
		continue_button.disabled = not has_save
	if load_button != null:
		load_button.disabled = not has_save

func _on_action(action: String) -> void:
	match action:
		"continue", "new", "load":
			menu_requested.emit(action)
		"settings":
			_open_settings()
		"extras":
			_show_extras()
		"quit":
			quit_requested.emit()

func _open_settings() -> void:
	if screen.has_node("TitleSettingsOverlay"):
		return
	var packed := load("res://scenes/ui/settings_screen.tscn") as PackedScene
	if packed == null:
		EventBus.toast_requested.emit("Settings are currently unavailable.")
		return
	var overlay := packed.instantiate() as Control
	overlay.name = "TitleSettingsOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 20
	screen.add_child(overlay)
	if overlay.has_signal("closed"):
		overlay.closed.connect(func() -> void:
			if is_instance_valid(overlay):
				overlay.queue_free()
		)

func _show_extras() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Reverie — Extras"
	dialog.dialog_text = "A story of two souls.\n\nCreated with love for dark fantasy, forgotten memories, and the bond between Gerald and Lilith.\n\nREVERIE  •  v0.2.1"
	screen.add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()

func _transparent_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	return style

func _hover_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.48, 0.19, 0.38, 0.16)
	style.border_color = Color(0.91, 0.77, 0.66, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	return style

func _pressed_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.36, 0.10, 0.25, 0.24)
	style.border_color = Color(0.93, 0.79, 0.59, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	return style

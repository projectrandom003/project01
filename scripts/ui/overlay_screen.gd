class_name OverlayScreen
extends Control
## Shared overlay controller. Static shell presentation lives in overlay_shell.tscn;
## subclasses supply only data-driven screen content and behavior.

signal closed

const SHELL_SCENE: PackedScene = preload("res://scenes/ui/components/overlay_shell.tscn")

var screen_title: String = "Menu"
var screen_subtitle: String = ""
var content: VBoxContainer
var header_actions: HBoxContainer
var _shell: Control
var _built: bool = false
var _closing: bool = false


func _ready() -> void:
	if _built:
		return
	_built = true
	UIFactory.set_full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()

	_shell = SHELL_SCENE.instantiate() as Control
	_shell.name = "OverlayShell"
	UIFactory.set_full_rect(_shell)
	add_child(_shell)

	var title_label := _shell.get_node("Margin/Panel/Root/Header/Titles/Title") as Label
	var subtitle_label := _shell.get_node("Margin/Panel/Root/Header/Titles/Subtitle") as Label
	content = _shell.get_node("Margin/Panel/Root/Content") as VBoxContainer
	header_actions = _shell.get_node("Margin/Panel/Root/Header/HeaderActions") as HBoxContainer
	var close_button := _shell.get_node("Margin/Panel/Root/Header/CloseButton") as Button
	title_label.text = screen_title
	subtitle_label.text = screen_subtitle
	subtitle_label.visible = not screen_subtitle.is_empty()
	close_button.text = "Close  X"
	close_button.tooltip_text = "Close"
	close_button.custom_minimum_size = Vector2(116, 40)
	close_button.focus_mode = Control.FOCUS_ALL
	close_button.add_theme_font_size_override("font_size", 14)
	close_button.add_theme_color_override("font_color", Color("#fff4d6"))
	close_button.add_theme_color_override("font_hover_color", Color("#ffffff"))
	close_button.add_theme_stylebox_override("normal", UITheme.style(Color("#2a2415"), UITheme.GOLD, 10, 1, 10))
	close_button.add_theme_stylebox_override("hover", UITheme.style(Color("#3b311b"), UITheme.GOLD_BRIGHT, 10, 2, 10))
	close_button.add_theme_stylebox_override("pressed", UITheme.style(Color("#1d180e"), UITheme.GOLD_BRIGHT, 10, 2, 10))
	close_button.add_theme_stylebox_override("focus", UITheme.style(Color("#3b311b"), Color("#fff0bd"), 10, 2, 10))
	close_button.pressed.connect(close_screen)

	_build_content()
	_refresh()


func _build_content() -> void:
	pass


func _refresh() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("open_menu"):
		close_screen()
		get_viewport().set_input_as_handled()


func close_screen() -> void:
	if _closing or not is_inside_tree():
		return
	_closing = true
	closed.emit()
	queue_free()

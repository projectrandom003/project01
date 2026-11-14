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
	closed.emit()
	queue_free()

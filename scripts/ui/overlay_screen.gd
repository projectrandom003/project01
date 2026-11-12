class_name OverlayScreen
extends Control
## Shared shell for full-screen menus: dimmed backdrop, titled glass panel,
## close button and a content area. Subclasses only build their content.

signal closed

var screen_title: String = "Menu"
var screen_subtitle: String = ""
var content: VBoxContainer
var header_actions: HBoxContainer
var _built: bool = false


func _ready() -> void:
	if _built:
		return
	_built = true
	UIFactory.set_full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()

	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.05, 0.74)
	UIFactory.set_full_rect(dim)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var margin := UIFactory.margin(34)
	UIFactory.set_full_rect(margin)
	add_child(margin)

	var panel := UIFactory.panel(Color("#0c1322"), Color(UITheme.BORDER.r, UITheme.BORDER.g, UITheme.BORDER.b, 0.9), 16, 1, 18, true)
	margin.add_child(panel)

	var root := UIFactory.vbox(12)
	panel.add_child(root)

	var header := UIFactory.hbox(12)
	var titles := UIFactory.vbox(0)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_child(UIFactory.heading(screen_title, 27, UITheme.TEXT))
	if not screen_subtitle.is_empty():
		titles.add_child(UIFactory.label(screen_subtitle, 12, UITheme.TEXT_DIM))
	header.add_child(titles)
	header.add_child(UIFactory.spacer())
	header_actions = UIFactory.hbox(8)
	header_actions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(header_actions)
	var close_button := UIFactory.button("Close  ✕", false, true)
	close_button.custom_minimum_size = Vector2(108, 38)
	close_button.pressed.connect(close_screen)
	header.add_child(close_button)
	root.add_child(header)
	root.add_child(UIFactory.separator())

	content = UIFactory.vbox(12)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content)

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

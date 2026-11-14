class_name InventoryItemCard
extends PanelContainer

signal selected(item_id: String)

var icon_panel: PanelContainer
var letter_label: Label
var name_label: Label
var count_label: Label
var item_id: String = ""


func setup(
	new_item_id: String,
	item_name: String,
	count_text: String,
	accent: Color,
	is_selected: bool
) -> void:
	item_id = new_item_id
	icon_panel = get_node("Content/IconCenter/IconPanel") as PanelContainer
	letter_label = get_node("Content/IconCenter/IconPanel/Letter") as Label
	name_label = get_node("Content/ItemName") as Label
	count_label = get_node("Content/Count") as Label
	custom_minimum_size = Vector2(126, 132)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	letter_label.text = item_name.substr(0, 1).to_upper() if not item_name.is_empty() else "?"
	letter_label.add_theme_color_override("font_color", accent)
	icon_panel.add_theme_stylebox_override("panel", UITheme.style(accent.darkened(0.62), accent, 8, 1, 4))
	name_label.text = item_name
	count_label.text = count_text
	count_label.add_theme_color_override("font_color", UITheme.TEAL if "E" in count_text else UITheme.TEXT_DIM)
	_apply_selection(accent, is_selected)


func _apply_selection(accent: Color, is_selected: bool) -> void:
	var bg := Color("#1a2947") if is_selected else Color("#111a2d")
	var border := accent if is_selected else UITheme.BORDER_SOFT
	var width := 2 if is_selected else 1
	add_theme_stylebox_override("panel", UITheme.style(bg, border, 10, width, 8))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selected.emit(item_id)
		accept_event()

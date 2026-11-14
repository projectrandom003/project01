class_name QuestListCard
extends PanelContainer

signal selected(quest_id: String)

var quest_id: String = ""
var _name_label: Label
var _state_panel: PanelContainer
var _state_label: Label
var _step_label: Label
var _tracked_label: Label


func setup(
	id: String,
	quest_name: String,
	state_text: String,
	state_color: Color,
	step_text: String,
	is_tracked: bool
) -> void:
	quest_id = id
	_name_label = get_node("Content/Header/QuestName") as Label
	_state_panel = get_node("Content/Header/StateChip") as PanelContainer
	_state_label = get_node("Content/Header/StateChip/StateText") as Label
	_step_label = get_node("Content/StepText") as Label
	_tracked_label = get_node("Content/TrackedLabel") as Label
	_name_label.text = quest_name
	_name_label.add_theme_color_override("font_color", UITheme.TEXT)
	_state_label.text = state_text
	_state_label.add_theme_color_override("font_color", state_color)
	_state_panel.add_theme_stylebox_override("panel", UITheme.style(Color(state_color.r, state_color.g, state_color.b, 0.10), Color(state_color.r, state_color.g, state_color.b, 0.45), 20, 1, 7))
	_step_label.text = step_text
	_step_label.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	_tracked_label.visible = is_tracked
	_tracked_label.add_theme_color_override("font_color", UITheme.GOLD)
	add_theme_stylebox_override("panel", UITheme.style(Color("#111a2d"), UITheme.BORDER_SOFT, 10, 1, 10))
	custom_minimum_size = Vector2(0, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selected.emit(quest_id)
		accept_event()

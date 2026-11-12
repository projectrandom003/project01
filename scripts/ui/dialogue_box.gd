class_name DialogueBox
extends Control
## Data-driven dialogue overlay. Nodes, choices, conditions and actions all come
## from resources/data/dialogue.json; this script only presents them.

signal closed(dialogue_id: String)

const TYPE_SPEED := 52.0

var _dialogue_id: String = ""
var _data: Dictionary = {}
var _node: Dictionary = {}
var _node_id: String = ""
var _target_text: String = ""
var _typing: bool = false
var _char_progress: float = 0.0
var _closing: bool = false

var _portrait: PortraitView
var _speaker_label: Label
var _text_label: RichTextLabel
var _choices_box: VBoxContainer
var _continue_button: Button
var _hint_label: Label
var _name_label: Label


func _ready() -> void:
	UIFactory.set_full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	set_process(false)
	theme = UITheme.build()

	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.04, 0.64)
	UIFactory.set_full_rect(dim)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := UIFactory.panel(Color("#0d1424"), Color(UITheme.GOLD.r, UITheme.GOLD.g, UITheme.GOLD.b, 0.35), 16, 1, 18, true)
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 48
	panel.offset_right = -48
	panel.offset_top = -314
	panel.offset_bottom = -26
	add_child(panel)

	var row := UIFactory.hbox(18)
	panel.add_child(row)

	_portrait = PortraitView.new()
	_portrait.custom_minimum_size = Vector2(196, 248)
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_portrait.setup({}, "Human", "neutral", "legendary", 0)
	row.add_child(_portrait)

	var column := UIFactory.vbox(8)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(column)

	var header := UIFactory.hbox(10)
	_speaker_label = UIFactory.heading("Speaker", 21, UITheme.GOLD_BRIGHT)
	_name_label = UIFactory.label("", 11, UITheme.TEXT_FAINT)
	_name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_speaker_label)
	header.add_child(_name_label)
	header.add_child(UIFactory.spacer())
	column.add_child(header)

	_text_label = UIFactory.rich("", 16, UITheme.TEXT, 104)
	_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_text_label)

	_choices_box = UIFactory.vbox(6)
	column.add_child(_choices_box)

	var footer := UIFactory.hbox(10)
	_hint_label = UIFactory.label("", 11, UITheme.TEXT_FAINT)
	footer.add_child(_hint_label)
	footer.add_child(UIFactory.spacer())
	_continue_button = UIFactory.button("Continue", true)
	_continue_button.custom_minimum_size = Vector2(150, 36)
	_continue_button.pressed.connect(_on_continue)
	footer.add_child(_continue_button)
	column.add_child(footer)


func _process(delta: float) -> void:
	if not _typing:
		return
	_char_progress += delta * TYPE_SPEED
	var total := _text_label.get_total_character_count()
	if int(_char_progress) >= total:
		_finish_typing()
	else:
		_text_label.visible_characters = int(_char_progress)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open(dialogue_id: String) -> void:
	_dialogue_id = dialogue_id
	_closing = false
	_data = ContentDB.get_dialogue(dialogue_id)
	if _data.is_empty():
		push_warning("[DialogueBox] Missing dialogue: " + dialogue_id)
		close()
		return
	visible = true
	set_process(true)
	_choices_box.visible = true
	var start := _resolve_start()
	_show_node(start)


func close() -> void:
	if _closing:
		return
	_closing = true
	visible = false
	set_process(false)
	_typing = false
	closed.emit(_dialogue_id)
	EventBus.dialogue_finished.emit(_dialogue_id)


func _resolve_start() -> String:
	for rule in _data.get("start_rules", []):
		var condition := str(rule.get("if", ""))
		if GameState.check_condition(condition):
			return str(rule.get("node", ""))
	return str(_data.get("start", "greet"))


func _show_node(node_id: String) -> void:
	if node_id.is_empty():
		close()
		return
	var nodes: Dictionary = _data.get("nodes", {})
	if not nodes.has(node_id):
		push_warning("[DialogueBox] Missing node '%s' in '%s'." % [node_id, _dialogue_id])
		close()
		return
	_node_id = node_id
	_node = nodes[node_id]
	var speaker := str(_node.get("speaker", "???"))
	_speaker_label.text = speaker
	_name_label.text = _dialogue_id.replace("_", " ").to_upper()
	var palette: Dictionary = _node.get("portrait", {})
	_portrait.setup(palette, _race_for_speaker(speaker), "neutral", "legendary", _dialogue_id.hash())
	_target_text = str(_node.get("text", ""))
	_text_label.text = _target_text
	_text_label.visible_characters = 0
	_char_progress = 0.0
	_typing = true
	UIFactory.clear(_choices_box)
	_continue_button.visible = true
	_continue_button.text = "Skip"
	_hint_label.text = ""


func _finish_typing() -> void:
	_typing = false
	_text_label.visible_characters = -1
	_build_choices()


func _build_choices() -> void:
	UIFactory.clear(_choices_box)
	var choices: Array = _node.get("choices", [])
	if choices.is_empty():
		_continue_button.visible = true
		_continue_button.text = "Continue" if not str(_node.get("next", "")).is_empty() else "Close"
		_hint_label.text = "Esc closes the conversation"
		return
	_continue_button.visible = false
	_hint_label.text = "Choose a reply"
	for choice in choices:
		var button := UIFactory.button(str(choice.get("text", "...")), false)
		button.custom_minimum_size = Vector2(0, 34)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var captured: Dictionary = choice
		button.pressed.connect(func() -> void: _choose(captured))
		_choices_box.add_child(button)


func _on_continue() -> void:
	if _typing:
		_finish_typing()
		return
	var next := str(_node.get("next", ""))
	if next.is_empty():
		close()
	else:
		_show_node(next)


func _choose(choice: Dictionary) -> void:
	_run_action(str(choice.get("action", "")))
	var next := str(choice.get("next", ""))
	if next.is_empty():
		close()
	else:
		_show_node(next)


func _run_action(action: String) -> void:
	if action.is_empty():
		return
	var parts := action.split(":", true, 2)
	match parts[0]:
		"start_quest":
			if parts.size() >= 2:
				GameState.start_quest(parts[1], _dialogue_id)
		"complete_quest":
			if parts.size() >= 2:
				GameState.complete_quest(parts[1])
		"add_item":
			if parts.size() >= 2:
				GameState.add_item(parts[1], int(parts[2]) if parts.size() >= 3 else 1)
		"add_currency":
			if parts.size() >= 3:
				GameState.add_currency(parts[1], int(parts[2]))
		"set_flag":
			if parts.size() >= 3:
				GameState.flags[parts[1]] = parts[2]
				GameState.queue_save()
		"toast":
			if parts.size() >= 2:
				EventBus.toast_requested.emit(parts[1])
		_:
			push_warning("[DialogueBox] Unknown action: " + action)


func _race_for_speaker(speaker: String) -> String:
	match speaker:
		"Elder Maelin":
			return "Elf"
		"Pip":
			return "Beastkin"
		"Sera Quill":
			return "Human"
		_:
			return "Human"

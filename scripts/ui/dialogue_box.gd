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

	_portrait = get_node("DialoguePanel/ContentRow/Portrait") as PortraitView
	_speaker_label = get_node("DialoguePanel/ContentRow/TextColumn/Header/SpeakerLabel") as Label
	_name_label = get_node("DialoguePanel/ContentRow/TextColumn/Header/NameLabel") as Label
	_text_label = get_node("DialoguePanel/ContentRow/TextColumn/TextLabel") as RichTextLabel
	_choices_box = get_node("DialoguePanel/ContentRow/TextColumn/ChoicesBox") as VBoxContainer
	_continue_button = get_node("DialoguePanel/ContentRow/TextColumn/Footer/ContinueButton") as Button
	_hint_label = get_node("DialoguePanel/ContentRow/TextColumn/Footer/HintLabel") as Label
	_portrait.setup({}, "Human", "neutral", "legendary", 0)
	_continue_button.pressed.connect(_on_continue)


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
		if GameState.quest_domain.check_condition(condition):
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
	# Named story NPCs may provide a real portrait asset per dialogue node.
	# Missing/invalid paths safely retain the existing procedural portrait.
	var portrait_path := str(_node.get("portrait_asset", ""))
	if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
		var portrait_resource: Resource = load(portrait_path)
		if portrait_resource is Texture2D:
			_portrait.set_portrait_texture(portrait_resource as Texture2D)
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
				if not GameState.quest_domain.start_quest(parts[1], _dialogue_id):
					EventBus.toast_requested.emit("This quest is not available yet.")
		"complete_quest":
			if parts.size() >= 2:
				if not GameState.quest_domain.complete_quest(parts[1]):
					EventBus.toast_requested.emit("Quest objective not complete yet. Check your current objective.")
		"open_shop":
			EventBus.shop_requested.emit()
		"add_item":
			if parts.size() >= 2:
				GameState.inventory_domain.add_item(parts[1], int(parts[2]) if parts.size() >= 3 else 1)
		"add_currency":
			if parts.size() >= 3:
				GameState.inventory_domain.add_currency(parts[1], int(parts[2]))
		"set_flag":
			if parts.size() >= 3:
				GameState.quest_domain.flags[parts[1]] = parts[2]
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
		"Moonkeeper Liora":
			return "Fae"
		_:
			return "Human"

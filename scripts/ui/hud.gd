class_name HUD
extends Control
## Always-on heads-up display: location, currencies, party, quest tracker,
## interaction prompt, touch controls and the main navigation buttons.
##
## The HUD is presentation only. It emits intent signals; GameScreen decides
## what to open and when to pause the world.

signal screen_requested(screen_id: String)
signal menu_requested
signal interact_requested
signal switch_avatar_requested

var joystick: TouchJoystick
var _area_label: Label
var _phase_label: Label
var _quest_label: Label
var _currency_box: HBoxContainer
var _party_box: VBoxContainer
var _prompt_panel: PanelContainer
var _prompt_label: Label
var _toast_box: VBoxContainer
var _touch_interact: Button
var _touch_switch: Button
var _hint_label: Label
var _minimap: Minimap

var _prompt_timer: float = 0.0
var _refresh_timer: float = 0.0
var _last_prompt: String = ""
var _toasts: Array = []


func _ready() -> void:
	UIFactory.set_full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UITheme.build()

	_build_top_bar()
	_build_minimap()
	_build_party_panel()
	_build_actions()
	_build_prompt()
	_build_toasts()
	_build_touch()

	EventBus.currency_changed.connect(refresh_currency)
	EventBus.party_changed.connect(refresh_party)
	EventBus.roster_changed.connect(refresh_party)
	EventBus.quest_updated.connect(_on_quest_updated)
	EventBus.toast_requested.connect(show_toast)

	refresh_currency()
	refresh_party()
	refresh_quest()


func _process(delta: float) -> void:
	_prompt_timer += delta
	_refresh_timer += delta
	if _refresh_timer >= 0.5:
		_refresh_timer = 0.0
		refresh_quest()
	if _prompt_timer < 0.12:
		return
	_prompt_timer = 0.0
	var prompt := ""
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("current_prompt"):
		var text: String = player.current_prompt()
		if not text.is_empty():
			var target := "target"
			if player.nearby_interactable != null and "display_name" in player.nearby_interactable:
				target = str(player.nearby_interactable.display_name)
			prompt = "[E]  %s  %s" % [text, target]
	if prompt != _last_prompt:
		_last_prompt = prompt
		_prompt_label.text = prompt
		_prompt_panel.visible = not prompt.is_empty()
		if _touch_interact != null:
			_touch_interact.visible = TouchInput.using_touch and not prompt.is_empty()


func set_world_info(area_name: String, phase_name: String) -> void:
	if _area_label.text != area_name:
		_area_label.text = area_name
	if _phase_label.text != phase_name:
		_phase_label.text = phase_name


func refresh_currency() -> void:
	if _currency_box == null:
		return
	UIFactory.clear(_currency_box)
	_currency_box.add_child(UIFactory.chip("Gold  " + UIFactory.number(GameState.currency("gold")), UITheme.GOLD))
	_currency_box.add_child(UIFactory.chip("Crystals  " + UIFactory.number(GameState.currency("crystals")), UITheme.TEAL))
	if GameState.currency("gems") > 0:
		_currency_box.add_child(UIFactory.chip("Gems  " + UIFactory.number(GameState.currency("gems")), UITheme.VIOLET))


func refresh_party() -> void:
	if _party_box == null:
		return
	UIFactory.clear(_party_box)
	var instances := GameState.party_instances()
	if instances.is_empty():
		_party_box.add_child(UIFactory.label("No party formed", 13, UITheme.TEXT_FAINT))
		return
	for instance in instances:
		var definition: CharacterDef = ContentDB.get_character(instance.char_id)
		if definition == null:
			continue
		var row := UIFactory.hbox(8)
		var portrait := PortraitView.new()
		portrait.custom_minimum_size = Vector2(42, 42)
		portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		portrait.setup_character(definition)
		row.add_child(portrait)
		var text := UIFactory.vbox(1)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_child(UIFactory.label(definition.display_name, 13, UITheme.TEXT))
		text.add_child(UIFactory.label(
			"Lv %d  ·  %s" % [instance.level, definition.role],
			11,
			UITheme.TEXT_DIM
		))
		row.add_child(text)
		var element_dot := ColorRect.new()
		element_dot.color = UITheme.element_color(definition.element)
		element_dot.custom_minimum_size = Vector2(6, 6)
		element_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(element_dot)
		_party_box.add_child(row)


func refresh_quest() -> void:
	if _quest_label == null:
		return
	var tracked := GameState.tracked_quest()
	if tracked.is_empty() or GameState.quest_state(tracked) == "not_started":
		_quest_label.visible = false
		return
	var definition: Dictionary = ContentDB.get_quest(tracked)
	if definition.is_empty():
		_quest_label.visible = false
		return
	var step: Dictionary = GameState.quest_step(tracked)
	var step_text := str(step.get("text", "Quest complete"))
	if GameState.quest_state(tracked) == "complete":
		step_text = "Complete"
	var distance := GameState.distance_to_tracked()
	var arrow := _quest_arrow()
	var suffix := ""
	if not tracked.is_empty() and GameState.quest_state(tracked) == "active" and distance > 0.0:
		suffix = "  (%s %.0fm)" % [arrow, distance / 16.0]
	_quest_label.text = "◆  %s — %s%s" % [str(definition.get("name", tracked)), step_text, suffix]
	_quest_label.visible = true


func _quest_arrow() -> String:
	# Returns a coarse 8-direction arrow toward the tracked quest destination.
	var dir := GameState.direction_to_tracked()
	if dir.length_squared() < 0.0001:
		return "•"
	var angle := dir.angle()
	if angle < 0.0:
		angle += TAU
	var sector := int(round(angle / (PI * 0.25))) % 8
	var arrows := ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"]
	return arrows[sector]


func show_toast(message: String) -> void:
	if _toast_box == null:
		return
	while _toasts.size() >= 3:
		var oldest: Control = _toasts.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	var panel := UIFactory.panel(Color("#141c30"), Color(UITheme.GOLD.r, UITheme.GOLD.g, UITheme.GOLD.b, 0.55), 10, 1, 10, true)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var text := UIFactory.wrapped(message, 13, UITheme.TEXT)
	text.custom_minimum_size = Vector2(320, 0)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(text)
	_toast_box.add_child(panel)
	_toasts.append(panel)
	panel.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	tween.tween_interval(3.0)
	tween.tween_property(panel, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func() -> void:
		if is_instance_valid(panel):
			_toasts.erase(panel)
			panel.queue_free()
	)


func _on_quest_updated(_quest_id: String) -> void:
	refresh_quest()


# ------------------------------------------------------------------- builders

func _build_top_bar() -> void:
	var top := MarginContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 82
	top.add_theme_constant_override("margin_left", 22)
	top.add_theme_constant_override("margin_right", 22)
	top.add_theme_constant_override("margin_top", 12)
	top.add_theme_constant_override("margin_bottom", 8)
	add_child(top)

	var row := UIFactory.hbox(14)
	top.add_child(row)

	var left := UIFactory.vbox(1)
	left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_area_label = UIFactory.heading("Greenward", 25, UITheme.TEXT)
	_phase_label = UIFactory.label("Morning", 12, UITheme.TEAL)
	_quest_label = UIFactory.label("", 12, UITheme.GOLD)
	_quest_label.visible = false
	left.add_child(_area_label)
	left.add_child(_phase_label)
	left.add_child(_quest_label)
	row.add_child(left)
	row.add_child(UIFactory.spacer())

	_currency_box = UIFactory.hbox(8)
	_currency_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_currency_box)


func _build_minimap() -> void:
	_minimap = Minimap.new()
	_minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_minimap.offset_left = -180
	_minimap.offset_right = -20
	_minimap.offset_top = 90
	_minimap.offset_bottom = 250
	add_child(_minimap)


func _build_party_panel() -> void:
	var panel := UIFactory.panel(Color(0.045, 0.065, 0.115, 0.78), UITheme.BORDER_SOFT, 12, 1, 10)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 20
	panel.offset_top = 92
	panel.offset_right = 290
	panel.offset_bottom = 92
	panel.custom_minimum_size = Vector2(260, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var box := UIFactory.vbox(7)
	box.add_child(UIFactory.label("PARTY", 10, UITheme.TEXT_FAINT))
	_party_box = UIFactory.vbox(6)
	box.add_child(_party_box)
	panel.add_child(box)


func _build_actions() -> void:
	var actions := UIFactory.vbox(7)
	actions.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	actions.offset_left = -158
	actions.offset_right = -20
	actions.offset_top = -306
	actions.offset_bottom = -20
	add_child(actions)

	var entries := [
		{ "id": "gacha", "text": "Summon" },
		{ "id": "collection", "text": "Roster" },
		{ "id": "inventory", "text": "Inventory" },
		{ "id": "quests", "text": "Quests" },
		{ "id": "map", "text": "Map" },
	]
	for entry in entries:
		var screen_id := str(entry.id)
		var button := UIFactory.button(str(entry.text))
		button.custom_minimum_size = Vector2(138, 42)
		button.pressed.connect(func() -> void: screen_requested.emit(screen_id))
		actions.add_child(button)

	var menu := UIFactory.button("Menu", true)
	menu.custom_minimum_size = Vector2(138, 42)
	menu.pressed.connect(func() -> void: menu_requested.emit())
	actions.add_child(menu)

	_hint_label = UIFactory.label("WASD move  ·  E interact  ·  Tab switch hero  ·  Esc menu", 10, UITheme.TEXT_FAINT)
	_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint_label.offset_left = -320
	_hint_label.offset_right = -20
	_hint_label.offset_top = -332
	_hint_label.offset_bottom = -310
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_hint_label)


func _build_prompt() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	center.offset_top = -104
	center.offset_bottom = -34
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_prompt_panel = UIFactory.panel(Color("#111a2c"), Color(UITheme.TEAL.r, UITheme.TEAL.g, UITheme.TEAL.b, 0.6), 22, 1, 10, true)
	_prompt_panel.visible = false
	_prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_label = UIFactory.label("", 13, UITheme.TEXT)
	_prompt_panel.add_child(_prompt_label)
	center.add_child(_prompt_panel)


func _build_toasts() -> void:
	_toast_box = UIFactory.vbox(6)
	_toast_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast_box.offset_left = -260
	_toast_box.offset_right = 260
	_toast_box.offset_top = 92
	_toast_box.offset_bottom = 92
	_toast_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_box)


func _build_touch() -> void:
	joystick = TouchJoystick.new()
	joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.offset_left = 18
	joystick.offset_right = 188
	joystick.offset_top = -188
	joystick.offset_bottom = -18
	joystick.visible = TouchInput.using_touch
	add_child(joystick)

	_touch_interact = UIFactory.button("Interact", true)
	_touch_interact.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_touch_interact.offset_left = -158
	_touch_interact.offset_right = -20
	_touch_interact.offset_top = -360
	_touch_interact.offset_bottom = -314
	_touch_interact.visible = false
	_touch_interact.pressed.connect(func() -> void: interact_requested.emit())
	add_child(_touch_interact)

	_touch_switch = UIFactory.button("Switch", true)
	_touch_switch.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_touch_switch.offset_left = -158
	_touch_switch.offset_right = -20
	_touch_switch.offset_top = -412
	_touch_switch.offset_bottom = -366
	_touch_switch.visible = TouchInput.using_touch
	_touch_switch.pressed.connect(func() -> void: switch_avatar_requested.emit())
	add_child(_touch_switch)

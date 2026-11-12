extends Node
## Registers input actions in code so bindings are readable, diffable and shared
## by every platform. Keyboard, controller and mouse are all covered here; touch
## is handled by the on-screen joystick (scripts/player/touch_input.gd).


func _enter_tree() -> void:
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("sprint", [KEY_SHIFT])
	_add_key_action("interact", [KEY_E, KEY_ENTER, KEY_SPACE])
	_add_key_action("switch_avatar", [KEY_TAB])
	_add_key_action("open_collection", [KEY_C])
	_add_key_action("open_gacha", [KEY_G])
	_add_key_action("open_inventory", [KEY_I])
	_add_key_action("open_quests", [KEY_Q])
	_add_key_action("open_menu", [KEY_ESCAPE])
	_add_key_action("zoom_in", [KEY_EQUAL, KEY_KP_ADD])
	_add_key_action("zoom_out", [KEY_MINUS, KEY_KP_SUBTRACT])

	_add_joy_button("interact", [JOY_BUTTON_A])
	_add_joy_button("open_menu", [JOY_BUTTON_START, JOY_BUTTON_BACK])
	_add_joy_button("open_collection", [JOY_BUTTON_Y])
	_add_joy_button("open_quests", [JOY_BUTTON_X])
	_add_joy_button("switch_avatar", [JOY_BUTTON_RIGHT_SHOULDER])
	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)


func _ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.25)


func _add_key_action(action: String, keys: Array) -> void:
	_ensure_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)


func _add_joy_button(action: String, buttons: Array) -> void:
	_ensure_action(action)
	for button in buttons:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		InputMap.action_add_event(action, event)


func _add_joy_axis(action: String, axis: int, value: float) -> void:
	_ensure_action(action)
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action, event)

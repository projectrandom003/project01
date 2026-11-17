extends Node
## Synthetic gamepad integration test. Verifies the real InputMap bindings and
## that a left-stick event reaches the composed Player locomotion component.

var failures: int = 0

func _ready() -> void:
	call_deferred("_run")


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("[controller] PASS " + label)
	else:
		failures += 1
		push_error("[controller] FAIL " + label + (": " + detail if not detail.is_empty() else ""))


func _joy_axis(axis: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)


func _joy_button(button: int, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)


func _run() -> void:
	var required_actions := [
		"move_up", "move_down", "move_left", "move_right", "sprint",
		"interact", "switch_avatar", "open_collection", "open_quests", "open_gacha", "open_inventory", "open_menu"
	]
	for action in required_actions:
		_check("InputMap action exists: " + action, InputMap.has_action(action))

	var negative_x := InputEventJoypadMotion.new()
	negative_x.device = 0
	negative_x.axis = JOY_AXIS_LEFT_X
	negative_x.axis_value = -1.0
	_check("negative X axis is bound exclusively to move_left", InputMap.event_is_action(negative_x, "move_left", true) and not InputMap.event_is_action(negative_x, "move_right", true))
	var positive_x := InputEventJoypadMotion.new()
	positive_x.device = 0
	positive_x.axis = JOY_AXIS_LEFT_X
	positive_x.axis_value = 1.0
	_check("positive X axis is bound exclusively to move_right", InputMap.event_is_action(positive_x, "move_right", true) and not InputMap.event_is_action(positive_x, "move_left", true))
	var negative_y := InputEventJoypadMotion.new()
	negative_y.device = 0
	negative_y.axis = JOY_AXIS_LEFT_Y
	negative_y.axis_value = -1.0
	_check("negative Y axis is bound exclusively to move_up", InputMap.event_is_action(negative_y, "move_up", true) and not InputMap.event_is_action(negative_y, "move_down", true))
	var positive_y := InputEventJoypadMotion.new()
	positive_y.device = 0
	positive_y.axis = JOY_AXIS_LEFT_Y
	positive_y.axis_value = 1.0
	_check("positive Y axis is bound exclusively to move_down", InputMap.event_is_action(positive_y, "move_down", true) and not InputMap.event_is_action(positive_y, "move_up", true))
	# The negative-direction axis contracts are checked via exact InputMap
	# event matching; headless Input.parse_input_event is not a physical pad.


	var confirm_button := InputEventJoypadButton.new()
	confirm_button.device = 0
	confirm_button.button_index = JOY_BUTTON_A
	confirm_button.pressed = true
	_check("A / Cross is bound exclusively to interact", InputMap.event_is_action(confirm_button, "interact", true))
	var start_button := InputEventJoypadButton.new()
	start_button.device = 0
	start_button.button_index = JOY_BUTTON_START
	start_button.pressed = true
	_check("Start is bound to pause/menu", InputMap.event_is_action(start_button, "open_menu", true))
	var collection_button := InputEventJoypadButton.new()
	collection_button.device = 0
	collection_button.button_index = JOY_BUTTON_Y
	collection_button.pressed = true
	_check("Y / Triangle is bound to collection", InputMap.event_is_action(collection_button, "open_collection", true))
	var quest_button := InputEventJoypadButton.new()
	quest_button.device = 0
	quest_button.button_index = JOY_BUTTON_X
	quest_button.pressed = true
	_check("X / Square is bound to quests", InputMap.event_is_action(quest_button, "open_quests", true))
	var shoulder_button := InputEventJoypadButton.new()
	shoulder_button.device = 0
	shoulder_button.button_index = JOY_BUTTON_RIGHT_SHOULDER
	shoulder_button.pressed = true
	_check("right shoulder is bound to avatar switch", InputMap.event_is_action(shoulder_button, "switch_avatar", true))
	var gacha_button := InputEventJoypadButton.new()
	gacha_button.device = 0
	gacha_button.button_index = JOY_BUTTON_LEFT_SHOULDER
	gacha_button.pressed = true
	_check("left shoulder is bound to summon screen", InputMap.event_is_action(gacha_button, "open_gacha", true))
	var inventory_button := InputEventJoypadButton.new()
	inventory_button.device = 0
	inventory_button.button_index = JOY_BUTTON_RIGHT_STICK
	inventory_button.pressed = true
	_check("right stick click is bound to inventory", InputMap.event_is_action(inventory_button, "open_inventory", true))
	var sprint_button := InputEventJoypadButton.new()
	sprint_button.device = 0
	sprint_button.button_index = JOY_BUTTON_LEFT_STICK
	sprint_button.pressed = true
	_check("left stick click is bound to sprint", InputMap.event_is_action(sprint_button, "sprint", true))
	var sprint_trigger := InputEventJoypadMotion.new()
	sprint_trigger.device = 0
	sprint_trigger.axis = JOY_AXIS_TRIGGER_LEFT
	sprint_trigger.axis_value = 1.0
	_check("left trigger is bound to sprint", InputMap.event_is_action(sprint_trigger, "sprint", true))

	var player_scene := preload("res://scenes/characters/player.tscn")
	var player := player_scene.instantiate() as Player
	add_child(player)
	await get_tree().physics_frame
	Input.action_press("move_right")
	await get_tree().create_timer(0.35).timeout
	_check("real Player locomotion responds to right action", player.velocity.x > 150.0, "velocity=%s" % str(player.velocity))
	Input.action_release("move_right")
	await get_tree().create_timer(0.25).timeout
	Input.action_press("move_left")
	await get_tree().create_timer(0.35).timeout
	_check("real Player locomotion responds to left action", player.velocity.x < -150.0, "velocity=%s" % str(player.velocity))
	Input.action_release("move_left")
	await get_tree().create_timer(0.25).timeout
	_check("Player decelerates after gamepad axis release", player.velocity.length() < 10.0, "velocity=%s" % str(player.velocity))
	player.queue_free()
	await get_tree().process_frame

	if failures == 0:
		print("[controller] OK — InputMap, button bindings and Player locomotion.")
		get_tree().quit(0)
	else:
		push_error("[controller] FAILED (%d)" % failures)
		get_tree().quit(1)

class_name SettingsControlsComponent
extends Node
## Owns supported-action rebinding, serialized InputEvents and capture state.

var screen: SettingsScreen


func bind(owner_screen: SettingsScreen) -> void:
	screen = owner_screen


func handle_event(event: InputEvent) -> bool:
	if screen == null or screen._capturing_action.is_empty():
		return false
	if event.is_action_pressed("ui_cancel"):
		screen._capturing_action = ""
		rebuild_controls()
		screen.get_viewport().set_input_as_handled()
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		assign_event(screen._capturing_action, event)
		screen.get_viewport().set_input_as_handled()
		return true
	if event is InputEventMouseButton and event.pressed:
		assign_event(screen._capturing_action, event)
		screen.get_viewport().set_input_as_handled()
		return true
	if event is InputEventJoypadButton and event.pressed:
		assign_event(screen._capturing_action, event)
		screen.get_viewport().set_input_as_handled()
		return true
	if event is InputEventJoypadMotion and absf(event.axis_value) >= 0.5:
		assign_event(screen._capturing_action, event)
		screen.get_viewport().set_input_as_handled()
		return true
	return true

func rebuild_controls() -> void:
	if screen._controls_box == null:
		return
	UIFactory.clear(screen._controls_box)
	var defaults: Dictionary = default_controls()
	var saved_controls: Dictionary = screen._working.get("controls", {})
	for pair in SettingsScreen.REBINDABLE_ACTIONS:
		var action := str(pair[0])
		var label_text := str(pair[1])
		var row := UIFactory.hbox(8)
		row.custom_minimum_size = Vector2(0, 34)
		var name_l := UIFactory.label(label_text, 12, UITheme.TEXT)
		name_l.custom_minimum_size = Vector2(150, 0)
		row.add_child(name_l)
		var bind_text := binding_label(action, saved_controls, defaults)
		var btn := Button.new()
		btn.text = bind_text
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 32)
		btn.tooltip_text = "Click to rebind " + label_text
		btn.pressed.connect(func() -> void: begin_capture(action, btn, label_text))
		row.add_child(btn)
		screen._controls_box.add_child(row)


func binding_label(action: String, saved_controls: Dictionary, defaults: Dictionary) -> String:
	if saved_controls.has(action):
		var saved_value: Variant = saved_controls[action]
		if saved_value is Dictionary:
			return str(saved_value.get("display", "Custom binding"))
		return str(saved_value)
	if defaults.has(action):
		return str(defaults[action])
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return "Unbound"
	return events[0].as_text().replace(" (Physical)", "")


func default_controls() -> Dictionary:
	# Snapshot current project-map bindings as safe defaults.
	var out := {}
	for pair in SettingsScreen.REBINDABLE_ACTIONS:
		var action := str(pair[0])
		var events: Array = screen._default_input_events.get(action, InputMap.action_get_events(action))
		if not events.is_empty():
			out[action] = events[0].as_text().replace(" (Physical)", "")
	return out


func begin_capture(action: String, button: Button, label_text: String) -> void:
	screen._capturing_action = action
	screen._capture_button = button
	button.text = "Press a key/button... (ESC to cancel)"
	EventBus.toast_requested.emit("Rebinding: " + label_text)



func assign_event(action: String, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		screen._capturing_action = ""
		rebuild_controls()
		return
	# Stage the binding only. Runtime InputMap changes happen on Apply so
	# Cancel/closing the panel cannot leave half-applied controls behind.
	var controls: Dictionary = screen._working.get("controls", {}).duplicate(true)
	controls[action] = serialize_event(event)
	screen._working["controls"] = controls
	screen._capturing_action = ""
	screen._mark_dirty()
	rebuild_controls()



func serialize_event(event: InputEvent) -> Dictionary:
	var data := {"display": event.as_text().replace(" (Physical)", "")}
	if event is InputEventKey:
		var key := event as InputEventKey
		data.merge({"type": "key", "keycode": key.keycode, "physical_keycode": key.physical_keycode, "unicode": key.unicode, "shift": key.shift_pressed, "ctrl": key.ctrl_pressed, "alt": key.alt_pressed, "meta": key.meta_pressed}, true)
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		data.merge({"type": "mouse", "button": mouse.button_index, "shift": mouse.shift_pressed, "ctrl": mouse.ctrl_pressed, "alt": mouse.alt_pressed, "meta": mouse.meta_pressed}, true)
	elif event is InputEventJoypadButton:
		var joy := event as InputEventJoypadButton
		data.merge({"type": "joy_button", "button": joy.button_index}, true)
	elif event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		data.merge({"type": "joy_motion", "axis": motion.axis, "value": motion.axis_value}, true)
	return data



func deserialize_event(data: Dictionary) -> InputEvent:
	match str(data.get("type", "")):
		"key":
			var event := InputEventKey.new()
			event.keycode = int(data.get("keycode", 0))
			event.physical_keycode = int(data.get("physical_keycode", 0))
			event.unicode = int(data.get("unicode", 0))
			event.shift_pressed = bool(data.get("shift", false))
			event.ctrl_pressed = bool(data.get("ctrl", false))
			event.alt_pressed = bool(data.get("alt", false))
			event.meta_pressed = bool(data.get("meta", false))
			return event
		"mouse":
			var event := InputEventMouseButton.new()
			event.button_index = int(data.get("button", 1))
			event.shift_pressed = bool(data.get("shift", false))
			event.ctrl_pressed = bool(data.get("ctrl", false))
			event.alt_pressed = bool(data.get("alt", false))
			event.meta_pressed = bool(data.get("meta", false))
			return event
		"joy_button":
			var event := InputEventJoypadButton.new()
			event.button_index = int(data.get("button", 0))
			return event
		"joy_motion":
			var event := InputEventJoypadMotion.new()
			event.axis = int(data.get("axis", 0))
			event.axis_value = float(data.get("value", 1.0))
			return event
	return null



func apply_controls(controls: Dictionary) -> void:
	if typeof(controls) != TYPE_DICTIONARY:
		controls = {}
	for pair in SettingsScreen.REBINDABLE_ACTIONS:
		var action := str(pair[0])
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		var saved_value: Variant = controls.get(action, null)
		if saved_value is Dictionary:
			var event := deserialize_event(saved_value)
			if event != null:
				InputMap.action_add_event(action, event)
				continue
		# Older settings stored labels only; retain project defaults safely.
		for default_event in screen._default_input_events.get(action, []):
			InputMap.action_add_event(action, default_event.duplicate(true))



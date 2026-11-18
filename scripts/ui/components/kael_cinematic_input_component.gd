class_name KaelCinematicInputComponent
extends Node
## Owns touch/mouse input and the authored playback controls.

signal advance_requested
signal auto_play_changed(enabled: bool)
signal skip_requested

var _owner_control: Control
var _auto_button: Button
var _skip_button: Button
var _auto_play := false

func bind(owner: Control) -> bool:
	_owner_control = owner
	_auto_button = owner.get_node_or_null("AutoPlayButton") as Button
	_skip_button = owner.get_node_or_null("SkipButton") as Button
	if _auto_button == null or _skip_button == null:
		push_error("[KaelInput] Auto Play and Skip buttons must be authored scene nodes.")
		return false
	_auto_button.toggle_mode = true
	_auto_button.button_pressed = false
	_auto_button.text = "Auto Play: Off"
	_auto_button.toggled.connect(_on_auto_toggled)
	_skip_button.pressed.connect(skip_requested.emit)
	return true

func _unhandled_input(event: InputEvent) -> void:
	if _auto_play:
		return
	var tapped := false
	if event is InputEventScreenTouch:
		tapped = (event as InputEventScreenTouch).pressed
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		tapped = mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed
	if tapped:
		advance_requested.emit()
		get_viewport().set_input_as_handled()

func _on_auto_toggled(enabled: bool) -> void:
	_auto_play = enabled
	_auto_button.text = "Auto Play: On" if enabled else "Auto Play: Off"
	auto_play_changed.emit(enabled)

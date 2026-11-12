class_name TouchJoystick
extends Control
## On-screen joystick for touch devices. It writes into TouchInput so the player
## controller never needs to know whether input came from a thumb or a keyboard.

const RADIUS := 70.0
const KNOB_RADIUS := 30.0

var _active_index: int = -1
var _center: Vector2 = Vector2.ZERO
var _knob: Vector2 = Vector2.ZERO
var _pressed: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(170, 170)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_center = size * 0.5
	_knob = _center
	set_process(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_center = size * 0.5
		if not _pressed:
			_knob = _center
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _active_index < 0:
			_active_index = event.index
			_pressed = true
			_update_knob(event.position)
			accept_event()
		elif not event.pressed and event.index == _active_index:
			_release()
			accept_event()
	elif event is InputEventScreenDrag and event.index == _active_index:
		_update_knob(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressed = true
			_update_knob(event.position)
		else:
			_release()
		accept_event()
	elif event is InputEventMouseMotion and _pressed:
		_update_knob(event.position)
		accept_event()


func _update_knob(local_position: Vector2) -> void:
	var offset := local_position - _center
	if offset.length() > RADIUS:
		offset = offset.normalized() * RADIUS
	_knob = _center + offset
	var value := offset / RADIUS
	TouchInput.set_move_vector(value)
	queue_redraw()


func _release() -> void:
	_active_index = -1
	_pressed = false
	_knob = _center
	TouchInput.release()
	queue_redraw()


func _draw() -> void:
	draw_circle(_center, RADIUS + 10.0, Color(0.03, 0.05, 0.10, 0.42))
	draw_circle(_center, RADIUS, Color(0.10, 0.16, 0.28, 0.55))
	draw_arc(_center, RADIUS, 0, TAU, 32, Color(UITheme.TEAL.r, UITheme.TEAL.g, UITheme.TEAL.b, 0.45), 2.0)
	draw_circle(_knob, KNOB_RADIUS, Color(0.14, 0.22, 0.36, 0.85))
	draw_arc(_knob, KNOB_RADIUS, 0, TAU, 24, Color(UITheme.GOLD.r, UITheme.GOLD.g, UITheme.GOLD.b, 0.65), 2.0)
	draw_circle(_knob, KNOB_RADIUS * 0.32, Color(UITheme.GOLD_BRIGHT.r, UITheme.GOLD_BRIGHT.g, UITheme.GOLD_BRIGHT.b, 0.75))

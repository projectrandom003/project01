class_name TouchJoystick
extends Control
## On-screen joystick for touch devices. It writes into TouchInput so the player
## controller never needs to know whether input came from a thumb or a keyboard.
## Visual composition is authored as editable scene nodes; input/calculation stays in script.

const RADIUS := 70.0
const KNOB_RADIUS := 30.0

var _active_index: int = -1
var _center: Vector2 = Vector2.ZERO
var _knob_pos: Vector2 = Vector2.ZERO
var _pressed: bool = false

@onready var _base_node: Node2D = get_node_or_null("Base") as Node2D
@onready var _outer_glow: Polygon2D = get_node_or_null("Base/OuterGlow") as Polygon2D
@onready var _base_fill: Polygon2D = get_node_or_null("Base/BaseFill") as Polygon2D
@onready var _base_ring: Line2D = get_node_or_null("Base/BaseRing") as Line2D
@onready var _knob_node: Node2D = get_node_or_null("Knob") as Node2D
@onready var _knob_fill: Polygon2D = get_node_or_null("Knob/KnobFill") as Polygon2D
@onready var _knob_ring: Line2D = get_node_or_null("Knob/KnobRing") as Line2D
@onready var _knob_dot: Polygon2D = get_node_or_null("Knob/KnobDot") as Polygon2D


func _ready() -> void:
	custom_minimum_size = Vector2(170, 170)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_center = size * 0.5
	_knob_pos = _center
	set_process(false)
	_refresh_visuals()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_center = size * 0.5
		if not _pressed:
			_knob_pos = _center
		_refresh_visuals()


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
	_knob_pos = _center + offset
	var value := offset / RADIUS
	TouchInput.set_move_vector(value)
	_update_knob_position()


func _release() -> void:
	_active_index = -1
	_pressed = false
	_knob_pos = _center
	TouchInput.release()
	_update_knob_position()


func _refresh_visuals() -> void:
	if _outer_glow:
		_outer_glow.polygon = _circle_poly(Vector2.ZERO, RADIUS + 10.0, 40)
	if _base_fill:
		_base_fill.polygon = _circle_poly(Vector2.ZERO, RADIUS, 40)
	if _base_ring:
		_base_ring.points = _ring_points(Vector2.ZERO, RADIUS, 40)
	if _knob_fill:
		_knob_fill.polygon = _circle_poly(Vector2.ZERO, KNOB_RADIUS, 32)
	if _knob_ring:
		_knob_ring.points = _ring_points(Vector2.ZERO, KNOB_RADIUS, 32)
	if _knob_dot:
		_knob_dot.polygon = _circle_poly(Vector2.ZERO, KNOB_RADIUS * 0.32, 16)
	if _base_node:
		_base_node.position = _center
	_update_knob_position()


func _update_knob_position() -> void:
	if _knob_node:
		_knob_node.position = _knob_pos


func _circle_poly(center: Vector2, radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	return pts


func _ring_points(center: Vector2, radius: float, segments: int) -> PackedVector2Array:
	var pts := _circle_poly(center, radius, segments)
	if pts.size() > 0:
		pts.append(pts[0])
	return pts

class_name PlayerCameraRig
extends Camera2D
## Camera node owns player zoom controls and avatar framing.

const MIN_ZOOM := 0.64
const MAX_ZOOM := 1.85
const ZOOM_RATE := 0.65
const WHEEL_STEP := 0.08
const GERALD_ZOOM_FACTOR := 1.0
const LOOKAHEAD_DISTANCE := 28.0
const LOOKAHEAD_VERTICAL := 0.6
const LOOKAHEAD_RATE := 5.0
const REFERENCE_MOVE_SPEED := 350.0

var _base_zoom: float = 1.1
var _avatar_id: String = "kael"


func _ready() -> void:
	_base_zoom = clampf(zoom.x, MIN_ZOOM, MAX_ZOOM)
	make_current()


func _process(delta: float) -> void:
	if Input.is_action_pressed("zoom_in"):
		set_base_zoom(_base_zoom - ZOOM_RATE * delta)
	if Input.is_action_pressed("zoom_out"):
		set_base_zoom(_base_zoom + ZOOM_RATE * delta)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		set_base_zoom(_base_zoom - WHEEL_STEP)
	elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		set_base_zoom(_base_zoom + WHEEL_STEP)


func update_follow_offset(delta: float, move_velocity: Vector2, movement_ratio: float) -> void:
	var target := Vector2.ZERO
	if move_velocity.length_squared() > 1.0:
		var direction := move_velocity.normalized()
		target = Vector2(direction.x, direction.y * LOOKAHEAD_VERTICAL) * LOOKAHEAD_DISTANCE * clampf(movement_ratio, 0.0, 1.0)
	offset = offset.lerp(target, 1.0 - exp(-LOOKAHEAD_RATE * delta))


func set_avatar_id(character_id: String) -> void:
	_avatar_id = character_id
	_apply_zoom()


func set_base_zoom(value: float) -> void:
	_base_zoom = clampf(value, MIN_ZOOM, MAX_ZOOM)
	_apply_zoom()


func _apply_zoom() -> void:
	var factor := GERALD_ZOOM_FACTOR if _avatar_id == "gerald" else 1.0
	zoom = Vector2.ONE * (_base_zoom * factor)

extends Node
## Bridge between the on-screen joystick (UI) and the player controller.
## Kept as its own autoload so gameplay never reaches into UI nodes.

var move_vector: Vector2 = Vector2.ZERO
var touch_active: bool = false
var interact_pressed: bool = false
var using_touch: bool = false


func _ready() -> void:
	using_touch = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")


func set_move_vector(value: Vector2) -> void:
	move_vector = value.limit_length(1.0)
	touch_active = value.length_squared() > 0.001


func release() -> void:
	move_vector = Vector2.ZERO
	touch_active = false
	interact_pressed = false

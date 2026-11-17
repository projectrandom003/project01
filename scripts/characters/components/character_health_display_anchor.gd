class_name CharacterHealthDisplayAnchor
extends Node2D
## Reusable anchor/hook for health and status displays above or near a character.
## Does not own HP math; display scenes can bind to this node's position/state.

signal display_visibility_changed(visible_state: bool)
signal display_value_changed(current: float, maximum: float)

@export var display_scene: PackedScene
@export var show_when_full: bool = false

var _display: Node
var _current: float = 1.0
var _maximum: float = 1.0


func _ready() -> void:
	if display_scene != null:
		set_display_scene(display_scene)
	_update_visibility()


func set_display_scene(scene: PackedScene) -> void:
	if _display != null and is_instance_valid(_display):
		_display.queue_free()
		_display = null
	display_scene = scene
	if display_scene != null:
		_display = display_scene.instantiate()
		add_child(_display)
	_update_visibility()


func set_values(current: float, maximum: float) -> void:
	_current = current
	_maximum = maxf(0.001, maximum)
	display_value_changed.emit(_current, _maximum)
	if _display != null and _display.has_method("set_values"):
		_display.call("set_values", _current, _maximum)
	elif _display != null and _display.has_method("refresh"):
		_display.call("refresh")
	_update_visibility()


func set_display_visible(value: bool) -> void:
	visible = value
	display_visibility_changed.emit(visible)


func _update_visibility() -> void:
	if not show_when_full and _maximum > 0.0 and is_equal_approx(_current, _maximum):
		visible = false
	else:
		visible = true
	display_visibility_changed.emit(visible)

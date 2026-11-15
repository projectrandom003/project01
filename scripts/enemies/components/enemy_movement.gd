class_name EnemyMovement
extends Node

signal movement_started(mode: StringName)
signal movement_stopped
signal destination_reached(position: Vector2)
signal movement_state_changed(from_mode: StringName, to_mode: StringName)

@export var config: Resource

var move_speed: float = 26.0
var roam_radius: float = 70.0
var home_position: Vector2 = Vector2.ZERO
var current_target_position: Vector2 = Vector2.ZERO
var current_mode: StringName = &"idle"
var _roam_timer: float = 0.0


func _ready() -> void:
	_apply_config()


func _apply_config() -> void:
	if config == null:
		return
	if "move_speed" in config: move_speed = float(config.move_speed)
	if "roam_radius" in config: roam_radius = float(config.roam_radius)


func set_mode(mode: StringName) -> void:
	if mode == current_mode:
		return
	var prev := current_mode
	current_mode = mode
	movement_state_changed.emit(prev, mode)
	if mode == &"idle":
		movement_stopped.emit()
	else:
		movement_started.emit(mode)


func reset_roam_timer(rng: RandomNumberGenerator = null) -> void:
	var lo := 2.0
	var hi := 5.0
	if config != null:
		if "roam_interval_min" in config: lo = float(config.roam_interval_min)
		if "roam_interval_max" in config: hi = float(config.roam_interval_max)
	if rng != null:
		_roam_timer = rng.randf_range(lo, hi)
	else:
		_roam_timer = randf_range(lo, hi)


func tick_roam_timer(delta: float) -> bool:
	_roam_timer -= delta
	return _roam_timer <= 0.0


func pick_roam_target(current_position: Vector2, is_walkable: Callable = Callable(), rng: RandomNumberGenerator = null) -> Vector2:
	for _i in 8:
		var offset := Vector2(
			rng.randf_range(-roam_radius, roam_radius) if rng != null else randf_range(-roam_radius, roam_radius),
			rng.randf_range(-roam_radius, roam_radius) if rng != null else randf_range(-roam_radius, roam_radius)
		)
		var candidate := home_position + offset
		if not is_walkable.is_valid() or bool(is_walkable.call(candidate)):
			current_target_position = candidate
			return candidate
	current_target_position = current_position
	return current_position


func move_toward_target(body: Node2D, target_pos: Vector2, delta: float, speed_mult: float = 1.0) -> Vector2:
	if body == null:
		return Vector2.ZERO
	if body.global_position.distance_to(target_pos) <= 4.0:
		destination_reached.emit(target_pos)
		return Vector2.ZERO
	var dir := (target_pos - body.global_position)
	if dir.length() <= 0.001:
		return Vector2.ZERO
	var step := move_speed * speed_mult * delta
	body.global_position = body.global_position.move_toward(target_pos, step)
	return dir.normalized()


func can_move_mode(mode: StringName) -> bool:
	if config == null:
		return true
	match mode:
		&"idle": return config.idle_enabled
		&"patrol", &"roam", &"roaming": return config.patrol_enabled
		&"chase": return config.chase_enabled
		&"return", &"returning": return config.return_enabled
		&"follow": return config.follow_enabled
		&"retreat": return config.retreat_speed_multiplier > 0.0
	return true

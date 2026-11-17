class_name PlayerLocomotionComponent
extends Node
## Reusable locomotion component for a CharacterBody2D player actor.

const WALK_SPEED := 235.0
const RUN_SPEED := 350.0
const ACCELERATION := 1700.0
const FRICTION := 2100.0
const TURN_BRAKE_MULT := 1.8
const SPEED_BLEND_RATE := 10.0
const STOP_SNAP_SPEED := 18.0
const TOUCH_SPRINT_ENTER := 0.92
const TOUCH_SPRINT_EXIT := 0.80

## Subtle, readable weight differences; keep the party within one traversal
## speed band so avatar switching never changes level pacing dramatically.
const AVATAR_MOVEMENT := {
	"kael": {"walk": 235.0, "run": 350.0, "accel": 1700.0, "friction": 2100.0, "turn": 1.8},
	"gerald": {"walk": 218.0, "run": 322.0, "accel": 1480.0, "friction": 2280.0, "turn": 2.05},
	"lilith": {"walk": 246.0, "run": 362.0, "accel": 1840.0, "friction": 1940.0, "turn": 1.65},
}

var body: CharacterBody2D
var _speed_target: float = WALK_SPEED
var _touch_sprint: bool = false
var _in_water: bool = false


func _ready() -> void:
	body = get_parent() as CharacterBody2D
	_speed_target = float(movement_profile(_avatar_id()).get("walk", WALK_SPEED))


static func movement_profile(character_id: String) -> Dictionary:
	return (AVATAR_MOVEMENT.get(character_id, AVATAR_MOVEMENT["kael"]) as Dictionary).duplicate(true)


func _avatar_id() -> String:
	return str(body.get("avatar_id")) if body != null else "kael"


func physics_step(delta: float) -> void:
	if body == null or not is_instance_valid(body):
		return
	var visual := body.get("visual") as ActorVisual
	var camera := body.get("camera") as Camera2D
	var enabled := bool(body.get("input_enabled"))
	var facing: Vector2 = body.get("facing_direction")
	var profile := movement_profile(_avatar_id())
	var friction := float(profile.get("friction", FRICTION))
	if not enabled:
		body.velocity = body.velocity.move_toward(Vector2.ZERO, friction * delta)
		body.move_and_slide()
		if visual != null:
			visual.walking = false
		visual_set_idle(visual)
		_touch_sprint = false
		_update_camera_follow(camera, delta, Vector2.ZERO, 0.0)
		GameState.session_domain.set_player_facing(facing)
		return

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var touch_driven := TouchInput.move_vector.length_squared() > 0.01
	if touch_driven:
		input_vector = TouchInput.move_vector
	input_vector = input_vector.limit_length(1.0)
	var sprinting := Input.is_action_pressed("sprint")
	if touch_driven:
		var push := input_vector.length()
		_touch_sprint = push >= (TOUCH_SPRINT_EXIT if _touch_sprint else TOUCH_SPRINT_ENTER)
		sprinting = sprinting or _touch_sprint
	else:
		_touch_sprint = false

	var nominal_speed: float = float(profile.get("run", RUN_SPEED)) if sprinting else float(profile.get("walk", WALK_SPEED))
	var speed: float = nominal_speed
	var world: Node = body.get_tree().get_first_node_in_group("world")
	var in_water := world != null and world.has_method("is_water_world") and bool(world.call("is_water_world", body.global_position))
	if in_water != _in_water:
		_in_water = in_water
		body.call("_update_water_visual", in_water)
	if in_water:
		speed *= 0.5
	_speed_target = lerpf(_speed_target, speed, 1.0 - exp(-SPEED_BLEND_RATE * delta))

	if input_vector.length_squared() > 0.001:
		var accel: float = float(profile.get("accel", ACCELERATION))
		if body.velocity.length_squared() > 25.0:
			var align := body.velocity.normalized().dot(input_vector.normalized())
			if align < 0.3:
				var turn_brake := float(profile.get("turn", TURN_BRAKE_MULT))
				accel *= lerpf(turn_brake, 1.0, clampf((align + 1.0) / 1.3, 0.0, 1.0))
		body.velocity = body.velocity.move_toward(input_vector * _speed_target, accel * delta)
		if visual != null and absf(input_vector.x) > 0.08:
			visual.facing = 1.0 if input_vector.x > 0.0 else -1.0
		facing = input_vector.normalized()
		body.set("facing_direction", facing)
		GameState.session_domain.set_player_facing(facing)
	else:
		body.velocity = body.velocity.move_toward(Vector2.ZERO, friction * delta)
		if body.velocity.length() < STOP_SNAP_SPEED:
			body.velocity = Vector2.ZERO

	body.move_and_slide()
	var movement_ratio := clampf(body.velocity.length() / maxf(1.0, nominal_speed), 0.0, 1.0)
	var moving := body.velocity.length() > STOP_SNAP_SPEED
	var direction: Vector2 = body.velocity.normalized() if moving else (input_vector if input_vector.length_squared() > 0.001 else facing)
	if visual != null:
		visual.set_move_direction(direction)
		visual.walking = moving
		if moving:
			var playback := (1.40 if sprinting else 1.36) * lerpf(0.55, 1.0, movement_ratio)
			visual.play(2 if sprinting else 1, -1, playback)
			if body.velocity.length_squared() > 1.0:
				facing = body.velocity.normalized()
				body.set("facing_direction", facing)
				GameState.session_domain.set_player_facing(facing)
		else:
			visual.play(0, -1, 1.0)
	_update_camera_follow(camera, delta, body.velocity, movement_ratio)


func _update_camera_follow(camera: Camera2D, delta: float, move_velocity: Vector2, ratio: float) -> void:
	if camera is PlayerCameraRig:
		(camera as PlayerCameraRig).update_follow_offset(delta, move_velocity, ratio)


func visual_set_idle(visual: ActorVisual) -> void:
	if visual != null:
		visual.set_move_direction(Vector2.ZERO)
		visual.play(0)

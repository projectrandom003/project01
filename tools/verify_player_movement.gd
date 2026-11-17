extends Node
## Runtime movement smoke test: exercises Player physics, camera follow and all
## three protagonist sprite sources using the real project scripts.

var failures: int = 0

func _ready() -> void:
	var player := preload("res://scenes/characters/player.tscn").instantiate() as Player
	add_child(player)
	await get_tree().process_frame
	_check("player starts with responsive camera follow", is_equal_approx(player.camera.position_smoothing_speed, 12.0), str(player.camera.position_smoothing_speed))
	for character_id in ["kael", "lilith", "gerald"]:
		player.set_avatar(character_id)
		await get_tree().process_frame
		_check("%s loads final sprite art" % character_id, player.avatar_id == character_id and not player.visual.using_temporary_art)
		var expected_scale := float(PlayerAvatarComponent.AVATAR_HEIGHT_SCALE.get(character_id, 1.0))
		_check("%s uses lore-accurate height scale" % character_id, is_equal_approx(player.visual.visual_scale, expected_scale), "scale=%.3f expected=%.3f" % [player.visual.visual_scale, expected_scale])
		var sprite := player.visual.get_node("FrameSprite") as Sprite2D
		Input.action_press("move_right")
		await get_tree().create_timer(0.30).timeout
		var walk_speed := player.velocity.length()
		var walk_state := player.visual.animator.state
		var walk_frame := player.visual.animator.frame
		await get_tree().create_timer(0.22).timeout
		var frame_advanced := player.visual.animator.frame != walk_frame
		_check("%s reaches walk speed under input" % character_id, walk_speed > 150.0, "speed=%.1f" % walk_speed)
		_check("%s enters WALK animation" % character_id, walk_state == CharacterAnimator.State.WALK, "state=%d" % walk_state)
		_check("%s advances walk frames" % character_id, frame_advanced, "frame=%d" % player.visual.animator.frame)
		var pose_min := INF
		var pose_max := -INF
		for sample in 6:
			await get_tree().create_timer(0.03).timeout
			pose_min = minf(pose_min, sprite.position.y)
			pose_max = maxf(pose_max, sprite.position.y)
		_check("%s adds continuous in-between body motion" % character_id, pose_max - pose_min > 0.25, "range=%.2f" % (pose_max - pose_min))
		Input.action_release("move_right")
		player.velocity = Vector2.ZERO
		await get_tree().physics_frame
		player.facing_direction = Vector2.LEFT
		await get_tree().create_timer(0.03).timeout
		_check("%s updates to the LEFT directional animation" % character_id, player.visual.animator.direction == CharacterAnimator.Direction.LEFT, "direction=%d" % player.visual.animator.direction)
		if character_id == "gerald":
			_check("gerald direction changes never spin the colossal sprite", absf(sprite.rotation) < deg_to_rad(4.0), "rotation=%.4f" % sprite.rotation)
		await get_tree().create_timer(0.25).timeout
		_check("%s decelerates after release" % character_id, player.velocity.length() < walk_speed)
	Input.action_press("sprint")
	Input.action_press("move_right")
	await get_tree().create_timer(0.30).timeout
	_check("sprint reaches higher speed", player.velocity.length() > 250.0, "speed=%.1f" % player.velocity.length())
	_check("sprint enters RUN animation", player.visual.animator.state == CharacterAnimator.State.RUN, "state=%d" % player.visual.animator.state)
	Input.action_release("move_right")
	Input.action_release("sprint")

	# ---- movement-feel upgrades: touch sprint, turn braking, camera look-ahead
	var touch := _touch_input()
	player.velocity = Vector2.ZERO
	await get_tree().create_timer(0.20).timeout
	if touch != null:
		touch.call("set_move_vector", Vector2.RIGHT * 0.5)
		await get_tree().create_timer(0.40).timeout
		_check("half joystick push walks (WALK)", player.visual.animator.state == CharacterAnimator.State.WALK, "state=%d" % player.visual.animator.state)
		_check("half joystick push is slower than full walk", player.velocity.length() < Player.WALK_SPEED * 0.8, "speed=%.1f" % player.velocity.length())
		touch.call("set_move_vector", Vector2.RIGHT)
		await get_tree().create_timer(0.45).timeout
		_check("joystick pushed to the edge sprints (RUN)", player.visual.animator.state == CharacterAnimator.State.RUN, "state=%d" % player.visual.animator.state)
		_check("touch sprint exceeds walk speed", player.velocity.length() > Player.WALK_SPEED * 1.2, "speed=%.1f" % player.velocity.length())
		_check("camera leads the movement direction", player.camera.offset.x > 5.0, "offset=%s" % str(player.camera.offset))
		_check("camera smoothing speed is untouched", is_equal_approx(player.camera.position_smoothing_speed, 12.0))
		var vx_before := player.velocity.x
		touch.call("set_move_vector", Vector2.LEFT)
		await get_tree().create_timer(0.12).timeout
		var vx_drop := vx_before - player.velocity.x
		_check("reversing brakes harder than plain acceleration", vx_drop > 260.0, "drop=%.1f" % vx_drop)
		touch.call("release")
		await get_tree().create_timer(0.40).timeout
		_check("player stops dead with no input", player.velocity == Vector2.ZERO, "velocity=%s" % str(player.velocity))
		_check("camera look-ahead returns to centre at rest", player.camera.offset.length() < 3.0, "offset=%s" % str(player.camera.offset))
	else:
		_check("TouchInput autoload available for movement-feel checks", false, "missing /root/TouchInput")
	print("[movement] %s" % ("OK" if failures == 0 else "FAILED (%d)" % failures))
	player.queue_free()
	get_tree().quit(0 if failures == 0 else 1)

func _touch_input() -> Node:
	# Autoloads are available as /root/<name>; resolve dynamically so `-s` headless runs
	# do not depend on compile-time global singleton identifier resolution.
	return get_tree().root.get_node_or_null("TouchInput")

func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("[movement] PASS " + label)
	else:
		failures += 1
		printerr("[movement] FAIL " + label + ("" if detail.is_empty() else " - " + detail))

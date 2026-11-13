extends Node
## Runtime movement smoke test: exercises Player physics, camera follow and all
## three protagonist sprite sources using the real project scripts.

var failures: int = 0

func _ready() -> void:
	var player := Player.new()
	add_child(player)
	await get_tree().process_frame
	_check("player starts with responsive camera follow", is_equal_approx(player.camera.position_smoothing_speed, 12.0), str(player.camera.position_smoothing_speed))
	for character_id in ["kael", "lilith", "gerald"]:
		player.set_avatar(character_id)
		await get_tree().process_frame
		_check("%s loads final sprite art" % character_id, player.avatar_id == character_id and not player.visual.using_temporary_art)
		var expected_scale := float(player.AVATAR_HEIGHT_SCALE.get(character_id, 1.0))
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
		player.visual.animator.set_direction_from_vector(Vector2.LEFT)
		await get_tree().create_timer(0.03).timeout
		_check("%s adds a directional turn transition" % character_id, absf(sprite.rotation) > 0.001, "rotation=%.4f" % sprite.rotation)
		await get_tree().create_timer(0.25).timeout
		_check("%s decelerates after release" % character_id, player.velocity.length() < walk_speed)
	Input.action_press("sprint")
	Input.action_press("move_right")
	await get_tree().create_timer(0.30).timeout
	_check("sprint reaches higher speed", player.velocity.length() > 250.0, "speed=%.1f" % player.velocity.length())
	_check("sprint enters RUN animation", player.visual.animator.state == CharacterAnimator.State.RUN, "state=%d" % player.visual.animator.state)
	Input.action_release("move_right")
	Input.action_release("sprint")
	print("[movement] %s" % ("OK" if failures == 0 else "FAILED (%d)" % failures))
	player.queue_free()
	get_tree().quit(0 if failures == 0 else 1)

func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("[movement] PASS " + label)
	else:
		failures += 1
		printerr("[movement] FAIL " + label + ("" if detail.is_empty() else " - " + detail))

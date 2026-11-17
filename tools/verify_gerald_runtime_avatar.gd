extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/characters/player.tscn") as PackedScene
	if packed == null:
		push_error("Could not load production Player scene")
		get_tree().quit(1)
		return
	var player := packed.instantiate() as Player
	add_child(player)
	await get_tree().process_frame
	player.set_avatar("gerald")
	await get_tree().process_frame
	if player.avatar_id != "gerald":
		push_error("Production Player did not switch to Gerald")
		get_tree().quit(1)
		return
	if player.visual == null or player.visual.using_temporary_art:
		push_error("Gerald is not using validated production sprite art")
		get_tree().quit(1)
		return
	var expected := (0.75 * 183.0) / 128.0
	var source_height := float(player.visual.frame_source.frame(CharacterAnimator.State.IDLE, CharacterAnimator.Direction.DOWN, 0).get_height())
	var kael_reference_height := 183.0
	var rendered_height := source_height * expected
	if absf(rendered_height / kael_reference_height - 0.75) > 0.01:
		push_error("Gerald's rendered sprite is not 0.75x Kael: %.1f px vs %.1f px" % [rendered_height, kael_reference_height])
		get_tree().quit(1)
		return
	print("GERALD_SCALE_RATIO_OK source_frame_height=%.1f world_height=%.1f kael_height=%.1f ratio=%.2f scale=%.4f" % [source_height, rendered_height, kael_reference_height, rendered_height / kael_reference_height, expected])
	if not is_equal_approx(player.visual.visual_scale, expected):
		push_error("Gerald tree-relative scale mismatch: %.4f" % player.visual.visual_scale)
		get_tree().quit(1)
		return
	var effects := player.visual.get_node_or_null("Effects") as Node2D
	if effects == null or not is_equal_approx(effects.scale.x, expected) or not is_equal_approx(effects.scale.y, expected):
		push_error("Gerald combat effects did not inherit the reduced world scale")
		get_tree().quit(1)
		return
	player.visual.animator.play_forced(CharacterAnimator.State.IDLE, CharacterAnimator.Direction.DOWN)
	var idle_frame := player.visual.animator.frame
	await get_tree().create_timer(0.25).timeout
	if player.visual.animator.frame == idle_frame:
		push_error("Gerald live idle animation did not advance")
		get_tree().quit(1)
		return
	player.visual.animator.play_forced(CharacterAnimator.State.WALK, CharacterAnimator.Direction.UP_RIGHT)
	var first_frame := player.visual.animator.frame
	await get_tree().create_timer(0.25).timeout
	if player.visual.animator.frame == first_frame:
		push_error("Gerald live directional walk animation did not advance")
		get_tree().quit(1)
		return
	var sprite := player.visual.get_node("FrameSprite") as Sprite2D
	player.visual.animator.play_forced(CharacterAnimator.State.IDLE, CharacterAnimator.Direction.DOWN)
	await get_tree().process_frame
	var idle_pose_start := sprite.position
	var idle_scale_start := sprite.scale
	await get_tree().create_timer(0.35).timeout
	if sprite.position.distance_to(idle_pose_start) < 0.08:
		push_error("Gerald's idle breathing / coat sway did not produce continuous secondary motion")
		get_tree().quit(1)
		return
	var max_idle_scale_delta := 0.0
	# Gerald's breath is deliberately slow (1.45 rad/s); sample a full cycle
	# instead of comparing arbitrary sine-wave phases near the sine's peak.
	for _frame in range(270):
		await get_tree().process_frame
		max_idle_scale_delta = maxf(max_idle_scale_delta, absf(sprite.scale.y - idle_scale_start.y))
	print("GERALD_IDLE_SCALE_DIAGNOSTIC max_delta=%.6f start=%.6f end=%.6f anim_time=%.4f state=%d" % [max_idle_scale_delta, idle_scale_start.y, sprite.scale.y, player.visual.anim_time, player.visual.animator.state])
	if max_idle_scale_delta < 0.001:
		push_error("Gerald's idle breathing did not produce a subtle anchored chest expansion")
		get_tree().quit(1)
		return
	if absf(sprite.scale.x - expected) > expected * 0.005 or absf(sprite.scale.y - expected) > expected * 0.01:
		push_error("Gerald's breathing exceeded the 8-metre silhouette scale envelope")
		get_tree().quit(1)
		return
	if absf(sprite.position.y) > 0.5:
		push_error("Gerald's idle breathing drifted away from his grounded baseline")
		get_tree().quit(1)
		return
	if absf(sprite.rotation) > deg_to_rad(0.5):
		push_error("Gerald's idle breathing introduced excessive body rotation")
		get_tree().quit(1)
		return
	print("GERALD_IDLE_BREATHING_OK anchored_pose=PASS restrained_motion=PASS")
	# This section drives directions directly; keep the live Player controller
	# from replacing them with its stationary facing vector during physics ticks.
	player.input_enabled = false
	for direction in CharacterAnimator.ALL_DIRECTIONS:
		player.visual.animator.set_direction(int(direction))
		await get_tree().process_frame
		if sprite.texture == null:
			push_error("Gerald has no live sprite texture in direction %d" % int(direction))
			get_tree().quit(1)
			return
		if absf(sprite.rotation) > deg_to_rad(4.0):
			push_error("Gerald sprite rotated instead of using directional art in direction %d" % int(direction))
			get_tree().quit(1)
			return
	player.visual.animator.play_forced(CharacterAnimator.State.RUN, CharacterAnimator.Direction.RIGHT)
	var run_frame := player.visual.animator.frame
	await get_tree().create_timer(0.25).timeout
	if player.visual.animator.frame == run_frame:
		push_error("Gerald live run animation did not advance")
		get_tree().quit(1)
		return
	player.visual.animator.play_forced(CharacterAnimator.State.IDLE)
	await get_tree().process_frame
	player.visual.play_attack("heavy_strike")
	await get_tree().process_frame
	await get_tree().process_frame
	var fx := player.visual.get_node_or_null("Effects/GeraldCombatFX") as GeraldCombatEffects
	if fx == null or not fx.visible or fx.attack_variant != "heavy_strike":
		push_error("Gerald live heavy-strike presentation did not activate")
		get_tree().quit(1)
		return
	for raw_direction in CharacterAnimator.ALL_DIRECTIONS:
		var direction := int(raw_direction)
		player.visual.animator.play_forced(CharacterAnimator.State.IDLE, direction)
		await get_tree().process_frame
		player.visual.play_attack("slash_combo")
		await get_tree().process_frame
		var expected_angle := PI * 0.5 - float(direction) * PI * 0.25
		var expected_direction := Vector2.RIGHT.rotated(expected_angle).normalized()
		var expected_origin := Vector2(0, -38) + expected_direction * 22.0
		var actual_attack_direction := fx._attack_direction()
		if player.visual.animator.direction != direction or not actual_attack_direction.is_equal_approx(expected_direction):
			push_error("Gerald attack direction mismatch requested=%d animator=%d expected=%s actual=%s" % [direction, player.visual.animator.direction, str(expected_direction), str(actual_attack_direction)])
			get_tree().quit(1)
			return
		if not fx.slash_trail.position.is_equal_approx(expected_origin):
			push_error("Gerald slash origin did not follow direction %d" % direction)
			get_tree().quit(1)
			return
		player.visual.animator.play_forced(CharacterAnimator.State.IDLE, direction)
		await get_tree().process_frame
		player.visual.play_skill("blade_wave")
		await get_tree().process_frame
		var expected_wave_position := Vector2(0, -38) + expected_direction * 30.0
		if not fx.cast_ring.position.is_equal_approx(expected_wave_position):
			push_error("Gerald blade wave did not follow direction %d" % direction)
			get_tree().quit(1)
			return
	for attack_variant in ["heavy_strike", "spinning_cleave"]:
		player.visual.animator.play_forced(CharacterAnimator.State.IDLE)
		await get_tree().process_frame
		player.visual.play_attack(attack_variant)
		await get_tree().process_frame
		if fx.attack_variant != attack_variant or not fx.get_node("SlashTrail").visible:
			push_error("Gerald attack variant failed to activate: " + attack_variant)
			get_tree().quit(1)
			return
	for skill_variant in ["ground_eruption", "guardian_aura"]:
		player.visual.animator.play_forced(CharacterAnimator.State.IDLE)
		await get_tree().process_frame
		player.visual.play_skill(skill_variant)
		await get_tree().process_frame
		if fx.skill_variant != skill_variant:
			push_error("Gerald skill variant failed to activate: " + skill_variant)
			get_tree().quit(1)
			return
		if skill_variant == "ground_eruption" and not fx.get_node("EruptionCenter").visible:
			push_error("Gerald Ground Eruption did not show its central spike")
			get_tree().quit(1)
			return
		if skill_variant == "guardian_aura" and (not fx.get_node("AuraHalo").visible or not fx.get_node("VoidHalo").visible):
			push_error("Gerald Guardian Aura did not show its paired halos")
			get_tree().quit(1)
			return
		if skill_variant == "ground_eruption":
			player.visual.animator.frame = 5
			await get_tree().process_frame
			if not fx.cast_embers.emitting:
				push_error("Gerald Ground Eruption release embers did not emit")
				get_tree().quit(1)
				return
	player.visual.animator.play_forced(CharacterAnimator.State.IDLE)
	await get_tree().create_timer(1.35).timeout
	if fx.visible:
		push_error("Gerald combat effects did not clean up after returning to IDLE")
		get_tree().quit(1)
		return
	print("GERALD_RUNTIME_AVATAR_OK player_scene=production art=validated scale=1.0723 height_ratio=0.75x_KAEL effects=scaled walk=advancing directional_attacks=8 directional_blade_waves=8 all_attack_variants=3 skills=3 impact_and_release_fx=PASS idle_cleanup=PASS")
	get_tree().quit(0)

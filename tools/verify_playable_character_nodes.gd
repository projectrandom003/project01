extends SceneTree

const PLAYABLE_SCENES := [
	"res://scenes/characters/playable_visuals/gerald_visual.tscn",
	"res://scenes/characters/playable_visuals/lilith_visual.tscn",
	"res://scenes/characters/playable_visuals/kael_visual.tscn",
]
const SLOT_NAMES := ["BackEquipment", "HairAccessory", "LeftHandEquipment", "RightHandEquipment", "ChestAccessory"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var checks := 0
	var errors: Array[String] = []
	for scene_path in PLAYABLE_SCENES:
		var packed := load(scene_path) as PackedScene
		if packed == null:
			errors.append("%s failed to load" % scene_path)
			continue
		checks += 1
		var instance := packed.instantiate()
		root.add_child(instance)
		await process_frame
		var body := instance.get_node_or_null("Body") as AnimatedSprite2D
		var directional_rig := instance.get_node_or_null("DirectionalEquipment") as DirectionalEquipmentLayers
		if directional_rig == null:
			errors.append("%s missing DirectionalEquipment rig" % scene_path)
		else:
			checks += 1
			if directional_rig.get_active_layer() == directional_rig.get_node_or_null("Down"):
				checks += 1
			else:
				errors.append("%s directional rig did not initialize facing Down" % scene_path)
		if body == null:
			errors.append("%s missing AnimatedSprite2D Body" % scene_path)
		else:
			checks += 1
			if body.sprite_frames == null:
				errors.append("%s Body has no SpriteFrames" % scene_path)
			else:
				checks += 1
				if body.is_playing():
					errors.append("%s unexpectedly starts playing" % scene_path)
				else:
					checks += 1
				if body.sprite_frames.get_frame_count(&"idle_0") <= 0:
					errors.append("%s idle_0 animation missing frames" % scene_path)
				else:
					checks += 1
		for socket in SLOT_NAMES:
			var socket_node := instance.get_node_or_null("DirectionalEquipment/Down/Slots/" + socket)
			if socket_node == null:
				errors.append("%s missing socket %s" % [scene_path, socket])
			else:
				checks += 1
				var mount := socket_node.get_node_or_null("Mount")
				if mount == null:
					errors.append("%s/%s missing EquipmentMount" % [scene_path, socket])
				else:
					checks += 1
					if mount.get_node_or_null("Visual") is Sprite2D and mount.get_node_or_null("AnimationPlayer") is AnimationPlayer and mount.get_node_or_null("Effects") is Node2D:
						checks += 1
					else:
						errors.append("%s/%s EquipmentMount hierarchy invalid" % [scene_path, socket])
		var spectral_glow := instance.get_node_or_null("Effects/Aura/LilithSpectralGlow") as Sprite2D
		var kael_aura := instance.get_node_or_null("Effects/Aura/KaelEmberAura") as Sprite2D
		if spectral_glow == null:
			errors.append("%s missing Lilith spectral node effect" % scene_path)
		else:
			checks += 1
			var expected_glow: bool = scene_path.contains("lilith_visual")
			if spectral_glow.visible != expected_glow:
				errors.append("%s spectral effect visibility mismatch" % scene_path)
			else:
				checks += 1
		if kael_aura == null:
			errors.append("%s missing Kael ember node effect" % scene_path)
		else:
			checks += 1
			var expected_kael_aura: bool = scene_path.contains("kael_visual")
			if kael_aura.visible != expected_kael_aura:
				errors.append("%s Kael aura visibility mismatch" % scene_path)
			else:
				checks += 1
		for node_path in ["GroundShadow", "Effects/Aura", "Effects/Particles", "AnimationPlayer", "Audio"]:
			if instance.get_node_or_null(node_path) == null:
				errors.append("%s missing node %s" % [scene_path, node_path])
			else:
				checks += 1
		instance.queue_free()
		await process_frame

	var directional_packed := load("res://scenes/characters/components/directional_equipment/directional_equipment_layers.tscn") as PackedScene
	if directional_packed == null:
		errors.append("Directional equipment layers failed to load")
	else:
		checks += 1
		var directional := directional_packed.instantiate() as DirectionalEquipmentLayers
		var direction_names := ["Down", "DownRight", "Right", "UpRight", "Up", "UpLeft", "Left", "DownLeft"]
		for direction_index in direction_names.size():
			var direction_name: String = direction_names[direction_index]
			var direction_node := directional.get_node_or_null(direction_name) as Node2D
			if direction_node == null or direction_node.get_node_or_null("Slots/BackEquipment/Mount/Visual") == null:
				errors.append("Directional layer missing %s equipment mount" % direction_name)
			else:
				checks += 1
			directional.set_direction(direction_index)
			var active_count := 0
			for candidate_name in direction_names:
				var candidate := directional.get_node_or_null(candidate_name) as Node2D
				if candidate != null and candidate.visible:
					active_count += 1
			if directional.get_active_layer() != direction_node or not direction_node.visible or active_count != 1:
				errors.append("Direction selector failed to isolate %s" % direction_name)
			else:
				checks += 1
		directional.free()

	var roster_packed := load("res://scenes/characters/playable_roster_preview.tscn") as PackedScene
	if roster_packed == null:
		errors.append("Playable roster preview failed to load")
	else:
		checks += 1
		var roster := roster_packed.instantiate()
		for node_path in ["Gerald", "Lilith", "Kael", "Camera2D"]:
			if roster.get_node_or_null(node_path) == null:
				errors.append("Roster preview missing %s" % node_path)
			else:
				checks += 1
		roster.free()

	var actor_packed := load("res://scenes/characters/actor_visual.tscn") as PackedScene
	if actor_packed == null:
		errors.append("live ActorVisual scene failed to load")
	else:
		checks += 1
		var actor := actor_packed.instantiate() as ActorVisual
		root.add_child(actor)
		await process_frame
		for node_path in ["FrameSprite", "DirectionalEquipment/Down/Slots/BackEquipment", "DirectionalEquipment/Down/Slots/HairAccessory", "DirectionalEquipment/Down/Slots/LeftHandEquipment", "DirectionalEquipment/Down/Slots/RightHandEquipment", "DirectionalEquipment/Down/Slots/ChestAccessory/Mount/Visual", "DirectionalEquipment/Down/Slots/BackEquipment/Mount/AnimationPlayer", "Effects/Aura", "Effects/Particles", "AnimationPlayer", "Audio"]:
			if actor.get_node_or_null(node_path) == null:
				errors.append("live ActorVisual missing %s" % node_path)
			else:
				checks += 1
		actor.configure_character("lilith")
		await process_frame
		var actor_glow := actor.get_node_or_null("Effects/Aura/LilithSpectralGlow") as Sprite2D
		var actor_kael_aura := actor.get_node_or_null("Effects/Aura/KaelEmberAura") as Sprite2D
		if actor_glow == null or not actor_glow.visible or actor_kael_aura == null or actor_kael_aura.visible:
			errors.append("live ActorVisual character-specific effects failed for Lilith")
		else:
			checks += 1
		actor.configure_character("kael")
		await process_frame
		if actor_glow == null or actor_glow.visible or actor_kael_aura == null or not actor_kael_aura.visible:
			errors.append("live ActorVisual character-specific effects failed for Kael")
		else:
			checks += 1
		if actor.animator != null:
			var gerald_report := actor.configure_character("gerald")
			actor.set_body_scale((0.75 * 183.0) / 128.0)
			if not bool(gerald_report.get("registered", false)):
				errors.append("Gerald world sheet did not register on the live ActorVisual")
			else:
				checks += 1
			if not is_equal_approx(actor.visual_scale, (0.75 * 183.0) / 128.0):
				errors.append("Gerald 0.75x-Kael world scale was clamped or not applied")
			else:
				checks += 1
			var gerald_effects := actor.get_node_or_null("Effects") as Node2D
			if gerald_effects == null or not is_equal_approx(gerald_effects.scale.x, (0.75 * 183.0) / 128.0) or not is_equal_approx(gerald_effects.scale.y, (0.75 * 183.0) / 128.0):
				errors.append("Gerald node-authored combat effects did not inherit his 0.75x-Kael world scale")
			else:
				checks += 1
			actor.play(ActorVisual.S_WALK)
			for direction in [CharacterAnimator.Direction.RIGHT, CharacterAnimator.Direction.UP_RIGHT, CharacterAnimator.Direction.UP, CharacterAnimator.Direction.LEFT, CharacterAnimator.Direction.DOWN_LEFT, CharacterAnimator.Direction.DOWN]:
				actor.animator.set_direction(direction)
				await process_frame
				await process_frame
			if absf((actor.get_node("FrameSprite") as Sprite2D).rotation) > deg_to_rad(4.0):
				errors.append("Gerald turn animation accumulated rotation around the sprite origin")
			else:
				checks += 1
			var live_rig := actor.get_node_or_null("DirectionalEquipment") as DirectionalEquipmentLayers
			actor.animator.set_direction(CharacterAnimator.Direction.RIGHT)
			await process_frame
			if live_rig == null or live_rig.get_active_layer() != live_rig.get_node_or_null("Right"):
				errors.append("live ActorVisual directional equipment did not follow CharacterAnimator")
			else:
				checks += 1
		actor.queue_free()
		await process_frame

	var player_packed := load("res://scenes/characters/player.tscn") as PackedScene
	if player_packed == null:
		errors.append("Player scene failed to load")
	else:
		checks += 1
		var player := player_packed.instantiate()
		root.add_child(player)
		await process_frame
		var visual := player.get_node_or_null("ActorVisual") as ActorVisual
		if visual == null:
			errors.append("Player has no ActorVisual")
		else:
			checks += 1
			var player_kael_aura := visual.get_node_or_null("Effects/Aura/KaelEmberAura") as Sprite2D
			if player_kael_aura == null or not player_kael_aura.visible:
				errors.append("Player did not activate Kael's ember aura")
			else:
				checks += 1
			for node_path in ["DirectionalEquipment/Right/Slots/BackEquipment/Mount/Visual", "DirectionalEquipment/Right/Slots/HairAccessory/Mount/Visual", "Effects/Aura/LilithSpectralGlow", "Effects/Aura/KaelEmberAura", "Effects/Particles"]:
				if visual.get_node_or_null(node_path) == null:
					errors.append("Player ActorVisual missing %s" % node_path)
				else:
					checks += 1
			if str(player.get("avatar_id")) != "kael":
				errors.append("Player did not retain canonical Kael avatar registration")
			else:
				checks += 1
			# Exercise the real Player avatar-switch path, not only ActorVisual directly.
			player.set_avatar("gerald")
			await process_frame
			if str(player.get("avatar_id")) != "gerald":
				errors.append("Player could not switch to Gerald through set_avatar()")
			else:
				checks += 1
			if not is_equal_approx(visual.visual_scale, (0.75 * 183.0) / 128.0):
				errors.append("Live Player did not apply Gerald's 0.75x-Kael scale")
			else:
				checks += 1
			var gerald_sprite := visual.get_node_or_null("FrameSprite") as Sprite2D
			if gerald_sprite == null or gerald_sprite.texture == null or absf(gerald_sprite.scale.x - ((0.75 * 183.0) / 128.0)) > ((0.75 * 183.0) / 128.0) * 0.005:
				errors.append("Live Player Gerald sprite geometry did not retain 0.75x-Kael scale (including restrained idle breathing tolerance)")
			else:
				checks += 1
			player.set_avatar("kael")
			await process_frame
		player.queue_free()
		await process_frame

	if errors.is_empty():
		print("[playable_character_nodes] PASS — %d checks, 0 failures" % checks)
	else:
		for error in errors:
			push_error(error)
		print("[playable_character_nodes] FAIL — %d checks, %d failures" % [checks, errors.size()])
	quit(0 if errors.is_empty() else 1)

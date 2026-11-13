extends Node
## Scene-based verification for the protagonists' playable avatar art.
##
## Run with:
##   godot --headless --path . res://tools/verify_character_avatars.tscn
##
## This exercises the REAL runtime seams rather than re-reading files:
##   - SpriteFramesActorSource.from_disk(<id>) loads world_sheet.tres
##   - every (state, direction) animation has the authoritative frame count,
##     fps, loop flag and non-null 96x128 frames
##   - a Player's default avatar is still the Wanderer placeholder
##   - pressing the switch_avatar action swaps the world actor onto the
##     selected character's disk sheet (using_temporary_art false, sprite
##     visible, no flip_h)
##   - facing changes select direction rows instead of mirroring
##   - a second press returns to the Wanderer
##
## Exits 0 when every check passes, 1 otherwise. Read-only: creates no files.

const CHARACTERS := ["gerald", "lilith", "kael"]
const EXPECTED_ANIMATIONS := 72


var _failures: int = 0
var _player: Player


func _ready() -> void:
	for character_id in CHARACTERS:
		print("[avatars] === %s ===" % character_id)
		_check("%s resolves in ContentDB" % character_id,
			ContentDB.get_character(character_id) != null)
		_check("%s reports world art ready" % character_id,
			MainCharacterRoster.world_art_ready(character_id))
		_check_sheet_contract(character_id)
	await _check_avatar_switching()
	print("[avatars] %s" % ("OK" if _failures == 0 else "FAILED (%d)" % _failures))
	get_tree().quit(0 if _failures == 0 else 1)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("[avatars] PASS " + label)
	else:
		_failures += 1
		printerr("[avatars] FAIL " + label + ("" if detail.is_empty() else " - " + detail))


func _check_sheet_contract(character_id: String) -> void:
	var source := SpriteFramesActorSource.from_playable(character_id)
	_check("%s source loaded from disk" % character_id,
		source != null and source.loaded_from_disk)
	_check("%s source has frames" % character_id, source != null and source.has_frames())
	_check("%s source is not temporary" % character_id,
		source != null and not source.is_temporary())
	_check("%s source does not mirror by facing" % character_id,
		source != null and not source.mirrors_by_facing())
	var errors: Array[String] = source.validate_sheets() if source != null else ["no source"]
	_check("%s source validates cleanly" % character_id, errors.is_empty(), str(errors))

	var sheet: SpriteFrames = MainCharacterRoster.world_sheet(character_id)
	_check("%s world sheet loads as SpriteFrames" % character_id, sheet != null)
	if sheet == null:
		return
	_check("%s sheet exposes %d animations" % [character_id, EXPECTED_ANIMATIONS],
		sheet.get_animation_names().size() == EXPECTED_ANIMATIONS,
		str(sheet.get_animation_names().size()))

	var frame_total := 0
	for raw_state in CharacterAnimator.EXTENDED_STATES:
		var state := int(raw_state)
		var state_name := CharacterAnimator.state_name(state)
		var expected_frames := CharacterAnimator.frame_count_for(state)
		var expected_fps := CharacterAnimator.fps_for(state)
		var expected_loop := CharacterAnimator.looping_for(state)
		for raw_dir in CharacterAnimator.ALL_DIRECTIONS:
			var dir := int(raw_dir)
			var anim := StringName("%s_%d" % [state_name, dir])
			if not sheet.has_animation(anim):
				_check("%s animation exists: %s" % [character_id, str(anim)], false)
				continue
			var count := sheet.get_frame_count(anim)
			_check("%s %s frame count == %d" % [character_id, str(anim), expected_frames],
				count == expected_frames, str(count))
			_check("%s %s fps == %.1f" % [character_id, str(anim), expected_fps],
				is_equal_approx(sheet.get_animation_speed(anim), expected_fps))
			_check("%s %s loop == %s" % [character_id, str(anim), str(expected_loop)],
				sheet.get_animation_loop(anim) == expected_loop)
			for i in count:
				var tex: Texture2D = sheet.get_frame_texture(anim, i)
				if tex == null:
					_check("%s %s frame %d is non-null" % [character_id, str(anim), i], false)
					continue
				_check("%s %s frame %d is 96x128" % [character_id, str(anim), i],
					tex.get_width() == 96 and tex.get_height() == 128,
					"%dx%d" % [tex.get_width(), tex.get_height()])
				frame_total += 1
	_check("%s sheet frame total == 432" % character_id, frame_total == 432, str(frame_total))


func _check_avatar_switching() -> void:
	_player = Player.new()
	add_child(_player)
	await get_tree().process_frame
	await get_tree().process_frame

	_check("player default avatar is the Wanderer", _player.avatar_id == "", _player.avatar_id)
	_check("player default visual uses temporary art", _player.visual.using_temporary_art)

	var ids := _player.available_avatars()
	_check("available avatars include the Wanderer", ids.has(""), str(ids))
	for character_id in CHARACTERS:
		_check("available avatars include %s" % character_id, ids.has(character_id), str(ids))

	# Cycle through every avatar and confirm each one really switches.
	for character_id in CHARACTERS:
		var guard := 0
		while _player.avatar_id != character_id and guard < 8:
			_send_switch_avatar()
			await get_tree().process_frame
			guard += 1
		_check("Tab reaches %s" % character_id, _player.avatar_id == character_id,
			_player.avatar_id)
		_check("%s avatar uses final art" % character_id,
			not _player.visual.using_temporary_art)
		_check("%s avatar registers a disk source" % character_id,
			bool(_player.visual.character_art_report().get("has_frames", false)),
			str(_player.visual.character_art_report()))
		_check("%s avatar animation count == 72" % character_id,
			int(_player.visual.character_art_report().get("animation_count", 0)) == EXPECTED_ANIMATIONS,
			str(_player.visual.character_art_report()))
		_check("%s avatar character_id is %s" % [character_id, character_id],
			_player.visual.character_id == character_id, _player.visual.character_id)
		var sprite := _player.visual._sprite
		_check("%s sprite node is visible" % character_id, sprite != null and sprite.visible)
		_check("%s sprite shows a frame" % character_id,
			sprite != null and sprite.texture != null)
		if sprite != null and sprite.texture != null:
			_check("%s sprite frame is 96x128" % character_id,
				sprite.texture.get_width() == 96 and sprite.texture.get_height() == 128)
		_check("%s sprite is not mirrored" % character_id, sprite != null and not sprite.flip_h)

		# Facing left must change the rendered direction, not mirror the texture.
		var down_tex: Texture2D = sprite.texture if sprite != null else null
		_player.visual.set_move_direction(Vector2(-1, 0))
		_player.visual.facing = -1.0
		await get_tree().process_frame
		var left_tex: Texture2D = sprite.texture if sprite != null else null
		_check("%s facing left selects a different direction frame" % character_id,
			left_tex != null and left_tex != down_tex)
		_check("%s facing left does not flip the sprite" % character_id,
			sprite != null and not sprite.flip_h)

	# One more press from the last avatar must land back on the Wanderer.
	var guard := 0
	while _player.avatar_id != "" and guard < 8:
		_send_switch_avatar()
		await get_tree().process_frame
		guard += 1
	_check("cycling returns to the Wanderer", _player.avatar_id == "", _player.avatar_id)
	_check("Wanderer avatar uses temporary art again", _player.visual.using_temporary_art)

	_player.queue_free()
	await get_tree().process_frame


func _send_switch_avatar() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_TAB
	event.physical_keycode = KEY_TAB
	event.pressed = true
	_player._unhandled_input(event)
	var release := InputEventKey.new()
	release.keycode = KEY_TAB
	release.physical_keycode = KEY_TAB
	release.pressed = false
	_player._unhandled_input(release)

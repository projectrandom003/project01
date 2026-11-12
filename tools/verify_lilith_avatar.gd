extends Node
## Scene-based verification for Lilith's playable avatar.
##
## Run with:
##   godot --headless --path . res://tools/verify_lilith_avatar.tscn
##
## This exercises the REAL runtime seams rather than re-reading files:
##   - SpriteFramesActorSource.from_disk("lilith") loads world_sheet.tres
##   - every (state, direction) animation has the authoritative frame count,
##     fps, loop flag and non-null 96x128 frames
##   - a Player's default avatar is still the Wanderer placeholder
##   - pressing the switch_avatar action swaps the world actor onto Lilith's
##     disk sheet (using_temporary_art false, sprite visible, no flip_h)
##   - facing changes select direction rows instead of mirroring
##   - a second press returns to the Wanderer
##
## Exits 0 when every check passes, 1 otherwise. Read-only: creates no files.

const FRAME_W := 96
const FRAME_H := 128
const EXPECTED_ANIMATIONS := 72

var _failures: int = 0
var _player: Player


func _ready() -> void:
	_check("ContentDB knows lilith", ContentDB.get_character("lilith") != null)
	_check("MainCharacterRoster reports lilith world art ready", MainCharacterRoster.world_art_ready("lilith"))
	_check_sheet_contract()
	await _check_avatar_switching()
	print("[lilith] %s" % ("OK" if _failures == 0 else "FAILED (%d)" % _failures))
	get_tree().quit(0 if _failures == 0 else 1)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("[lilith] PASS " + label)
	else:
		_failures += 1
		printerr("[lilith] FAIL " + label + ("" if detail.is_empty() else " - " + detail))


func _check_sheet_contract() -> void:
	var source := SpriteFramesActorSource.from_disk("lilith")
	_check("lilith source loaded from disk", source != null and source.loaded_from_disk)
	_check("lilith source has frames", source != null and source.has_frames())
	_check("lilith source is not temporary", source != null and not source.is_temporary())
	_check("lilith source does not mirror by facing", source != null and not source.mirrors_by_facing())
	var errors: Array[String] = source.validate_sheets() if source != null else ["no source"]
	_check("lilith source validates cleanly", errors.is_empty(), str(errors))

	var sheet: SpriteFrames = MainCharacterRoster.world_sheet("lilith")
	_check("lilith world sheet loads as SpriteFrames", sheet != null)
	if sheet == null:
		return
	_check("lilith sheet exposes %d animations" % EXPECTED_ANIMATIONS,
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
				_check("animation exists: " + str(anim), false)
				continue
			var count: int = sheet.get_frame_count(anim)
			_check("%s frame count == %d" % [anim, expected_frames], count == expected_frames, str(count))
			_check("%s fps == %.1f" % [anim, expected_fps],
				is_equal_approx(sheet.get_animation_speed(anim), expected_fps))
			_check("%s loop == %s" % [anim, str(expected_loop)],
				sheet.get_animation_loop(anim) == expected_loop)
			for i in count:
				var tex: Texture2D = sheet.get_frame_texture(anim, i)
				if tex == null:
					_check("%s frame %d is non-null" % [anim, i], false)
					continue
				_check("%s frame %d is %dx%d" % [anim, i, FRAME_W, FRAME_H],
					tex.get_width() == FRAME_W and tex.get_height() == FRAME_H,
					"%dx%d" % [tex.get_width(), tex.get_height()])
				frame_total += 1
	_check("lilith sheet frame total == 432", frame_total == 432, str(frame_total))


func _check_avatar_switching() -> void:
	_player = Player.new()
	add_child(_player)
	await get_tree().process_frame
	await get_tree().process_frame

	_check("player default avatar is the Wanderer", _player.avatar_id == "", _player.avatar_id)
	_check("player default visual uses temporary art", _player.visual.using_temporary_art)

	var ids := _player.available_avatars()
	_check("available avatars include the Wanderer and Lilith", ids.has("") and ids.has("lilith"), str(ids))
	_check("available avatars exclude artless protagonists", not ids.has("gerald") and not ids.has("kael"), str(ids))

	# First Tab press: Wanderer -> Lilith.
	_send_switch_avatar()
	await get_tree().process_frame
	_check("Tab switches the avatar to lilith", _player.avatar_id == "lilith", _player.avatar_id)
	_check("lilith avatar uses final art", not _player.visual.using_temporary_art)
	_check("lilith avatar registers a disk source", _player.visual.character_art_report().get("has_frames", false),
		str(_player.visual.character_art_report()))
	_check("lilith avatar animation count == 72",
		int(_player.visual.character_art_report().get("animation_count", 0)) == EXPECTED_ANIMATIONS,
		str(_player.visual.character_art_report()))
	_check("lilith avatar character_id is lilith", _player.visual.character_id == "lilith", _player.visual.character_id)

	var sprite := _player.visual._sprite
	_check("lilith sprite node is visible", sprite != null and sprite.visible)
	_check("lilith sprite shows a frame", sprite != null and sprite.texture != null)
	if sprite != null and sprite.texture != null:
		_check("lilith sprite frame is 96x128",
			sprite.texture.get_width() == FRAME_W and sprite.texture.get_height() == FRAME_H)
	_check("lilith sprite is not mirrored", sprite != null and not sprite.flip_h)

	# Facing left must change the rendered direction, not mirror the texture.
	var down_tex: Texture2D = sprite.texture if sprite != null else null
	_player.visual.set_move_direction(Vector2(-1, 0))
	_player.visual.facing = -1.0
	await get_tree().process_frame
	var left_tex: Texture2D = sprite.texture if sprite != null else null
	_check("facing left selects a different direction frame", left_tex != null and left_tex != down_tex)
	_check("facing left does not flip the sprite", sprite != null and not sprite.flip_h)

	# Second Tab press: Lilith -> Wanderer.
	_send_switch_avatar()
	await get_tree().process_frame
	_check("second Tab returns to the Wanderer", _player.avatar_id == "", _player.avatar_id)
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

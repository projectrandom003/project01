extends SceneTree

const SHEET_PATH := "res://assets/characters/gerald/world_sheet.tres"
# Generated from the exact 8-direction Gerald reference sheet supplied by the user.
# Row order matches CharacterAnimator: DOWN, DOWN_RIGHT, RIGHT, UP_RIGHT,
# UP, UP_LEFT, LEFT, DOWN_LEFT. Five evenly spaced idle poses are retained.
const PNG_PATH := "res://assets/characters/gerald/generated/gerald_idle_user_reference_8dir_5f_96x128.png"
const FRAME_W := 96
const FRAME_H := 128
const FRAMES_PER_DIRECTION := 5

func _initialize() -> void:
	var sheet := load(SHEET_PATH) as SpriteFrames
	var texture := load(PNG_PATH) as Texture2D
	if sheet == null or texture == null:
		push_error("Gerald idle install: missing SpriteFrames or user-reference idle atlas at " + PNG_PATH)
		quit(1)
		return
	if texture.get_width() != FRAME_W * FRAMES_PER_DIRECTION or texture.get_height() != FRAME_H * 8:
		push_error("Unexpected 5x8 idle atlas dimensions: %dx%d" % [texture.get_width(), texture.get_height()])
		quit(1)
		return
	for direction in range(8):
		var animation := StringName("idle_%d" % direction)
		if not sheet.has_animation(animation):
			push_error("Missing existing animation " + String(animation))
			quit(1)
			return
		sheet.remove_animation(animation)
		sheet.add_animation(animation)
		sheet.set_animation_speed(animation, CharacterAnimator.fps_for(CharacterAnimator.State.IDLE))
		sheet.set_animation_loop(animation, true)
		for frame_index in CharacterAnimator.frame_count_for(CharacterAnimator.State.IDLE):
			var atlas_frame := AtlasTexture.new()
			atlas_frame.atlas = texture
			atlas_frame.region = Rect2((frame_index % FRAMES_PER_DIRECTION) * FRAME_W, direction * FRAME_H, FRAME_W, FRAME_H)
			sheet.add_frame(animation, atlas_frame)
	var err := ResourceSaver.save(sheet, SHEET_PATH)
	if err != OK:
		push_error("Could not save Gerald SpriteFrames: %s" % error_string(err))
		quit(1)
		return
	print("GERALD_IDLE_INSTALL_OK source=user_reference directions=8 frames_per_direction=5 total_frames=40")
	quit(0)

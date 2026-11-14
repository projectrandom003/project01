extends SceneTree

const SHEET_PATH := "res://assets/characters/gerald/world_sheet.tres"
const PNG_PATH := "res://assets/characters/gerald/generated/gerald_walk_8dir_8f_96x128_q64.png"
const DIRECTIONS := ["down", "down_right", "right", "up_right", "up", "up_left", "left", "down_left"]
const FRAME_W := 96
const FRAME_H := 128
const FRAMES_PER_DIRECTION := 8
const REQUIRED_FRAMES := 16

func _initialize() -> void:
	var sheet := load(SHEET_PATH) as SpriteFrames
	if sheet == null:
		push_error("Could not load Gerald SpriteFrames: " + SHEET_PATH)
		quit(1)
		return
	var texture := load(PNG_PATH) as Texture2D
	if texture == null:
		push_error("Could not load generated walk atlas: " + PNG_PATH)
		quit(1)
		return
	if texture.get_width() != FRAME_W * FRAMES_PER_DIRECTION or texture.get_height() != FRAME_H * FRAMES_PER_DIRECTION:
		push_error("Unexpected atlas dimensions: %dx%d" % [texture.get_width(), texture.get_height()])
		quit(1)
		return
	var replaced := 0
	for direction in range(8):
		var animation := StringName("walk_%d" % direction)
		if not sheet.has_animation(animation):
			push_error("Missing existing animation " + String(animation))
			quit(1)
			return
		sheet.remove_animation(animation)
		sheet.add_animation(animation)
		sheet.set_animation_speed(animation, CharacterAnimator.fps_for(CharacterAnimator.State.WALK))
		sheet.set_animation_loop(animation, true)
		for frame_index in range(REQUIRED_FRAMES):
			var source_frame := frame_index % FRAMES_PER_DIRECTION
			var atlas_frame := AtlasTexture.new()
			atlas_frame.atlas = texture
			atlas_frame.region = Rect2(source_frame * FRAME_W, direction * FRAME_H, FRAME_W, FRAME_H)
			sheet.add_frame(animation, atlas_frame)
		if sheet.get_frame_count(animation) != REQUIRED_FRAMES:
			push_error("Wrong frame count after install for " + String(animation))
			quit(1)
			return
		replaced += 1
	var err := ResourceSaver.save(sheet, SHEET_PATH)
	if err != OK:
		push_error("Could not save Gerald SpriteFrames: %s" % error_string(err))
		quit(1)
		return
	print("GERALD_WALK_INSTALL_OK directions=%d frames_per_direction=%d total_frames=%d" % [replaced, REQUIRED_FRAMES, replaced * REQUIRED_FRAMES])
	for direction in range(8):
		var animation := StringName("walk_%d" % direction)
		print("%s => %s (%d frames)" % [String(animation), DIRECTIONS[direction], sheet.get_frame_count(animation)])
	quit(0)

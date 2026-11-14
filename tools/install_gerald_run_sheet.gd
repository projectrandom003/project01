extends SceneTree

const SHEET_PATH := "res://assets/characters/gerald/world_sheet.tres"
const PNG_PATH := "res://assets/characters/gerald/generated/gerald_run_8dir_8f_96x128.png"
const FRAME_W := 96
const FRAME_H := 128
const FRAMES_PER_DIRECTION := 8

func _initialize() -> void:
	var sheet := load(SHEET_PATH) as SpriteFrames
	var texture := load(PNG_PATH) as Texture2D
	if sheet == null or texture == null:
		push_error("Gerald run install: missing SpriteFrames or generated run atlas")
		quit(1)
		return
	if texture.get_width() != FRAME_W * FRAMES_PER_DIRECTION or texture.get_height() != FRAME_H * FRAMES_PER_DIRECTION:
		push_error("Unexpected run atlas dimensions: %dx%d" % [texture.get_width(), texture.get_height()])
		quit(1)
		return
	for direction in range(8):
		var animation := StringName("run_%d" % direction)
		if not sheet.has_animation(animation):
			push_error("Missing existing animation " + String(animation))
			quit(1)
			return
		sheet.remove_animation(animation)
		sheet.add_animation(animation)
		sheet.set_animation_speed(animation, CharacterAnimator.fps_for(CharacterAnimator.State.RUN))
		sheet.set_animation_loop(animation, true)
		for frame_index in CharacterAnimator.frame_count_for(CharacterAnimator.State.RUN):
			var atlas_frame := AtlasTexture.new()
			atlas_frame.atlas = texture
			atlas_frame.region = Rect2((frame_index % FRAMES_PER_DIRECTION) * FRAME_W, direction * FRAME_H, FRAME_W, FRAME_H)
			sheet.add_frame(animation, atlas_frame)
	var err := ResourceSaver.save(sheet, SHEET_PATH)
	if err != OK:
		push_error("Could not save Gerald SpriteFrames: %s" % error_string(err))
		quit(1)
		return
	print("GERALD_RUN_INSTALL_OK directions=8 frames_per_direction=16 source_unique_frames=8 total_frames=128")
	quit(0)

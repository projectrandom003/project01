extends SceneTree

func _initialize() -> void:
	var source := SpriteFramesActorSource.from_disk("gerald") as SpriteFramesActorSource
	if source == null or not source.has_frames():
		push_error("Gerald SpriteFrames source did not load")
		quit(1)
		return
	var errors := source.validate_sheets()
	if not errors.is_empty():
		for error in errors:
			push_error(error)
		quit(1)
		return
	var states := [CharacterAnimator.State.WALK, CharacterAnimator.State.RUN]
	var checked := 0
	for state in states:
		for direction in CharacterAnimator.ALL_DIRECTIONS:
			var count := source.frame_count(state, direction)
			if count != CharacterAnimator.frame_count_for(state):
				push_error("Frame count mismatch state=%d dir=%d count=%d" % [state, direction, count])
				quit(1)
				return
			for frame_index in count:
				var texture := source.frame(state, direction, frame_index)
				if texture == null or texture.get_width() != 96 or texture.get_height() != 128:
					push_error("Invalid frame state=%d dir=%d frame=%d" % [state, direction, frame_index])
					quit(1)
					return
				checked += 1
	print("GERALD_MOVEMENT_VERIFY_OK states=2 directions=8 frames_per_direction=16 total_frames=%d checked=%d" % [checked, checked])
	quit(0)

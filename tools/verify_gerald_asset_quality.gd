extends SceneTree

func _initialize() -> void:
	var source := SpriteFramesActorSource.from_disk("gerald") as SpriteFramesActorSource
	if source == null or not source.has_frames():
		push_error("Gerald production SpriteFrames did not load")
		quit(1)
		return
	var errors := source.validate_sheets()
	if not errors.is_empty():
		for error in errors:
			push_error(error)
		quit(1)
		return
	var checked := 0
	var empty_frames: Array[String] = []
	for state in CharacterAnimator.EXTENDED_STATES:
		for direction in CharacterAnimator.ALL_DIRECTIONS:
			var count := source.frame_count(int(state), int(direction))
			for frame_index in count:
				var tex := source.frame(int(state), int(direction), frame_index)
				if tex == null:
					empty_frames.append("%s_%d:%d null" % [CharacterAnimator.state_name(int(state)), int(direction), frame_index])
					continue
				var image := tex.get_image()
				if image == null or image.is_empty():
					empty_frames.append("%s_%d:%d empty-image" % [CharacterAnimator.state_name(int(state)), int(direction), frame_index])
					continue
				var used := image.get_used_rect()
				if used.size.x < 8 or used.size.y < 8:
					empty_frames.append("%s_%d:%d transparent-or-tiny" % [CharacterAnimator.state_name(int(state)), int(direction), frame_index])
				checked += 1
	if not empty_frames.is_empty():
		for issue in empty_frames:
			push_error("GERALD_FRAME_QUALITY: " + issue)
		quit(1)
		return
	print("GERALD_ASSET_QUALITY_OK animations=72 nonempty_frames=%d directions=8" % checked)
	quit(0)

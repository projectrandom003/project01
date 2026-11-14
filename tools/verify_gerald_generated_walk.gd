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
	var expected := [
		CharacterAnimator.Direction.DOWN,
		CharacterAnimator.Direction.DOWN_RIGHT,
		CharacterAnimator.Direction.RIGHT,
		CharacterAnimator.Direction.UP_RIGHT,
		CharacterAnimator.Direction.UP,
		CharacterAnimator.Direction.UP_LEFT,
		CharacterAnimator.Direction.LEFT,
		CharacterAnimator.Direction.DOWN_LEFT,
	]
	var checked := 0
	for direction in expected:
		var count := source.frame_count(CharacterAnimator.State.WALK, direction)
		if count != CharacterAnimator.frame_count_for(CharacterAnimator.State.WALK):
			push_error("Walk frame count mismatch for direction %d: %d" % [direction, count])
			quit(1)
			return
		for frame_index in count:
			var texture := source.frame(CharacterAnimator.State.WALK, direction, frame_index)
			if texture == null or texture.get_width() != 96 or texture.get_height() != 128:
				push_error("Invalid walk frame dir=%d frame=%d" % [direction, frame_index])
				quit(1)
				return
			checked += 1
	print("GERALD_GENERATED_WALK_VERIFY_OK animations=72 walk_directions=8 walk_frames=%d dimensions=96x128 checked=%d" % [source.frame_count(CharacterAnimator.State.WALK, 0), checked])
	quit(0)

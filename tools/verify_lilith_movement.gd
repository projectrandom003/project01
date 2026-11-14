extends SceneTree

func _initialize() -> void:
	var resource_path := "res://assets/characters/lilith/world_sheet.tres"
	var sf := load(resource_path) as SpriteFrames
	if sf == null:
		push_error("Lilith SpriteFrames failed to load")
		quit(1)
		return
	var failures := 0
	for state in ["walk", "run"]:
		for direction in range(8):
			var anim := StringName("%s_%d" % [state, direction])
			if not sf.has_animation(anim):
				push_error("Missing " + String(anim))
				failures += 1
				continue
			var count := sf.get_frame_count(anim)
			if count != 16:
				push_error("%s has %d frames" % [String(anim), count])
				failures += 1
				continue
			var signatures: Dictionary = {}
			for i in range(count):
				var tex := sf.get_frame_texture(anim, i)
				if tex == null or tex.get_width() != 96 or tex.get_height() != 128:
					push_error("Bad texture %s frame %d" % [String(anim), i])
					failures += 1
					continue
				signatures[tex.get_image().get_data().hex_encode()] = true
			print("[LilithMovement] %s frames=%d distinct_pixel_frames=%d fps=%.1f" % [String(anim), count, signatures.size(), sf.get_animation_speed(anim)])
	print("[LilithMovement] " + ("PASS" if failures == 0 else "FAIL %d" % failures))
	quit(0 if failures == 0 else 1)

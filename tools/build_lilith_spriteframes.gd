extends SceneTree
## Slices Lilith's per-state world atlases into a production SpriteFrames.
##
## Run with:
##   godot --headless --path . --script res://tools/build_lilith_spriteframes.gd
##
## Input : assets/characters/lilith/<state>_sheet.png
##         (per-state atlas: <frames>*96 wide x 8*128 tall, 8 direction rows)
## Output: assets/characters/lilith/world_sheet.tres
##         (72 animations: <state>_<dir>, authoritative frame counts/fps/loop)
##
## Frame counts, fps and loop flags come from CharacterAnimator so this script
## cannot drift from the runtime contract. Exits 0 only when the saved resource
## reloads with all 72 animations and passes SpriteFramesActorSource validation.

const CHARACTER_ID := "lilith"
const DIR := "res://assets/characters/lilith/"
const SHEET := DIR + "world_sheet.tres"
const FRAME_W := 96
const FRAME_H := 128


func _initialize() -> void:
	var sf := SpriteFrames.new()
	if sf.has_animation(&"default"):
		sf.remove_animation(&"default")

	var errors: Array[String] = []
	var frame_total := 0
	for raw_state in CharacterAnimator.EXTENDED_STATES:
		var state := int(raw_state)
		var state_name := CharacterAnimator.state_name(state)
		var png := "%s%s_sheet.png" % [DIR, state_name]
		var texture: Texture2D = null
		if ResourceLoader.exists(png):
			texture = load(png) as Texture2D
		if texture == null:
			errors.append("missing or unloadable atlas: " + png)
			continue
		var expected_w := CharacterAnimator.frame_count_for(state) * FRAME_W
		if texture.get_width() != expected_w or texture.get_height() != FRAME_H * 8:
			errors.append("%s is %dx%d, expected %dx%d" % [
				png, texture.get_width(), texture.get_height(), expected_w, FRAME_H * 8])
			continue
		var count := CharacterAnimator.frame_count_for(state)
		var speed := CharacterAnimator.fps_for(state)
		var loop := CharacterAnimator.looping_for(state)
		for raw_dir in CharacterAnimator.ALL_DIRECTIONS:
			var dir := int(raw_dir)
			var anim := StringName("%s_%d" % [state_name, dir])
			sf.add_animation(anim)
			sf.set_animation_speed(anim, speed)
			sf.set_animation_loop(anim, loop)
			for i in count:
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(i * FRAME_W, dir * FRAME_H, FRAME_W, FRAME_H)
				sf.add_frame(anim, atlas)
				frame_total += 1

	if not errors.is_empty():
		for e in errors:
			push_error("[LilithSpriteFrames] " + e)
		quit(1)
		return

	var save_error := ResourceSaver.save(sf, SHEET)
	if save_error != OK:
		push_error("[LilithSpriteFrames] ResourceSaver.save failed: %d" % save_error)
		quit(1)
		return

	# Round-trip: load the saved resource and validate it through the real seam.
	var reloaded := load(SHEET)
	if not (reloaded is SpriteFrames):
		push_error("[LilithSpriteFrames] saved resource did not reload as SpriteFrames")
		quit(1)
		return
	var source := SpriteFramesActorSource.from_disk(CHARACTER_ID)
	var validation: Array[String] = source.validate_sheets()
	var names := (reloaded as SpriteFrames).get_animation_names().size()
	print("[LilithSpriteFrames] wrote %s" % SHEET)
	print("[LilithSpriteFrames] animations=%d frames=%d loaded_from_disk=%s temporary=%s" % [
		names, frame_total, str(source.loaded_from_disk), str(source.is_temporary())])
	if not validation.is_empty():
		for e in validation:
			push_error("[LilithSpriteFrames] " + e)
		quit(1)
		return
	if names != 72 or frame_total != 432 or source.is_temporary():
		push_error("[LilithSpriteFrames] unexpected sheet totals")
		quit(1)
		return
	print("[LilithSpriteFrames] OK")
	quit(0)

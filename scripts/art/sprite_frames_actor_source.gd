class_name SpriteFramesActorSource
extends ActorFrameSource
## PRODUCTION sprite-sheet implementation of the ActorFrameSource seam.
##
## Wraps a Godot `SpriteFrames` resource whose animations are named
## "<state_name>_<dir_index>" (e.g. "idle_0" ... "defeat_7") plus the additive
## "cast_<dir>" set, with speed = CharacterAnimator.STATE_FPS / CAST_FPS and
## loop = STATE_LOOPING / CAST_LOOPING. This is the class REAL painted art plugs
## into: register it on ActorVisual via set_frame_source() and NOTHING else in
## gameplay/rendering changes.
##
## MISSING-ASSET FALLBACK: from_disk() NEVER crashes. If no disk asset exists,
## has_frames() is false, is_temporary() is true, frame() returns null and
## validate_sheets() reports the missing sheet, so ActorVisual gracefully keeps
## the procedural placeholder. is_temporary() is false ONLY when a real
## disk-backed SpriteFrames was actually loaded.
##
## build_from_textures() is an OPTIONAL helper that assembles an in-memory
## SpriteFrames from ProceduralArt.character_frame() -- used by the TEMPORARY
## DemoCharacterFrames demonstration character (see that class).
##
## PRODUCTION REGISTRATION CONTRACT (register_character / validation_report):
## A real painted world sheet MUST expose ALL 9 animation states (the 8 core
## states + the additive CAST state) x 8 directions = 72 animations, each with
## the authoritative frame counts / fps / loop flags and 96x128 frames. Until
## such a fully validated sheet exists on disk, has_frames() is false and
## ProceduralActorFrames REMAINS the active fallback for every world actor:
## a missing or incomplete sheet NEVER replaces the procedural placeholder.

# ------------------------------------------------------------------ constants

const SHEET_PATH_TEMPLATE := "res://assets/characters/%s/world_sheet.tres"
const SHEET_PNG_TEMPLATE := "res://assets/characters/%s/world_sheet.png"

# ------------------------------------------------------------------ state

var character_id: String = ""
var sprite_frames: SpriteFrames = null
var sheet_path: String = ""
var loaded_from_disk: bool = false
var missing_reason: String = ""


func _init(p_character_id: String = "", p_sprite_frames: SpriteFrames = null) -> void:
	character_id = p_character_id
	sprite_frames = p_sprite_frames
	sheet_path = ""
	loaded_from_disk = false
	missing_reason = ""


# ------------------------------------------------------------- disk loading

## Try to load res://assets/characters/<id>/world_sheet.tres (a sliced
## SpriteFrames) or world_sheet.png. On ANY failure return a NOT-loaded source
## (has_frames false, is_temporary true, missing_reason set) -- NEVER crash.
static func from_disk(character_id: String) -> ActorFrameSource:
	# Instantiate via a RUNTIME load() of this script rather than
	# `SpriteFramesActorSource.new()`, and type against the BASE class. A static
	# method that names its OWN global class (return type or constructor call)
	# compiles a self-reference into the script's constant pool; once this class
	# is subclassed (DemoCharacterFrames) that cycle pins the global-class script
	# graph past GDScript/rendering-server teardown, so Godot reports leaked
	# ObjectDB instances at exit. A runtime load() + base typing breaks the cycle
	# while keeping identical behaviour (still returns a SpriteFramesActorSource).
	var src: ActorFrameSource = load("res://scripts/art/sprite_frames_actor_source.gd").new(character_id)
	var tres := "res://assets/characters/%s/world_sheet.tres" % character_id
	var png := "res://assets/characters/%s/world_sheet.png" % character_id
	src.sheet_path = tres
	if ResourceLoader.exists(tres):
		var loaded: Resource = load(tres)
		if loaded is SpriteFrames:
			src.sprite_frames = loaded as SpriteFrames
			src.loaded_from_disk = true
			src.missing_reason = ""
		else:
			src.missing_reason = "%s exists but is not a SpriteFrames resource" % tres
	elif FileAccess.file_exists(png) or ResourceLoader.exists(png):
		src.sheet_path = png
		src.missing_reason = "%s is a raw image; slice it into a SpriteFrames .tres to register this character" % png
	else:
		src.missing_reason = "no world_sheet.tres / world_sheet.png for character '%s' (expected under res://assets/characters/%s/)" % [character_id, character_id]
	return src


# ------------------------------------------------------- SpriteFrames assembly

## Animation name for a (state, direction) address. CAST (8) -> "cast_<dir>".
static func _anim_name(s: int, d: int) -> String:
	return "%s_%d" % [CharacterAnimator.state_name(s), d]


static func _anim(s: int, d: int) -> StringName:
	return StringName(_anim_name(s, d))


## OPTIONAL helper: assemble an in-memory SpriteFrames covering ALL 9 states
## (8 core + CAST) x 8 directions at the authoritative frame counts/fps/loop,
## from ProceduralArt.character_frame() cached textures. Bounded & lazy: the
## generator caches textures, so no per-frame allocation happens here.
func build_from_textures(palette: Dictionary) -> void:
	var sf := SpriteFrames.new()
	# A fresh SpriteFrames owns a "default" animation; drop it for a clean sheet.
	if sf.has_animation(&"default"):
		sf.remove_animation(&"default")
	for raw_s in CharacterAnimator.EXTENDED_STATES:
		var s := int(raw_s)
		var frames := CharacterAnimator.frame_count_for(s)
		var speed := CharacterAnimator.fps_for(s)
		var loop := CharacterAnimator.looping_for(s)
		for raw_d in CharacterAnimator.ALL_DIRECTIONS:
			var d := int(raw_d)
			var anim := _anim(s, d)
			sf.add_animation(anim)
			sf.set_animation_speed(anim, speed)
			sf.set_animation_loop(anim, loop)
			for i in frames:
				var tex: Texture2D = ProceduralArt.character_frame(palette, s, d, i)
				if tex == null:
					tex = ProceduralArt.white_pixel()
				sf.add_frame(anim, tex)
	sprite_frames = sf
	loaded_from_disk = false
	missing_reason = ""


# -------------------------------------------------------- ActorFrameSource API

func has_frames() -> bool:
	return sprite_frames != null and sprite_frames.has_animation(_anim(0, 0))


## FALSE only when a real disk-backed SpriteFrames is loaded.
func is_temporary() -> bool:
	return not loaded_from_disk


## Real sheets address all 8 directions explicitly, so the renderer must NOT
## mirror them from the actor's facing sign (that would flip LEFT into RIGHT).
func mirrors_by_facing() -> bool:
	return false


func source_label() -> String:
	if loaded_from_disk:
		return "spriteframes:%s" % sheet_path
	if not missing_reason.is_empty():
		return "spriteframes-missing"
	return "spriteframes-inmemory"


func frame(state: int, direction: int, index: int) -> Texture2D:
	if sprite_frames == null:
		return null
	if not CharacterAnimator.is_valid_state(state):
		return null
	var d := direction if CharacterAnimator.is_valid_direction(direction) else 0
	var anim := _anim(state, d)
	if not sprite_frames.has_animation(anim):
		return null
	var count := sprite_frames.get_frame_count(anim)
	if count <= 0:
		return null
	var i := clampi(index, 0, count - 1)
	return sprite_frames.get_frame_texture(anim, i)


func frame_count(state: int, direction: int) -> int:
	var d := direction if CharacterAnimator.is_valid_direction(direction) else 0
	if sprite_frames != null:
		var anim := _anim(state, d)
		if sprite_frames.has_animation(anim):
			return maxi(1, sprite_frames.get_frame_count(anim))
	return maxi(1, CharacterAnimator.frame_count_for(state))


func fps(state: int) -> float:
	if sprite_frames != null:
		var anim := _anim(state, 0)
		if sprite_frames.has_animation(anim):
			return maxf(1.0, sprite_frames.get_animation_speed(anim))
	return maxf(1.0, CharacterAnimator.fps_for(state))


func is_looping(state: int) -> bool:
	if sprite_frames != null:
		var anim := _anim(state, 0)
		if sprite_frames.has_animation(anim):
			return sprite_frames.get_animation_loop(anim)
	return CharacterAnimator.looping_for(state)


func cast_frame(direction: int, index: int) -> Texture2D:
	return frame(CharacterAnimator.CAST_STATE, direction, index)


func cast_frame_count(direction: int) -> int:
	return frame_count(CharacterAnimator.CAST_STATE, direction)


func cast_fps() -> float:
	return fps(CharacterAnimator.CAST_STATE)


## [] when every 9 x 8 animation exists, has the right frame count, non-null
## 96x128 textures and correct loop flags; otherwise precise, human-readable
## errors. A missing sheet is reported (not thrown) so callers fall back safely.
func validate_sheets() -> Array[String]:
	var errors: Array[String] = []
	if sprite_frames == null:
		var why := missing_reason if not missing_reason.is_empty() else "sprite_frames is null"
		errors.append("no sprite sheet registered: %s" % why)
		return errors
	var width := int(GreenwardStyle.SPRITE_SPECS["world_width"])
	var height := int(GreenwardStyle.SPRITE_SPECS["world_height"])
	for raw_s in CharacterAnimator.EXTENDED_STATES:
		var s := int(raw_s)
		var expected_frames := CharacterAnimator.frame_count_for(s)
		var expected_loop := CharacterAnimator.looping_for(s)
		for raw_d in CharacterAnimator.ALL_DIRECTIONS:
			var d := int(raw_d)
			var anim := _anim(s, d)
			var label := _anim_name(s, d)
			if not sprite_frames.has_animation(anim):
				errors.append("missing animation '%s'" % label)
				continue
			var count := sprite_frames.get_frame_count(anim)
			if count != expected_frames:
				errors.append("animation '%s' has %d frames, expected %d" % [label, count, expected_frames])
			if sprite_frames.get_animation_loop(anim) != expected_loop:
				errors.append("animation '%s' loop=%s, expected %s" % [label, str(sprite_frames.get_animation_loop(anim)), str(expected_loop)])
			for i in count:
				var tex := sprite_frames.get_frame_texture(anim, i)
				if tex == null:
					errors.append("animation '%s' frame %d is null" % [label, i])
				elif tex.get_width() != width or tex.get_height() != height:
					errors.append("animation '%s' frame %d is %dx%d, expected %dx%d" % [label, i, tex.get_width(), tex.get_height(), width, height])
	return errors


## Machine-readable load/validation status (never throws).
func load_report() -> Dictionary:
	return {
		"character_id": character_id,
		"sheet_path": sheet_path,
		"loaded_from_disk": loaded_from_disk,
		"has_frames": has_frames(),
		"is_temporary": is_temporary(),
		"missing_reason": missing_reason,
		"source": source_label(),
		"animation_count": sprite_frames.get_animation_names().size() if sprite_frames != null else 0,
		"validation_errors": validate_sheets(),
	}


## super.specs() (the frozen Phase-3 contract) plus production metadata.
func specs() -> Dictionary:
	var d := super.specs()
	d["temporary"] = is_temporary()
	d["source"] = source_label()
	d["character_id"] = character_id
	d["sheet_path"] = sheet_path
	d["loaded_from_disk"] = loaded_from_disk
	d["missing_reason"] = missing_reason
	d["extended_states"] = CharacterAnimator.EXTENDED_STATES.duplicate()
	return d


# ------------------------------------------- registration / reporting API
# ADDITIVE. These static helpers type against the ActorFrameSource BASE (like
# from_disk()) and never name this script's own global identifier in a return
# type or constructor call -- the self-reference that caused the headless
# leaked-RID warnings stays fixed. ProceduralActorFrames is always the fallback.

## Try to register a real, validated world SpriteFrames for `character_id`.
## Returns the SAME source from_disk() produced: a complete, validated sheet is
## a registered disk source; otherwise it is the not-loaded source and the
## caller keeps its procedural fallback. Never crashes, even for unknown ids.
static func register_character(character_id: String) -> ActorFrameSource:
	var src: ActorFrameSource = from_disk(character_id)
	if src == null:
		return null
	if src.has_frames() and src.validate_sheets().is_empty():
		# Real, fully validated disk art: this is the registered source.
		return src
	# No disk art (or an incomplete sheet): hand back the SAME from_disk()
	# source. It is not-loaded for the missing case, so the caller keeps its
	# procedural fallback; a partial sheet is never half-registered.
	return src


## Machine-readable sprite-integration status for a character id. Combines the
## CharacterAssetRegistry sheet paths, on-disk presence, the from_disk() outcome
## and validation into one defensive report (never throws, even for unknown ids).
static func validation_report(character_id: String) -> Dictionary:
	var expected_paths: Dictionary = {}
	for raw_kind in CharacterAssetRegistry.SHEET_KINDS:
		var kind := str(raw_kind)
		expected_paths[kind] = CharacterAssetRegistry.expected_path(character_id, kind)
	var tres := SHEET_PATH_TEMPLATE % character_id
	var png := SHEET_PNG_TEMPLATE % character_id
	var disk_present := _disk_asset_present(tres) or _disk_asset_present(png)
	var src: ActorFrameSource = from_disk(character_id)
	var has_frames := false
	var validation_errors: Array[String] = ["no sprite sheet registered"]
	var animation_count := 0
	if src != null:
		has_frames = src.has_frames()
		validation_errors = src.validate_sheets()
		if src.has_method("load_report"):
			var rep: Variant = src.call("load_report")
			if rep is Dictionary:
				animation_count = int((rep as Dictionary).get("animation_count", 0))
	var registered := has_frames and validation_errors.is_empty()
	return {
		"character_id": character_id,
		"expected_paths": expected_paths,
		"disk_present": disk_present,
		"has_frames": has_frames,
		"validation_errors": validation_errors,
		"registered": registered,
		"fallback_active": not registered,
		"animation_count": animation_count,
	}


static func _disk_asset_present(path: String) -> bool:
	if path.is_empty():
		return false
	if ResourceLoader.exists(path):
		return true
	return FileAccess.file_exists(path)


## Animation names held by the registered SpriteFrames (empty when none).
func animation_names() -> Array[String]:
	var names: Array[String] = []
	if sprite_frames == null:
		return names
	for raw_name in sprite_frames.get_animation_names():
		names.append(str(raw_name))
	return names


## Machine-readable registration status for this concrete source instance.
func registration_report() -> Dictionary:
	return {
		"character_id": character_id,
		"loaded_from_disk": loaded_from_disk,
		"has_frames": has_frames(),
		"is_temporary": is_temporary(),
		"animation_count": sprite_frames.get_animation_names().size() if sprite_frames != null else 0,
		"validation_errors": validate_sheets(),
		"source": source_label(),
	}

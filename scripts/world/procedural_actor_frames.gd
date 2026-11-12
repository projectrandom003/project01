class_name ProceduralActorFrames
extends ActorFrameSource
## TEMPORARY PLACEHOLDER — generated procedurally; replace with painted
## sprite sheets by subclassing ActorFrameSource.
##
## This is the CLEARLY MARKED TEMPORARY frame source for PROJECT FANTASY. It
## has NO painted assets: every (state, direction, frame_index) cell is a
## cached 96x128 RGBA8 texture produced at runtime by
## ProceduralArt.character_frame(palette, state, direction, frame_index).
## Caching lives in ProceduralArt, so frame() never allocates textures.
##
## It is a thin adapter over the shared integer contract:
##   STATES (8): 0 IDLE, 1 WALK, 2 RUN, 3 INTERACT, 4 ATTACK, 5 DAMAGE,
##     6 VICTORY, 7 DEFEAT  ("Directional movement" is the DIRECTION axis,
##     NOT a ninth state).
##   DIRECTIONS (8): 0 DOWN, 1 DOWN_RIGHT, 2 RIGHT, 3 UP_RIGHT, 4 UP,
##     5 UP_LEFT, 6 LEFT, 7 DOWN_LEFT.
## frame_count / fps / is_looping are driven by CharacterAnimator's constants
## so the animator and this source can NEVER disagree about frame indices;
## canvas / anchor / outline geometry is read defensively from
## GreenwardStyle.SPRITE_SPECS (both created by a parallel agent and registered
## as global classes on import).
##
## To ship real art, DO NOT edit gameplay: subclass ActorFrameSource (e.g.
## SpriteFramesActorSource) and register it instead. See REPLACEMENT_SPEC in
## ActorFrameSource and specs() below for the exact replacement specification.

var palette: Dictionary = {}
var boss: bool = false


func _init(p_palette: Dictionary = {}, p_boss: bool = false) -> void:
	# Duplicate so an external dictionary cannot mutate our palette mid-run
	# (keeps frame() deterministic for a fixed sequence of calls).
	palette = p_palette.duplicate()
	boss = p_boss


## TEMPORARY source: frames ARE available (procedurally generated).
func has_frames() -> bool:
	return true


## Always temporary -- real art must replace this source.
func is_temporary() -> bool:
	return true


## Label contains both "placeholder" and "temporary" so tooling/docs can flag
## it unambiguously.
func source_label() -> String:
	return "procedural-placeholder-temporary"


## Return a NON-NULL Texture2D for EVERY valid (state, direction, index).
## Addresses are clamped, and ProceduralArt handles the texture cache (no
## per-call allocation). A final defensive fallback guarantees non-null even
## if the generator is stubbed while the parallel agent's work is integrating.
func frame(state: int, direction: int, index: int) -> Texture2D:
	var s := _safe_state(state)
	var d := _safe_direction(direction)
	var count := frame_count(s, d)
	var i := clampi(index, 0, count - 1)
	var tex: Texture2D = ProceduralArt.character_frame(palette, s, d, i)
	if tex == null:
		# ProceduralArt.white_pixel() already exists and returns a valid 2x2
		# Texture2D; use it only as a last-resort non-null guarantee.
		tex = ProceduralArt.white_pixel()
	return tex


## Frame count for a state; identical across all 8 directions by contract.
## Uses CharacterAnimator.frame_count_for() so the additive CAST state (8)
## reports 7 frames; states 0-7 are byte-for-byte unchanged.
func frame_count(state: int, direction: int) -> int:
	var s := _safe_state(state)
	var _d := _safe_direction(direction)  # validated; count is direction-independent
	return maxi(1, CharacterAnimator.frame_count_for(s))


## Nominal fps for a state (guarded >= 1.0). CAST (8) -> 12.0.
func fps(state: int) -> float:
	var s := _safe_state(state)
	return maxf(1.0, CharacterAnimator.fps_for(s))


## Loop flag for a state. CAST (8) is a non-looping one-shot.
func is_looping(state: int) -> bool:
	var s := _safe_state(state)
	return CharacterAnimator.looping_for(s)


# ---------------------------------------------------------------------------
# Phase-4 additive CAST frames (all procedurally generated, TEMPORARY).
# ---------------------------------------------------------------------------

## Non-null 96x128 cached CAST frame, clamped to the authoritative frame count.
## Delegates to ProceduralArt.character_frame(palette, CAST_STATE, d, i).
func cast_frame(direction: int, index: int) -> Texture2D:
	var d := _safe_direction(direction)
	var count := cast_frame_count(d)
	var i := clampi(index, 0, count - 1)
	var tex: Texture2D = ProceduralArt.character_frame(palette, CharacterAnimator.CAST_STATE, d, i)
	if tex == null:
		tex = ProceduralArt.white_pixel()
	return tex


## CAST frame count (authoritative: 7).
func cast_frame_count(direction: int) -> int:
	var _d := _safe_direction(direction)
	return maxi(1, CharacterAnimator.frame_count_for(CharacterAnimator.CAST_STATE))


## CAST fps (authoritative: 12.0).
func cast_fps() -> float:
	return maxf(1.0, CharacterAnimator.fps_for(CharacterAnimator.CAST_STATE))


## Full machine-readable contract: base specs() (canvas/anchor/fps/frames/
## format/replacement/states/directions) enriched with GreenwardStyle geometry
## and CharacterAnimator-driven timing. The exact replacement specification is
## inherited via super.specs()/REPLACEMENT_SPEC, so it is ALWAYS present.
func specs() -> Dictionary:
	var d := super.specs()
	d["temporary"] = true
	d["source"] = source_label()
	d["is_temporary"] = is_temporary()

	# Defensive read of the parallel agent's GreenwardStyle.SPRITE_SPECS.
	var g := _greenward()
	var world_w := int(g.get("world_width", 96))
	var world_h := int(g.get("world_height", 128))
	var boss_w := int(g.get("boss_width", 128))
	var boss_h := int(g.get("boss_height", 192))
	var anchor: Variant = g.get("anchor", Vector2(0.5, 1.0))
	var outline := int(g.get("outline_px", 1))
	var cur_w: int = boss_w if boss else world_w
	var cur_h: int = boss_h if boss else world_h
	d["canvas"] = {
		"world": {"width": world_w, "height": world_h},
		"boss": {"width": boss_w, "height": boss_h},
		"current": {"width": cur_w, "height": cur_h},
	}
	# The placeholder generator itself always returns a 96x128 texture.
	d["placeholder_canvas"] = {"width": 96, "height": 128}
	d["anchor"] = anchor
	d["outline_px"] = outline
	d["boss"] = boss

	# Timing mirrors CharacterAnimator constants (single source of truth), so
	# any frame index the animator produces is valid here for all 8 directions.
	var fps_map := {}
	var frames_map := {}
	var loop_map := {}
	for raw in CharacterAnimator.ALL_STATES:
		var s := int(raw)
		fps_map[s] = float(CharacterAnimator.STATE_FPS.get(s, 1.0))
		frames_map[s] = int(CharacterAnimator.STATE_FRAMES.get(s, 1))
		loop_map[s] = bool(CharacterAnimator.STATE_LOOPING.get(s, false))
	d["fps"] = fps_map
	d["frames"] = frames_map
	d["loop"] = loop_map
	d["states"] = CharacterAnimator.ALL_STATES.duplicate()
	d["directions"] = CharacterAnimator.ALL_DIRECTIONS.duplicate()

	# Mirror GreenwardStyle.SPRITE_SPECS verbatim so its geometry/import
	# metadata is available to docs/tools even if keys differ from our defaults.
	if not g.is_empty():
		d["greenward_style"] = g.duplicate(true)
	return d

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

## Defensive accessor for the parallel agent's GreenwardStyle global class.
## `GreenwardStyle` is registered on import; we reference it by name but read
## every key with a hard-coded default so a missing key/shape never crashes.
static func _greenward() -> Dictionary:
	var spec: Variant = GreenwardStyle.SPRITE_SPECS
	if spec is Dictionary:
		return spec as Dictionary
	return {}


static func _safe_state(s: int) -> int:
	if CharacterAnimator.is_valid_state(s):
		return s
	return 0  # IDLE


static func _safe_direction(d: int) -> int:
	if CharacterAnimator.is_valid_direction(d):
		return d
	return 0  # DOWN

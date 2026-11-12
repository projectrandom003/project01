class_name ActorFrameSource
extends RefCounted
## STABLE SPRITE / ANIMATION INTERFACE -- the seam that final art plugs into.
##
## ActorVisual (and any other renderer) talks to character art ONLY through
## this pure-data interface. It holds NO nodes, does NO file IO and owns NO
## SceneTree state, so it is safe to unit-test headlessly. The base class is a
## "virtual" contract: every method returns a SAFE DEFAULT meaning "no real
## frames are available, fall back to procedural placeholder art". A production
## source is a SINGLE subclass -- e.g. `SpriteFramesActorSource` -- that returns
## true from has_frames(), hands back Texture2D frames and overrides the timing
## helpers; NO gameplay or rendering code needs to change.
##
## ---- INTEGER CONTRACT (shared, must not drift) ----------------------------
## STATES (8): 0 IDLE, 1 WALK, 2 RUN, 3 INTERACT, 4 ATTACK, 5 DAMAGE,
##   6 VICTORY, 7 DEFEAT. "Directional movement" is NOT a ninth state; it is
##   the DIRECTION dimension below applied on top of a state.
## DIRECTIONS (8): 0 DOWN, 1 DOWN_RIGHT, 2 RIGHT, 3 UP_RIGHT, 4 UP,
##   5 UP_LEFT, 6 LEFT, 7 DOWN_LEFT.
## frame(state, direction, index) therefore addresses 8 x 8 x frame cells.
## The authoritative fps / frame counts / loop flags live in
## CharacterAnimator.STATE_FPS / STATE_FRAMES / STATE_LOOPING.
##
## ---- EXACT REPLACEMENT SPECIFICATION (final painted sprite sheets) --------
## The canonical machine-readable text is the REPLACEMENT_SPEC constant below
## (also returned by specs()); this docstring restates it for the docs.
##  * Canvas: 96 x 128 px per frame for world actors; 128 x 192 px for
##    elite/boss actors. Transparent RGBA8, sRGB, 1-2 px dark outline at 1x.
##  * Anchor: bottom-centre (0.5, 1.0); Y-sort at the ground point. EVERY
##    frame keeps the feet on the SAME foot baseline (no foot-sliding).
##  * Directions: 8 (left/right flip alone is enough for the slice). Each
##    state is authored for all 8 directions for production.
##  * Per-state frames / fps / loop:
##      IDLE     5 @  9 fps  loop       WALK     7 @ 12 fps  loop
##      RUN      7 @ 14 fps  loop       INTERACT 6 @ 12 fps  one-shot
##      ATTACK   6 @ 15 fps  one-shot   DAMAGE   2 @ 12 fps  one-shot
##      VICTORY  8 @ 12 fps  one-shot   DEFEAT   6 @ 10 fps  one-shot (death)
##  * Sheet layout: one row per direction (8 rows), one column per frame;
##    0-based frame index left-to-right. One sheet per (character, state) OR a
##    single <id>_world_sheet.png atlas sliced into SpriteFrames.
##  * Naming: lowercase snake_case, content-id folder, e.g.
##    assets/characters/mira_sol/world_sheet.png (ART_PIPELINE.md section 9/3);
##    a per-state variant <id>_<state>_<dir>.png is also acceptable.
##  * Import: Filter=Linear, Mipmaps=On, Compression=VRAM-compressed where
##    supported (lossless for UI), Fix Alpha Border=On for atlases.
##  * SpriteFrames registration: build one animation per "<state>_<direction>"
##    (e.g. "walk_2"), speed = STATE_FPS[state], loop = STATE_LOOPING[state].
##    Then subclass ActorFrameSource (SpriteFramesActorSource): has_frames()
##    -> true, frame(state,dir,index) -> Texture2D, frame_count/fps/is_looping
##    from the resource, is_temporary() -> false, source_label() ->
##    "spriteframes", specs() -> sane metadata. Register it on ActorVisual in
##    place of the ProceduralActorFrames placeholder.
##  * Fall-back rule: if has_frames() is false, frame() returns null, or a
##    (state, direction, index) is missing, KEEP the procedural placeholder so
##    content never crashes. is_temporary() stays true until a real source is
##    registered.

# ---------------------------------------------------------------------------
# Canonical replacement specification (quoted verbatim by the docs / specs())
# ---------------------------------------------------------------------------

const REPLACEMENT_SPEC: String = """FINAL ART REPLACEMENT SPECIFICATION (painted sprite sheets)
Canvas: 96 x 128 px per frame (world actors); 128 x 192 px (elite/boss). Transparent RGBA8, sRGB, 1-2 px dark outline at 1x.
Anchor: bottom-centre (0.5, 1.0); Y-sort by ground point; feet on an identical foot baseline across every frame (no foot-sliding).
States (8 ints): 0 IDLE, 1 WALK, 2 RUN, 3 INTERACT, 4 ATTACK, 5 DAMAGE, 6 VICTORY, 7 DEFEAT. 'Directional movement' is NOT a 9th state -- it is the DIRECTION dimension applied on top of a state.
Directions (8 ints): 0 DOWN, 1 DOWN_RIGHT, 2 RIGHT, 3 UP_RIGHT, 4 UP, 5 UP_LEFT, 6 LEFT, 7 DOWN_LEFT. Author every state for all 8 directions in production (left/right flip alone is enough for the slice).
Per-state frames / fps / loop (authoritative: CharacterAnimator.STATE_FRAMES / STATE_FPS / STATE_LOOPING):
  IDLE     5 @  9 fps  loop
  WALK     7 @ 12 fps  loop
  RUN      7 @ 14 fps  loop
  INTERACT 6 @ 12 fps  one-shot
  ATTACK   6 @ 15 fps  one-shot
  DAMAGE   2 @ 12 fps  one-shot
  VICTORY  8 @ 12 fps  one-shot
  DEFEAT   6 @ 10 fps  one-shot (non-looping death)
Sheet layout: one row per direction (8 rows), one column per frame; 0-based frame index left-to-right. One sheet per (character, state) or a single <id>_world_sheet.png atlas sliced into SpriteFrames.
Naming: lowercase snake_case, content-id folder, e.g. assets/characters/mira_sol/world_sheet.png (ART_PIPELINE.md section 9/3); per-state variant <id>_<state>_<dir>.png is also acceptable.
Import: Filter=Linear, Mipmaps=On, Compression=VRAM-compressed where supported (lossless for UI), Fix Alpha Border=On for atlases.
SpriteFrames registration: one animation per "<state>_<direction>" (e.g. "walk_2"), speed = STATE_FPS[state], loop = STATE_LOOPING[state]. Subclass ActorFrameSource (SpriteFramesActorSource): has_frames()->true, frame(state,dir,index)->Texture2D, frame_count/fps/is_looping from the resource, is_temporary()->false, source_label()->"spriteframes", specs()->sane metadata, then hand it to ActorVisual in place of the procedural placeholder. NO gameplay code changes.
Fall-back rule: if has_frames() is false, frame() returns null, or a (state, direction, index) is missing, keep the ProceduralActorFrames placeholder so content never crashes; is_temporary() stays true until a real source is registered."""

# ---------------------------------------------------------------------------
# Phase-4 extended metadata (CAST + the 9-state/9-name contract). Kept as a
# SEPARATE constant; specs() itself stays EXACTLY as the Phase-3 tests assert.
# ---------------------------------------------------------------------------

const EXTENDED_INFO := {
	"extended_states": [0, 1, 2, 3, 4, 5, 6, 7, 8],
	"extended_state_names": {
		0: "idle", 1: "walk", 2: "run", 3: "interact",
		4: "attack", 5: "damage", 6: "victory", 7: "defeat", 8: "cast",
	},
	"locomotion_states": [0, 1, 2],
	"cast": {
		"state": 8, "name": "cast", "frames": 7, "fps": 12.0,
		"loop": false, "priority": 5,
	},
}

# ---------------------------------------------------------------------------
# Base / virtual contract -- safe defaults ("use procedural fallback")
# ---------------------------------------------------------------------------

## FALSE by default == "no real frames; use the procedural fallback". A real
## sprite-sheet source must override this to return true.
func has_frames() -> bool:
	return false


## Return the Texture2D for (state, direction, index). NULL by default == no
## frame available; renderers must fall back to procedural art. A production
## source returns a non-null Texture2D for every valid address.
func frame(state: int, direction: int, index: int) -> Texture2D:
	# Reference the parameters defensively; the base never has frames.
	if state < 0 or direction < 0 or index < 0:
		return null
	return null


## Frame count for (state, direction). Direction is part of the address but
## counts are identical across all 8 directions by contract; always >= 1.
## Uses CharacterAnimator.frame_count_for() so the additive CAST state (8)
## reports 7 frames while states 0-7 are byte-for-byte unchanged.
func frame_count(state: int, direction: int) -> int:
	var _d := 0
	if CharacterAnimator.is_valid_direction(direction):
		_d = direction
	return maxi(1, CharacterAnimator.frame_count_for(state))


## Nominal fps for a state (guarded to >= 1.0). CAST (8) -> 12.0.
func fps(state: int) -> float:
	return maxf(1.0, CharacterAnimator.fps_for(state))


## Whether a state loops (IDLE / WALK / RUN loop; CAST does not).
func is_looping(state: int) -> bool:
	return CharacterAnimator.looping_for(state)


## TRUE by default == the renderer may mirror the sprite horizontally from the
## actor's `facing` sign. The procedural fallback draws ONE silhouette and relies
## on mirroring. A production 8-direction sheet already encodes left/right in its
## direction rows, so it overrides this to FALSE to avoid double-mirroring.
func mirrors_by_facing() -> bool:
	return true


## TRUE by default == placeholder art. A production SpriteFramesActorSource
## overrides this to return false.
func is_temporary() -> bool:
	return true


## Human-readable label describing where frames come from.
func source_label() -> String:
	return "procedural-placeholder"


## Machine-readable contract: canvas / anchor / fps / frames / format, plus
## "temporary", the exact "replacement" specification, and the "states" /
## "directions" lists. Override (usually via super.specs()) in a real source.
func specs() -> Dictionary:
	return {
		"temporary": true,
		"replacement": REPLACEMENT_SPEC,
		"source": source_label(),
		"states": _copy_list(CharacterAnimator.ALL_STATES),
		"directions": _copy_list(CharacterAnimator.ALL_DIRECTIONS),
		"states_count": 8,
		"directions_count": 8,
		"state_names": _copy_map(CharacterAnimator.STATE_NAMES),
		"direction_names": _copy_map(CharacterAnimator.DIRECTION_NAMES),
		"fps": _copy_map(CharacterAnimator.STATE_FPS),
		"frames": _copy_map(CharacterAnimator.STATE_FRAMES),
		"loop": _copy_map(CharacterAnimator.STATE_LOOPING),
		"canvas": {
			"world": {"width": 96, "height": 128},
			"boss": {"width": 128, "height": 192},
		},
		"anchor": Vector2(0.5, 1.0),
		"anchor_xy": [0.5, 1.0],
		"foot_baseline": "bottom-centre, identical on every frame",
		"format": "RGBA8 PNG / SpriteFrames, sRGB, transparent",
		"outline_px": 1,
		"filter": "Linear",
		"mipmaps": true,
		"compression": "VRAM compressed where supported; lossless for UI",
		"fix_alpha_border": true,
		"sheet_layout": "8 direction rows x <frames> columns; 0-based frame index",
		"sheet_naming": "<content_id>/world_sheet.png or <id>_<state>_<dir>.png; lowercase snake_case",
		"fall_back": "has_frames()==false, frame()==null or a missing (state,direction,index) keeps the ProceduralActorFrames placeholder.",
	}

# ---------------------------------------------------------------------------
# Phase-4 additive CAST / sheet API (all safe defaults; a real sheet source
# overrides them). NONE of this changes specs() above.
# ---------------------------------------------------------------------------

## Texture for the additive CAST state (8) at (direction, index). NULL by
## default == "no real cast frames; use the procedural fallback".
func cast_frame(direction: int, index: int) -> Texture2D:
	if direction < 0 or index < 0:
		return null
	return null


## CAST frame count for a direction (authoritative: 7 by default).
func cast_frame_count(direction: int) -> int:
	var _d := direction
	return CharacterAnimator.frame_count_for(CharacterAnimator.CAST_STATE)


## Nominal CAST fps (12.0 by default).
func cast_fps() -> float:
	return CharacterAnimator.fps_for(CharacterAnimator.CAST_STATE)


## Validate any registered sprite sheet. The virtual base has NO sheet, so it
## returns a clear informational error rather than crashing.
func validate_sheets() -> Array[String]:
	var errors: Array[String] = []
	errors.append("no sprite sheet registered (base ActorFrameSource / procedural fallback)")
	return errors


## Machine-readable EXTENDED contract: the full specs() plus the 9-state /
## 9-name lists, the CAST spec and the locomotion states.
func extended_specs() -> Dictionary:
	var d := specs()
	d["extended_states"] = (EXTENDED_INFO["extended_states"] as Array).duplicate()
	d["extended_state_names"] = _copy_map(EXTENDED_INFO["extended_state_names"] as Dictionary)
	d["locomotion_states"] = (EXTENDED_INFO["locomotion_states"] as Array).duplicate()
	d["cast"] = (EXTENDED_INFO["cast"] as Dictionary).duplicate(true)
	return d

# ---------------------------------------------------------------------------
# Internal helpers (fresh copies of read-only CharacterAnimator const maps)
# ---------------------------------------------------------------------------

static func _copy_map(src: Dictionary) -> Dictionary:
	var out := {}
	for k in src.keys():
		out[k] = src[k]
	return out


static func _copy_list(src: Array) -> Array:
	var out := []
	for raw in src:
		out.append(raw)
	return out

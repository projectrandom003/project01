class_name CharacterArtPipeline
extends RefCounted
## CHARACTER ART PIPELINE — Part 1 of PROJECT FANTASY Phase 5 (FOUNDATION).
##
## ZERO final assets exist. Every shipped visual is RUNTIME PROCEDURAL PLACEHOLDER
## art; this file is a pure CONTRACT/SPECIFICATION, not artwork. It defines the
## exact production specs for the ten character-art asset kinds that a FUTURE
## external generation/illustration round will drop into the project. It NEVER
## creates, loads-as-final, or fabricates any image/binary file.
##
## PURE / headless: plain data + (optional, defensive) FileAccess /
## ResourceLoader existence checks only. NO nodes, NO SceneTree state, NO
## autoloads, NO generated textures. Deterministic and defensive: an unknown
## kind returns a clear error/empty dict and NEVER crashes.
##
## Authoritative values are taken from CharacterAnimator (STATE_FRAMES / FPS /
## LOOPING + CAST_*), GreenwardStyle.SPRITE_SPECS, AssetManifest and
## documentation/ART_PIPELINE.md §3/§9/§10/§14. See also
## assets/CHARACTER_ART_PIPELINE.md and assets/GENERATION_PROMPTS.md.

# ------------------------------------------------------------------ constants
# The TEN production asset kinds (stable id list).
const ASSET_KINDS: Array[String] = [
	"full_body_illustration",
	"character_portrait",
	"combat_sprite",
	"movement_sheet",
	"attack_sheet",
	"cast_sheet",
	"skill_vfx",
	"ultimate_vfx",
	"victory_sheet",
	"defeat_sheet",
]

# Canonical dimensions / anchors (px). World actor frame 96x128; boss/elite
# 128x192; bottom-centre anchor, feet on ONE baseline. Portrait master
# 1024x1280 -> export 256x384 top-centre bust crop. Full-body master 1024x2048.
# Combat sprite 128x192. Skill/ultimate VFX 192x192, 6 frames, centre anchor.
const FRAME_W := 96
const FRAME_H := 128
const BOSS_W := 128
const BOSS_H := 192
const COMBAT_W := 128
const COMBAT_H := 192
const PORTRAIT_MASTER_W := 1024
const PORTRAIT_MASTER_H := 1280
const PORTRAIT_EXPORT_W := 256
const PORTRAIT_EXPORT_H := 384
const FULLBODY_MASTER_W := 1024
const FULLBODY_MASTER_H := 2048
const VFX_W := 192
const VFX_H := 192
const VFX_FRAMES := 6
const DIRECTION_COUNT := 8
const SHEET_HEIGHT := 1024  # 8 direction rows * 128 px
const FORMAT := "RGBA8 PNG / WebP, sRGB, transparent (alpha cutout, never opaque)"
const RGBA8_NOTE := "transparent RGBA8 background; alpha cutouts, NOT opaque; 0-based frame index"

# Per-state authoritative timing from CharacterAnimator (IDLE..DEFEAT) plus the
# additive CAST state. frames / fps / loop are the single source of truth shared
# with the sprite sheets that get sliced into a SpriteFrames .tres.
const STATE_SPECS: Dictionary = {
	"idle":     {"frames": 5, "fps": 9.0,  "loop": true},
	"walk":     {"frames": 7, "fps": 12.0, "loop": true},
	"run":      {"frames": 7, "fps": 14.0, "loop": true},
	"interact": {"frames": 6, "fps": 12.0, "loop": false},
	"attack":   {"frames": 6, "fps": 15.0, "loop": false},
	"damage":   {"frames": 2, "fps": 12.0, "loop": false},
	"victory":  {"frames": 8, "fps": 12.0, "loop": false},
	"defeat":   {"frames": 6, "fps": 10.0, "loop": false},
	"cast":     {"frames": 7, "fps": 12.0, "loop": false},
}

# 9 animatable states (8 core + additive CAST) in stable order.
const STATES: Array[String] = [
	"idle", "walk", "run", "interact", "attack", "damage", "victory", "defeat", "cast",
]
# 8 directions, 0-based row order (row 0 = DOWN ... row 7 = DOWN_LEFT).
const DIRECTION_NAMES: Array[String] = [
	"down", "down_right", "right", "up_right", "up", "up_left", "left", "down_left",
]

# Which states each SHEET kind owns (all 9 states covered exactly once across
# movement/attack/cast/victory/defeat sheets).
const SHEET_STATES: Dictionary = {
	"movement_sheet": ["idle", "walk", "run"],
	"attack_sheet":   ["attack", "interact", "damage"],
	"cast_sheet":     ["cast"],
	"victory_sheet":  ["victory"],
	"defeat_sheet":   ["defeat"],
}

# Per-state sheet = <frames>*96 wide x 8*128 tall (1024). Column counts below
# are literally STATE_SPECS[state].frames.
const _IMPORT_WORLD := {
	"filter": "Linear", "mipmaps": true,
	"compression": "VRAM compressed where supported; lossless for UI",
	"fix_alpha_border": true,
}
const _IMPORT_UI := {
	"filter": "Linear", "mipmaps": false,
	"compression": "Lossless (UI)", "fix_alpha_border": false,
}
const _IMPORT_VFX := {
	"filter": "Linear", "mipmaps": false,
	"compression": "Lossless", "fix_alpha_border": true,
}

# One exact production spec per kind. Every kind records: dimensions, anchor,
# transparent-RGBA8 requirement, frame count, sheet layout (where applicable),
# import settings, naming convention, replacement seam and a short description.
# NOTE: `frames` for a SHEET kind is the number of <state>_<dir> animation clips
# (states x 8) in the sliced SpriteFrames; per-state column counts live in
# `frame_counts`. `sheet_width`/`sheet_height` describe the widest per-state PNG
# atlas for that kind (height is always 8*128 = 1024).
const KIND_SPECS: Dictionary = {
	"full_body_illustration": {
		"kind": "full_body_illustration",
		"description": "Full-height key illustration of the character (head to toe), used for splash / collection / summon reveal. Single static frame.",
		"width": 1024, "height": 2048,
		"master_width": 1024, "master_height": 2048,
		"anchor": "bottom-centre (0.5, 1.0), feet on ONE baseline, ~6-head heroic proportions",
		"anchor_vector": Vector2(0.5, 1.0),
		"transparent": true, "format": FORMAT, "background": RGBA8_NOTE,
		"frames": 1, "frame_counts": {"full_body": 1},
		"sheet": false, "states": [],
		"sheet_layout": "single static frame; no atlas",
		"sheet_width": 0, "sheet_height": 0,
		"import": _IMPORT_UI,
		"naming": "lower_snake_case content-id folder; <id>/full_body_illustration.png",
		"seam": "scripts/ui/main_backdrop.gd key-art layer + collection/summon screen big art (scripts/ui/screens/collection_screen.gd, gacha_screen.gd)",
		"extension": "png",
	},
	"character_portrait": {
		"kind": "character_portrait",
		"description": "Head-and-shoulders bust portrait. Master 1024x1280 cropped/exported to 256x384, top-centre bust crop, eyes in upper third. Single static frame.",
		"width": 256, "height": 384,
		"master_width": 1024, "master_height": 1280,
		"anchor": "top-centre (0.5, 0.0) bust crop from the top; eyes in the upper third",
		"anchor_vector": Vector2(0.5, 0.0),
		"transparent": true, "format": FORMAT, "background": RGBA8_NOTE,
		"frames": 1, "frame_counts": {"portrait": 1},
		"sheet": false, "states": [],
		"sheet_layout": "single static frame; no atlas",
		"sheet_width": 0, "sheet_height": 0,
		"import": _IMPORT_UI,
		"naming": "lower_snake_case content-id folder; <id>/portrait.png (per assets/README.md also <id>/battle_bust.png, <id>/portrait_512.png)",
		"seam": "scripts/ui/portrait_view.gd (PortraitView.setup_character / _draw) -> PortraitAssetSource.texture_for(<id>) with procedural fallback",
		"extension": "png",
	},
	"combat_sprite": {
		"kind": "combat_sprite",
		"description": "Single full combat pose used on battle unit cards / combat screen. 128x192 (elite/boss canvas), bottom-centre. Single static frame.",
		"width": 128, "height": 192,
		"master_width": 128, "master_height": 192,
		"anchor": "bottom-centre (0.5, 1.0), feet on ONE baseline",
		"anchor_vector": Vector2(0.5, 1.0),
		"transparent": true, "format": FORMAT, "background": RGBA8_NOTE,
		"frames": 1, "frame_counts": {"combat": 1},
		"sheet": false, "states": [],
		"sheet_layout": "single static frame; no atlas",
		"sheet_width": 0, "sheet_height": 0,
		"import": _IMPORT_WORLD,
		"naming": "lower_snake_case content-id folder; <id>/combat_sprite.png",
		"seam": "scripts/ui/combat/unit_card.gd + scripts/ui/screens/combat_screen.gd battle unit art",
		"extension": "png",
	},
	"movement_sheet": {
		"kind": "movement_sheet",
		"description": "8-direction locomotion: IDLE / WALK / RUN, each authored for all 8 directions. Looping states.",
		"width": 96, "height": 128,
		"master_width": 0, "master_height": 0,
		"anchor": "bottom-centre (0.5, 1.0), feet on ONE identical baseline across every frame/state/direction",
		"anchor_vector": Vector2(0.5, 1.0),
		"transparent": true, "format": FORMAT, "background": RGBA8_NOTE,
		"frames": 24, "frame_counts": {"idle": 5, "walk": 7, "run": 7},
		"sheet": true, "states": ["idle", "walk", "run"],
		"sheet_layout": "per-state atlas = <frames>*96 wide x 8*128 tall; 8 direction rows (DOWN..DOWN_LEFT) x <frames> frame columns, 0-based columns; idle 480x1024, walk 672x1024, run 672x1024",
		"sheet_width": 672, "sheet_height": 1024,
		"import": _IMPORT_WORLD,
		"naming": "lower_snake_case content-id folder; <id>/movement_sheet.png sliced to <id>/movement_sheet.tres; animations idle_<dir>, walk_<dir>, run_<dir>",
		"seam": "ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>)) -> scripts/world/actor_frame_source.gd + scripts/art/sprite_frames_actor_source.gd",
		"extension": "tres",
	},
	"attack_sheet": {
		"kind": "attack_sheet",
		"description": "Combat/action one-shots: ATTACK / INTERACT / DAMAGE, all 8 directions. One-shot states.",
		"width": 96, "height": 128,
		"master_width": 0, "master_height": 0,
		"anchor": "bottom-centre (0.5, 1.0), feet on ONE identical baseline",
		"anchor_vector": Vector2(0.5, 1.0),
		"transparent": true, "format": FORMAT, "background": RGBA8_NOTE,
		"frames": 24, "frame_counts": {"attack": 6, "interact": 6, "damage": 2},
		"sheet": true, "states": ["attack", "interact", "damage"],
		"sheet_layout": "per-state atlas = <frames>*96 wide x 8*128 tall; attack 576x1024, interact 576x1024, damage 192x1024",
		"sheet_width": 576, "sheet_height": 1024,
		"import": _IMPORT_WORLD,
		"naming": "lower_snake_case content-id folder; <id>/attack_sheet.png sliced to <id>/attack_sheet.tres; animations attack_<dir>, interact_<dir>, damage_<dir>",
		"seam": "ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>)) -> scripts/world/actor_frame_source.gd + scripts/art/sprite_frames_actor_source.gd",
		"extension": "tres",
	},
	"cast_sheet": {
		"kind": "cast_sheet",
		"description": "Additive 9th-state CAST one-shot (7 frames @ 12 fps), all 8 directions.",
		"width": 96, "height": 128,
		"master_width": 0, "master_height": 0,
		"anchor": "bottom-centre (0.5, 1.0), feet on ONE identical baseline",
		"anchor_vector": Vector2(0.5, 1.0),
		"transparent": true, "format": FORMAT, "background": RGBA8_NOTE,
		"frames": 8, "frame_counts": {"cast": 7},
		"sheet": true, "states": ["cast"],
		"sheet_layout": "single atlas 7*96 = 672 wide x 8*128 = 1024 tall; 8 direction rows x 7 columns, 0-based",
		"sheet_width": 672, "sheet_height": 1024,
		"import": _IMPORT_WORLD,
		"naming": "lower_snake_case content-id folder; <id>/cast_sheet.png sliced to <id>/cast_sheet.tres; animations cast_<dir>",
		"seam": "ActorVisual.play_cast() / SpriteFramesActorSource.cast_frame() via ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>))",
		"extension": "tres",
	},
	"skill_vfx": {
		"kind": "skill_vfx",
		"description": "Skill effects flipbook (per skill id), 192x192 frames, 6 frames, additive glow, centre anchor.",
		"width": 192, "height": 192,
		"master_width": 192, "master_height": 192,
		"anchor": "centre (0.5, 0.5)",
		"anchor_vector": Vector2(0.5, 0.5),
		"transparent": true, "format": FORMAT, "background": "transparent RGBA8 (additive); alpha cutouts, never opaque",
		"frames": 6, "frame_counts": {"skill": 6},
		"sheet": false, "states": [],
		"sheet_layout": "1 row x 6 frame columns, 0-based; atlas 1152x192",
		"sheet_width": 1152, "sheet_height": 192,
		"import": _IMPORT_VFX,
		"naming": "lower_snake_case skill-id folder; assets/vfx/<skill_id>/effect.png (6 frames)",
		"seam": "scripts/combat/combat_engine.gd VFX hooks / scripts/world/procedural_art.gd soft_glow()",
		"extension": "png",
	},
	"ultimate_vfx": {
		"kind": "ultimate_vfx",
		"description": "Ultimate effects flipbook (per ultimate id), 192x192 frames, 6 frames, additive glow, centre anchor.",
		"width": 192, "height": 192,
		"master_width": 192, "master_height": 192,
		"anchor": "centre (0.5, 0.5)",
		"anchor_vector": Vector2(0.5, 0.5),
		"transparent": true, "format": FORMAT, "background": "transparent RGBA8 (additive); alpha cutouts, never opaque",
		"frames": 6, "frame_counts": {"ultimate": 6},
		"sheet": false, "states": [],
		"sheet_layout": "1 row x 6 frame columns, 0-based; atlas 1152x192",
		"sheet_width": 1152, "sheet_height": 192,
		"import": _IMPORT_VFX,
		"naming": "lower_snake_case ultimate-id folder; assets/vfx/<ultimate_id>/effect.png (6 frames)",
		"seam": "scripts/combat/combat_engine.gd VFX hooks / scripts/world/procedural_art.gd soft_glow()",
		"extension": "png",
	},
	"victory_sheet": {
		"kind": "victory_sheet",
		"description": "VICTORY one-shot (8 frames @ 12 fps), all 8 directions.",
		"width": 96, "height": 128,
		"master_width": 0, "master_height": 0,
		"anchor": "bottom-centre (0.5, 1.0), feet on ONE identical baseline",
		"anchor_vector": Vector2(0.5, 1.0),
		"transparent": true, "format": FORMAT, "background": RGBA8_NOTE,
		"frames": 8, "frame_counts": {"victory": 8},
		"sheet": true, "states": ["victory"],
		"sheet_layout": "single atlas 8*96 = 768 wide x 8*128 = 1024 tall; 8 direction rows x 8 columns, 0-based",
		"sheet_width": 768, "sheet_height": 1024,
		"import": _IMPORT_WORLD,
		"naming": "lower_snake_case content-id folder; <id>/victory_sheet.png sliced to <id>/victory_sheet.tres; animations victory_<dir>",
		"seam": "ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>)) -> scripts/world/actor_frame_source.gd + scripts/art/sprite_frames_actor_source.gd",
		"extension": "tres",
	},
	"defeat_sheet": {
		"kind": "defeat_sheet",
		"description": "DEFEAT one-shot (6 frames @ 10 fps), all 8 directions; holds the last frame.",
		"width": 96, "height": 128,
		"master_width": 0, "master_height": 0,
		"anchor": "bottom-centre (0.5, 1.0), feet on ONE identical baseline",
		"anchor_vector": Vector2(0.5, 1.0),
		"transparent": true, "format": FORMAT, "background": RGBA8_NOTE,
		"frames": 8, "frame_counts": {"defeat": 6},
		"sheet": true, "states": ["defeat"],
		"sheet_layout": "single atlas 6*96 = 576 wide x 8*128 = 1024 tall; 8 direction rows x 6 columns, 0-based",
		"sheet_width": 576, "sheet_height": 1024,
		"import": _IMPORT_WORLD,
		"naming": "lower_snake_case content-id folder; <id>/defeat_sheet.png sliced to <id>/defeat_sheet.tres; animations defeat_<dir>",
		"seam": "ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>)) -> scripts/world/actor_frame_source.gd + scripts/art/sprite_frames_actor_source.gd",
		"extension": "tres",
	},
}

# ------------------------------------------------------------------ public API

## Fresh typed copy of the ten stable kind ids.
static func kinds() -> Array[String]:
	var out: Array[String] = []
	for k in ASSET_KINDS:
		out.append(k)
	return out


## Deep copy of one kind spec, or {} for an unknown kind (never throws).
static func spec(kind: String) -> Dictionary:
	if KIND_SPECS.has(kind):
		return (KIND_SPECS[kind] as Dictionary).duplicate(true)
	return {}


## Godot import settings dict for a kind, or {} for an unknown kind.
static func import_settings(kind: String) -> Dictionary:
	var s := spec(kind)
	if s.is_empty():
		return {}
	return (s["import"] as Dictionary).duplicate(true)


## Full sheet layout: 9 states x 8 directions x frame counts, plus per-state
## atlas sizes and the <state>_<dir> animation names. `grid` is the literal
## 9x8 frame-count grid (state -> array of 8 equal column counts).
static func sheet_layout() -> Dictionary:
	var states: Dictionary = {}
	var grid: Dictionary = {}
	for st in STATES:
		var spec_state: Dictionary = STATE_SPECS[st]
		var frames := int(spec_state["frames"])
		var per_dir: Array[int] = []
		var anims: Array[String] = []
		for d in DIRECTION_COUNT:
			per_dir.append(frames)
			anims.append("%s_%d" % [st, d])
		grid[st] = per_dir
		states[st] = {
			"frames": frames,
			"fps": float(spec_state["fps"]),
			"loop": bool(spec_state["loop"]),
			"columns": frames,
			"rows": DIRECTION_COUNT,
			"sheet_width": frames * FRAME_W,
			"sheet_height": DIRECTION_COUNT * FRAME_H,
			"direction_frame_counts": per_dir.duplicate(),
			"animations": anims,
		}
	return {
		"frame_width": FRAME_W,
		"frame_height": FRAME_H,
		"direction_count": DIRECTION_COUNT,
		"direction_names": DIRECTION_NAMES.duplicate(),
		"state_count": STATES.size(),
		"states": STATES.duplicate(),
		"per_state": states,
		"grid": grid,
		"sheets": {
			"movement_sheet": {"states": ["idle", "walk", "run"], "atlas_widths": {"idle": 480, "walk": 672, "run": 672}, "atlas_height": SHEET_HEIGHT},
			"attack_sheet":   {"states": ["attack", "interact", "damage"], "atlas_widths": {"attack": 576, "interact": 576, "damage": 192}, "atlas_height": SHEET_HEIGHT},
			"cast_sheet":     {"states": ["cast"], "atlas_widths": {"cast": 672}, "atlas_height": SHEET_HEIGHT},
			"victory_sheet":  {"states": ["victory"], "atlas_widths": {"victory": 768}, "atlas_height": SHEET_HEIGHT},
			"defeat_sheet":   {"states": ["defeat"], "atlas_widths": {"defeat": 576}, "atlas_height": SHEET_HEIGHT},
		},
		"slice_target": "SpriteFrames .tres; one animation per <state_name>_<dir> (cast_<dir> included), speed = fps, loop = loop flag",
	}


## All <state>_<dir> animation names (9 states x 8 directions = 72).
static func animation_names() -> Array[String]:
	var out: Array[String] = []
	for st in STATES:
		for d in DIRECTION_COUNT:
			out.append("%s_%d" % [st, d])
	return out


## Validate a proposed asset candidate. Returns [] when dims / anchor /
## transparency / frames / format / naming are all valid; precise, human-
## readable errors otherwise. NEVER throws; unknown kind -> clear error.
##
## Candidate schema (all keys expected for a valid result):
##   { "width": int, "height": int, "anchor": String (or Vector2),
##     "transparent": bool, "frames": int, "format": String,
##     "naming": String (a lower_snake_case file name/path) }
static func validate_asset(kind: String, candidate: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var s := spec(kind)
	if s.is_empty():
		errors.append("unknown asset kind '%s' (expected one of %s)" % [kind, str(ASSET_KINDS)])
		return errors
	if int(candidate.get("width", -1)) != int(s["width"]):
		errors.append("kind '%s': width %s, expected %d px" % [kind, str(candidate.get("width", "missing")), int(s["width"])])
	if int(candidate.get("height", -1)) != int(s["height"]):
		errors.append("kind '%s': height %s, expected %d px" % [kind, str(candidate.get("height", "missing")), int(s["height"])])
	# anchor: accept the exact spec string OR a matching Vector2.
	var anchor_val: Variant = candidate.get("anchor", "")
	var anchor_ok := false
	if typeof(anchor_val) == TYPE_VECTOR2:
		anchor_ok = (anchor_val as Vector2).is_equal_approx(s["anchor_vector"] as Vector2)
	elif typeof(anchor_val) == TYPE_STRING:
		anchor_ok = (str(anchor_val).strip_edges().to_lower() == str(s["anchor"]).strip_edges().to_lower())
	if not anchor_ok:
		errors.append("kind '%s': anchor '%s' does not match spec anchor '%s'" % [kind, str(anchor_val), str(s["anchor"])])
	if not bool(candidate.get("transparent", false)):
		errors.append("kind '%s': background must be transparent RGBA8 (transparent=true)" % kind)
	var frames_val: Variant = candidate.get("frames", -1)
	var frames_ok := (typeof(frames_val) == TYPE_INT or typeof(frames_val) == TYPE_FLOAT) and int(frames_val) == int(s["frames"])
	if not frames_ok:
		errors.append("kind '%s': frame/animation count %s, expected %d" % [kind, str(frames_val), int(s["frames"])])
	# format: transparent RGBA8 PNG/WebP, never opaque jpg/bmp.
	var fmt := str(candidate.get("format", "")).strip_edges().to_lower()
	var fmt_ok := ("png" in fmt) or ("webp" in fmt)
	if ("jpg" in fmt) or ("jpeg" in fmt) or ("bmp" in fmt):
		fmt_ok = false
	if not (("rgba8" in fmt) or ("rgba" in fmt) or ("alpha" in fmt) or ("transparent" in fmt)):
		fmt_ok = false
	if not fmt_ok:
		errors.append("kind '%s': invalid format '%s' (expected transparent RGBA8 PNG/WebP)" % [kind, fmt])
	# naming: lower_snake_case basename with the expected extension.
	var naming := str(candidate.get("naming", ""))
	if not _valid_naming(naming, str(s["extension"])):
		errors.append("kind '%s': invalid naming '%s' (expected lower_snake_case <id>/<name>.%s)" % [kind, naming, str(s["extension"])])
	return errors


## Example filename per kind (illustrative, not created on disk).
static func naming_examples() -> Dictionary:
	return {
		"full_body_illustration": "lyra_vey/full_body_illustration.png",
		"character_portrait":     "lyra_vey/portrait.png",
		"combat_sprite":          "lyra_vey/combat_sprite.png",
		"movement_sheet":         "lyra_vey/movement_sheet.tres",
		"attack_sheet":           "lyra_vey/attack_sheet.tres",
		"cast_sheet":             "lyra_vey/cast_sheet.tres",
		"skill_vfx":              "vfx/gale_shot/effect.png",
		"ultimate_vfx":           "vfx/tempest_dance/effect.png",
		"victory_sheet":          "lyra_vey/victory_sheet.tres",
		"defeat_sheet":           "lyra_vey/defeat_sheet.tres",
	}


## Compact machine-readable summary of the whole pipeline contract.
static func summary() -> Dictionary:
	return {
		"kind_count": ASSET_KINDS.size(),
		"kinds": kinds(),
		"frame": {"width": FRAME_W, "height": FRAME_H},
		"boss_frame": {"width": BOSS_W, "height": BOSS_H},
		"world_anchor": Vector2(0.5, 1.0),
		"portrait_master": {"width": PORTRAIT_MASTER_W, "height": PORTRAIT_MASTER_H},
		"portrait_export": {"width": PORTRAIT_EXPORT_W, "height": PORTRAIT_EXPORT_H},
		"full_body_master": {"width": FULLBODY_MASTER_W, "height": FULLBODY_MASTER_H},
		"combat_sprite": {"width": COMBAT_W, "height": COMBAT_H},
		"vfx": {"width": VFX_W, "height": VFX_H, "frames": VFX_FRAMES, "anchor": Vector2(0.5, 0.5)},
		"state_count": STATES.size(),
		"direction_count": DIRECTION_COUNT,
		"animation_count": animation_names().size(),
		"state_specs": STATE_SPECS.duplicate(true),
		"final_assets_exist": 0,
		"note": "CONTRACT / SPECIFICATION only. ZERO final assets; all shipped visuals are runtime procedural placeholder art.",
	}


## {kind: exact replacement seam string}.
static func replacement_seams() -> Dictionary:
	var out: Dictionary = {}
	for k in ASSET_KINDS:
		out[k] = str((KIND_SPECS[k] as Dictionary)["seam"])
	return out


## A fully valid candidate for a kind (useful for self-tests / future tools).
## Returns {} for an unknown kind.
static func example_candidate(kind: String) -> Dictionary:
	var s := spec(kind)
	if s.is_empty():
		return {}
	return {
		"width": int(s["width"]),
		"height": int(s["height"]),
		"anchor": str(s["anchor"]),
		"transparent": true,
		"frames": int(s["frames"]),
		"format": str(s["format"]),
		"naming": str(naming_examples().get(kind, "<id>/%s.%s" % [kind, str(s["extension"])])),
	}


## Internal consistency self-check ([] when the const tables are coherent).
static func self_check() -> Array[String]:
	var problems: Array[String] = []
	if ASSET_KINDS.size() != 10:
		problems.append("ASSET_KINDS must hold 10 kinds, has %d" % ASSET_KINDS.size())
	for k in ASSET_KINDS:
		if not KIND_SPECS.has(k):
			problems.append("KIND_SPECS missing kind '%s'" % k)
		elif validate_asset(k, example_candidate(k)).size() > 0:
			problems.append("example_candidate('%s') fails validation: %s" % [k, str(validate_asset(k, example_candidate(k)))])
	if animation_names().size() != STATES.size() * DIRECTION_COUNT:
		problems.append("animation_names() must be 9x8 = 72")
	var covered: Dictionary = {}
	for key in SHEET_STATES.keys():
		for st in (SHEET_STATES[key] as Array):
			covered[st] = true
	for st in STATES:
		if not covered.has(st):
			problems.append("state '%s' is not covered by any sheet kind" % st)
	return problems


# ------------------------------------------------------------------ internals

## lower_snake_case basename (allow an optional content-id folder prefix) with
## the expected extension. Pure string checks; never throws.
static func _valid_naming(naming: String, expected_ext: String) -> bool:
	if naming.strip_edges().is_empty():
		return false
	var base := naming.get_file()
	if base.is_empty():
		return false
	var ext := base.get_extension().to_lower()
	if ext != expected_ext:
		return false
	var stem := base.substr(0, base.length() - ext.length() - 1)
	if stem.is_empty():
		return false
	var re := RegEx.new()
	re.compile("^[a-z0-9_]+$")
	return re.search(stem) != null

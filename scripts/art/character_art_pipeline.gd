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

# ------------------------------------------------------------------ catalog facade
# The static contract lives in CharacterArtPipelineCatalog; this class owns
# lookup, validation, naming and replacement-seam behavior.
const ASSET_KINDS = CharacterArtPipelineCatalog.ASSET_KINDS
const FRAME_W = CharacterArtPipelineCatalog.FRAME_W
const FRAME_H = CharacterArtPipelineCatalog.FRAME_H
const BOSS_W = CharacterArtPipelineCatalog.BOSS_W
const BOSS_H = CharacterArtPipelineCatalog.BOSS_H
const COMBAT_W = CharacterArtPipelineCatalog.COMBAT_W
const COMBAT_H = CharacterArtPipelineCatalog.COMBAT_H
const PORTRAIT_MASTER_W = CharacterArtPipelineCatalog.PORTRAIT_MASTER_W
const PORTRAIT_MASTER_H = CharacterArtPipelineCatalog.PORTRAIT_MASTER_H
const PORTRAIT_EXPORT_W = CharacterArtPipelineCatalog.PORTRAIT_EXPORT_W
const PORTRAIT_EXPORT_H = CharacterArtPipelineCatalog.PORTRAIT_EXPORT_H
const FULLBODY_MASTER_W = CharacterArtPipelineCatalog.FULLBODY_MASTER_W
const FULLBODY_MASTER_H = CharacterArtPipelineCatalog.FULLBODY_MASTER_H
const VFX_W = CharacterArtPipelineCatalog.VFX_W
const VFX_H = CharacterArtPipelineCatalog.VFX_H
const VFX_FRAMES = CharacterArtPipelineCatalog.VFX_FRAMES
const DIRECTION_COUNT = CharacterArtPipelineCatalog.DIRECTION_COUNT
const SHEET_HEIGHT = CharacterArtPipelineCatalog.SHEET_HEIGHT
const FORMAT = CharacterArtPipelineCatalog.FORMAT
const RGBA8_NOTE = CharacterArtPipelineCatalog.RGBA8_NOTE
const STATE_SPECS = CharacterArtPipelineCatalog.STATE_SPECS
const STATES = CharacterArtPipelineCatalog.STATES
const DIRECTION_NAMES = CharacterArtPipelineCatalog.DIRECTION_NAMES
const SHEET_STATES = CharacterArtPipelineCatalog.SHEET_STATES
const _IMPORT_WORLD = CharacterArtPipelineCatalog._IMPORT_WORLD
const _IMPORT_UI = CharacterArtPipelineCatalog._IMPORT_UI
const _IMPORT_VFX = CharacterArtPipelineCatalog._IMPORT_VFX
const KIND_SPECS = CharacterArtPipelineCatalog.KIND_SPECS
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
			"movement_sheet": {"states": ["idle", "walk", "run"], "atlas_widths": {"idle": 480, "walk": 1536, "run": 1536}, "atlas_height": SHEET_HEIGHT},
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

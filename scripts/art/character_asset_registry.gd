class_name CharacterAssetRegistry
extends RefCounted
## CHARACTER ASSET REGISTRY — Part 6 of PROJECT FANTASY Phase 5 (FOUNDATION).
##
## ZERO final assets exist. Every shipped visual is RUNTIME PROCEDURAL PLACEHOLDER
## art; this file is the disk-COMPUTED production registry / CONTRACT, not art.
## Status is NEVER hardcoded: FINAL requires a real finished file on disk AND a
## clean validate_finished_asset(); otherwise the final file is MISSING, while a
## procedural fallback (TEMPORARY) is reported separately/orthogonally. Because
## no real images exist, counts.final == 0 for a fixed disk state.
##
## CRITICAL: this phase does NOT create ANY of the expected files (in particular
## res://assets/characters/player/world_sheet.png and
## res://assets/portraits/player/portrait.png), so AssetManifest.check_disk()
## stays false for all 8 classes. This registry only points at FUTURE paths.
##
## PURE / headless: plain data + defensive FileAccess / ResourceLoader /
## ResourceLoader-based texture checks. NO nodes, NO SceneTree, NO autoloads, NO
## generated textures, no default FINAL. report() is deterministic for a fixed
## disk state (no wall-clock timestamp).

# ------------------------------------------------------------------ status values
const STATUS_FINAL := "final"
const STATUS_TEMPORARY := "temporary"
const STATUS_MISSING := "missing"

# The 10 production asset kinds (explicit copy of CharacterArtPipeline.ASSET_KINDS).
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

# Sheet kinds are consumed as sliced SpriteFrames .tres; all others as .png.
const SHEET_KINDS: Array[String] = [
	"movement_sheet", "attack_sheet", "cast_sheet", "victory_sheet", "defeat_sheet",
]

# The 12 first characters (explicit copy of CharacterArtSpec.CHARACTER_IDS).
const CHARACTER_IDS: Array[String] = [
	"lyra_vey", "bramble", "seraphine", "nyx", "coralyn", "ignis",
	"mira_sol", "thistle", "vespera", "arachnia", "terra", "kael",
]

# Exact expected FINAL file dimensions per .png kind (sheet .tres have no single
# image; their FRAME textures are validated at 96x128 instead).
const FILE_DIMS: Dictionary = {
	"full_body_illustration": [1024, 2048],
	"character_portrait":     [256, 384],
	"combat_sprite":          [128, 192],
	"skill_vfx":              [1152, 192],
	"ultimate_vfx":           [1152, 192],
}

const FRAME_W := 96
const FRAME_H := 128

# Which <state>_<dir> animations each sheet .tres must expose.
const SHEET_ANIMS: Dictionary = {
	"movement_sheet": ["idle", "walk", "run"],
	"attack_sheet":   ["attack", "interact", "damage"],
	"cast_sheet":     ["cast"],
	"victory_sheet":  ["victory"],
	"defeat_sheet":   ["defeat"],
}

# ------------------------------------------------------------------ public API

## Fresh typed copy of the 12 character ids.
static func character_ids() -> Array[String]:
	var out: Array[String] = []
	for cid in CHARACTER_IDS:
		out.append(cid)
	return out


## Fresh typed copy of the 10 asset kinds.
static func kinds() -> Array[String]:
	var out: Array[String] = []
	for k in ASSET_KINDS:
		out.append(k)
	return out


## res://assets/characters/<id>/<kind>.png, or <kind>.tres for sheet kinds.
## Defensive: unknown ids/kinds still produce a (non-existent) path string.
static func expected_path(char_id: String, kind: String) -> String:
	var ext := "tres" if SHEET_KINDS.has(kind) else "png"
	return "res://assets/characters/%s/%s.%s" % [char_id, kind, ext]


## 12 * 10 = 120 entries, each:
## { id, character_id, kind, path, status, final_on_disk, fallback,
##   validation_errors }. status is computed from disk + validation.
static func entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for cid in CHARACTER_IDS:
		for kind in ASSET_KINDS:
			var path := expected_path(cid, kind)
			var on_disk := _path_exists(path)
			var verrors := validate_finished_asset(cid, kind)
			var status := STATUS_MISSING
			if on_disk and verrors.is_empty():
				status = STATUS_FINAL
			elif on_disk:
				status = STATUS_TEMPORARY
			out.append({
				"id": "%s|%s" % [cid, kind],
				"character_id": cid,
				"kind": kind,
				"path": path,
				"status": status,
				"final_on_disk": on_disk,
				"fallback": "procedural placeholder (present, rendering)",
				"validation_errors": verrors,
			})
	return out


## entries() filtered to a single character id ([] for an unknown id).
static func entries_for(char_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in entries():
		if str(e["character_id"]) == char_id:
			out.append(e)
	return out


## { "<char_id>|<kind>": bool } — whether each expected FINAL file exists on
## disk. Uses FileAccess.file_exists / ResourceLoader.exists (never throws).
static func check_disk() -> Dictionary:
	var result: Dictionary = {}
	for cid in CHARACTER_IDS:
		for kind in ASSET_KINDS:
			result["%s|%s" % [cid, kind]] = _path_exists(expected_path(cid, kind))
	return result


## Disk-computed FINAL-file status for one (character, kind):
##   FINAL       - file exists on disk AND validate_finished_asset() == []
##   TEMPORARY   - a file exists but fails validation (placeholder stand-in)
##   MISSING     - the final file is absent on disk (procedural fallback is
##                 reported separately in report()/production_manifest()).
## NEVER hardcoded; never returns FINAL without a real validated file.
static func status_for(char_id: String, kind: String) -> String:
	if not CHARACTER_IDS.has(char_id) or not ASSET_KINDS.has(kind):
		return STATUS_MISSING
	var path := expected_path(char_id, kind)
	if not _path_exists(path):
		return STATUS_MISSING
	if validate_finished_asset(char_id, kind).is_empty():
		return STATUS_FINAL
	return STATUS_TEMPORARY


## [] only when a real, loadable, correctly-sized RGBA8 asset with a transparent
## corner exists at the expected path; precise errors otherwise. A missing file
## is reported (not thrown) so callers fall back safely. Never creates art.
static func validate_finished_asset(char_id: String, kind: String) -> Array[String]:
	var errors: Array[String] = []
	if not CHARACTER_IDS.has(char_id):
		errors.append("unknown character id '%s'" % char_id)
	if not ASSET_KINDS.has(kind):
		errors.append("unknown asset kind '%s' (expected one of %s)" % [kind, str(ASSET_KINDS)])
	if not errors.is_empty():
		return errors
	var path := expected_path(char_id, kind)
	if not _path_exists(path):
		errors.append("missing final asset file: %s (no real finished asset on disk)" % path)
		return errors
	var loaded: Resource = load(path)
	if loaded == null:
		errors.append("could not load final asset: %s" % path)
		return errors
	if SHEET_KINDS.has(kind):
		if not (loaded is SpriteFrames):
			errors.append("%s is not a SpriteFrames resource (sheet kinds expect .tres)" % path)
			return errors
		_validate_spriteframes(loaded as SpriteFrames, kind, errors)
	else:
		if not (loaded is Texture2D):
			errors.append("%s is not a Texture2D" % path)
			return errors
		_validate_texture(loaded as Texture2D, kind, errors)
	return errors


## Honest, deterministic production report for the current disk state.
## final/temporary/missing are ORTHOGONAL lists of "<char>|<kind>" ids:
##   final     = entries with a valid disk file                     (0 today)
##   temporary = entries whose procedural fallback is present      (all 120)
##   missing   = entries whose final file is absent on disk        (all 120)
static func report() -> Dictionary:
	var final: Array[String] = []
	var temporary: Array[String] = []
	var missing: Array[String] = []
	var by_character: Dictionary = {}
	var disk := check_disk()
	for cid in CHARACTER_IDS:
		var c_final: Array = []
		var c_temporary: Array = []
		var c_missing: Array = []
		for kind in ASSET_KINDS:
			var key := "%s|%s" % [cid, kind]
			var on_disk := bool(disk.get(key, false))
			var verrors := validate_finished_asset(cid, kind)
			# MISSING describes the absent final file (orthogonal to fallback).
			if not on_disk or not verrors.is_empty():
				missing.append(key)
				c_missing.append(kind)
			# TEMPORARY describes the present procedural fallback (all kinds).
			temporary.append(key)
			c_temporary.append(kind)
			# FINAL only for a real, validated disk file.
			if on_disk and verrors.is_empty():
				final.append(key)
				c_final.append(kind)
		by_character[cid] = {
			"final": c_final,
			"temporary": c_temporary,
			"missing": c_missing,
			"counts": {
				"final": c_final.size(),
				"temporary": c_temporary.size(),
				"missing": c_missing.size(),
				"total": ASSET_KINDS.size(),
			},
		}
	var total := CHARACTER_IDS.size() * ASSET_KINDS.size()
	return {
		"final": final,
		"temporary": temporary,
		"missing": missing,
		"counts": {
			"final": final.size(),
			"temporary": temporary.size(),
			"missing": missing.size(),
			"total": total,
		},
		"total": total,
		"by_character": by_character,
		"generated_at": "deterministic-disk-state#%d (computed on demand; no wall-clock)" % str(disk).hash(),
	}


## Machine-readable production manifest (the data behind ASSET_PRODUCTION_MANIFEST.md).
static func production_manifest() -> Dictionary:
	var rep := report()
	var characters: Array[Dictionary] = []
	for cid in CHARACTER_IDS:
		var rows: Array[Dictionary] = []
		for e in entries_for(cid):
			rows.append({
				"kind": e["kind"],
				"path": e["path"],
				"status": e["status"],
				"final_on_disk": e["final_on_disk"],
				"fallback": e["fallback"],
			})
		characters.append({"id": cid, "rows": rows})
	return {
		"rule": "an asset may be marked FINAL only if a real finished file exists on disk AND passes validate_finished_asset(); never hardcoded",
		"status_values": [STATUS_FINAL, STATUS_TEMPORARY, STATUS_MISSING],
		"counts": rep["counts"],
		"total": rep["total"],
		"characters": characters,
		"replacement_seams": replacement_seams(),
		"note": "ZERO final assets. All shipped visuals are runtime procedural placeholder art. No image/binary art files were created in this phase.",
		"generated_at": rep["generated_at"],
	}


## {kind: exact replacement seam string} (from CharacterArtPipeline).
static func replacement_seams() -> Dictionary:
	return CharacterArtPipeline.replacement_seams()


# ------------------------------------------------------------------ internals

static func _path_exists(path: String) -> bool:
	if path.is_empty():
		return false
	if FileAccess.file_exists(path):
		return true
	return ResourceLoader.exists(path)


static func _validate_texture(tex: Texture2D, kind: String, errors: Array[String]) -> void:
	var img := tex.get_image()
	if img == null:
		errors.append("kind '%s': texture has no readable Image (must be RGBA8)" % kind)
		return
	if img.get_format() != Image.FORMAT_RGBA8:
		errors.append("kind '%s': image format is not RGBA8" % kind)
	var w := tex.get_width()
	var h := tex.get_height()
	if FILE_DIMS.has(kind):
		var dims: Array = FILE_DIMS[kind]
		if w != int(dims[0]) or h != int(dims[1]):
			errors.append("kind '%s': image is %dx%d, expected %dx%d" % [kind, w, h, int(dims[0]), int(dims[1])])
	else:
		errors.append("kind '%s': no expected dimensions registered" % kind)
	# transparent corner: all four corners must be fully (or near) transparent.
	var corners := [
		img.get_pixel(0, 0), img.get_pixel(w - 1, 0),
		img.get_pixel(0, h - 1), img.get_pixel(w - 1, h - 1),
	]
	for c in corners:
		if (c as Color).a > 0.05:
			errors.append("kind '%s': a corner pixel is not transparent (opaque background)" % kind)
			break


static func _validate_spriteframes(sf: SpriteFrames, kind: String, errors: Array[String]) -> void:
	var states: Array = SHEET_ANIMS.get(kind, [])
	for st in states:
		for d in 8:
			var anim := StringName("%s_%d" % [st, d])
			if not sf.has_animation(anim):
				errors.append("sheet '%s': missing animation '%s'" % [kind, str(anim)])
				continue
			var count := sf.get_frame_count(anim)
			for i in count:
				var frame_tex := sf.get_frame_texture(anim, i)
				if frame_tex == null:
					errors.append("sheet '%s' animation '%s' frame %d is null" % [kind, str(anim), i])
				elif frame_tex.get_width() != FRAME_W or frame_tex.get_height() != FRAME_H:
					errors.append("sheet '%s' animation '%s' frame %d is %dx%d, expected %dx%d" % [kind, str(anim), i, frame_tex.get_width(), frame_tex.get_height(), FRAME_W, FRAME_H])

class_name PortraitAssetSource
extends RefCounted
## PORTRAIT ASSET SOURCE — Part 6 of PROJECT FANTASY Phase 5 (FOUNDATION).
##
## ZERO final assets exist. Every shipped portrait is a RUNTIME PROCEDURAL
## PLACEHOLDER drawn by scripts/ui/portrait_view.gd (PortraitView). This file is
## a pure CONTRACT / loader seam, NOT art. When a real painted portrait is
## dropped at the expected path, texture_for() returns it; otherwise it returns
## null SAFELY (never crashes) and the caller keeps the procedural fallback.
## This phase creates NO image/binary file at any expected path.
##
## PURE / headless: plain data + defensive FileAccess / ResourceLoader / load
## checks. NO nodes, NO SceneTree, NO autoloads, NO generated textures. The
## LATER round will edit PortraitView to call texture_for() and fall back to
## procedural art when it returns null.

# 12 first characters (explicit copy of CharacterArtSpec.CHARACTER_IDS).
const CHARACTER_IDS: Array[String] = [
	"lyra_vey", "bramble", "seraphine", "nyx", "coralyn", "ignis",
	"mira_sol", "thistle", "vespera", "arachnia", "terra", "kael",
]

# Canonical (validated) exported portrait is the "hud" class: 256x384,
# top-centre bust crop. Other classes are optional higher/lower res exports.
const SIZE_CLASSES: Dictionary = {
	"master":     {"width": 1024, "height": 1280, "suffix": "master", "use": "editable master / big splash"},
	"collection": {"width": 512,  "height": 640,  "suffix": "512",     "use": "collection / summon"},
	"hud":        {"width": 256,  "height": 384,  "suffix": "",        "use": "canonical HUD export (validated dims)"},
	"battle":     {"width": 256,  "height": 320,  "suffix": "battle",  "use": "battle unit card bust"},
}

const CANONICAL_W := 256
const CANONICAL_H := 384

# ------------------------------------------------------------------ public API

## Expected path for a character portrait at a given size class.
## "hud" (default) -> res://assets/characters/<id>/portrait.png; other classes
## -> res://assets/characters/<id>/portrait_<suffix>.png. Unknown size classes
## fall back to the canonical hud path (never throws).
static func expected_path(char_id: String, size_class: String = "hud") -> String:
	if size_class == "hud" or not SIZE_CLASSES.has(size_class):
		return "res://assets/characters/%s/portrait.png" % char_id
	var suffix := str((SIZE_CLASSES[size_class] as Dictionary)["suffix"])
	return "res://assets/characters/%s/portrait_%s.png" % [char_id, suffix]


## The real painted portrait texture, or null when missing/invalid. Missing
## assets return null SAFELY (never crash); the caller falls back to the
## procedural PortraitView art. For the canonical "hud" class the texture is
## additionally validated (dims / RGBA8 / alpha) before being returned.
static func texture_for(char_id: String, size_class: String = "hud") -> Texture2D:
	var path := expected_path(char_id, size_class)
	if not _path_exists(path):
		return null
	var loaded: Resource = load(path)
	if not (loaded is Texture2D):
		return null
	var tex := loaded as Texture2D
	if size_class == "hud" and not validate_portrait(tex).is_empty():
		return null
	return tex


## True when ANY expected portrait file for the character exists on disk.
static func has_portrait(char_id: String) -> bool:
	for sc in SIZE_CLASSES.keys():
		if _path_exists(expected_path(char_id, str(sc))):
			return true
	return false


## Disk-computed status: "final" (valid painted portrait loads), "temporary"
## (a file exists but fails validation / procedural fallback in use), or
## "missing" (no final file on disk). Never hardcoded; never FINAL without a
## real validated file.
static func status(char_id: String) -> String:
	if not has_portrait(char_id):
		return "missing"
	var tex := texture_for(char_id, "hud")
	if tex != null:
		return "final"
	return "temporary"


## [] when the texture is 256x384, RGBA8 and has real alpha (transparent
## corner); precise errors otherwise. Null-safe: a null texture is an error.
static func validate_portrait(tex: Texture2D) -> Array[String]:
	var errors: Array[String] = []
	if tex == null:
		errors.append("portrait texture is null")
		return errors
	var w := tex.get_width()
	var h := tex.get_height()
	if w != CANONICAL_W or h != CANONICAL_H:
		errors.append("portrait is %dx%d, expected %dx%d" % [w, h, CANONICAL_W, CANONICAL_H])
	var img := tex.get_image()
	if img == null:
		errors.append("portrait has no readable Image (must be RGBA8)")
		return errors
	if img.get_format() != Image.FORMAT_RGBA8:
		errors.append("portrait image format is not RGBA8")
	# alpha present: at least one corner pixel must be (near) transparent.
	var has_alpha := false
	var corners := [
		img.get_pixel(0, 0), img.get_pixel(w - 1, 0),
		img.get_pixel(0, h - 1), img.get_pixel(w - 1, h - 1),
	]
	for c in corners:
		if (c as Color).a < 0.999:
			has_alpha = true
			break
	if not has_alpha:
		errors.append("portrait has no alpha channel / transparent background (opaque)")
	return errors


## Godot import settings for the canonical portrait export (lossless UI).
static func import_settings() -> Dictionary:
	return {
		"filter": "Linear",
		"mipmaps": false,
		"compression": "Lossless (UI)",
		"fix_alpha_border": false,
		"format": "RGBA8 PNG / WebP, sRGB, transparent",
		"srgb": true,
		"keep_aspect_ratio": true,
		"never_stretch": true,
		"anchor": "top-centre (0.5, 0.0) bust crop",
	}


## Deterministic, honest status report across all 12 characters.
static func report() -> Dictionary:
	var present: Array[String] = []
	var missing: Array[String] = []
	var temporary: Array[String] = []
	var per_character: Dictionary = {}
	for cid in CHARACTER_IDS:
		var st := status(cid)
		per_character[cid] = {
			"status": st,
			"hud_path": expected_path(cid, "hud"),
			"procedural_fallback": "scripts/ui/portrait_view.gd (PortraitView)",
		}
		if st == "final":
			present.append(cid)
		else:
			missing.append(cid)
		# A procedural fallback is present for every character (orthogonal).
		temporary.append(cid)
	return {
		"canonical_export": {"width": CANONICAL_W, "height": CANONICAL_H},
		"size_classes": SIZE_CLASSES.duplicate(true),
		"character_ids": character_ids(),
		"present": present,
		"missing": missing,
		"temporary_fallback": temporary,
		"counts": {
			"present": present.size(),
			"missing": missing.size(),
			"temporary": temporary.size(),
			"total": CHARACTER_IDS.size(),
		},
		"per_character": per_character,
		"replacement_seam": replacement_seam(),
		"note": "ZERO final portraits. Missing assets return null -> procedural PortraitView fallback. No image/binary art file was created in this phase.",
	}


## Exact replacement seam string (used by the LATER PortraitView round).
static func replacement_seam() -> String:
	return "scripts/ui/portrait_view.gd (PortraitView.setup_character / _draw) -> PortraitAssetSource.texture_for(<id>, \"hud\") with a procedural fallback on null"


## Fresh typed copy of the 12 character ids.
static func character_ids() -> Array[String]:
	var out: Array[String] = []
	for cid in CHARACTER_IDS:
		out.append(cid)
	return out


# ------------------------------------------------------------------ internals

static func _path_exists(path: String) -> bool:
	if path.is_empty():
		return false
	if FileAccess.file_exists(path):
		return true
	return ResourceLoader.exists(path)

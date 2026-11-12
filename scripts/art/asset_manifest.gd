class_name AssetManifest
extends RefCounted
## ASSET MANIFEST -- the contract for dropping REAL painted art into PROJECT
## FANTASY. PURE / headless-testable: plain data + ResourceLoader/FileAccess
## existence checks, NO nodes, NO SceneTree state, NO generated textures.
##
## No final painted assets ship with this build; every class is procedural
## placeholder. This manifest is the contract for dropping in real art.
## It records, for EACH of the eight asset classes, the exact file path,
## dimensions, transparent-RGBA8 requirement, anchor, animation frame layout,
## import settings, naming convention and the exact REPLACEMENT SEAM in code.
## status_report() reflects reality: 0 FINAL, 8 TEMPORARY (a procedural
## fallback is present for every class) and 8 MISSING (none of the expected
## final files exist on disk). See assets/README.md / assets/ASSET_STATUS.md.
##
## References: documentation/ART_PIPELINE.md, documentation/VISUAL_STYLE.md.

# Status values ---------------------------------------------------------------
const STATUS_FINAL := "final"
const STATUS_TEMPORARY := "temporary"
const STATUS_MISSING := "missing"

# The EIGHT asset classes (stable id list) ------------------------------------
const ASSET_CLASSES: Array[String] = [
	"character_sprites",
	"character_portraits",
	"environment_tilesets",
	"buildings",
	"vegetation",
	"monster_sprites",
	"skill_effects",
	"ui_illustrations",
]

# One spec dict per class. Keys: id, class, path, width, height, anchor,
# frames, import, naming, seam, status -- plus a few informative extras.
# `frames` is the per-direction frame-column count used for animated sheets
# (1 for static art). `import` is the exact Godot import settings dict.
const CLASS_SPECS: Dictionary = {
	"character_sprites": {
		"id": "character_sprites",
		"class": "painted anime character sprites",
		"path": "res://assets/characters/player/world_sheet.png",
		"width": 96, "height": 128,
		"anchor": "bottom-centre (0.5, 1.0), feet on one baseline, Y-sort at ground point",
		"frames": 8,
		"import": {
			"filter": "Linear", "mipmaps": true,
			"compression": "VRAM compressed where supported; lossless for UI",
			"fix_alpha_border": true,
		},
		"naming": "lower_snake_case content-id folder; <id>/world_sheet.png or <id>_<state>_<dir>.png; 8 direction rows x <frames> columns, 0-based frame index",
		"seam": "ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>)); scripts/world/actor_frame_source.gd + scripts/art/sprite_frames_actor_source.gd",
		"status": STATUS_TEMPORARY,
		"transparent": true,
		"format": "RGBA8 PNG / WebP, sRGB, transparent",
		"background": "transparent RGBA8 (alpha cutouts), NOT opaque",
		"sheet_layout": "8 direction rows x <frame_counts[state]> frame columns; one row per direction, 0-based columns",
	},
	"character_portraits": {
		"id": "character_portraits",
		"class": "character portraits",
		"path": "res://assets/portraits/player/portrait.png",
		"width": 256, "height": 384,
		"anchor": "top-centre (0.5, 0.0); bust crop from the top",
		"frames": 1,
		"import": {
			"filter": "Linear", "mipmaps": false,
			"compression": "Lossless (UI)", "fix_alpha_border": false,
		},
		"naming": "lower_snake_case content-id folder; <id>/portrait.png",
		"seam": "scripts/ui/portrait_view.gd (PortraitView) / ContentDB character portrait lookup",
		"status": STATUS_TEMPORARY,
		"transparent": true,
		"format": "RGBA8 PNG / WebP, sRGB, transparent",
		"background": "transparent RGBA8",
		"sheet_layout": "single static frame",
	},
	"environment_tilesets": {
		"id": "environment_tilesets",
		"class": "environment tilesets",
		"path": "res://assets/tilesets/greenward_terrain.png",
		"width": 512, "height": 512,
		"anchor": "tile grid top-left (0.0, 0.0); 16x16 px cells",
		"frames": 1,
		"import": {
			"filter": "Linear", "mipmaps": true,
			"compression": "VRAM compressed", "fix_alpha_border": true,
		},
		"naming": "lower_snake_case biome id; greenward_terrain.png / <biome>_tileset.png",
		"seam": "scripts/world/chunk_builder.gd terrain MultiMesh + scripts/world/procedural_art.gd prop_texture()",
		"status": STATUS_TEMPORARY,
		"transparent": true,
		"format": "RGBA8 PNG / WebP, sRGB, transparent",
		"background": "transparent RGBA8 cutouts for overlay tiles",
		"sheet_layout": "static tile atlas, 16x16 cells",
	},
	"buildings": {
		"id": "buildings",
		"class": "buildings",
		"path": "res://assets/buildings/watchtower/building.png",
		"width": 256, "height": 256,
		"anchor": "bottom-centre (0.5, 1.0), Y-sort at ground point",
		"frames": 1,
		"import": {
			"filter": "Linear", "mipmaps": true,
			"compression": "VRAM compressed", "fix_alpha_border": true,
		},
		"naming": "lower_snake_case content-id folder; <id>/building.png",
		"seam": "scripts/world/procedural_art.gd _build_prop()/_paint_kind() + GreenwardStyle.prop_palette()",
		"status": STATUS_TEMPORARY,
		"transparent": true,
		"format": "RGBA8 PNG / WebP, sRGB, transparent",
		"background": "transparent RGBA8",
		"sheet_layout": "single static frame per variant",
	},
	"vegetation": {
		"id": "vegetation",
		"class": "vegetation",
		"path": "res://assets/vegetation/willow_tree/plant.png",
		"width": 128, "height": 160,
		"anchor": "bottom-centre (0.5, 1.0), trunk base on the ground line",
		"frames": 1,
		"import": {
			"filter": "Linear", "mipmaps": true,
			"compression": "VRAM compressed", "fix_alpha_border": true,
		},
		"naming": "lower_snake_case content-id folder; <id>/plant.png",
		"seam": "scripts/world/procedural_art.gd tree/fern/flower painters via _build_prop() + GreenwardStyle.prop_palette()",
		"status": STATUS_TEMPORARY,
		"transparent": true,
		"format": "RGBA8 PNG / WebP, sRGB, transparent",
		"background": "transparent RGBA8",
		"sheet_layout": "single static frame per variant",
	},
	"monster_sprites": {
		"id": "monster_sprites",
		"class": "monster sprites",
		"path": "res://assets/monsters/glade_wisp/world_sheet.png",
		"width": 96, "height": 128,
		"anchor": "bottom-centre (0.5, 1.0); boss canvas 128x192",
		"frames": 8,
		"import": {
			"filter": "Linear", "mipmaps": true,
			"compression": "VRAM compressed where supported", "fix_alpha_border": true,
		},
		"naming": "lower_snake_case content-id folder; <id>/world_sheet.png; 8 direction rows x frames",
		"seam": "ActorVisual (Kind.MONSTER) via scripts/world/actor_frame_source.gd + SpriteFramesActorSource",
		"status": STATUS_TEMPORARY,
		"transparent": true,
		"format": "RGBA8 PNG / WebP, sRGB, transparent",
		"background": "transparent RGBA8",
		"sheet_layout": "8 direction rows x <frame_counts[state]> columns, 0-based",
	},
	"skill_effects": {
		"id": "skill_effects",
		"class": "skill effects",
		"path": "res://assets/vfx/wind_slash/effect.png",
		"width": 192, "height": 192,
		"anchor": "centre (0.5, 0.5)",
		"frames": 6,
		"import": {
			"filter": "Linear", "mipmaps": false,
			"compression": "Lossless", "fix_alpha_border": true,
		},
		"naming": "lower_snake_case skill-id folder; <id>/effect.png; 1 row x N frame columns",
		"seam": "scripts/combat/combat_engine.gd VFX hooks / scripts/world/procedural_art.gd soft_glow()",
		"status": STATUS_TEMPORARY,
		"transparent": true,
		"format": "RGBA8 PNG / WebP, sRGB, transparent (additive)",
		"background": "transparent RGBA8",
		"sheet_layout": "1 row x 6 frame columns, 0-based",
	},
	"ui_illustrations": {
		"id": "ui_illustrations",
		"class": "UI illustrations",
		"path": "res://assets/ui/title/illustration.png",
		"width": 640, "height": 360,
		"anchor": "centre (0.5, 0.5)",
		"frames": 1,
		"import": {
			"filter": "Linear", "mipmaps": false,
			"compression": "Lossless (UI)", "fix_alpha_border": false,
		},
		"naming": "lower_snake_case content-id folder; <id>/illustration.png",
		"seam": "scripts/ui/main_backdrop.gd + scripts/ui/ui_theme.gd",
		"status": STATUS_TEMPORARY,
		"transparent": true,
		"format": "RGBA8 PNG / WebP, sRGB, transparent",
		"background": "transparent RGBA8",
		"sheet_layout": "single static frame",
	},
}

# ------------------------------------------------------------------ public API

## One spec dict per class (fresh deep copies; callers cannot mutate the const).
static func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in ASSET_CLASSES:
		result.append((CLASS_SPECS[id] as Dictionary).duplicate(true))
	return result


## Full spec for a single class id, or {} for an unknown id.
static func asset_spec(class_id: String) -> Dictionary:
	if CLASS_SPECS.has(class_id):
		return (CLASS_SPECS[class_id] as Dictionary).duplicate(true)
	return {}


## Godot import settings dict for a class (or {} for an unknown id).
static func import_settings(class_id: String) -> Dictionary:
	var spec := asset_spec(class_id)
	if spec.is_empty():
		return {}
	return (spec["import"] as Dictionary).duplicate(true)


## The exact expected res:// file path recorded in an entry.
static func expected_path(entry: Dictionary) -> String:
	return str(entry.get("path", ""))


## {class_id: bool} -- whether each expected final file actually exists on
## disk. Uses FileAccess.file_exists / ResourceLoader.exists (never throws).
static func check_disk() -> Dictionary:
	var result := {}
	for e in entries():
		result[str(e["id"])] = _path_exists(expected_path(e))
	return result


static func _path_exists(path: String) -> bool:
	if path.is_empty():
		return false
	if FileAccess.file_exists(path):
		return true
	return ResourceLoader.exists(path)


## Honest, reality-based status. `final` = classes shipping a real painted
## asset (0). `temporary` = classes whose procedural fallback IS present and
## rendering right now (all 8). `missing` = classes whose expected FINAL file
## is absent on disk (all 8). These last two are ORTHOGONAL: a class can be
## both "temporary" (fallback present) and "missing" (final file absent).
static func status_report() -> Dictionary:
	var final: Array = []
	var temporary: Array = []
	var missing: Array = []
	var all := entries()
	var disk := check_disk()
	for e in all:
		var id := str(e["id"])
		var st := str(e["status"])
		if st == STATUS_FINAL:
			final.append(id)
		elif st == STATUS_TEMPORARY:
			temporary.append(id)
		elif st == STATUS_MISSING:
			missing.append(id)
		if not bool(disk.get(id, false)) and not missing.has(id):
			missing.append(id)
	return {
		"final": final,
		"temporary": temporary,
		"missing": missing,
		"counts": {
			"final": final.size(),
			"temporary": temporary.size(),
			"missing": missing.size(),
		},
		"total": all.size(),
		"entries": all,
	}


## Validate a proposed sprite-sheet spec against its registered class. Returns
## [] when valid, else human-readable errors for wrong dims, a missing anchor,
## a non-transparent background, a bad frame count, or an invalid format.
static func validate_sheet_specs(sheet: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var class_id := str(sheet.get("class", ""))
	var spec := asset_spec(class_id)
	if spec.is_empty():
		errors.append("unknown asset class '%s' (expected one of %s)" % [class_id, str(ASSET_CLASSES)])
		return errors
	if int(sheet.get("width", -1)) != int(spec["width"]):
		errors.append("class '%s': width %s, expected %d px" % [class_id, str(sheet.get("width", "missing")), int(spec["width"])])
	if int(sheet.get("height", -1)) != int(spec["height"]):
		errors.append("class '%s': height %s, expected %d px" % [class_id, str(sheet.get("height", "missing")), int(spec["height"])])
	var anchor := str(sheet.get("anchor", ""))
	if anchor.strip_edges().is_empty():
		errors.append("class '%s': missing anchor" % class_id)
	if not bool(sheet.get("transparent", false)):
		errors.append("class '%s': background must be transparent RGBA8 (transparent=true)" % class_id)
	var frames_val: Variant = sheet.get("frames", -1)
	var frames_ok := (typeof(frames_val) == TYPE_INT or typeof(frames_val) == TYPE_FLOAT) and int(frames_val) == int(spec["frames"])
	if not frames_ok:
		errors.append("class '%s': frame layout %s, expected %d frames" % [class_id, str(frames_val), int(spec["frames"])])
	var fmt := str(sheet.get("format", "")).strip_edges().to_lower()
	var fmt_ok := ("png" in fmt) or ("webp" in fmt)
	if ("jpg" in fmt) or ("jpeg" in fmt) or ("bmp" in fmt):
		fmt_ok = false
	if not fmt_ok:
		errors.append("class '%s': invalid format '%s' (expected transparent RGBA8 PNG/WebP)" % [class_id, fmt])
	return errors


## {class_id: exact replacement seam string}.
static func replacement_seams() -> Dictionary:
	var out := {}
	for e in entries():
		out[str(e["id"])] = str(e["seam"])
	return out

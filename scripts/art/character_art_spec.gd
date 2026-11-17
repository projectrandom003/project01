class_name CharacterArtSpec
extends RefCounted
## CHARACTER ART SPEC — Part 2 of PROJECT FANTASY Phase 5 (FOUNDATION).
##
## ZERO final assets exist. Every shipped visual is RUNTIME PROCEDURAL PLACEHOLDER
## art; this file is a pure CONTRACT/SPECIFICATION, not artwork. It holds ONE
## authored art spec per character id (the first 12 characters). Identity fields
## are derived verbatim from resources/data/characters.json so a test can cross-
## check `CharacterArtSpec.for_id(id).race == ContentDB.get_character(id).race`
## etc. Descriptive fields are authored here from each character's existing
## lore / title / role / palette and do NOT alter or replace gameplay data.
##
## ONE consistent anime-fantasy art direction is shared across all 12 (the
## STYLE_ANCHOR below): ~6-head heroic proportions, upper-left key light,
## 1-2 px dark ink outline, cel-shaded painterly rendering, transparent RGBA8
## backgrounds and element-motif accents. Legendary + Mythic characters carry a
## distinct visual tier (extra ornamentation, an aura motif, a premium frame).
## No copyrighted characters, logos or reference traces.
##
## PURE / headless: no nodes, no SceneTree, no autoloads, no file IO, no
## generated textures. Static factories construct instances via a RUNTIME
## load() of this script and type against the RefCounted base / untyped Variant;
## this avoids the GDScript global-class self-reference cycle that produces
## headless leaked-RID warnings (same technique as SpriteFramesActorSource).

# ------------------------------------------------------------------ constants
# The 12 first characters, in canonical order.
const CHARACTER_IDS = CharacterArtSpecCatalog.CHARACTER_IDS

const VALID_RARITIES = CharacterArtSpecCatalog.VALID_RARITIES
const VALID_ELEMENTS = CharacterArtSpecCatalog.VALID_ELEMENTS
const REQUIRED_FIELDS = CharacterArtSpecCatalog.REQUIRED_FIELDS
const _SELF_PATH := "res://scripts/art/character_art_spec.gd"

# The SHARED global art-direction anchor, prepended to every generation prompt.
# Original anime-fantasy, no copyrighted characters/logos, consistent
# proportions/lighting/outline/palette language from GreenwardStyle, transparent
# background, upper-left key light.
const STYLE_ANCHOR := CharacterArtPromptBuilder.STYLE_ANCHOR

# ------------------------------------------------------------------ authored specs
# ONE entry per character id. Identity + palette + skills/ultimate are EXACT
# copies of resources/data/characters.json; everything else is authored art
# direction consistent with the existing lore/title/role/palette.
const SPECS = CharacterArtSpecCatalog.SPECS

# ------------------------------------------------------------------ instance state
# All required fields are plain data (safe to snapshot / to_dict()).
var id: String = ""
var display_name: String = ""
var title: String = ""
var race: String = ""
var element: String = ""
var rarity: String = ""
var role: String = ""
var physical_appearance: String = ""
var hair_style: String = ""
var hair_color: String = ""
var hair_color_name: String = ""
var pose: String = ""
var motif: String = ""
var expression: String = ""
var outfit: String = ""
var accessories: String = ""
var weapon: String = ""
var personality: String = ""
var visual_theme: String = ""
var palette: Dictionary = {}
var animation_requirements: Dictionary = {}
var portrait_requirements: Dictionary = {}
var generation_prompt: String = ""
var portrait_prompt: String = ""
var sheet_prompt: String = ""
var skills: Array = []
var ultimate: String = ""
var tier_note: String = ""


func _init(data: Dictionary = {}) -> void:
	var d: Dictionary = data.duplicate(true)
	if d.is_empty():
		return
	id = str(d.get("id", ""))
	display_name = str(d.get("display_name", ""))
	title = str(d.get("title", ""))
	race = str(d.get("race", ""))
	element = str(d.get("element", ""))
	rarity = str(d.get("rarity", ""))
	role = str(d.get("role", ""))
	physical_appearance = str(d.get("physical_appearance", ""))
	hair_style = str(d.get("hair_style", ""))
	hair_color_name = str(d.get("hair_color_name", ""))
	pose = str(d.get("pose", ""))
	motif = str(d.get("motif", ""))
	expression = str(d.get("expression", ""))
	palette = (d.get("palette", {}) as Dictionary).duplicate(true)
	outfit = str(d.get("outfit", ""))
	accessories = str(d.get("accessories", ""))
	weapon = str(d.get("weapon", ""))
	personality = str(d.get("personality", ""))
	visual_theme = str(d.get("visual_theme", ""))
	skills = (d.get("skills", []) as Array).duplicate()
	ultimate = str(d.get("ultimate", ""))
	tier_note = str(d.get("tier_note", ""))
	hair_color = "%s (%s)" % [str(palette.get("hair", "#ffffff")), str(d.get("hair_color_name", ""))]
	animation_requirements = _animation_requirements(d)
	portrait_requirements = _portrait_requirements(d)
	generation_prompt = CharacterArtPromptBuilder.full_body_prompt(d)
	portrait_prompt = CharacterArtPromptBuilder.portrait_prompt(d)
	sheet_prompt = CharacterArtPromptBuilder.sheet_prompt(d)


# ------------------------------------------------------------------ factories
# Construct via a RUNTIME load() + base/Variant typing (NOT this global class's
# name) to avoid the static self-reference cycle and headless leaked-RID warns.

## All 12 authored specs, in CHARACTER_IDS order. Returns an untyped Array of
## CharacterArtSpec instances (element access at call sites is dynamic).
static func all() -> Array:
	var out: Array = []
	for cid in CHARACTER_IDS:
		var entry: Dictionary = (SPECS[cid] as Dictionary).duplicate(true)
		entry["id"] = cid
		out.append(load(_SELF_PATH).new(entry))
	return out


## One spec for an id, or null for an unknown id (null-ish safe, never throws).
static func for_id(id: String):
	if not SPECS.has(id):
		return null
	var entry: Dictionary = (SPECS[id] as Dictionary).duplicate(true)
	entry["id"] = id
	return load(_SELF_PATH).new(entry)


## Fresh typed copy of the 12 stable character ids.
static func ids() -> Array[String]:
	var out: Array[String] = []
	for cid in CHARACTER_IDS:
		out.append(cid)
	return out


## [] when all 12 specs are present, unique, every required field is non-empty
## and identity fields are internally consistent; precise errors otherwise.
static func validate_specs() -> Array[String]:
	var errors: Array[String] = []
	# uniqueness + count
	var seen: Dictionary = {}
	for cid in CHARACTER_IDS:
		if seen.has(cid):
			errors.append("duplicate character id '%s' in CHARACTER_IDS" % cid)
		seen[cid] = true
	if CHARACTER_IDS.size() != 12:
		errors.append("expected 12 character ids, found %d" % CHARACTER_IDS.size())
	if SPECS.size() != CHARACTER_IDS.size():
		errors.append("SPECS has %d entries, expected %d" % [SPECS.size(), CHARACTER_IDS.size()])
	# per-character checks (built from a runtime load to stay cycle-free)
	for entry in all():
		var spec: RefCounted = entry as RefCounted
		var cid := str(spec.get("id"))
		if not SPECS.has(cid):
			errors.append("spec '%s' is not in SPECS" % cid)
		var dict := (spec.call("to_dict") as Dictionary)
		for field in REQUIRED_FIELDS:
			var v: Variant = dict.get(field, null)
			if v == null:
				errors.append("spec '%s' missing field '%s'" % [cid, field])
			elif (typeof(v) == TYPE_STRING) and str(v).strip_edges().is_empty():
				errors.append("spec '%s' field '%s' is empty" % [cid, field])
			elif (typeof(v) == TYPE_DICTIONARY) and (v as Dictionary).is_empty():
				errors.append("spec '%s' field '%s' is empty" % [cid, field])
		# identity consistency vs the frozen SPECS data
		var raw: Dictionary = SPECS.get(cid, {})
		if str(dict.get("display_name", "")) != str(raw.get("display_name", "")):
			errors.append("spec '%s' display_name inconsistent with SPECS" % cid)
		if str(dict.get("title", "")) != str(raw.get("title", "")):
			errors.append("spec '%s' title inconsistent with SPECS" % cid)
		if str(dict.get("race", "")) != str(raw.get("race", "")):
			errors.append("spec '%s' race inconsistent with SPECS" % cid)
		if str(dict.get("element", "")) != str(raw.get("element", "")):
			errors.append("spec '%s' element inconsistent with SPECS" % cid)
		if str(dict.get("rarity", "")) != str(raw.get("rarity", "")):
			errors.append("spec '%s' rarity inconsistent with SPECS" % cid)
		if str(dict.get("role", "")) != str(raw.get("role", "")):
			errors.append("spec '%s' role inconsistent with SPECS" % cid)
		if not VALID_RARITIES.has(str(dict.get("rarity", ""))):
			errors.append("spec '%s' rarity '%s' is not one of %s" % [cid, str(dict.get("rarity", "")), str(VALID_RARITIES)])
		if not VALID_ELEMENTS.has(str(dict.get("element", ""))):
			errors.append("spec '%s' element '%s' is not one of %s" % [cid, str(dict.get("element", "")), str(VALID_ELEMENTS)])
		var pal: Dictionary = dict.get("palette", {})
		for pk in ["hair", "primary", "secondary", "accent", "skin"]:
			var hex := str(pal.get(pk, ""))
			if hex.length() != 7 or not hex.begins_with("#"):
				errors.append("spec '%s' palette.%s is not a #rrggbb hex" % [cid, pk])
		# animation + portrait requirements integrity
		var anim: Dictionary = dict.get("animation_requirements", {})
		if (anim.get("animations", []) as Array).size() != 72:
			errors.append("spec '%s' animation_requirements must list 72 animations" % cid)
		if (anim.get("states", []) as Array).size() != 9:
			errors.append("spec '%s' animation_requirements must list 9 states" % cid)
		# legendary/mythic premium tier must be described
		var rar := str(dict.get("rarity", ""))
		if (rar == "legendary" or rar == "mythic") and str(dict.get("tier_note", "")).strip_edges().is_empty():
			errors.append("spec '%s' (%s) must describe a distinct visual tier" % [cid, rar])
	return errors


## id -> {name, race, element, rarity, title, role} (identity from SPECS).
static func identity_table() -> Dictionary:
	var out: Dictionary = {}
	for cid in CHARACTER_IDS:
		var d: Dictionary = SPECS[cid]
		out[cid] = {
			"name": str(d["display_name"]),
			"race": str(d["race"]),
			"element": str(d["element"]),
			"rarity": str(d["rarity"]),
			"title": str(d["title"]),
			"role": str(d["role"]),
		}
	return out


# ------------------------------------------------------------------ instance API

## Full spec as a plain Dictionary (fresh copy; all required fields present).
func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"title": title,
		"race": race,
		"element": element,
		"rarity": rarity,
		"role": role,
		"physical_appearance": physical_appearance,
		"hair_style": hair_style,
		"hair_color": hair_color,
		"hair_color_name": hair_color_name,
		"pose": pose,
		"motif": motif,
		"expression": expression,
		"outfit": outfit,
		"accessories": accessories,
		"weapon": weapon,
		"personality": personality,
		"visual_theme": visual_theme,
		"palette": palette.duplicate(true),
		"animation_requirements": animation_requirements.duplicate(true),
		"portrait_requirements": portrait_requirements.duplicate(true),
		"generation_prompt": generation_prompt,
		"portrait_prompt": portrait_prompt,
		"sheet_prompt": sheet_prompt,
		"skills": skills.duplicate(),
		"ultimate": ultimate,
		"tier_note": tier_note,
	}


## A detailed, ready-to-use generation prompt for one kind:
## "full_body" | "portrait" | "sheet" | "vfx". Unknown -> "" (never throws).
func prompt_for(kind: String) -> String:
	match kind:
		"full_body":
			return generation_prompt
		"portrait":
			return portrait_prompt
		"sheet":
			return sheet_prompt
		"vfx":
			return CharacterArtPromptBuilder.vfx_prompt(to_dict())
		_:
			return ""


## The 72 required <state>_<dir> animation names for this character.
func required_animations() -> Array[String]:
	var out: Array[String] = []
	for a in (animation_requirements.get("animations", []) as Array):
		out.append(str(a))
	return out


# ------------------------------------------------------------------ composition
# Prompt language is a separate pure module; keep these thin wrappers for
# compatibility while CharacterArtPromptBuilder owns generation wording.

static func _palette_line(d: Dictionary) -> String:
	return CharacterArtPromptBuilder.palette_line(d)


static func _full_body_prompt(d: Dictionary) -> String:
	return CharacterArtPromptBuilder.full_body_prompt(d)


static func _portrait_prompt(d: Dictionary) -> String:
	return CharacterArtPromptBuilder.portrait_prompt(d)


static func _sheet_prompt(d: Dictionary) -> String:
	return CharacterArtPromptBuilder.sheet_prompt(d)


func _vfx_prompt() -> String:
	return CharacterArtPromptBuilder.vfx_prompt(to_dict())


static func _animation_requirements(d: Dictionary) -> Dictionary:
	var states: Array[String] = ["idle", "walk", "run", "interact", "attack", "damage", "victory", "defeat", "cast"]
	var frame_counts := {"idle": 5, "walk": 16, "run": 16, "interact": 6, "attack": 6, "damage": 2, "victory": 8, "defeat": 6, "cast": 7}
	var fps := {"idle": 9.0, "walk": 12.0, "run": 16.0, "interact": 12.0, "attack": 15.0, "damage": 12.0, "victory": 12.0, "defeat": 10.0, "cast": 12.0}
	var looping := {"idle": true, "walk": true, "run": true, "interact": false, "attack": false, "damage": false, "victory": false, "defeat": false, "cast": false}
	var anims: Array[String] = []
	for st in states:
		for dir in 8:
			anims.append("%s_%d" % [st, dir])
	return {
		"required_states": states.duplicate(),
		"states": states.duplicate(),
		"directions": 8,
		"direction_names": ["down", "down_right", "right", "up_right", "up", "up_left", "left", "down_left"],
		"locomotion_8_directions": true,
		"animations": anims,
		"frame_counts": frame_counts,
		"fps": fps,
		"looping": looping,
		"skill_vfx_ids": (d.get("skills", []) as Array).duplicate(),
		"ultimate_vfx_ids": [str(d.get("ultimate", ""))],
	}


static func _portrait_requirements(d: Dictionary) -> Dictionary:
	var rar := str(d.get("rarity", "common"))
	var premium := (rar == "legendary" or rar == "mythic")
	return {
		"master_width": 1024, "master_height": 1280,
		"export_width": 256, "export_height": 384,
		"crop": "top-centre (0.5, 0.0) bust crop, head and shoulders, eyes in the upper third",
		"expression_set": ["neutral", str(d.get("expression", "alternate"))],
		"background_treatment": "transparent RGBA8 (alpha cutout); a subtle element-tinted vignette is allowed, never an opaque backdrop",
		"rarity_frame": "%s frame; %s" % [rar, "premium ornate frame for Legendary/Mythic tier" if premium else "standard frame"],
		"lighting": "upper-left key light, consistent across all 12 characters",
		"outline_px": "1-2 px dark ink outline",
	}

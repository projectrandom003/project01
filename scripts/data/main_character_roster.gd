class_name MainCharacterRoster
extends RefCounted
## Read-only registry for the two main protagonists (Lilith, Gerald).
##
## Full definitions live in resources/data/main_characters.json using the same
## schema as ContentDB's characters.json. ContentDB merges these entries into its
## live character table at boot, so both protagonists are registered playable
## characters and the starting party, portraits, combat and saves resolve them
## through the normal ContentDB API.
##
## The registry remains the asset/authoring view: it is the only place that
## knows about the design reference sheets, the playable-art folders and the
## runtime world sheets.
##
## Design references live under res://assets/characters/main/<folder>/; playable
## art lives under res://assets/characters/<id>/. portrait_texture() only ever
## returns a real 256x384 RGBA8 portrait, so a protagonist without one stays
## null and keeps the procedural fallback.

const DATA_PATH := "res://resources/data/main_characters.json"
const COLLECTIBLES_PATH := "res://resources/data/characters.json"
const PORTRAIT_W := 256
const PORTRAIT_H := 384

static var _entries: Dictionary = {}
static var _loaded: bool = false


# ------------------------------------------------------------------ public API

## Character ids in stable alphabetical order: ["gerald", "lilith"].
static func ids() -> Array[String]:
	_ensure_loaded()
	var out: Array[String] = []
	for key in _entries.keys():
		out.append(str(key))
	out.sort()
	return out


## Raw JSON entry for one protagonist ({} when unknown).
static func get_entry(character_id: String) -> Dictionary:
	_ensure_loaded()
	var value: Variant = _entries.get(character_id, {})
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	return value


## CharacterDef built from the JSON entry, or null when unknown. Reuses the
## exact same parser as ContentDB so the shape cannot drift.
static func get_definition(character_id: String) -> CharacterDef:
	var entry := get_entry(character_id)
	if entry.is_empty():
		return null
	return CharacterDef.from_dict(character_id, entry)


static func has_character(character_id: String) -> bool:
	return not get_entry(character_id).is_empty()


static func is_main_character(character_id: String) -> bool:
	return bool(get_entry(character_id).get("main_character", false))


## True when a running ContentDB exposes this entry as a playable character.
## ContentDB merges the protagonists in at boot; in `--script` tools there is
## no ContentDB instance, so this returns false even though the game registers
## them. Use a scene-based tool to observe the live value.
static func is_in_content_db(character_id: String) -> bool:
	var db := _content_db()
	return db != null and db.characters.has(character_id)


# ----------------------------------------------------------------------- assets

static func asset_folder(character_id: String) -> String:
	return str(_assets(character_id).get("asset_folder", ""))


static func reference_sheet_path(character_id: String) -> String:
	return str(_assets(character_id).get("reference_sheet", ""))


## The imported reference sheet as a Texture2D, or null when missing. This is
## the full multi-view design sheet (1536x1024), NOT a portrait crop.
static func reference_texture(character_id: String) -> Texture2D:
	var path := reference_sheet_path(character_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var loaded: Resource = load(path)
	return loaded as Texture2D


static func portrait_path(character_id: String) -> String:
	return str(assets_for(character_id).get("portrait_target", ""))


## Folder holding the playable (in-game) art. Falls back to the design-reference
## folder for protagonists that only have a reference sheet.
static func playable_folder(character_id: String) -> String:
	var folder := str(assets_for(character_id).get("playable_folder", ""))
	return folder if not folder.is_empty() else asset_folder(character_id)


static func world_sheet_path(character_id: String) -> String:
	return str(assets_for(character_id).get("world_sheet", ""))


static func combat_sprite_path(character_id: String) -> String:
	return str(assets_for(character_id).get("combat_sprite", ""))


static func full_body_path(character_id: String) -> String:
	return str(assets_for(character_id).get("full_body_illustration", ""))


## The runtime SpriteFrames for the world actor, or null when no validated sheet
## exists yet. Never throws on a missing/corrupt resource.
static func world_sheet(character_id: String) -> SpriteFrames:
	var path := world_sheet_path(character_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var loaded: Resource = load(path)
	return loaded as SpriteFrames


## True when a playable world sheet exists AND exposes every (state, direction)
## animation the runtime animator asks for.
static func world_art_ready(character_id: String) -> bool:
	var sheet := world_sheet(character_id)
	if sheet == null:
		return false
	var names := sheet.get_animation_names()
	for raw_state in CharacterAnimator.EXTENDED_STATES:
		var state_name := CharacterAnimator.state_name(int(raw_state))
		for raw_dir in CharacterAnimator.ALL_DIRECTIONS:
			if not names.has(StringName("%s_%d" % [state_name, int(raw_dir)])):
				return false
	return true


## A future 256x384 RGBA8 cut-out portrait, or null. Never returns the reference
## sheet, so callers can safely treat null as "keep the procedural fallback".
static func portrait_texture(character_id: String) -> Texture2D:
	var path := portrait_path(character_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var loaded: Resource = load(path)
	var tex := loaded as Texture2D
	if tex == null:
		return null
	if tex.get_width() != PORTRAIT_W or tex.get_height() != PORTRAIT_H:
		return null
	return tex


## "reference_only" while only the design sheet exists, "portrait_ready" once a
## valid 256x384 portrait is on disk.
static func asset_status(character_id: String) -> String:
	if portrait_texture(character_id) != null:
		return "portrait_ready"
	if reference_texture(character_id) != null:
		return "reference_only"
	return "missing"


## Authoring status declared in JSON ("final", "placeholder", "missing"). This is
## metadata only; world_art_ready()/portrait_texture() are the on-disk truth.
static func art_status(character_id: String) -> String:
	return str(assets_for(character_id).get("art_status", "missing"))


# ---------------------------------------------------------------------- report

## Deterministic, honest status snapshot for tooling and documentation.
static func report() -> Dictionary:
	var per_character: Dictionary = {}
	for character_id in ids():
		var entry := get_entry(character_id)
		var def := get_definition(character_id)
		var ref := reference_texture(character_id)
		var sheet := world_sheet(character_id)
		per_character[character_id] = {
			"name": def.display_name if def != null else character_id,
			"element": def.element if def != null else "",
			"rarity": def.rarity if def != null else "",
			"asset_folder": asset_folder(character_id),
			"playable_folder": playable_folder(character_id),
			"reference_sheet": reference_sheet_path(character_id),
			"reference_loaded": ref != null,
			"reference_size": [ref.get_width(), ref.get_height()] if ref != null else [0, 0],
			"portrait_target": portrait_path(character_id),
			"portrait_ready": portrait_texture(character_id) != null,
			"asset_status": asset_status(character_id),
			"world_sheet": world_sheet_path(character_id),
			"world_animations": sheet.get_animation_names().size() if sheet != null else 0,
			"world_art_ready": world_art_ready(character_id),
			"combat_sprite": combat_sprite_path(character_id),
			"combat_sprite_ready": _texture_ready(combat_sprite_path(character_id)),
			"full_body_illustration": full_body_path(character_id),
			"full_body_ready": _texture_ready(full_body_path(character_id)),
			"art_status": art_status(character_id),
			"in_content_db": is_in_content_db(character_id),
			"playable": bool(entry.get("playable", false)),
			"recruited_by_default": bool(entry.get("recruited_by_default", false)),
		}
	return {
		"data_path": DATA_PATH,
		"ids": ids(),
		"count": ids().size(),
		"per_character": per_character,
		"content_db_running": _content_db() != null,
		"note": "Asset/authoring view for the protagonists. ContentDB merges the same definitions into its live roster; in_content_db requires a running ContentDB.",
	}


# ------------------------------------------------------------------- internals

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(DATA_PATH):
		return
	var text := FileAccess.get_file_as_string(DATA_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_entries = parsed


static func _assets(character_id: String) -> Dictionary:
	var value: Variant = get_entry(character_id).get("assets", {})
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	return value


## The "assets" block for ANY character.
##
## The protagonists (Lilith, Gerald) carry theirs in main_characters.json.
## Kael is BOTH a starting-party member and one of the twelve collectible
## characters, so his playable-art block lives with the collectible roster in
## characters.json. Look in both so one helper serves every character.
static func assets_for(character_id: String) -> Dictionary:
	var own := _assets(character_id)
	if not own.is_empty():
		return own
	return _collectible_assets(character_id)


static var _collectibles: Dictionary = {}
static var _collectibles_loaded: bool = false


static func _collectible_assets(character_id: String) -> Dictionary:
	if not _collectibles_loaded:
		_collectibles_loaded = true
		if FileAccess.file_exists(COLLECTIBLES_PATH):
			var parsed: Variant = JSON.parse_string(
				FileAccess.get_file_as_string(COLLECTIBLES_PATH))
			if typeof(parsed) == TYPE_DICTIONARY:
				_collectibles = parsed
	var entry: Variant = _collectibles.get(character_id, {})
	if typeof(entry) != TYPE_DICTIONARY:
		return {}
	var value: Variant = (entry as Dictionary).get("assets", {})
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	return value


## True when `path` is a loadable Texture2D. Missing paths are simply false.
static func _texture_ready(path: String) -> bool:
	if path.is_empty() or not ResourceLoader.exists(path):
		return false
	var loaded: Resource = load(path)
	return loaded is Texture2D


static func _content_db() -> Node:
	if not Engine.is_editor_hint() and Engine.get_main_loop() is SceneTree:
		var tree := Engine.get_main_loop() as SceneTree
		return tree.root.get_node_or_null("ContentDB")
	return null

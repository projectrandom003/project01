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
## knows about the design reference sheets and the future portrait paths.
##
## Assets live under res://assets/characters/main/<folder>/ and are design
## reference sheets, not cut-out portraits. portrait_texture() only ever returns
## a real 256x384 RGBA8 portrait, so it stays null until an artist supplies one.

const DATA_PATH := "res://resources/data/main_characters.json"
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
	return str(_assets(character_id).get("portrait_target", ""))


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


# ---------------------------------------------------------------------- report

## Deterministic, honest status snapshot for tooling and documentation.
static func report() -> Dictionary:
	var per_character: Dictionary = {}
	for character_id in ids():
		var entry := get_entry(character_id)
		var def := get_definition(character_id)
		var ref := reference_texture(character_id)
		per_character[character_id] = {
			"name": def.display_name if def != null else character_id,
			"element": def.element if def != null else "",
			"rarity": def.rarity if def != null else "",
			"asset_folder": asset_folder(character_id),
			"reference_sheet": reference_sheet_path(character_id),
			"reference_loaded": ref != null,
			"reference_size": [ref.get_width(), ref.get_height()] if ref != null else [0, 0],
			"portrait_target": portrait_path(character_id),
			"portrait_ready": portrait_texture(character_id) != null,
			"asset_status": asset_status(character_id),
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


static func _content_db() -> Node:
	if not Engine.is_editor_hint() and Engine.get_main_loop() is SceneTree:
		var tree := Engine.get_main_loop() as SceneTree
		return tree.root.get_node_or_null("ContentDB")
	return null

extends Node
## Loads and validates every data file once at boot.
## Content is data-driven: adding a character, skill, enemy or quest means
## editing JSON — never rewriting gameplay code.

const DATA_DIR := "res://resources/data/"

var characters: Dictionary = {}
var skills: Dictionary = {}
var enemies: Dictionary = {}
var enemy_groups: Dictionary = {}
var items: Dictionary = {}
var banners: Dictionary = {}
var quests: Dictionary = {}
var dialogues: Dictionary = {}
var regions: Dictionary = {}

var validation_errors: Array[String] = []


func _ready() -> void:
	_load_all()
	_validate()
	if not validation_errors.is_empty():
		for message in validation_errors:
			push_error("[ContentDB] " + message)
	else:
		print("[ContentDB] Loaded %d characters, %d skills, %d enemies, %d items." % [
			characters.size(), skills.size(), enemies.size(), items.size()
		])


func _load_all() -> void:
	skills = _load_defs("skills.json", "skill")
	characters = _load_defs("characters.json", "character")
	_load_main_characters()
	enemies = _load_defs("enemies.json", "enemy")
	enemy_groups = _read_json("enemy_groups.json")
	items = _read_json("items.json")
	banners = _read_json("banners.json")
	quests = _read_json("quests.json")
	dialogues = _read_json("dialogue.json")
	regions = _read_json("regions.json")


func _read_json(file_name: String) -> Dictionary:
	var path := DATA_DIR + file_name
	if not FileAccess.file_exists(path):
		validation_errors.append("Missing data file: " + path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		validation_errors.append("Invalid JSON in " + file_name)
		return {}
	return parsed


func _load_defs(file_name: String, kind: String) -> Dictionary:
	var raw := _read_json(file_name)
	var result: Dictionary = {}
	for key in raw.keys():
		var entry: Dictionary = raw[key]
		match kind:
			"character":
				result[key] = CharacterDef.from_dict(key, entry)
			"skill":
				result[key] = SkillDef.from_dict(key, entry)
			"enemy":
				result[key] = _enemy_def(key, entry)
	return result


## Main protagonists live in main_characters.json so the twelve collectible
## art-pipeline characters keep their authored specs. Merging them here makes
## ContentDB.get_character("gerald"/"lilith") resolve for the starting party,
## portraits, combat and saves while keeping one definition per character.
func _load_main_characters() -> void:
	var raw := _read_json("main_characters.json")
	if raw.is_empty():
		return
	# Same strict schema as characters.json, validated against the live skills.
	var skills_raw := _read_json("skills.json")
	for message in ContentValidator.validate_document("characters.json", raw, { "skills.json": skills_raw }):
		validation_errors.append(str(message))
	for key in raw.keys():
		var entry: Variant = raw[key]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		characters[str(key)] = CharacterDef.from_dict(str(key), entry)


func _enemy_def(enemy_id: String, data: Dictionary) -> Dictionary:
	var copy := data.duplicate(true)
	copy["id"] = enemy_id
	copy["name"] = str(copy.get("name", enemy_id))
	return copy


func get_character(character_id: String) -> CharacterDef:
	return characters.get(character_id, null)


func get_skill(skill_id: String) -> SkillDef:
	return skills.get(skill_id, null)


func get_item(item_id: String) -> Dictionary:
	return items.get(item_id, {})


func get_enemy(enemy_id: String) -> Dictionary:
	return enemies.get(enemy_id, {})


func get_enemy_group(group_id: String) -> Dictionary:
	return enemy_groups.get(group_id, {})


func get_banner(banner_id: String) -> Dictionary:
	return banners.get(banner_id, {})


func get_quest(quest_id: String) -> Dictionary:
	return quests.get(quest_id, {})


func get_dialogue(dialogue_id: String) -> Dictionary:
	return dialogues.get(dialogue_id, {})


func get_region(region_id: String) -> Dictionary:
	return regions.get(region_id, {})


func character_ids() -> Array:
	return characters.keys()


func characters_of_rarity(rarity: String) -> Array:
	var result: Array = []
	for character_id in characters.keys():
		if characters[character_id].rarity == rarity:
			result.append(character_id)
	return result


func _validate() -> void:
	# Strict, data-only validation lives in ContentValidator so the same rules
	# run at boot, in tests and in the CI content check.
	var report := ContentValidator.validate_all(DATA_DIR)
	for message in report.get("errors", []):
		var text := str(message)
		if not validation_errors.has(text):
			validation_errors.append(text)

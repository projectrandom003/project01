class_name ContentValidator
extends RefCounted
## Strict, data-only validation for every JSON content file.
##
## This class does not depend on ContentDB or any scene. It is used by:
##   - ContentDB at boot,
##   - tools/validate_content.gd in CI,
##   - tests with synthetic documents.
##
## Errors are formatted as:
##   characters.json → characters.lyra_vey.base.hp: expected number, got string

const DATA_DIR := "res://resources/data/"
const DATA_FILES := [
	"characters.json",
	"skills.json",
	"enemies.json",
	"enemy_groups.json",
	"items.json",
	"banners.json",
	"quests.json",
	"dialogue.json",
	"regions.json",
]

const RARITIES := ["common", "rare", "epic", "legendary", "mythic"]
const ELEMENTS := ["fire", "wind", "earth", "water", "light", "dark", "neutral"]
const SKILL_KINDS := ["damage", "heal", "shield", "buff"]
const TARGETS := ["single_enemy", "all_enemies", "single_ally", "all_allies", "self"]
const STATUS_IDS := [
	"burn", "poison", "regen", "stun", "blind",
	"atk_up", "atk_down", "def_up", "def_down", "spd_up", "spd_down", "shield",
]
const ITEM_CATEGORIES := ["currency", "material", "equipment"]
const EQUIPMENT_SLOTS := ["weapon", "armor", "accessory"]
const EQUIPMENT_STATS := ["hp", "atk", "def", "spd", "crit"]
const QUEST_STEP_TYPES := ["talk", "kill"]
const BANNER_TYPES := ["standard", "limited"]
# The full set of Phase-3 prop kinds ProceduralArt / GreenwardStyle can paint.
# (The original 12 plus every additional tree/ground/structure/magical/water/
# wildlife kind.) Keeping this in sync with GreenwardStyle.ALL_PROP_KINDS fixes a
# latent inconsistency where regions.json could only declare the first 12 kinds.
const PROP_TYPES := [
	"glade_tree", "ancient_tree", "rock", "flower", "mushroom", "bush",
	"crystal", "hut", "waypoint", "lantern", "fence", "ruin_pillar",
	"willow_tree", "birch_tree", "pine_tree", "blossom_tree", "dead_tree",
	"fern", "tall_grass", "reeds", "lily_pad", "moss_rock", "pebble",
	"flower_cluster", "berry_bush", "glow_mushroom", "cottage",
	"wooden_bridge", "stone_bridge", "dock", "well", "shrine", "ruin_arch",
	"signpost", "barrel", "cart", "spirit_bloom", "rune_stone",
	"crystal_cluster", "wisp_lantern", "waterfall", "river_rock",
	"foam_ripple", "butterfly", "moth", "bird", "firefly_sprite",
	"watchtower", "market_stall", "stone_wall", "gazebo", "banner_post", "moon_shrine",
	# PART 5: cool Moonpetal Hollow + village-approach silhouettes (4 new kinds).
	"birch_grove", "moon_lantern", "stone_path", "village_gate",
]
const QUEST_STATES := ["not_started", "active", "complete"]
const WEATHER_BIAS_STATES := ["clear", "mist", "rain", "pollen_bloom"]
const CONNECTION_KINDS := ["gate", "bridge", "portal", "path"]
const ID_CHARS := "abcdefghijklmnopqrstuvwxyz0123456789_"


# ------------------------------------------------------------------ public API

static func validate_all(data_dir: String = DATA_DIR) -> Dictionary:
	var parsed: Dictionary = {}
	var errors: Array[String] = []

	for raw_file_name in DATA_FILES:
		var file_name := str(raw_file_name)
		var path := data_dir + file_name
		if not FileAccess.file_exists(path):
			errors.append("%s: file is missing" % file_name)
			continue
		var text := FileAccess.get_file_as_string(path)
		errors.append_array(_scan_duplicate_keys(file_name, text))
		var json := JSON.new()
		var parse_error := json.parse(text)
		if parse_error != OK:
			errors.append("%s: invalid JSON — %s (line %d)" % [
				file_name, json.get_error_message(), json.get_error_line()
			])
			continue
		if typeof(json.data) != TYPE_DICTIONARY:
			errors.append("%s: top-level JSON value must be an object" % file_name)
			continue
		parsed[file_name] = json.data

	for raw_file_name in parsed.keys():
		var file_name := str(raw_file_name)
		errors.append_array(_validate_document(file_name, parsed[raw_file_name], parsed))

	return { "data": parsed, "errors": errors }


static func validate_text(file_name: String, text: String, context: Dictionary = {}) -> Array[String]:
	var errors: Array[String] = []
	errors.append_array(_scan_duplicate_keys(file_name, text))

	var json := JSON.new()
	var parse_error := json.parse(text)
	if parse_error != OK:
		errors.append("%s: invalid JSON — %s (line %d)" % [
			file_name, json.get_error_message(), json.get_error_line()
		])
		return errors
	if typeof(json.data) != TYPE_DICTIONARY:
		errors.append("%s: top-level JSON value must be an object" % file_name)
		return errors

	var merged := context.duplicate(true)
	merged[file_name] = json.data
	errors.append_array(_validate_document(file_name, json.data, merged))
	return errors


static func validate_document(file_name: String, data: Dictionary, context: Dictionary = {}) -> Array[String]:
	var merged := context.duplicate(true)
	merged[file_name] = data
	return _validate_document(file_name, data, merged)


# --------------------------------------------------------------------- dispatch

static func _validate_document(file_name: String, data: Dictionary, context: Dictionary) -> Array[String]:
	match file_name:
		"characters.json":
			return _validate_characters(data, context)
		"skills.json":
			return _validate_skills(data)
		"enemies.json":
			return _validate_enemies(data, context)
		"enemy_groups.json":
			return _validate_enemy_groups(data, context)
		"items.json":
			return _validate_items(data)
		"banners.json":
			return _validate_banners(data, context)
		"quests.json":
			return _validate_quests(data, context)
		"dialogue.json":
			return _validate_dialogue(data, context)
		"regions.json":
			return _validate_regions(data, context)
	return ["%s: unknown content file" % file_name]


# ------------------------------------------------------------------ characters

static func _validate_characters(data: Dictionary, context: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var file := "characters.json"
	var root := "characters"
	var skills: Dictionary = context.get("skills.json", {})

	for raw_id in data.keys():
		var id := str(raw_id)
		var path := root + "." + id
		if not _valid_id(id):
			_err(errors, file, path, "ID must be lower_snake_case")
		var entry: Variant = data[raw_id]
		if typeof(entry) != TYPE_DICTIONARY:
			_err(errors, file, path, "expected an object")
			continue
		var character: Dictionary = entry

		_require_nonempty_string(character, "name", path, file, errors)
		_require_enum(character, "element", ELEMENTS, path, file, errors)
		_require_enum(character, "rarity", RARITIES, path, file, errors)
		_optional_string(character, "title", path, file, errors)
		_optional_string(character, "race", path, file, errors)
		_optional_string(character, "role", path, file, errors)
		_optional_string(character, "lore", path, file, errors)

		var base = _require(character, "base", "dictionary", path, file, errors)
		if typeof(base) == TYPE_DICTIONARY:
			_validate_stats(base, path + ".base", file, errors)

		var skill_list = _require(character, "skills", "array", path, file, errors)
		if typeof(skill_list) == TYPE_ARRAY:
			if skill_list.size() < 2:
				_err(errors, file, path + ".skills", "must contain at least 2 active skills")
			for index in skill_list.size():
				var skill_id: Variant = skill_list[index]
				var skill_path := "%s.skills[%d]" % [path, index]
				if typeof(skill_id) != TYPE_STRING:
					_err(errors, file, skill_path, "expected a skill ID string")
					continue
				if not skills.has(str(skill_id)):
					_err(errors, file, skill_path, "references missing skill '%s'" % str(skill_id))

		var ultimate := _optional_string(character, "ultimate", path, file, errors)
		if not ultimate.is_empty() and not skills.has(ultimate):
			_err(errors, file, path + ".ultimate", "references missing skill '%s'" % ultimate)

		var passive = character.get("passive", null)
		if passive != null:
			var passive_path := path + ".passive"
			if typeof(passive) != TYPE_DICTIONARY:
				_err(errors, file, passive_path, "expected an object")
			else:
				var passive_dict: Dictionary = passive
				var passive_id := _require_nonempty_string(passive_dict, "id", passive_path, file, errors)
				_require_nonempty_string(passive_dict, "name", passive_path, file, errors)
				_require_nonempty_string(passive_dict, "text", passive_path, file, errors)
				if not passive_id.is_empty() and not PassiveEffects.is_supported(passive_id):
					_err(errors, file, passive_path + ".id", "unknown passive '%s'" % passive_id)

		var palette = _require(character, "palette", "dictionary", path, file, errors)
		if typeof(palette) == TYPE_DICTIONARY:
			_validate_palette(palette, ["hair", "primary", "secondary", "accent", "skin"], path + ".palette", file, errors)

		if character.has("portrait_seed"):
			_require_int(character, "portrait_seed", path, file, errors, 0)

	return errors


# ---------------------------------------------------------------------- skills

static func _validate_skills(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var file := "skills.json"
	var root := "skills"

	for raw_id in data.keys():
		var id := str(raw_id)
		var path := root + "." + id
		if not _valid_id(id):
			_err(errors, file, path, "ID must be lower_snake_case")
		var entry: Variant = data[raw_id]
		if typeof(entry) != TYPE_DICTIONARY:
			_err(errors, file, path, "expected an object")
			continue
		var skill: Dictionary = entry

		_require_nonempty_string(skill, "name", path, file, errors)
		_optional_string(skill, "description", path, file, errors)
		_require_enum(skill, "element", ELEMENTS, path, file, errors)
		var kind := _require_enum(skill, "kind", SKILL_KINDS, path, file, errors)
		var power := _require_number(skill, "power", path, file, errors, 0.0)
		_require_enum(skill, "target", TARGETS, path, file, errors)
		_require_number(skill, "energy_gain", path, file, errors, 0.0, INF, false)
		_require_number(skill, "crit_bonus", path, file, errors, 0.0, 1.0, false)
		_require_number(skill, "lifesteal", path, file, errors, 0.0, 1.0, false)
		_require_bool(skill, "cleanse", path, file, errors, false)
		_require_bool(skill, "ultimate", path, file, errors, false)

		var statuses: Variant = skill.get("statuses", [])
		if statuses != null:
			_validate_status_list(statuses, path + ".statuses", file, errors)

		if kind in ["damage", "heal", "shield"] and power <= 0.0:
			_err(errors, file, path + ".power", "%s skills must have power > 0" % kind)
		if kind == "buff":
			if typeof(statuses) != TYPE_ARRAY or statuses.is_empty():
				_err(errors, file, path + ".statuses", "buff skills must apply at least one status")

	return errors


static func _validate_status_list(statuses: Variant, path: String, file: String, errors: Array[String]) -> void:
	if typeof(statuses) != TYPE_ARRAY:
		_err(errors, file, path, "expected an array")
		return
	var list: Array = statuses
	for index in list.size():
		var entry: Variant = list[index]
		var status_path := "%s[%d]" % [path, index]
		if typeof(entry) != TYPE_DICTIONARY:
			_err(errors, file, status_path, "expected an object")
			continue
		var status: Dictionary = entry
		var status_id := _require_enum(status, "id", STATUS_IDS, status_path, file, errors)
		_require_number(status, "chance", status_path, file, errors, 0.0, 1.0)
		_require_int(status, "turns", status_path, file, errors, 1)
		var potency := _require_number(status, "potency", status_path, file, errors, 0.0)
		if status_id in ["shield", "burn", "poison", "regen"] and potency <= 0.0:
			_err(errors, file, status_path + ".potency", "%s status must have potency > 0" % status_id)


# --------------------------------------------------------------------- enemies

static func _validate_enemies(data: Dictionary, context: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var file := "enemies.json"
	var root := "enemies"
	var skills: Dictionary = context.get("skills.json", {})

	for raw_id in data.keys():
		var id := str(raw_id)
		var path := root + "." + id
		if not _valid_id(id):
			_err(errors, file, path, "ID must be lower_snake_case")
		var entry: Variant = data[raw_id]
		if typeof(entry) != TYPE_DICTIONARY:
			_err(errors, file, path, "expected an object")
			continue
		var enemy: Dictionary = entry

		_require_nonempty_string(enemy, "name", path, file, errors)
		_require_enum(enemy, "element", ELEMENTS, path, file, errors)
		_require_enum(enemy, "rarity", RARITIES, path, file, errors)
		_optional_string(enemy, "role", path, file, errors)
		_optional_string(enemy, "lore", path, file, errors)

		var base = _require(enemy, "base", "dictionary", path, file, errors)
		if typeof(base) == TYPE_DICTIONARY:
			_validate_stats(base, path + ".base", file, errors)

		var skill_list = _require(enemy, "skills", "array", path, file, errors)
		if typeof(skill_list) == TYPE_ARRAY:
			if skill_list.is_empty():
				_err(errors, file, path + ".skills", "must contain at least one skill")
			for index in skill_list.size():
				var skill_id: Variant = skill_list[index]
				var skill_path := "%s.skills[%d]" % [path, index]
				if typeof(skill_id) != TYPE_STRING:
					_err(errors, file, skill_path, "expected a skill ID string")
					continue
				if not skills.has(str(skill_id)):
					_err(errors, file, skill_path, "references missing skill '%s'" % str(skill_id))

		var ultimate := _optional_string(enemy, "ultimate", path, file, errors)
		if not ultimate.is_empty() and not skills.has(ultimate):
			_err(errors, file, path + ".ultimate", "references missing skill '%s'" % ultimate)

		var palette = _require(enemy, "palette", "dictionary", path, file, errors)
		if typeof(palette) == TYPE_DICTIONARY:
			_validate_palette(palette, ["primary", "secondary", "accent"], path + ".palette", file, errors)

		var phases: Variant = enemy.get("phases", null)
		if phases != null:
			_validate_phases(phases, path + ".phases", file, errors)

	return errors


static func _validate_phases(phases: Variant, path: String, file: String, errors: Array[String]) -> void:
	if typeof(phases) != TYPE_ARRAY:
		_err(errors, file, path, "expected an array")
		return
	var list: Array = phases
	for index in list.size():
		var entry: Variant = list[index]
		var phase_path := "%s[%d]" % [path, index]
		if typeof(entry) != TYPE_DICTIONARY:
			_err(errors, file, phase_path, "expected an object")
			continue
		var phase: Dictionary = entry
		_require_number(phase, "hp_below", phase_path, file, errors, 0.0, 1.0)
		_require_nonempty_string(phase, "message", phase_path, file, errors)
		if phase.has("status"):
			var status: Variant = phase["status"]
			if typeof(status) != TYPE_DICTIONARY:
				_err(errors, file, phase_path + ".status", "expected an object")
			else:
				var status_dict: Dictionary = status
				_require_enum(status_dict, "id", STATUS_IDS, phase_path + ".status", file, errors)
				_require_int(status_dict, "turns", phase_path + ".status", file, errors, 1)
				_require_number(status_dict, "potency", phase_path + ".status", file, errors, 0.0)


# ---------------------------------------------------------------- enemy groups

static func _validate_enemy_groups(data: Dictionary, context: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var file := "enemy_groups.json"
	var root := "enemy_groups"
	var enemies: Dictionary = context.get("enemies.json", {})
	var items: Dictionary = context.get("items.json", {})
	var regions: Dictionary = context.get("regions.json", {})

	for raw_id in data.keys():
		var id := str(raw_id)
		var path := root + "." + id
		if not _valid_id(id):
			_err(errors, file, path, "ID must be lower_snake_case")
		var entry: Variant = data[raw_id]
		if typeof(entry) != TYPE_DICTIONARY:
			_err(errors, file, path, "expected an object")
			continue
		var group: Dictionary = entry

		_require_nonempty_string(group, "name", path, file, errors)
		var region := _require_nonempty_string(group, "region", path, file, errors)
		if not region.is_empty() and not regions.has(region):
			_err(errors, file, path + ".region", "references missing region '%s'" % region)
		_require_int(group, "level", path, file, errors, 1)

		var enemy_list = _require(group, "enemies", "array", path, file, errors)
		if typeof(enemy_list) == TYPE_ARRAY:
			if enemy_list.is_empty():
				_err(errors, file, path + ".enemies", "must contain at least one enemy")
			for index in enemy_list.size():
				var enemy_id: Variant = enemy_list[index]
				var enemy_path := "%s.enemies[%d]" % [path, index]
				if typeof(enemy_id) != TYPE_STRING:
					_err(errors, file, enemy_path, "expected an enemy ID string")
					continue
				if not enemies.has(str(enemy_id)):
					_err(errors, file, enemy_path, "references missing enemy '%s'" % str(enemy_id))

		var rewards = _require(group, "rewards", "dictionary", path, file, errors)
		if typeof(rewards) == TYPE_DICTIONARY:
			_validate_rewards(rewards, path + ".rewards", file, errors, items)

		_require_bool(group, "elite", path, file, errors, false)
		_require_bool(group, "boss", path, file, errors, false)

		var quest_kills: Variant = group.get("quest_kills", null)
		if quest_kills != null:
			if typeof(quest_kills) != TYPE_DICTIONARY:
				_err(errors, file, path + ".quest_kills", "expected an object")
			else:
				var kills: Dictionary = quest_kills
				for raw_enemy_id in kills.keys():
					var enemy_id := str(raw_enemy_id)
					if not enemies.has(enemy_id):
						_err(errors, file, path + ".quest_kills." + enemy_id, "references missing enemy '%s'" % enemy_id)
					var count: Variant = kills[raw_enemy_id]
					if not _is_positive_int(count):
						_err(errors, file, path + ".quest_kills." + enemy_id, "expected a positive integer")

	return errors


# ---------------------------------------------------------------------- items

static func _validate_items(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var file := "items.json"
	var root := "items"

	for raw_id in data.keys():
		var id := str(raw_id)
		var path := root + "." + id
		if not _valid_id(id):
			_err(errors, file, path, "ID must be lower_snake_case")
		var entry: Variant = data[raw_id]
		if typeof(entry) != TYPE_DICTIONARY:
			_err(errors, file, path, "expected an object")
			continue
		var item: Dictionary = entry

		_require_nonempty_string(item, "name", path, file, errors)
		_require_nonempty_string(item, "description", path, file, errors)
		var category := _require_enum(item, "category", ITEM_CATEGORIES, path, file, errors)
		_optional_string(item, "icon", path, file, errors)
		if item.has("color"):
			var color := _optional_string(item, "color", path, file, errors)
			if not color.is_empty() and not _is_color(color):
				_err(errors, file, path + ".color", "expected a #rrggbb colour")
		if item.has("rarity"):
			_require_enum(item, "rarity", RARITIES, path, file, errors)

		if category == "equipment":
			_require_enum(item, "slot", EQUIPMENT_SLOTS, path, file, errors)
			if item.has("element"):
				_require_enum(item, "element", ELEMENTS, path, file, errors)
			var stats = _require(item, "stats", "dictionary", path, file, errors)
			if typeof(stats) == TYPE_DICTIONARY:
				_validate_equipment_stats(stats, path + ".stats", file, errors)
			if item.has("level"):
				_require_int(item, "level", path, file, errors, 1)
		else:
			if item.has("slot"):
				_err(errors, file, path + ".slot", "%s items must not define an equipment slot" % category)
			if item.has("stats"):
				_err(errors, file, path + ".stats", "%s items must not define equipment stats" % category)

	return errors


static func _validate_equipment_stats(stats: Dictionary, path: String, file: String, errors: Array[String]) -> void:
	if stats.is_empty():
		_err(errors, file, path, "equipment must define at least one stat")
		return
	for raw_key in stats.keys():
		var key := str(raw_key)
		var stat_path := path + "." + key
		if not EQUIPMENT_STATS.has(key):
			_err(errors, file, stat_path, "unknown equipment stat")
			continue
		var value: Variant = stats[raw_key]
		if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
			_err(errors, file, stat_path, "expected a number")
			continue
		var number := float(value)
		if key == "crit":
			if number < 0.0 or number > 1.0:
				_err(errors, file, stat_path, "crit must be between 0 and 1")
		elif number < 0.0:
			_err(errors, file, stat_path, "stat must be >= 0")


# -------------------------------------------------------------------- banners

static func _validate_banners(data: Dictionary, context: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var file := "banners.json"
	var root := "banners"
	var characters: Dictionary = context.get("characters.json", {})
	var items: Dictionary = context.get("items.json", {})

	for raw_id in data.keys():
		var id := str(raw_id)
		var path := root + "." + id
		if not _valid_id(id):
			_err(errors, file, path, "ID must be lower_snake_case")
		var entry: Variant = data[raw_id]
		if typeof(entry) != TYPE_DICTIONARY:
			_err(errors, file, path, "expected an object")
			continue
		var banner: Dictionary = entry

		_require_nonempty_string(banner, "name", path, file, errors)
		_optional_string(banner, "subtitle", path, file, errors)
		_require_enum(banner, "type", BANNER_TYPES, path, file, errors)
		_require_number(banner, "featured_rate", path, file, errors, 0.0, 1.0)
		_require_int(banner, "hard_pity", path, file, errors, 1)
		var featured_pity := _require_int(banner, "featured_pity", path, file, errors, 1)
		var hard_pity := int(banner.get("hard_pity", 0))
		if featured_pity > 0 and hard_pity > 0 and featured_pity < hard_pity:
			_err(errors, file, path + ".featured_pity", "must be greater than or equal to hard_pity")
		_require_bool(banner, "ten_pull_epic_guarantee", path, file, errors)

		var rates = _require(banner, "rates", "dictionary", path, file, errors)
		var rate_total := 0.0
		if typeof(rates) == TYPE_DICTIONARY:
			var rate_dict: Dictionary = rates
			for rarity in RARITIES:
				if not rate_dict.has(rarity):
					_err(errors, file, path + ".rates." + rarity, "required rarity rate is missing")
					continue
				var rate: Variant = rate_dict[rarity]
				if typeof(rate) != TYPE_INT and typeof(rate) != TYPE_FLOAT:
					_err(errors, file, path + ".rates." + rarity, "expected a number")
					continue
				var value := float(rate)
				if value < 0.0 or value > 1.0:
					_err(errors, file, path + ".rates." + rarity, "rate must be between 0 and 1")
				rate_total += value
			for raw_rarity in rate_dict.keys():
				if not RARITIES.has(str(raw_rarity)):
					_err(errors, file, path + ".rates." + str(raw_rarity), "unknown rarity")
			if absf(rate_total - 1.0) > 0.02:
				_err(errors, file, path + ".rates", "rates must sum to 1.0 (got %.3f)" % rate_total)

		var cost = _require(banner, "cost", "dictionary", path, file, errors)
		if typeof(cost) == TYPE_DICTIONARY:
			var cost_dict: Dictionary = cost
			var currency := _require_nonempty_string(cost_dict, "currency", path + ".cost", file, errors)
			if not currency.is_empty():
				var currency_item: Dictionary = items.get(currency, {})
				if currency_item.is_empty():
					_err(errors, file, path + ".cost.currency", "references missing item '%s'" % currency)
				elif str(currency_item.get("category", "")) != "currency":
					_err(errors, file, path + ".cost.currency", "item '%s' is not a currency" % currency)
			var single := _require_int(cost_dict, "single", path + ".cost", file, errors, 1)
			var ten := _require_int(cost_dict, "ten", path + ".cost", file, errors, 1)
			if single > 0 and ten > 0 and ten > single * 10:
				_err(errors, file, path + ".cost.ten", "ten-pull cost cannot exceed ten single pulls")

		var pool = _require(banner, "pool", "dictionary", path, file, errors)
		var seen_characters: Dictionary = {}
		if typeof(pool) == TYPE_DICTIONARY:
			var pool_dict: Dictionary = pool
			for rarity in RARITIES:
				if not pool_dict.has(rarity):
					_err(errors, file, path + ".pool." + rarity, "required rarity pool is missing")
					continue
				var pool_list: Variant = pool_dict[rarity]
				if typeof(pool_list) != TYPE_ARRAY:
					_err(errors, file, path + ".pool." + rarity, "expected an array")
					continue
				if pool_list.is_empty():
					_err(errors, file, path + ".pool." + rarity, "pool must not be empty")
				for index in pool_list.size():
					var character_id: Variant = pool_list[index]
					var character_path := "%s.pool.%s[%d]" % [path, rarity, index]
					if typeof(character_id) != TYPE_STRING:
						_err(errors, file, character_path, "expected a character ID string")
						continue
					var character_key := str(character_id)
					if not characters.has(character_key):
						_err(errors, file, character_path, "references missing character '%s'" % character_key)
						continue
					var character: Variant = characters[character_key]
					if typeof(character) == TYPE_DICTIONARY and str(character.get("rarity", "")) != rarity:
						_err(errors, file, character_path, "character '%s' is not %s rarity" % [character_key, rarity])
					if seen_characters.has(character_key):
						_err(errors, file, character_path, "character '%s' appears more than once in the pool" % character_key)
					seen_characters[character_key] = true
			for raw_rarity in pool_dict.keys():
				if not RARITIES.has(str(raw_rarity)):
					_err(errors, file, path + ".pool." + str(raw_rarity), "unknown rarity")

		var featured = _require(banner, "featured", "array", path, file, errors)
		if typeof(featured) == TYPE_ARRAY:
			if featured.is_empty():
				_err(errors, file, path + ".featured", "must contain at least one character")
			for index in featured.size():
				var character_id: Variant = featured[index]
				var featured_path := "%s.featured[%d]" % [path, index]
				if typeof(character_id) != TYPE_STRING:
					_err(errors, file, featured_path, "expected a character ID string")
					continue
				var character_key := str(character_id)
				if not characters.has(character_key):
					_err(errors, file, featured_path, "references missing character '%s'" % character_key)
				elif not seen_characters.has(character_key):
					_err(errors, file, featured_path, "featured character '%s' is not in the banner pool" % character_key)

	return errors


# --------------------------------------------------------------------- quests

static func _validate_quests(data: Dictionary, context: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var file := "quests.json"
	var root := "quests"
	var regions: Dictionary = context.get("regions.json", {})
	var dialogues: Dictionary = context.get("dialogue.json", {})
	var enemies: Dictionary = context.get("enemies.json", {})
	var items: Dictionary = context.get("items.json", {})
	var quests: Dictionary = context.get("quests.json", {})

	for raw_id in data.keys():
		var id := str(raw_id)
		var path := root + "." + id
		if not _valid_id(id):
			_err(errors, file, path, "ID must be lower_snake_case")
		var entry: Variant = data[raw_id]
		if typeof(entry) != TYPE_DICTIONARY:
			_err(errors, file, path, "expected an object")
			continue
		var quest: Dictionary = entry

		_require_nonempty_string(quest, "name", path, file, errors)
		var region := _require_nonempty_string(quest, "region", path, file, errors)
		if not region.is_empty() and not regions.has(region):
			_err(errors, file, path + ".region", "references missing region '%s'" % region)
		_require_nonempty_string(quest, "summary", path, file, errors)

		if quest.has("requires"):
			var requires := _optional_string(quest, "requires", path, file, errors)
			if not requires.is_empty():
				if requires == id:
					_err(errors, file, path + ".requires", "a quest cannot require itself")
				elif not quests.has(requires):
					_err(errors, file, path + ".requires", "references missing quest '%s'" % requires)

		var steps = _require(quest, "steps", "array", path, file, errors)
		if typeof(steps) == TYPE_ARRAY:
			if steps.is_empty():
				_err(errors, file, path + ".steps", "must contain at least one step")
			for index in steps.size():
				var step: Variant = steps[index]
				var step_path := "%s.steps[%d]" % [path, index]
				if typeof(step) != TYPE_DICTIONARY:
					_err(errors, file, step_path, "expected an object")
					continue
				var step_dict: Dictionary = step
				var step_type := _require_enum(step_dict, "type", QUEST_STEP_TYPES, step_path, file, errors)
				var target := _require_nonempty_string(step_dict, "target", step_path, file, errors)
				_require_nonempty_string(step_dict, "text", step_path, file, errors)
				var step_grid: Variant = step_dict.get("grid", null)
				if step_grid != null:
					_validate_grid(step_grid, step_path + ".grid", file, errors)
				if step_type == "talk" and not target.is_empty() and not dialogues.has(target):
					_err(errors, file, step_path + ".target", "references missing dialogue '%s'" % target)
				if step_type == "kill":
					if not target.is_empty() and not enemies.has(target):
						_err(errors, file, step_path + ".target", "references missing enemy '%s'" % target)
					_require_int(step_dict, "count", step_path, file, errors, 1)

		var rewards = _require(quest, "rewards", "dictionary", path, file, errors)
		if typeof(rewards) == TYPE_DICTIONARY:
			_validate_rewards(rewards, path + ".rewards", file, errors, items)

	return errors


# ------------------------------------------------------------------- dialogue

static func _validate_dialogue(data: Dictionary, context: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var file := "dialogue.json"
	var root := "dialogue"
	var quests: Dictionary = context.get("quests.json", {})
	var characters: Dictionary = context.get("characters.json", {})
	var items: Dictionary = context.get("items.json", {})

	for raw_id in data.keys():
		var id := str(raw_id)
		var path := root + "." + id
		if not _valid_id(id):
			_err(errors, file, path, "ID must be lower_snake_case")
		var entry: Variant = data[raw_id]
		if typeof(entry) != TYPE_DICTIONARY:
			_err(errors, file, path, "expected an object")
			continue
		var dialogue: Dictionary = entry

		var nodes = _require(dialogue, "nodes", "dictionary", path, file, errors)
		var node_ids: Dictionary = {}
		if typeof(nodes) == TYPE_DICTIONARY:
			var node_dict: Dictionary = nodes
			if node_dict.is_empty():
				_err(errors, file, path + ".nodes", "must contain at least one node")
			for raw_node_id in node_dict.keys():
				node_ids[str(raw_node_id)] = true

		var start := _require_nonempty_string(dialogue, "start", path, file, errors)
		if not start.is_empty() and not node_ids.has(start):
			_err(errors, file, path + ".start", "references missing node '%s'" % start)

		var start_rules: Variant = dialogue.get("start_rules", null)
		if start_rules != null:
			if typeof(start_rules) != TYPE_ARRAY:
				_err(errors, file, path + ".start_rules", "expected an array")
			else:
				var rules: Array = start_rules
				for index in rules.size():
					var rule: Variant = rules[index]
					var rule_path := "%s.start_rules[%d]" % [path, index]
					if typeof(rule) != TYPE_DICTIONARY:
						_err(errors, file, rule_path, "expected an object")
						continue
					var rule_dict: Dictionary = rule
					var condition := _require_string(rule_dict, "if", rule_path, file, errors)
					var node_id := _require_nonempty_string(rule_dict, "node", rule_path, file, errors)
					if not node_id.is_empty() and not node_ids.has(node_id):
						_err(errors, file, rule_path + ".node", "references missing node '%s'" % node_id)
					_validate_condition(condition, rule_path + ".if", file, errors, quests, characters)

		if typeof(nodes) == TYPE_DICTIONARY:
			var node_dict: Dictionary = nodes
			for raw_node_id in node_dict.keys():
				var node_id := str(raw_node_id)
				var node_path := "%s.nodes.%s" % [path, node_id]
				var node: Variant = node_dict[raw_node_id]
				if typeof(node) != TYPE_DICTIONARY:
					_err(errors, file, node_path, "expected an object")
					continue
				var node_dict_value: Dictionary = node
				_require_nonempty_string(node_dict_value, "speaker", node_path, file, errors)
				_require_nonempty_string(node_dict_value, "text", node_path, file, errors)

				var portrait: Variant = node_dict_value.get("portrait", null)
				if portrait != null:
					if typeof(portrait) != TYPE_DICTIONARY:
						_err(errors, file, node_path + ".portrait", "expected an object")
					else:
						_validate_palette(
							portrait,
							["hair", "primary", "secondary", "accent", "skin"],
							node_path + ".portrait",
							file,
							errors
						)

				var next := _optional_string(node_dict_value, "next", node_path, file, errors)
				if not next.is_empty() and not node_ids.has(next):
					_err(errors, file, node_path + ".next", "references missing node '%s'" % next)

				var choices: Variant = node_dict_value.get("choices", null)
				if choices != null:
					if typeof(choices) != TYPE_ARRAY:
						_err(errors, file, node_path + ".choices", "expected an array")
					else:
						var choice_list: Array = choices
						for index in choice_list.size():
							var choice: Variant = choice_list[index]
							var choice_path := "%s.choices[%d]" % [node_path, index]
							if typeof(choice) != TYPE_DICTIONARY:
								_err(errors, file, choice_path, "expected an object")
								continue
							var choice_dict: Dictionary = choice
							_require_nonempty_string(choice_dict, "text", choice_path, file, errors)
							var choice_next := _optional_string(choice_dict, "next", choice_path, file, errors)
							if not choice_next.is_empty() and not node_ids.has(choice_next):
								_err(errors, file, choice_path + ".next", "references missing node '%s'" % choice_next)
							var action := _optional_string(choice_dict, "action", choice_path, file, errors)
							_validate_action(action, choice_path + ".action", file, errors, quests, characters, items)

	return errors


static func _validate_condition(
	condition: String,
	path: String,
	file: String,
	errors: Array[String],
	quests: Dictionary,
	characters: Dictionary
) -> void:
	if condition.is_empty():
		return
	var parts := condition.split(":", true, 2)
	match parts[0]:
		"quest_state":
			if parts.size() != 3:
				_err(errors, file, path, "expected quest_state:<quest_id>:<state>")
				return
			if not quests.has(parts[1]):
				_err(errors, file, path, "references missing quest '%s'" % parts[1])
			if not QUEST_STATES.has(parts[2]):
				_err(errors, file, path, "invalid quest state '%s'" % parts[2])
		"quest_ready", "quest_active", "quest_complete":
			if parts.size() < 2:
				_err(errors, file, path, "expected %s:<quest_id>" % parts[0])
			elif not quests.has(parts[1]):
				_err(errors, file, path, "references missing quest '%s'" % parts[1])
		"has_character":
			if parts.size() < 2:
				_err(errors, file, path, "expected has_character:<character_id>")
			elif not characters.has(parts[1]):
				_err(errors, file, path, "references missing character '%s'" % parts[1])
		"level_at_least":
			if parts.size() < 2 or not parts[1].is_valid_int():
				_err(errors, file, path, "expected level_at_least:<positive integer>")
			elif int(parts[1]) < 1:
				_err(errors, file, path, "level must be at least 1")
		_:
			_err(errors, file, path, "unknown condition '%s'" % parts[0])


static func _validate_action(
	action: String,
	path: String,
	file: String,
	errors: Array[String],
	quests: Dictionary,
	characters: Dictionary,
	items: Dictionary
) -> void:
	if action.is_empty():
		return
	var parts := action.split(":", true, 2)
	match parts[0]:
		"start_quest", "complete_quest":
			if parts.size() < 2:
				_err(errors, file, path, "expected %s:<quest_id>" % parts[0])
			elif not quests.has(parts[1]):
				_err(errors, file, path, "references missing quest '%s'" % parts[1])
		"add_item":
			if parts.size() < 2:
				_err(errors, file, path, "expected add_item:<item_id>[:count]")
			elif not items.has(parts[1]):
				_err(errors, file, path, "references missing item '%s'" % parts[1])
			if parts.size() >= 3 and (not parts[2].is_valid_int() or int(parts[2]) <= 0):
				_err(errors, file, path, "item count must be a positive integer")
		"add_currency":
			if parts.size() < 3:
				_err(errors, file, path, "expected add_currency:<currency_id>:<amount>")
				return
			var item: Dictionary = items.get(parts[1], {})
			if item.is_empty():
				_err(errors, file, path, "references missing item '%s'" % parts[1])
			elif str(item.get("category", "")) != "currency":
				_err(errors, file, path, "item '%s' is not a currency" % parts[1])
			if not parts[2].is_valid_int() or int(parts[2]) <= 0:
				_err(errors, file, path, "currency amount must be a positive integer")
		"set_flag":
			if parts.size() < 3 or parts[1].is_empty():
				_err(errors, file, path, "expected set_flag:<key>:<value>")
		"toast":
			if parts.size() < 2 or parts[1].is_empty():
				_err(errors, file, path, "expected toast:<text>")
		_:
			_err(errors, file, path, "unknown action '%s'" % parts[0])


# -------------------------------------------------------------------- regions

static func _validate_regions(data: Dictionary, context: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var file := "regions.json"
	var root := "regions"
	var groups: Dictionary = context.get("enemy_groups.json", {})

	for raw_id in data.keys():
		var id := str(raw_id)
		var path := root + "." + id
		if not _valid_id(id):
			_err(errors, file, path, "ID must be lower_snake_case")
		var entry: Variant = data[raw_id]
		if typeof(entry) != TYPE_DICTIONARY:
			_err(errors, file, path, "expected an object")
			continue
		var region: Dictionary = entry

		_require_nonempty_string(region, "name", path, file, errors)
		_optional_string(region, "subtitle", path, file, errors)
		_require_int(region, "chunk_size", path, file, errors, 1)
		_require_int(region, "tile_width", path, file, errors, 1)
		_require_int(region, "tile_height", path, file, errors, 1)
		_require_int(region, "load_radius", path, file, errors, 0)
		_require_int(region, "noise_seed", path, file, errors, -2147483648, 2147483647)
		_require_number(region, "clearing_radius", path, file, errors, 0.0)

		var spawn_grid: Variant = region.get("spawn_grid", null)
		if spawn_grid == null:
			_err(errors, file, path + ".spawn_grid", "required field is missing")
		else:
			_validate_grid(spawn_grid, path + ".spawn_grid", file, errors)

		var biome = _require(region, "biome", "dictionary", path, file, errors)
		if typeof(biome) == TYPE_DICTIONARY:
			var biome_dict: Dictionary = biome
			_require_number(biome_dict, "water_level", path + ".biome", file, errors)
			_require_number(biome_dict, "deep_water_level", path + ".biome", file, errors)
			_validate_color_array(biome_dict, "grass_colors", path + ".biome", file, errors)
			for key in ["path_color", "water_shallow", "water_deep"]:
				var color := _require_nonempty_string(biome_dict, key, path + ".biome", file, errors)
				if not color.is_empty() and not _is_color(color):
					_err(errors, file, path + ".biome." + key, "expected a #rrggbb colour")

		var props = _require(region, "props", "array", path, file, errors)
		if typeof(props) == TYPE_ARRAY:
			var prop_list: Array = props
			if prop_list.is_empty():
				_err(errors, file, path + ".props", "must contain at least one prop")
			for index in prop_list.size():
				var prop: Variant = prop_list[index]
				var prop_path := "%s.props[%d]" % [path, index]
				if typeof(prop) != TYPE_DICTIONARY:
					_err(errors, file, prop_path, "expected an object")
					continue
				var prop_dict: Dictionary = prop
				_require_enum(prop_dict, "type", PROP_TYPES, prop_path, file, errors)
				_require_number(prop_dict, "weight", prop_path, file, errors, 0.0)
				_require_number(prop_dict, "min_elevation", prop_path, file, errors)

		var pois: Variant = region.get("pois", null)
		if pois != null:
			if typeof(pois) != TYPE_ARRAY:
				_err(errors, file, path + ".pois", "expected an array")
			else:
				var poi_ids: Dictionary = {}
				var poi_list: Array = pois
				for index in poi_list.size():
					var poi: Variant = poi_list[index]
					var poi_path := "%s.pois[%d]" % [path, index]
					if typeof(poi) != TYPE_DICTIONARY:
						_err(errors, file, poi_path, "expected an object")
						continue
					var poi_dict: Dictionary = poi
					var poi_id := _require_nonempty_string(poi_dict, "id", poi_path, file, errors)
					if not poi_id.is_empty():
						if poi_ids.has(poi_id):
							_err(errors, file, poi_path + ".id", "duplicate POI id '%s'" % poi_id)
						poi_ids[poi_id] = true
					_require_nonempty_string(poi_dict, "name", poi_path, file, errors)
					var grid: Variant = poi_dict.get("grid", null)
					if grid == null:
						_err(errors, file, poi_path + ".grid", "required field is missing")
					else:
						_validate_grid(grid, poi_path + ".grid", file, errors)
					_require_nonempty_string(poi_dict, "type", poi_path, file, errors)

		var spawns: Variant = region.get("spawns", null)
		if spawns != null:
			if typeof(spawns) != TYPE_ARRAY:
				_err(errors, file, path + ".spawns", "expected an array")
			else:
				var spawn_list: Array = spawns
				for index in spawn_list.size():
					var spawn: Variant = spawn_list[index]
					var spawn_path := "%s.spawns[%d]" % [path, index]
					if typeof(spawn) != TYPE_DICTIONARY:
						_err(errors, file, spawn_path, "expected an object")
						continue
					var spawn_dict: Dictionary = spawn
					var group_id := _require_nonempty_string(spawn_dict, "group", spawn_path, file, errors)
					if not group_id.is_empty() and not groups.has(group_id):
						_err(errors, file, spawn_path + ".group", "references missing enemy group '%s'" % group_id)
					var grid: Variant = spawn_dict.get("grid", null)
					if grid == null:
						_err(errors, file, spawn_path + ".grid", "required field is missing")
					else:
						_validate_grid(grid, spawn_path + ".grid", file, errors)
					_require_number(spawn_dict, "radius", spawn_path, file, errors, 0.0)
					_require_int(spawn_dict, "count", spawn_path, file, errors, 1)

		# Strict validation for the OPTIONAL multi-region / world-coordinate
		# fields. Missing fields produce NO error (backwards compatible); when a
		# field is present its structure and cross-references are checked.
		_validate_region_extensions(region, id, path, file, errors, data)

	return errors


# ------------------------------------------------------- optional region links

static func _validate_region_extensions(
	region: Dictionary,
	id: String,
	path: String,
	file: String,
	errors: Array[String],
	data: Dictionary
) -> void:
	# world_origin: array of exactly two numbers (a LOGICAL global/world offset).
	if region.has("world_origin"):
		_validate_grid(region["world_origin"], path + ".world_origin", file, errors)

	# environment: dictionary describing the region's ambient character.
	if region.has("environment"):
		var env: Variant = region["environment"]
		var env_path := path + ".environment"
		if typeof(env) != TYPE_DICTIONARY:
			_err(errors, file, env_path, "expected an object")
		else:
			var env_dict: Dictionary = env
			_require_nonempty_string(env_dict, "zone", env_path, file, errors)
			if env_dict.has("weather_bias"):
				var bias: Variant = env_dict["weather_bias"]
				var bias_path := env_path + ".weather_bias"
				if typeof(bias) != TYPE_ARRAY:
					_err(errors, file, bias_path, "expected an array")
				else:
					var bias_list: Array = bias
					for index in bias_list.size():
						var state: Variant = bias_list[index]
						var state_path := "%s[%d]" % [bias_path, index]
						if typeof(state) != TYPE_STRING:
							_err(errors, file, state_path, "expected a weather state string")
						elif not WEATHER_BIAS_STATES.has(str(state)):
							_err(errors, file, state_path, "must be one of: %s" % ", ".join(WEATHER_BIAS_STATES))
			if env_dict.has("fog_density"):
				_require_number(env_dict, "fog_density", env_path, file, errors, 0.0, 1.0)
			if env_dict.has("ambient_tint"):
				var tint := _require_nonempty_string(env_dict, "ambient_tint", env_path, file, errors)
				if not tint.is_empty() and not _is_color(tint):
					_err(errors, file, env_path + ".ambient_tint", "expected a #rrggbb colour")
			if env_dict.has("ambient_music"):
				_optional_string(env_dict, "ambient_music", env_path, file, errors)

	# entry_points: dictionary of lower_snake_case id -> 2-number grid.
	var entry_ids: Dictionary = {}
	if region.has("entry_points"):
		var eps: Variant = region["entry_points"]
		var eps_path := path + ".entry_points"
		if typeof(eps) != TYPE_DICTIONARY:
			_err(errors, file, eps_path, "expected an object")
		else:
			var eps_dict: Dictionary = eps
			for raw_key in eps_dict.keys():
				var key := str(raw_key)
				var key_path := eps_path + "." + key
				if not _valid_id(key):
					_err(errors, file, key_path, "entry point id must be lower_snake_case")
				entry_ids[key] = true
				_validate_grid(eps_dict[raw_key], key_path, file, errors)

	# connections: cross-region travel edges. `data` holds ALL region definitions,
	# so destination entry points can be resolved here without any I/O.
	if region.has("connections"):
		var conns: Variant = region["connections"]
		var conns_path := path + ".connections"
		if typeof(conns) != TYPE_ARRAY:
			_err(errors, file, conns_path, "expected an array")
		else:
			var conn_list: Array = conns
			var seen_ids: Dictionary = {}
			for index in conn_list.size():
				var conn: Variant = conn_list[index]
				var conn_path := "%s[%d]" % [conns_path, index]
				if typeof(conn) != TYPE_DICTIONARY:
					_err(errors, file, conn_path, "expected an object")
					continue
				var c: Dictionary = conn

				var cid := _require_nonempty_string(c, "id", conn_path, file, errors)
				if not cid.is_empty():
					if not _valid_id(cid):
						_err(errors, file, conn_path + ".id", "connection id must be lower_snake_case")
					if seen_ids.has(cid):
						_err(errors, file, conn_path + ".id", "duplicate connection id '%s'" % cid)
					seen_ids[cid] = true

				var to := _require_nonempty_string(c, "to", conn_path, file, errors)
				if not to.is_empty():
					if to == id:
						_err(errors, file, conn_path + ".to", "region connection cannot target itself")
					if not data.has(to):
						_err(errors, file, conn_path + ".to", "references missing region '%s'" % to)

				var via := _require_nonempty_string(c, "via", conn_path, file, errors)
				if not via.is_empty() and not entry_ids.has(via):
					_err(errors, file, conn_path + ".via", "references missing entry point '%s' in region '%s'" % [via, id])

				var entry := _require_nonempty_string(c, "entry", conn_path, file, errors)
				if not entry.is_empty() and data.has(to) and to != id:
					var dest_eps := _entry_point_ids(data[to])
					if not dest_eps.has(entry):
						_err(errors, file, conn_path + ".entry", "references missing entry point '%s' in destination region '%s'" % [entry, to])

				_require_enum(c, "kind", CONNECTION_KINDS, conn_path, file, errors)
				_require_nonempty_string(c, "label", conn_path, file, errors)


static func _entry_point_ids(region_def: Variant) -> Dictionary:
	var result: Dictionary = {}
	if typeof(region_def) != TYPE_DICTIONARY:
		return result
	var eps: Variant = region_def.get("entry_points", {})
	if typeof(eps) == TYPE_DICTIONARY:
		for raw_key in eps.keys():
			result[str(raw_key)] = true
	return result


## Pure cross-region graph validation: missing regions, self-loops, dangling
## via/entry points, duplicate region ids (Dictionary keys are unique by
## construction, but checked anyway) and UNREACHABLE regions from "greenward"
## (BFS over `connections`). No nodes, no SceneTree, no file I/O, no autoloads.
## Returns [] for the shipped data. Kept self-contained (does not depend on
## RegionGraph) because ContentValidator is loaded by ContentDB at every boot.
static func validate_region_graph(regions: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var ROOT := "greenward"

	# Duplicate region ids (cannot occur in a Dictionary, but verify anyway).
	var seen_ids: Dictionary = {}
	for raw_id in regions.keys():
		var rid := str(raw_id)
		if seen_ids.has(rid):
			errors.append("regions → %s: duplicate region id" % rid)
		seen_ids[rid] = true
		if typeof(regions[raw_id]) != TYPE_DICTIONARY:
			errors.append("regions → %s: region definition must be an object" % rid)

	# Build adjacency from valid edges and collect per-edge problems.
	var graph: Dictionary = {}
	for raw_id in regions.keys():
		var rid := str(raw_id)
		var def: Variant = regions[raw_id]
		var targets: Array = []
		if typeof(def) == TYPE_DICTIONARY:
			var d: Dictionary = def
			var eps := _entry_point_ids(d)
			var conns: Variant = d.get("connections", [])
			if typeof(conns) == TYPE_ARRAY:
				for index in conns.size():
					var conn: Variant = conns[index]
					if typeof(conn) != TYPE_DICTIONARY:
						errors.append("regions → %s.connections[%d]: expected an object" % [rid, index])
						continue
					var c: Dictionary = conn
					var to := str(c.get("to", ""))
					var via := str(c.get("via", ""))
					var entry := str(c.get("entry", ""))
					if to.is_empty():
						errors.append("regions → %s.connections[%d]: missing 'to'" % [rid, index])
						continue
					if to == rid:
						errors.append("regions → %s.connections[%d]: region connection cannot target itself" % [rid, index])
						continue
					if not regions.has(to):
						errors.append("regions → %s.connections[%d]: references missing region '%s'" % [rid, index, to])
						continue
					if via.is_empty() or not eps.has(via):
						errors.append("regions → %s.connections[%d]: dangling 'via' entry point '%s'" % [rid, index, via])
					var dest_eps := _entry_point_ids(regions.get(to, null))
					if entry.is_empty() or not dest_eps.has(entry):
						errors.append("regions → %s.connections[%d]: dangling 'entry' point '%s' in region '%s'" % [rid, index, entry, to])
					targets.append(to)
		graph[rid] = targets

	# BFS reachability from the default region over the valid edges.
	var reachable: Dictionary = {}
	if regions.has(ROOT):
		var queue: Array = [ROOT]
		reachable[ROOT] = true
		while not queue.is_empty():
			var cur := str(queue.pop_front())
			for raw_next in graph.get(cur, []):
				var next_id := str(raw_next)
				if regions.has(next_id) and not reachable.has(next_id):
					reachable[next_id] = true
					queue.append(next_id)
	for raw_id in regions.keys():
		var rid := str(raw_id)
		if not reachable.has(rid):
			errors.append("regions → %s: region is unreachable from '%s'" % [rid, ROOT])
	return errors


# --------------------------------------------------------------------- helpers

static func _validate_stats(base: Dictionary, path: String, file: String, errors: Array[String]) -> void:
	for key in ["hp", "atk", "def", "spd"]:
		_require_number(base, key, path, file, errors, 0.0001)
	_require_number(base, "crit", path, file, errors, 0.0, 1.0)


static func _validate_palette(
	palette: Dictionary,
	required_keys: Array,
	path: String,
	file: String,
	errors: Array[String]
) -> void:
	for key in required_keys:
		var color := _require_nonempty_string(palette, str(key), path, file, errors)
		if not color.is_empty() and not _is_color(color):
			_err(errors, file, path + "." + str(key), "expected a #rrggbb colour")


static func _validate_color_array(
	entry: Dictionary,
	key: String,
	path: String,
	file: String,
	errors: Array[String]
) -> void:
	if not entry.has(key):
		_err(errors, file, path + "." + key, "required field is missing")
		return
	var value: Variant = entry[key]
	if typeof(value) != TYPE_ARRAY:
		_err(errors, file, path + "." + key, "expected an array of colours")
		return
	var list: Array = value
	if list.is_empty():
		_err(errors, file, path + "." + key, "must contain at least one colour")
	for index in list.size():
		var color: Variant = list[index]
		if typeof(color) != TYPE_STRING or not _is_color(str(color)):
			_err(errors, file, "%s.%s[%d]" % [path, key, index], "expected a #rrggbb colour")


static func _validate_grid(value: Variant, path: String, file: String, errors: Array[String]) -> void:
	if typeof(value) != TYPE_ARRAY:
		_err(errors, file, path, "expected an array of two numbers")
		return
	var grid: Array = value
	if grid.size() != 2:
		_err(errors, file, path, "expected exactly two coordinates")
		return
	for index in 2:
		var coordinate: Variant = grid[index]
		if typeof(coordinate) != TYPE_INT and typeof(coordinate) != TYPE_FLOAT:
			_err(errors, file, "%s[%d]" % [path, index], "expected a number")


static func _validate_rewards(
	rewards: Dictionary,
	path: String,
	file: String,
	errors: Array[String],
	items: Dictionary
) -> void:
	var has_reward := false
	for key in ["gold", "crystals", "xp"]:
		if rewards.has(key):
			has_reward = true
			_require_number(rewards, key, path, file, errors, 0.0)
	if rewards.has("items"):
		var items_value: Variant = rewards["items"]
		if typeof(items_value) != TYPE_DICTIONARY:
			_err(errors, file, path + ".items", "expected an object of item_id: count")
		else:
			var item_dict: Dictionary = items_value
			if item_dict.is_empty():
				_err(errors, file, path + ".items", "must contain at least one item")
			for raw_item_id in item_dict.keys():
				has_reward = true
				var item_id := str(raw_item_id)
				var item_path := path + ".items." + item_id
				if not items.has(item_id):
					_err(errors, file, item_path, "references missing item '%s'" % item_id)
				var count: Variant = item_dict[raw_item_id]
				if not _is_positive_int(count):
					_err(errors, file, item_path, "expected a positive integer count")
	if not has_reward:
		_err(errors, file, path, "must contain at least one currency, XP or item reward")


static func _require(entry: Dictionary, key: String, expected: String, path: String, file: String, errors: Array[String], required: bool = true) -> Variant:
	if not entry.has(key):
		if required:
			_err(errors, file, path + "." + key, "required field is missing")
		return null
	var value: Variant = entry[key]
	if not _type_ok(value, expected):
		_err(errors, file, path + "." + key, "expected %s, got %s" % [expected, _type_name(value)])
		return null
	return value


static func _require_string(entry: Dictionary, key: String, path: String, file: String, errors: Array[String], required: bool = true) -> String:
	var value = _require(entry, key, "string", path, file, errors, required)
	if typeof(value) != TYPE_STRING:
		return ""
	return str(value)


static func _require_nonempty_string(entry: Dictionary, key: String, path: String, file: String, errors: Array[String]) -> String:
	var value := _require_string(entry, key, path, file, errors)
	if value.strip_edges().is_empty():
		_err(errors, file, path + "." + key, "must not be empty")
		return ""
	return value


static func _optional_string(entry: Dictionary, key: String, path: String, file: String, errors: Array[String]) -> String:
	if not entry.has(key):
		return ""
	return _require_string(entry, key, path, file, errors, false)


static func _require_enum(entry: Dictionary, key: String, allowed: Array, path: String, file: String, errors: Array[String]) -> String:
	var value := _require_string(entry, key, path, file, errors)
	if value.is_empty():
		return ""
	if not allowed.has(value):
		_err(errors, file, path + "." + key, "must be one of: %s" % ", ".join(allowed))
		return ""
	return value


static func _require_number(
	entry: Dictionary,
	key: String,
	path: String,
	file: String,
	errors: Array[String],
	min_value: float = -INF,
	max_value: float = INF,
	required: bool = true
) -> float:
	var value = _require(entry, key, "number", path, file, errors, required)
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return 0.0
	var number := float(value)
	if number < min_value or number > max_value:
		_err(errors, file, path + "." + key, "must be between %s and %s (got %s)" % [
			_format_number(min_value), _format_number(max_value), _format_number(number)
		])
	return number


static func _require_int(
	entry: Dictionary,
	key: String,
	path: String,
	file: String,
	errors: Array[String],
	min_value: int = -2147483648,
	max_value: int = 2147483647
) -> int:
	# Godot's JSON parser represents every number as a float, so accept any
	# numeric value that is integral while still rejecting 1.5.
	var value = _require(entry, key, "number", path, file, errors)
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return 0
	var number := int(value)
	if not is_equal_approx(float(value), float(number)):
		_err(errors, file, path + "." + key, "expected an integer (got %s)" % _format_number(float(value)))
		return 0
	if number < min_value or number > max_value:
		_err(errors, file, path + "." + key, "must be between %d and %d (got %d)" % [min_value, max_value, number])
	return number


static func _require_bool(
	entry: Dictionary,
	key: String,
	path: String,
	file: String,
	errors: Array[String],
	required: bool = true
) -> bool:
	var value = _require(entry, key, "bool", path, file, errors, required)
	if typeof(value) != TYPE_BOOL:
		return false
	return bool(value)


static func _is_positive_int(value: Variant) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	var number := float(value)
	return number >= 1.0 and is_equal_approx(number, roundf(number))


static func _type_ok(value: Variant, expected: String) -> bool:
	match expected:
		"string":
			return typeof(value) == TYPE_STRING
		"number":
			return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
		"int":
			return typeof(value) == TYPE_INT
		"bool":
			return typeof(value) == TYPE_BOOL
		"array":
			return typeof(value) == TYPE_ARRAY
		"dictionary":
			return typeof(value) == TYPE_DICTIONARY
	return false


static func _type_name(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return "bool"
		TYPE_INT:
			return "int"
		TYPE_FLOAT:
			return "float"
		TYPE_STRING:
			return "string"
		TYPE_ARRAY:
			return "array"
		TYPE_DICTIONARY:
			return "dictionary"
	return "value"


static func _err(errors: Array[String], file: String, path: String, message: String) -> void:
	errors.append("%s → %s: %s" % [file, path, message])


static func _valid_id(id: String) -> bool:
	if id.is_empty():
		return false
	if not "abcdefghijklmnopqrstuvwxyz".contains(id[0]):
		return false
	for index in id.length():
		if not ID_CHARS.contains(id[index]):
			return false
	return true


static func _is_color(value: String) -> bool:
	if value.length() != 7 or not value.begins_with("#"):
		return false
	for index in range(1, 7):
		if not "0123456789abcdefABCDEF".contains(value[index]):
			return false
	return true


static func _format_number(value: float) -> String:
	if is_inf(value):
		return "infinity"
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%.3f" % value


# ------------------------------------------------------- duplicate key scanner

static func _scan_duplicate_keys(file_name: String, text: String) -> Array[String]:
	var errors: Array[String] = []
	_scan_value(text, 0, file_name, "", errors)
	return errors


static func _scan_value(text: String, index: int, file_name: String, path: String, errors: Array[String]) -> int:
	index = _skip_ws(text, index)
	if index >= text.length():
		return index
	var character := text[index]
	match character:
		"{":
			return _scan_object(text, index, file_name, path, errors)
		"[":
			return _scan_array(text, index, file_name, path, errors)
		"\"":
			return _scan_string(text, index)
		_:
			while index < text.length() and not ",]} \t\r\n".contains(text[index]):
				index += 1
			return index


static func _scan_object(text: String, index: int, file_name: String, path: String, errors: Array[String]) -> int:
	index += 1
	var keys: Dictionary = {}
	index = _skip_ws(text, index)
	if index < text.length() and text[index] == "}":
		return index + 1
	while index < text.length():
		index = _skip_ws(text, index)
		if index >= text.length() or text[index] != "\"":
			return index
		var key_start := index
		index = _scan_string(text, index)
		var key := text.substr(key_start + 1, maxi(0, index - key_start - 2))
		if keys.has(key):
			var location := path if not path.is_empty() else "(root)"
			_err(errors, file_name, location, "duplicate key '%s'" % key)
		keys[key] = true
		index = _skip_ws(text, index)
		if index < text.length() and text[index] == ":":
			index += 1
		var child_path := key if path.is_empty() else path + "." + key
		index = _scan_value(text, index, file_name, child_path, errors)
		index = _skip_ws(text, index)
		if index < text.length() and text[index] == ",":
			index += 1
			continue
		if index < text.length() and text[index] == "}":
			return index + 1
		return index
	return index


static func _scan_array(text: String, index: int, file_name: String, path: String, errors: Array[String]) -> int:
	index += 1
	var item_index := 0
	index = _skip_ws(text, index)
	if index < text.length() and text[index] == "]":
		return index + 1
	while index < text.length():
		var child_path := "%s[%d]" % [path, item_index]
		index = _scan_value(text, index, file_name, child_path, errors)
		index = _skip_ws(text, index)
		if index < text.length() and text[index] == ",":
			item_index += 1
			index += 1
			continue
		if index < text.length() and text[index] == "]":
			return index + 1
		return index
	return index


static func _scan_string(text: String, index: int) -> int:
	index += 1
	while index < text.length():
		var character := text[index]
		if character == "\\":
			index += 2
		elif character == "\"":
			return index + 1
		else:
			index += 1
	return index


static func _skip_ws(text: String, index: int) -> int:
	while index < text.length() and " \t\r\n".contains(text[index]):
		index += 1
	return index

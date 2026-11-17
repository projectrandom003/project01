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
##   characters.json â†’ characters.lyra_vey.base.hp: expected number, got string

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
const EQUIPMENT_STATS := ["hp", "atk", "def", "spd", "crit", "crit_dmg"]
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
	# Lived-in village furniture: real bench and stacked-goods crate art.
	"bench", "crate",
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
			errors.append("%s: invalid JSON â€” %s (line %d)" % [
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
		errors.append("%s: invalid JSON â€” %s (line %d)" % [
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
	return CharacterCombatContentValidator.validate_characters(data, context, ELEMENTS, RARITIES)

static func _validate_skills(data: Dictionary) -> Array[String]:
	return CharacterCombatContentValidator.validate_skills(data, ELEMENTS, SKILL_KINDS, TARGETS, STATUS_IDS)

static func _validate_enemies(data: Dictionary, context: Dictionary) -> Array[String]:
	return CharacterCombatContentValidator.validate_enemies(data, context, ELEMENTS, RARITIES, STATUS_IDS)

static func _validate_enemy_groups(data: Dictionary, context: Dictionary) -> Array[String]:
	return CharacterCombatContentValidator.validate_enemy_groups(data, context, STATUS_IDS)


static func _validate_items(data: Dictionary) -> Array[String]:
	return ItemBannerContentValidator.validate_items(data, ITEM_CATEGORIES, ELEMENTS, EQUIPMENT_SLOTS, EQUIPMENT_STATS, RARITIES)

static func _validate_banners(data: Dictionary, context: Dictionary) -> Array[String]:
	return ItemBannerContentValidator.validate_banners(data, context, RARITIES, BANNER_TYPES)


static func _validate_quests(data: Dictionary, context: Dictionary) -> Array[String]:
	return QuestDialogueContentValidator.validate_quests(data, context, QUEST_STEP_TYPES)

static func _validate_dialogue(data: Dictionary, context: Dictionary) -> Array[String]:
	return QuestDialogueContentValidator.validate_dialogue(data, context, QUEST_STATES)


# -------------------------------------------------------------------- regions

static func _validate_regions(data: Dictionary, context: Dictionary) -> Array[String]:
	return RegionContentValidator.validate_regions(data, context, PROP_TYPES, WEATHER_BIAS_STATES, CONNECTION_KINDS)


static func _entry_point_ids(region_def: Variant) -> Dictionary:
	return RegionGraphValidator.entry_point_ids(region_def)

static func validate_region_graph(regions: Dictionary) -> Array[String]:
	return RegionGraphValidator.validate_region_graph(regions)


# --------------------------------------------------------------------- helpers

static func _validate_stats(base: Dictionary, path: String, file: String, errors: Array[String]) -> void:
	for key in ["hp", "atk", "def", "spd"]:
		_require_number(base, key, path, file, errors, 0.0001)
	_require_number(base, "crit", path, file, errors, 0.0, 1.0)
	if base.has("crit_dmg"):
		_require_number(base, "crit_dmg", path, file, errors, 1.0)


static func _validate_growth(growth: Dictionary, path: String, file: String, errors: Array[String]) -> void:
	for raw_key in growth.keys():
		var key := str(raw_key)
		var growth_path := path + "." + key
		var value: Variant = growth[raw_key]
		if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
			_err(errors, file, growth_path, "expected a number")
			continue
		if float(value) < 0.0:
			_err(errors, file, growth_path, "growth must be >= 0")


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
	errors.append("%s â†’ %s: %s" % [file, path, message])


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



## Backward-compatible facade for existing validation tools and tests.
static func _scan_duplicate_keys(file_name: String, text: String) -> Array[String]:
	return JsonDuplicateKeyScanner.scan_duplicate_keys(file_name, text)

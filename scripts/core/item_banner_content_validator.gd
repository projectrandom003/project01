class_name ItemBannerContentValidator
extends RefCounted
## Domain validators for inventory items, equipment and summon banners.
## Primitive schema checks stay centralized in ContentValidator.

static func validate_items(data: Dictionary, item_categories: Array, element_types: Array, equipment_slots: Array, equipment_stats: Array, rarities: Array) -> Array[String]:
	var errors: Array[String] = []
	var file := "items.json"
	var root := "items"

	for raw_id in data.keys():
		var id := str(raw_id)
		var path := root + "." + id
		if not ContentValidator._valid_id(id):
			ContentValidator._err(errors, file, path, "ID must be lower_snake_case")
		var entry: Variant = data[raw_id]
		if typeof(entry) != TYPE_DICTIONARY:
			ContentValidator._err(errors, file, path, "expected an object")
			continue
		var item: Dictionary = entry

		ContentValidator._require_nonempty_string(item, "name", path, file, errors)
		ContentValidator._require_nonempty_string(item, "description", path, file, errors)
		var category := ContentValidator._require_enum(item, "category", item_categories, path, file, errors)
		ContentValidator._optional_string(item, "icon", path, file, errors)
		if item.has("color"):
			var color := ContentValidator._optional_string(item, "color", path, file, errors)
			if not color.is_empty() and not ContentValidator._is_color(color):
				ContentValidator._err(errors, file, path + ".color", "expected a #rrggbb colour")
		if item.has("rarity"):
			ContentValidator._require_enum(item, "rarity", rarities, path, file, errors)

		if category == "equipment":
			ContentValidator._require_enum(item, "slot", equipment_slots, path, file, errors)
			if item.has("element"):
				ContentValidator._require_enum(item, "element", element_types, path, file, errors)
			var stats = ContentValidator._require(item, "stats", "dictionary", path, file, errors)
			if typeof(stats) == TYPE_DICTIONARY:
				_validate_equipment_stats(stats, path + ".stats", file, errors, equipment_stats)
			if item.has("level"):
				ContentValidator._require_int(item, "level", path, file, errors, 1)
		else:
			if item.has("slot"):
				ContentValidator._err(errors, file, path + ".slot", "%s items must not define an equipment slot" % category)
			if item.has("stats"):
				ContentValidator._err(errors, file, path + ".stats", "%s items must not define equipment stats" % category)

	return errors


static func _validate_equipment_stats(stats: Dictionary, path: String, file: String, errors: Array[String], equipment_stats: Array) -> void:
	if stats.is_empty():
		ContentValidator._err(errors, file, path, "equipment must define at least one stat")
		return
	for raw_key in stats.keys():
		var key := str(raw_key)
		var stat_path := path + "." + key
		if not equipment_stats.has(key):
			ContentValidator._err(errors, file, stat_path, "unknown equipment stat")
			continue
		var value: Variant = stats[raw_key]
		if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
			ContentValidator._err(errors, file, stat_path, "expected a number")
			continue
		var number := float(value)
		if key == "crit":
			if number < 0.0 or number > 1.0:
				ContentValidator._err(errors, file, stat_path, "crit must be between 0 and 1")
		elif number < 0.0:
			ContentValidator._err(errors, file, stat_path, "stat must be >= 0")


# -------------------------------------------------------------------- banners

static func validate_banners(data: Dictionary, context: Dictionary, rarities: Array, banner_types: Array) -> Array[String]:
	var errors: Array[String] = []
	var file := "banners.json"
	var root := "banners"
	var characters: Dictionary = context.get("characters.json", {})
	var items: Dictionary = context.get("items.json", {})

	for raw_id in data.keys():
		var id := str(raw_id)
		var path := root + "." + id
		if not ContentValidator._valid_id(id):
			ContentValidator._err(errors, file, path, "ID must be lower_snake_case")
		var entry: Variant = data[raw_id]
		if typeof(entry) != TYPE_DICTIONARY:
			ContentValidator._err(errors, file, path, "expected an object")
			continue
		var banner: Dictionary = entry

		ContentValidator._require_nonempty_string(banner, "name", path, file, errors)
		ContentValidator._optional_string(banner, "subtitle", path, file, errors)
		ContentValidator._require_enum(banner, "type", banner_types, path, file, errors)
		ContentValidator._require_number(banner, "featured_rate", path, file, errors, 0.0, 1.0)
		ContentValidator._require_int(banner, "hard_pity", path, file, errors, 1)
		var featured_pity := ContentValidator._require_int(banner, "featured_pity", path, file, errors, 1)
		var hard_pity := int(banner.get("hard_pity", 0))
		if featured_pity > 0 and hard_pity > 0 and featured_pity < hard_pity:
			ContentValidator._err(errors, file, path + ".featured_pity", "must be greater than or equal to hard_pity")
		ContentValidator._require_bool(banner, "ten_pull_epic_guarantee", path, file, errors)

		var rates = ContentValidator._require(banner, "rates", "dictionary", path, file, errors)
		var rate_total := 0.0
		if typeof(rates) == TYPE_DICTIONARY:
			var rate_dict: Dictionary = rates
			for rarity in rarities:
				if not rate_dict.has(rarity):
					ContentValidator._err(errors, file, path + ".rates." + rarity, "required rarity rate is missing")
					continue
				var rate: Variant = rate_dict[rarity]
				if typeof(rate) != TYPE_INT and typeof(rate) != TYPE_FLOAT:
					ContentValidator._err(errors, file, path + ".rates." + rarity, "expected a number")
					continue
				var value := float(rate)
				if value < 0.0 or value > 1.0:
					ContentValidator._err(errors, file, path + ".rates." + rarity, "rate must be between 0 and 1")
				rate_total += value
			for raw_rarity in rate_dict.keys():
				if not rarities.has(str(raw_rarity)):
					ContentValidator._err(errors, file, path + ".rates." + str(raw_rarity), "unknown rarity")
			if absf(rate_total - 1.0) > 0.02:
				ContentValidator._err(errors, file, path + ".rates", "rates must sum to 1.0 (got %.3f)" % rate_total)

		var cost = ContentValidator._require(banner, "cost", "dictionary", path, file, errors)
		if typeof(cost) == TYPE_DICTIONARY:
			var cost_dict: Dictionary = cost
			var currency := ContentValidator._require_nonempty_string(cost_dict, "currency", path + ".cost", file, errors)
			if not currency.is_empty():
				var currency_item: Dictionary = items.get(currency, {})
				if currency_item.is_empty():
					ContentValidator._err(errors, file, path + ".cost.currency", "references missing item '%s'" % currency)
				elif str(currency_item.get("category", "")) != "currency":
					ContentValidator._err(errors, file, path + ".cost.currency", "item '%s' is not a currency" % currency)
			var single := ContentValidator._require_int(cost_dict, "single", path + ".cost", file, errors, 1)
			var ten := ContentValidator._require_int(cost_dict, "ten", path + ".cost", file, errors, 1)
			if single > 0 and ten > 0 and ten > single * 10:
				ContentValidator._err(errors, file, path + ".cost.ten", "ten-pull cost cannot exceed ten single pulls")

		var pool = ContentValidator._require(banner, "pool", "dictionary", path, file, errors)
		var seen_characters: Dictionary = {}
		if typeof(pool) == TYPE_DICTIONARY:
			var pool_dict: Dictionary = pool
			for rarity in rarities:
				if not pool_dict.has(rarity):
					ContentValidator._err(errors, file, path + ".pool." + rarity, "required rarity pool is missing")
					continue
				var pool_list: Variant = pool_dict[rarity]
				if typeof(pool_list) != TYPE_ARRAY:
					ContentValidator._err(errors, file, path + ".pool." + rarity, "expected an array")
					continue
				if pool_list.is_empty():
					ContentValidator._err(errors, file, path + ".pool." + rarity, "pool must not be empty")
				for index in pool_list.size():
					var character_id: Variant = pool_list[index]
					var character_path := "%s.pool.%s[%d]" % [path, rarity, index]
					if typeof(character_id) != TYPE_STRING:
						ContentValidator._err(errors, file, character_path, "expected a character ID string")
						continue
					var character_key := str(character_id)
					if not characters.has(character_key):
						ContentValidator._err(errors, file, character_path, "references missing character '%s'" % character_key)
						continue
					var character: Variant = characters[character_key]
					if typeof(character) == TYPE_DICTIONARY and str(character.get("rarity", "")) != rarity:
						ContentValidator._err(errors, file, character_path, "character '%s' is not %s rarity" % [character_key, rarity])
					if seen_characters.has(character_key):
						ContentValidator._err(errors, file, character_path, "character '%s' appears more than once in the pool" % character_key)
					seen_characters[character_key] = true
			for raw_rarity in pool_dict.keys():
				if not rarities.has(str(raw_rarity)):
					ContentValidator._err(errors, file, path + ".pool." + str(raw_rarity), "unknown rarity")

		var featured = ContentValidator._require(banner, "featured", "array", path, file, errors)
		if typeof(featured) == TYPE_ARRAY:
			if featured.is_empty():
				ContentValidator._err(errors, file, path + ".featured", "must contain at least one character")
			for index in featured.size():
				var character_id: Variant = featured[index]
				var featured_path := "%s.featured[%d]" % [path, index]
				if typeof(character_id) != TYPE_STRING:
					ContentValidator._err(errors, file, featured_path, "expected a character ID string")
					continue
				var character_key := str(character_id)
				if not characters.has(character_key):
					ContentValidator._err(errors, file, featured_path, "references missing character '%s'" % character_key)
				elif not seen_characters.has(character_key):
					ContentValidator._err(errors, file, featured_path, "featured character '%s' is not in the banner pool" % character_key)

	return errors


# --------------------------------------------------------------------- quests


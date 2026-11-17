class_name CharacterCombatContentValidator
extends RefCounted
## Domain validators for character, skill, enemy and enemy-group data.
## Shared schema primitives remain centralized in ContentValidator.

static func validate_characters(data: Dictionary, context: Dictionary, elements: Array, rarities: Array) -> Array[String]:
	var errors: Array[String] = []
	var file := "characters.json"
	var root := "characters"
	var skills: Dictionary = context.get("skills.json", {})

	for raw_id in data.keys():
		var id := str(raw_id)
		var path := root + "." + id
		if not ContentValidator._valid_id(id):
			ContentValidator._err(errors, file, path, "ID must be lower_snake_case")
		var entry: Variant = data[raw_id]
		if typeof(entry) != TYPE_DICTIONARY:
			ContentValidator._err(errors, file, path, "expected an object")
			continue
		var character: Dictionary = entry

		ContentValidator._require_nonempty_string(character, "name", path, file, errors)
		ContentValidator._require_enum(character, "element", elements, path, file, errors)
		ContentValidator._require_enum(character, "rarity", rarities, path, file, errors)
		ContentValidator._optional_string(character, "title", path, file, errors)
		ContentValidator._optional_string(character, "race", path, file, errors)
		ContentValidator._optional_string(character, "role", path, file, errors)
		ContentValidator._optional_string(character, "lore", path, file, errors)

		var base = ContentValidator._require(character, "base", "dictionary", path, file, errors)
		if typeof(base) == TYPE_DICTIONARY:
			ContentValidator._validate_stats(base, path + ".base", file, errors)
		if character.has("growth"):
			var growth = character.get("growth", null)
			if typeof(growth) == TYPE_DICTIONARY:
				ContentValidator._validate_growth(growth, path + ".growth", file, errors)

		var skill_list = ContentValidator._require(character, "skills", "array", path, file, errors)
		if typeof(skill_list) == TYPE_ARRAY:
			if skill_list.size() < 2:
				ContentValidator._err(errors, file, path + ".skills", "must contain at least 2 active skills")
			for index in skill_list.size():
				var skill_id: Variant = skill_list[index]
				var skill_path := "%s.skills[%d]" % [path, index]
				if typeof(skill_id) != TYPE_STRING:
					ContentValidator._err(errors, file, skill_path, "expected a skill ID string")
					continue
				if not skills.has(str(skill_id)):
					ContentValidator._err(errors, file, skill_path, "references missing skill '%s'" % str(skill_id))

		var ultimate := ContentValidator._optional_string(character, "ultimate", path, file, errors)
		if not ultimate.is_empty() and not skills.has(ultimate):
			ContentValidator._err(errors, file, path + ".ultimate", "references missing skill '%s'" % ultimate)

		var passive = character.get("passive", null)
		if passive != null:
			var passive_path := path + ".passive"
			if typeof(passive) != TYPE_DICTIONARY:
				ContentValidator._err(errors, file, passive_path, "expected an object")
			else:
				var passive_dict: Dictionary = passive
				var passive_id := ContentValidator._require_nonempty_string(passive_dict, "id", passive_path, file, errors)
				ContentValidator._require_nonempty_string(passive_dict, "name", passive_path, file, errors)
				ContentValidator._require_nonempty_string(passive_dict, "text", passive_path, file, errors)
				if not passive_id.is_empty() and not PassiveEffects.is_supported(passive_id):
					ContentValidator._err(errors, file, passive_path + ".id", "unknown passive '%s'" % passive_id)

		var palette = ContentValidator._require(character, "palette", "dictionary", path, file, errors)
		if typeof(palette) == TYPE_DICTIONARY:
			ContentValidator._validate_palette(palette, ["hair", "primary", "secondary", "accent", "skin"], path + ".palette", file, errors)

		if character.has("portrait_seed"):
			ContentValidator._require_int(character, "portrait_seed", path, file, errors, 0)

	return errors


# ---------------------------------------------------------------------- skills

static func validate_skills(data: Dictionary, elements: Array, skill_kinds: Array, targets: Array, status_ids: Array) -> Array[String]:
	var errors: Array[String] = []
	var file := "skills.json"
	var root := "skills"

	for raw_id in data.keys():
		var id := str(raw_id)
		var path := root + "." + id
		if not ContentValidator._valid_id(id):
			ContentValidator._err(errors, file, path, "ID must be lower_snake_case")
		var entry: Variant = data[raw_id]
		if typeof(entry) != TYPE_DICTIONARY:
			ContentValidator._err(errors, file, path, "expected an object")
			continue
		var skill: Dictionary = entry

		ContentValidator._require_nonempty_string(skill, "name", path, file, errors)
		ContentValidator._optional_string(skill, "description", path, file, errors)
		ContentValidator._require_enum(skill, "element", elements, path, file, errors)
		var kind := ContentValidator._require_enum(skill, "kind", skill_kinds, path, file, errors)
		var power := ContentValidator._require_number(skill, "power", path, file, errors, 0.0)
		ContentValidator._require_enum(skill, "target", targets, path, file, errors)
		ContentValidator._require_number(skill, "energy_gain", path, file, errors, 0.0, INF, false)
		ContentValidator._require_number(skill, "crit_bonus", path, file, errors, 0.0, 1.0, false)
		ContentValidator._require_number(skill, "lifesteal", path, file, errors, 0.0, 1.0, false)
		ContentValidator._require_bool(skill, "cleanse", path, file, errors, false)
		ContentValidator._require_bool(skill, "ultimate", path, file, errors, false)
		var scaling_stat := ContentValidator._optional_string(skill, "scaling_stat", path, file, errors)
		if not scaling_stat.is_empty() and scaling_stat not in ["atk", "def", "hp", "spd"]:
			ContentValidator._err(errors, file, path + ".scaling_stat", "must be atk, def, hp or spd")
		ContentValidator._optional_string(skill, "animation_key", path, file, errors)
		ContentValidator._optional_string(skill, "vfx_key", path, file, errors)
		if skill.has("cooldown_turns"):
			ContentValidator._require_int(skill, "cooldown_turns", path, file, errors, 0)
		if skill.has("ai_tags"):
			var ai_tags: Variant = skill["ai_tags"]
			if typeof(ai_tags) != TYPE_ARRAY:
				ContentValidator._err(errors, file, path + ".ai_tags", "expected an array")
			else:
				for tag_index in ai_tags.size():
					if typeof(ai_tags[tag_index]) != TYPE_STRING or str(ai_tags[tag_index]).strip_edges().is_empty():
						ContentValidator._err(errors, file, "%s.ai_tags[%d]" % [path, tag_index], "expected a non-empty string")

		var statuses: Variant = skill.get("statuses", [])
		if statuses != null:
			_validate_status_list(statuses, path + ".statuses", file, errors, status_ids)

		if kind in ["damage", "heal", "shield"] and power <= 0.0:
			ContentValidator._err(errors, file, path + ".power", "%s skills must have power > 0" % kind)
		if kind == "buff":
			if typeof(statuses) != TYPE_ARRAY or statuses.is_empty():
				ContentValidator._err(errors, file, path + ".statuses", "buff skills must apply at least one status")

	return errors


static func _validate_status_list(statuses: Variant, path: String, file: String, errors: Array[String], status_ids: Array) -> void:
	if typeof(statuses) != TYPE_ARRAY:
		ContentValidator._err(errors, file, path, "expected an array")
		return
	var list: Array = statuses
	for index in list.size():
		var entry: Variant = list[index]
		var status_path := "%s[%d]" % [path, index]
		if typeof(entry) != TYPE_DICTIONARY:
			ContentValidator._err(errors, file, status_path, "expected an object")
			continue
		var status: Dictionary = entry
		var status_id := ContentValidator._require_enum(status, "id", status_ids, status_path, file, errors)
		ContentValidator._require_number(status, "chance", status_path, file, errors, 0.0, 1.0)
		ContentValidator._require_int(status, "turns", status_path, file, errors, 1)
		var potency := ContentValidator._require_number(status, "potency", status_path, file, errors, 0.0)
		if status_id in ["shield", "burn", "poison", "regen"] and potency <= 0.0:
			ContentValidator._err(errors, file, status_path + ".potency", "%s status must have potency > 0" % status_id)


# --------------------------------------------------------------------- enemies

static func validate_enemies(data: Dictionary, context: Dictionary, elements: Array, rarities: Array, status_ids: Array) -> Array[String]:
	var errors: Array[String] = []
	var file := "enemies.json"
	var root := "enemies"
	var skills: Dictionary = context.get("skills.json", {})

	for raw_id in data.keys():
		var id := str(raw_id)
		var path := root + "." + id
		if not ContentValidator._valid_id(id):
			ContentValidator._err(errors, file, path, "ID must be lower_snake_case")
		var entry: Variant = data[raw_id]
		if typeof(entry) != TYPE_DICTIONARY:
			ContentValidator._err(errors, file, path, "expected an object")
			continue
		var enemy: Dictionary = entry

		ContentValidator._require_nonempty_string(enemy, "name", path, file, errors)
		ContentValidator._require_enum(enemy, "element", elements, path, file, errors)
		ContentValidator._require_enum(enemy, "rarity", rarities, path, file, errors)
		ContentValidator._optional_string(enemy, "role", path, file, errors)
		ContentValidator._optional_string(enemy, "lore", path, file, errors)

		var base = ContentValidator._require(enemy, "base", "dictionary", path, file, errors)
		if typeof(base) == TYPE_DICTIONARY:
			ContentValidator._validate_stats(base, path + ".base", file, errors)

		var skill_list = ContentValidator._require(enemy, "skills", "array", path, file, errors)
		if typeof(skill_list) == TYPE_ARRAY:
			if skill_list.is_empty():
				ContentValidator._err(errors, file, path + ".skills", "must contain at least one skill")
			for index in skill_list.size():
				var skill_id: Variant = skill_list[index]
				var skill_path := "%s.skills[%d]" % [path, index]
				if typeof(skill_id) != TYPE_STRING:
					ContentValidator._err(errors, file, skill_path, "expected a skill ID string")
					continue
				if not skills.has(str(skill_id)):
					ContentValidator._err(errors, file, skill_path, "references missing skill '%s'" % str(skill_id))

		var ultimate := ContentValidator._optional_string(enemy, "ultimate", path, file, errors)
		if not ultimate.is_empty() and not skills.has(ultimate):
			ContentValidator._err(errors, file, path + ".ultimate", "references missing skill '%s'" % ultimate)

		var palette = ContentValidator._require(enemy, "palette", "dictionary", path, file, errors)
		if typeof(palette) == TYPE_DICTIONARY:
			ContentValidator._validate_palette(palette, ["primary", "secondary", "accent"], path + ".palette", file, errors)

		var phases: Variant = enemy.get("phases", null)
		if phases != null:
			_validate_phases(phases, path + ".phases", file, errors, status_ids)

	return errors


static func _validate_phases(phases: Variant, path: String, file: String, errors: Array[String], status_ids: Array) -> void:
	if typeof(phases) != TYPE_ARRAY:
		ContentValidator._err(errors, file, path, "expected an array")
		return
	var list: Array = phases
	for index in list.size():
		var entry: Variant = list[index]
		var phase_path := "%s[%d]" % [path, index]
		if typeof(entry) != TYPE_DICTIONARY:
			ContentValidator._err(errors, file, phase_path, "expected an object")
			continue
		var phase: Dictionary = entry
		ContentValidator._require_number(phase, "hp_below", phase_path, file, errors, 0.0, 1.0)
		ContentValidator._require_nonempty_string(phase, "message", phase_path, file, errors)
		if phase.has("status"):
			var status: Variant = phase["status"]
			if typeof(status) != TYPE_DICTIONARY:
				ContentValidator._err(errors, file, phase_path + ".status", "expected an object")
			else:
				var status_dict: Dictionary = status
				ContentValidator._require_enum(status_dict, "id", status_ids, phase_path + ".status", file, errors)
				ContentValidator._require_int(status_dict, "turns", phase_path + ".status", file, errors, 1)
				ContentValidator._require_number(status_dict, "potency", phase_path + ".status", file, errors, 0.0)


# ---------------------------------------------------------------- enemy groups

static func validate_enemy_groups(data: Dictionary, context: Dictionary, status_ids: Array) -> Array[String]:
	var errors: Array[String] = []
	var file := "enemy_groups.json"
	var root := "enemy_groups"
	var enemies: Dictionary = context.get("enemies.json", {})
	var items: Dictionary = context.get("items.json", {})
	var regions: Dictionary = context.get("regions.json", {})

	for raw_id in data.keys():
		var id := str(raw_id)
		var path := root + "." + id
		if not ContentValidator._valid_id(id):
			ContentValidator._err(errors, file, path, "ID must be lower_snake_case")
		var entry: Variant = data[raw_id]
		if typeof(entry) != TYPE_DICTIONARY:
			ContentValidator._err(errors, file, path, "expected an object")
			continue
		var group: Dictionary = entry

		ContentValidator._require_nonempty_string(group, "name", path, file, errors)
		var region := ContentValidator._require_nonempty_string(group, "region", path, file, errors)
		if not region.is_empty() and not regions.has(region):
			ContentValidator._err(errors, file, path + ".region", "references missing region '%s'" % region)
		ContentValidator._require_int(group, "level", path, file, errors, 1)

		var enemy_list = ContentValidator._require(group, "enemies", "array", path, file, errors)
		if typeof(enemy_list) == TYPE_ARRAY:
			if enemy_list.is_empty():
				ContentValidator._err(errors, file, path + ".enemies", "must contain at least one enemy")
			for index in enemy_list.size():
				var enemy_id: Variant = enemy_list[index]
				var enemy_path := "%s.enemies[%d]" % [path, index]
				if typeof(enemy_id) != TYPE_STRING:
					ContentValidator._err(errors, file, enemy_path, "expected an enemy ID string")
					continue
				if not enemies.has(str(enemy_id)):
					ContentValidator._err(errors, file, enemy_path, "references missing enemy '%s'" % str(enemy_id))

		var rewards = ContentValidator._require(group, "rewards", "dictionary", path, file, errors)
		if typeof(rewards) == TYPE_DICTIONARY:
			ContentValidator._validate_rewards(rewards, path + ".rewards", file, errors, items)

		ContentValidator._require_bool(group, "elite", path, file, errors, false)
		ContentValidator._require_bool(group, "boss", path, file, errors, false)

		var quest_kills: Variant = group.get("quest_kills", null)
		if quest_kills != null:
			if typeof(quest_kills) != TYPE_DICTIONARY:
				ContentValidator._err(errors, file, path + ".quest_kills", "expected an object")
			else:
				var kills: Dictionary = quest_kills
				for raw_enemy_id in kills.keys():
					var enemy_id := str(raw_enemy_id)
					if not enemies.has(enemy_id):
						ContentValidator._err(errors, file, path + ".quest_kills." + enemy_id, "references missing enemy '%s'" % enemy_id)
					var count: Variant = kills[raw_enemy_id]
					if not ContentValidator._is_positive_int(count):
						ContentValidator._err(errors, file, path + ".quest_kills." + enemy_id, "expected a positive integer")

	return errors


# ---------------------------------------------------------------------- items


class_name QuestDialogueContentValidator
extends RefCounted
## Domain validators for quest progression and branching dialogue content.
## Uses ContentValidator for shared schema primitives.

static func validate_quests(data: Dictionary, context: Dictionary, quest_step_types: Array) -> Array[String]:
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
		if not ContentValidator._valid_id(id):
			ContentValidator._err(errors, file, path, "ID must be lower_snake_case")
		var entry: Variant = data[raw_id]
		if typeof(entry) != TYPE_DICTIONARY:
			ContentValidator._err(errors, file, path, "expected an object")
			continue
		var quest: Dictionary = entry

		ContentValidator._require_nonempty_string(quest, "name", path, file, errors)
		var region := ContentValidator._require_nonempty_string(quest, "region", path, file, errors)
		if not region.is_empty() and not regions.has(region):
			ContentValidator._err(errors, file, path + ".region", "references missing region '%s'" % region)
		ContentValidator._require_nonempty_string(quest, "summary", path, file, errors)

		if quest.has("requires"):
			var requires := ContentValidator._optional_string(quest, "requires", path, file, errors)
			if not requires.is_empty():
				if requires == id:
					ContentValidator._err(errors, file, path + ".requires", "a quest cannot require itself")
				elif not quests.has(requires):
					ContentValidator._err(errors, file, path + ".requires", "references missing quest '%s'" % requires)

		var steps = ContentValidator._require(quest, "steps", "array", path, file, errors)
		if typeof(steps) == TYPE_ARRAY:
			if steps.is_empty():
				ContentValidator._err(errors, file, path + ".steps", "must contain at least one step")
			for index in steps.size():
				var step: Variant = steps[index]
				var step_path := "%s.steps[%d]" % [path, index]
				if typeof(step) != TYPE_DICTIONARY:
					ContentValidator._err(errors, file, step_path, "expected an object")
					continue
				var step_dict: Dictionary = step
				var step_type := ContentValidator._require_enum(step_dict, "type", quest_step_types, step_path, file, errors)
				var target := ContentValidator._require_nonempty_string(step_dict, "target", step_path, file, errors)
				ContentValidator._require_nonempty_string(step_dict, "text", step_path, file, errors)
				var step_grid: Variant = step_dict.get("grid", null)
				if step_grid != null:
					ContentValidator._validate_grid(step_grid, step_path + ".grid", file, errors)
				if step_type == "talk" and not target.is_empty() and not dialogues.has(target):
					ContentValidator._err(errors, file, step_path + ".target", "references missing dialogue '%s'" % target)
				if step_type == "kill":
					if not target.is_empty() and not enemies.has(target):
						ContentValidator._err(errors, file, step_path + ".target", "references missing enemy '%s'" % target)
					ContentValidator._require_int(step_dict, "count", step_path, file, errors, 1)

		var rewards = ContentValidator._require(quest, "rewards", "dictionary", path, file, errors)
		if typeof(rewards) == TYPE_DICTIONARY:
			ContentValidator._validate_rewards(rewards, path + ".rewards", file, errors, items)

	return errors


# ------------------------------------------------------------------- dialogue

static func validate_dialogue(data: Dictionary, context: Dictionary, quest_states: Array) -> Array[String]:
	var errors: Array[String] = []
	var file := "dialogue.json"
	var root := "dialogue"
	var quests: Dictionary = context.get("quests.json", {})
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
		var dialogue: Dictionary = entry

		var nodes = ContentValidator._require(dialogue, "nodes", "dictionary", path, file, errors)
		var node_ids: Dictionary = {}
		if typeof(nodes) == TYPE_DICTIONARY:
			var node_dict: Dictionary = nodes
			if node_dict.is_empty():
				ContentValidator._err(errors, file, path + ".nodes", "must contain at least one node")
			for raw_node_id in node_dict.keys():
				node_ids[str(raw_node_id)] = true

		var start := ContentValidator._require_nonempty_string(dialogue, "start", path, file, errors)
		if not start.is_empty() and not node_ids.has(start):
			ContentValidator._err(errors, file, path + ".start", "references missing node '%s'" % start)

		var start_rules: Variant = dialogue.get("start_rules", null)
		if start_rules != null:
			if typeof(start_rules) != TYPE_ARRAY:
				ContentValidator._err(errors, file, path + ".start_rules", "expected an array")
			else:
				var rules: Array = start_rules
				for index in rules.size():
					var rule: Variant = rules[index]
					var rule_path := "%s.start_rules[%d]" % [path, index]
					if typeof(rule) != TYPE_DICTIONARY:
						ContentValidator._err(errors, file, rule_path, "expected an object")
						continue
					var rule_dict: Dictionary = rule
					var condition := ContentValidator._require_string(rule_dict, "if", rule_path, file, errors)
					var node_id := ContentValidator._require_nonempty_string(rule_dict, "node", rule_path, file, errors)
					if not node_id.is_empty() and not node_ids.has(node_id):
						ContentValidator._err(errors, file, rule_path + ".node", "references missing node '%s'" % node_id)
					_validate_condition(condition, rule_path + ".if", file, errors, quests, characters, quest_states)

		if typeof(nodes) == TYPE_DICTIONARY:
			var node_dict: Dictionary = nodes
			for raw_node_id in node_dict.keys():
				var node_id := str(raw_node_id)
				var node_path := "%s.nodes.%s" % [path, node_id]
				var node: Variant = node_dict[raw_node_id]
				if typeof(node) != TYPE_DICTIONARY:
					ContentValidator._err(errors, file, node_path, "expected an object")
					continue
				var node_dict_value: Dictionary = node
				ContentValidator._require_nonempty_string(node_dict_value, "speaker", node_path, file, errors)
				ContentValidator._require_nonempty_string(node_dict_value, "text", node_path, file, errors)

				var portrait: Variant = node_dict_value.get("portrait", null)
				if portrait != null:
					if typeof(portrait) != TYPE_DICTIONARY:
						ContentValidator._err(errors, file, node_path + ".portrait", "expected an object")
					else:
						ContentValidator._validate_palette(
							portrait,
							["hair", "primary", "secondary", "accent", "skin"],
							node_path + ".portrait",
							file,
							errors
						)

				var next := ContentValidator._optional_string(node_dict_value, "next", node_path, file, errors)
				if not next.is_empty() and not node_ids.has(next):
					ContentValidator._err(errors, file, node_path + ".next", "references missing node '%s'" % next)

				var choices: Variant = node_dict_value.get("choices", null)
				if choices != null:
					if typeof(choices) != TYPE_ARRAY:
						ContentValidator._err(errors, file, node_path + ".choices", "expected an array")
					else:
						var choice_list: Array = choices
						for index in choice_list.size():
							var choice: Variant = choice_list[index]
							var choice_path := "%s.choices[%d]" % [node_path, index]
							if typeof(choice) != TYPE_DICTIONARY:
								ContentValidator._err(errors, file, choice_path, "expected an object")
								continue
							var choice_dict: Dictionary = choice
							ContentValidator._require_nonempty_string(choice_dict, "text", choice_path, file, errors)
							var choice_next := ContentValidator._optional_string(choice_dict, "next", choice_path, file, errors)
							if not choice_next.is_empty() and not node_ids.has(choice_next):
								ContentValidator._err(errors, file, choice_path + ".next", "references missing node '%s'" % choice_next)
							var action := ContentValidator._optional_string(choice_dict, "action", choice_path, file, errors)
							_validate_action(action, choice_path + ".action", file, errors, quests, characters, items)

	return errors


static func _validate_condition(
	condition: String,
	path: String,
	file: String,
	errors: Array[String],
	quests: Dictionary,
	characters: Dictionary,
	quest_states: Array
) -> void:
	if condition.is_empty():
		return
	var parts := condition.split(":", true, 2)
	match parts[0]:
		"quest_state":
			if parts.size() != 3:
				ContentValidator._err(errors, file, path, "expected quest_state:<quest_id>:<state>")
				return
			if not quests.has(parts[1]):
				ContentValidator._err(errors, file, path, "references missing quest '%s'" % parts[1])
			if not quest_states.has(parts[2]):
				ContentValidator._err(errors, file, path, "invalid quest state '%s'" % parts[2])
		"quest_ready", "quest_active", "quest_complete":
			if parts.size() < 2:
				ContentValidator._err(errors, file, path, "expected %s:<quest_id>" % parts[0])
			elif not quests.has(parts[1]):
				ContentValidator._err(errors, file, path, "references missing quest '%s'" % parts[1])
		"has_character":
			if parts.size() < 2:
				ContentValidator._err(errors, file, path, "expected has_character:<character_id>")
			elif not characters.has(parts[1]):
				ContentValidator._err(errors, file, path, "references missing character '%s'" % parts[1])
		"level_at_least":
			if parts.size() < 2 or not parts[1].is_valid_int():
				ContentValidator._err(errors, file, path, "expected level_at_least:<positive integer>")
			elif int(parts[1]) < 1:
				ContentValidator._err(errors, file, path, "level must be at least 1")
		_:
			ContentValidator._err(errors, file, path, "unknown condition '%s'" % parts[0])


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
				ContentValidator._err(errors, file, path, "expected %s:<quest_id>" % parts[0])
			elif not quests.has(parts[1]):
				ContentValidator._err(errors, file, path, "references missing quest '%s'" % parts[1])
		"add_item":
			if parts.size() < 2:
				ContentValidator._err(errors, file, path, "expected add_item:<item_id>[:count]")
			elif not items.has(parts[1]):
				ContentValidator._err(errors, file, path, "references missing item '%s'" % parts[1])
			if parts.size() >= 3 and (not parts[2].is_valid_int() or int(parts[2]) <= 0):
				ContentValidator._err(errors, file, path, "item count must be a positive integer")
		"add_currency":
			if parts.size() < 3:
				ContentValidator._err(errors, file, path, "expected add_currency:<currency_id>:<amount>")
				return
			var item: Dictionary = items.get(parts[1], {})
			if item.is_empty():
				ContentValidator._err(errors, file, path, "references missing item '%s'" % parts[1])
			elif str(item.get("category", "")) != "currency":
				ContentValidator._err(errors, file, path, "item '%s' is not a currency" % parts[1])
			if not parts[2].is_valid_int() or int(parts[2]) <= 0:
				ContentValidator._err(errors, file, path, "currency amount must be a positive integer")
		"set_flag":
			if parts.size() < 3 or parts[1].is_empty():
				ContentValidator._err(errors, file, path, "expected set_flag:<key>:<value>")
		"toast":
			if parts.size() < 2 or parts[1].is_empty():
				ContentValidator._err(errors, file, path, "expected toast:<text>")
		"open_shop":
			pass
		_:
			ContentValidator._err(errors, file, path, "unknown action '%s'" % parts[0])



class_name GameStatePersistenceComponent
extends Node
## Owns save serialization and legacy-profile migration for the GameState autoload.

var state


func bind(owner_state) -> void:
	state = owner_state


func to_dict() -> Dictionary:
	if state == null:
		return {}
	var roster_data: Array = []
	for instance in state.roster:
		roster_data.append(instance.to_dict())
	return {
		"profile": state.profile,
		"roster": roster_data,
		"party": state.party,
		"inventory": state.inventory,
		"quests": state.quests,
		"pity": state.pity,
		"flags": state.flags,
		"gear_levels": state.gear_levels.duplicate(true),
		"position": {"x": state.player_position.x, "y": state.player_position.y},
		"has_position": state.has_player_position,
		"player_facing": {"x": state.player_facing.x, "y": state.player_facing.y},
		"region": state.player_region,
		"active_world_id": state.active_world_id,
		"region_positions": state.region_positions.duplicate(true),
	}


func load_from_dict(data: Dictionary) -> void:
	if state == null:
		return
	state.profile = data.get("profile", {})
	if state.profile.is_empty():
		return
	state.roster.clear()
	var removed_uids: Dictionary = {}
	var refunded_items: Dictionary = {}
	for entry in data.get("roster", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var instance: CharacterInstance = CharacterInstance.from_dict(entry)
		if ContentDB.get_character(instance.char_id) == null or instance.uid.is_empty():
			continue
		if state.REMOVED_CHARACTERS.has(instance.char_id):
			# Retire removed starter characters while refunding all equipped items.
			removed_uids[instance.uid] = true
			for slot in instance.equipment.keys():
				var item_id: String = str(instance.equipment[slot])
				if not item_id.is_empty():
					refunded_items[item_id] = int(refunded_items.get(item_id, 0)) + 1
			continue
		state.roster.append(instance)

	# Older saves may not contain the current starting trio.
	state._ensure_starting_characters()
	state.party.clear()
	var party_had_removed := false
	for uid in data.get("party", []):
		var text_uid: String = str(uid)
		if removed_uids.has(text_uid):
			party_had_removed = true
			continue
		if state._find_instance(text_uid) != null and not state.party.has(text_uid):
			state.party.append(text_uid)
	if party_had_removed:
		state._reset_party_to_starters()
	else:
		state._fill_party()

	state.inventory = data.get("inventory", {})
	for item_id in refunded_items.keys():
		state.inventory[item_id] = int(state.inventory.get(item_id, 0)) + int(refunded_items[item_id])
	state.quests = data.get("quests", {})
	state.pity = data.get("pity", {})
	state.flags = data.get("flags", {})
	var saved_gear_levels: Variant = data.get("gear_levels", {})
	state.gear_levels = saved_gear_levels.duplicate(true) if typeof(saved_gear_levels) == TYPE_DICTIONARY else {}
	var pos: Dictionary = data.get("position", {})
	state.player_position = Vector2(float(pos.get("x", 0.0)), float(pos.get("y", 0.0)))
	state.has_player_position = bool(data.get("has_position", false))
	var facing: Variant = data.get("player_facing", null)
	if typeof(facing) == TYPE_DICTIONARY:
		var facing_data: Dictionary = facing
		state.player_facing = Vector2(float(facing_data.get("x", 0.0)), float(facing_data.get("y", 1.0)))
		if state.player_facing.length_squared() < 0.0001:
			state.player_facing = Vector2(0.0, 1.0)
	elif facing is Vector2:
		state.player_facing = (facing as Vector2).normalized() if (facing as Vector2).length_squared() > 0.0001 else Vector2(0.0, 1.0)
	else:
		state.player_facing = Vector2(0.0, 1.0)

	# Per-region/world fields are optional so old saves remain loadable.
	state.player_region = str(data.get("region", data.get("active_world_id", "greenward")))
	if state.player_region.is_empty():
		state.player_region = "greenward"
	state.active_world_id = str(data.get("active_world_id", state.player_region))
	if state.active_world_id.is_empty():
		state.active_world_id = state.player_region
	state.player_region = state.active_world_id
	var region_positions_value: Variant = data.get("region_positions", {})
	state.region_positions = region_positions_value.duplicate(true) if typeof(region_positions_value) == TYPE_DICTIONARY else {}
	if state.has_player_position and not state.region_positions.has(state.player_region):
		state.region_positions[state.player_region] = {"x": state.player_position.x, "y": state.player_position.y}

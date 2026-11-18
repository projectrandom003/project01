class_name EquipmentStatModifiers
extends RefCounted

const SET_BONUSES := {
	"greenward_wayfarer": {
		2: {"hp": 40.0, "def": 4.0},
		3: {"spd": 5.0, "crit": 0.02}
	}
}

static func for_character(uid: String) -> Dictionary:
	return _compute(uid)


static func set_bonus_for_character(uid: String) -> Dictionary:
	var bonuses := {"hp": 0.0, "atk": 0.0, "def": 0.0, "spd": 0.0, "crit": 0.0, "crit_dmg": 0.0}
	for slot in CharacterInstance.SLOTS:
		var rolled: Dictionary = GameState.gear_rerolls.get(uid + "|" + slot, {})
		var rolled_stat := str(rolled.get("stat", ""))
		if bonuses.has(rolled_stat):
			bonuses[rolled_stat] = float(bonuses[rolled_stat]) + float(rolled.get("value", 0.0))
	var instance: CharacterInstance = null
	for candidate in GameState.roster_domain.roster:
		if candidate.uid == uid:
			instance = candidate
			break
	if instance == null:
		return bonuses
	var equipped_sets: Dictionary = {}
	for slot in CharacterInstance.SLOTS:
		var item_id := instance.equipped_item(slot)
		if item_id.is_empty():
			continue
		var set_id := str(ContentDB.get_item(item_id).get("set_id", ""))
		if not set_id.is_empty():
			equipped_sets[set_id] = int(equipped_sets.get(set_id, 0)) + 1
	for set_id in equipped_sets:
		var thresholds: Dictionary = SET_BONUSES.get(set_id, {})
		var count := int(equipped_sets[set_id])
		for threshold in thresholds:
			if count < int(threshold):
				continue
			var bonus: Dictionary = thresholds[threshold]
			for stat in bonus:
				bonuses[str(stat)] = float(bonuses.get(str(stat), 0.0)) + float(bonus[stat])
	return bonuses


static func _compute(uid: String) -> Dictionary:
	var total := {"hp": 0.0, "atk": 0.0, "def": 0.0, "spd": 0.0, "crit": 0.0, "crit_dmg": 0.0}
	var instance: CharacterInstance = null
	for candidate in GameState.roster_domain.roster:
		if candidate.uid == uid:
			instance = candidate
			break
	if instance == null:
		return total
	var equipped_sets: Dictionary = {}
	for slot in CharacterInstance.SLOTS:
		var item_id := instance.equipped_item(slot)
		if item_id.is_empty():
			continue
		var item := ContentDB.get_item(item_id)
		var set_id := str(item.get("set_id", ""))
		if not set_id.is_empty():
			equipped_sets[set_id] = int(equipped_sets.get(set_id, 0)) + 1
		var stats: Dictionary = item.get("stats", {})
		var enhancement_mult := 1.0 + 0.08 * float(GameState.roster_domain.gear_level(uid, slot))
		for k in stats.keys():
			var key := str(k)
			if not total.has(key):
				total[key] = 0.0
			total[key] = float(total[key]) + float(stats[k]) * enhancement_mult
	for set_id in equipped_sets:
		var thresholds: Dictionary = SET_BONUSES.get(set_id, {})
		var count := int(equipped_sets[set_id])
		for threshold in thresholds:
			if count < int(threshold):
				continue
			var bonus: Dictionary = thresholds[threshold]
			for stat in bonus:
				var key := str(stat)
				if not total.has(key):
					total[key] = 0.0
				total[key] = float(total[key]) + float(bonus[stat])
	return total

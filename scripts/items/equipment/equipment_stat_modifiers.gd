class_name EquipmentStatModifiers
extends RefCounted

static func for_character(uid: String) -> Dictionary:
	return _compute(uid)


static func _compute(uid: String) -> Dictionary:
	var total := {"hp": 0.0, "atk": 0.0, "def": 0.0, "spd": 0.0, "crit": 0.0, "crit_dmg": 0.0}
	var instance: CharacterInstance = null
	for candidate in GameState.roster_domain.roster:
		if candidate.uid == uid:
			instance = candidate
			break
	if instance == null:
		return total
	for slot in CharacterInstance.SLOTS:
		var item_id := instance.equipped_item(slot)
		if item_id.is_empty():
			continue
		var item := ContentDB.get_item(item_id)
		var stats: Dictionary = item.get("stats", {})
		var enhancement_mult := 1.0 + 0.08 * float(GameState.roster_domain.gear_level(uid, slot))
		for k in stats.keys():
			var key := str(k)
			if not total.has(key):
				total[key] = 0.0
			total[key] = float(total[key]) + float(stats[k]) * enhancement_mult
	return total

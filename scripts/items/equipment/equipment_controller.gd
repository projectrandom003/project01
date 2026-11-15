class_name EquipmentController
extends Node

signal equipment_changed(uid: String, slot: String, item_id: String)
signal equipment_failed(uid: String, slot: String, reason: String)
signal equipment_upgraded(uid: String, slot: String, level: int)
signal stat_modifiers_changed(uid: String)

@export var game_state_path: NodePath


func get_equipped(uid: String, slot: String) -> String:
	var instance: CharacterInstance = null
	for candidate in GameState.roster:
		if candidate.uid == uid:
			instance = candidate
			break
	return instance.equipped_item(slot) if instance != null else ""


func can_equip(uid: String, item_id: String) -> Dictionary:
	var data := ContentDB.get_item(item_id)
	if data.is_empty():
		return {"ok": false, "reason": "Unknown item."}
	if str(data.get("category", "")) != "equipment":
		return {"ok": false, "reason": "Item is not equipment."}
	var slot := str(data.get("slot", ""))
	if not CharacterInstance.SLOTS.has(slot):
		return {"ok": false, "reason": "Invalid equipment slot."}
	if GameState.item_count(item_id) <= 0:
		return {"ok": false, "reason": "Item not in inventory."}
	return {"ok": true, "slot": slot}


func equip(uid: String, item_id: String) -> bool:
	var check := can_equip(uid, item_id)
	if not bool(check.get("ok", false)):
		equipment_failed.emit(uid, str(check.get("slot", "")), str(check.get("reason", "Cannot equip item.")))
		return false
	var slot := str(check.get("slot", ""))
	if GameState.equip_item(uid, item_id):
		equipment_changed.emit(uid, slot, item_id)
		stat_modifiers_changed.emit(uid)
		return true
	equipment_failed.emit(uid, slot, "Equip failed.")
	return false


func unequip(uid: String, slot: String) -> bool:
	if GameState.unequip_item(uid, slot):
		equipment_changed.emit(uid, slot, "")
		stat_modifiers_changed.emit(uid)
		return true
	equipment_failed.emit(uid, slot, "Unequip failed.")
	return false


func get_stat_modifiers(uid: String) -> Dictionary:
	var total := {"hp": 0.0, "atk": 0.0, "def": 0.0, "spd": 0.0, "crit": 0.0, "crit_dmg": 0.0}
	var instance: CharacterInstance = null
	for candidate in GameState.roster:
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
		var enhancement_mult := 1.0 + 0.08 * float(GameState.gear_level(uid, slot))
		for k in stats.keys():
			var key := str(k)
			if not total.has(key):
				total[key] = 0.0
			total[key] = float(total[key]) + float(stats[k]) * enhancement_mult
	return total


func upgrade_info(uid: String, slot: String) -> Dictionary:
	return GameState.gear_upgrade_info(uid, slot)


func enhance(uid: String, slot: String) -> bool:
	if GameState.enhance_gear(uid, slot):
		equipment_upgraded.emit(uid, slot, GameState.gear_level(uid, slot))
		stat_modifiers_changed.emit(uid)
		return true
	return false

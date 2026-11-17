class_name EquipmentLoadout
extends RefCounted

var uid: String = ""
var slots: Dictionary = {} # slot_name -> EquipmentSlot


static func for_character(character_uid: String):
	var loadout = (load("res://scripts/items/equipment/equipment_loadout.gd") as GDScript).new()
	loadout.uid = character_uid
	var slot_script := load("res://scripts/items/equipment/equipment_slot.gd") as GDScript
	for slot_name in CharacterInstance.SLOTS:
		loadout.slots[slot_name] = slot_script.create(slot_name, [slot_name])
	loadout.sync_from_game_state()
	return loadout


func sync_from_game_state() -> void:
	var instance = null
	for candidate in GameState.roster_domain.roster:
		if candidate.uid == uid:
			instance = candidate
			break
	if instance == null:
		return
	for slot_name in CharacterInstance.SLOTS:
		var slot = slots.get(slot_name, null)
		if slot != null:
			slot.equipped_item_id = instance.equipped_item(slot_name)


func get_item(slot_name: String) -> String:
	var slot: EquipmentSlot = slots.get(slot_name, null)
	return slot.equipped_item_id if slot != null else ""

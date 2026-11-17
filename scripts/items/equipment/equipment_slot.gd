class_name EquipmentSlot
extends RefCounted

signal changed(slot_name: String, item_id: String)

var slot_name: String = ""
var equipped_item_id: String = ""
var allowed_types: Array[String] = []


static func create(name_value: String, allowed: Array[String] = []):
	var slot = (load("res://scripts/items/equipment/equipment_slot.gd") as GDScript).new()
	slot.slot_name = name_value
	slot.allowed_types = allowed.duplicate()
	return slot


func can_accept(item_data: Dictionary) -> bool:
	if str(item_data.get("category", "")) != "equipment":
		return false
	if not slot_name.is_empty() and str(item_data.get("slot", "")) != slot_name:
		return false
	if not allowed_types.is_empty():
		var t := str(item_data.get("slot", item_data.get("type", "")))
		if not allowed_types.has(t):
			return false
	return true


func equip(item_id: String) -> void:
	equipped_item_id = item_id
	changed.emit(slot_name, item_id)


func unequip() -> String:
	var prev := equipped_item_id
	equipped_item_id = ""
	changed.emit(slot_name, "")
	return prev

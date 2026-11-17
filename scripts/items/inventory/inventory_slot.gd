class_name InventorySlot
extends RefCounted

signal selected(item_id: String)
signal activated(item_id: String, action: String)

var index: int = -1
var item_id: String = ""
var quantity: int = 0
var equipped_count: int = 0
var locked: bool = false
var filter: String = "all"


static func from_item(item_id_value: String, qty: int, idx: int = -1):
	var slot = (load("res://scripts/items/inventory/inventory_slot.gd") as GDScript).new()
	slot.index = idx
	slot.item_id = item_id_value
	slot.quantity = qty
	return slot


func is_empty() -> bool:
	return item_id.is_empty() or quantity <= 0


func matches_filter(filter_id: String) -> bool:
	if filter_id == "all" or item_id.is_empty():
		return true
	return str(ContentDB.get_item(item_id).get("category", "")) == filter_id

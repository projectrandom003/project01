class_name InventorySelection
extends RefCounted

signal changed(item_id: String)

var selected_item_id: String = ""


func select(item_id: String) -> void:
	selected_item_id = item_id
	changed.emit(item_id)


func clear() -> void:
	selected_item_id = ""
	changed.emit("")

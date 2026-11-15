class_name InventoryController
extends Node

signal inventory_updated
signal item_added(item_id: String, amount: int, total: int)
signal item_removed(item_id: String, amount: int, total: int)
signal item_moved(from_index: int, to_index: int)
signal item_selected(item_id: String)
signal item_inspected(item_id: String)
signal item_used(item_id: String)
signal inventory_full(item_id: String, amount: int)
signal notification_requested(message: String, kind: String)

@export var capacity: int = 0 # 0 = unlimited (current behavior)


func get_items(filter: String = "all") -> Array[String]:
	var ids: Array[String] = []
	for key in GameState.inventory.keys():
		var item_id := str(key)
		var count := int(GameState.inventory[key])
		if count <= 0:
			continue
		var data := ContentDB.get_item(item_id)
		if data.is_empty():
			continue
		var category := str(data.get("category", "material"))
		if filter == "all" or filter == category:
			ids.append(item_id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var da := ContentDB.get_item(a)
		var db := ContentDB.get_item(b)
		var ca := str(da.get("category", ""))
		var cb := str(db.get("category", ""))
		if ca == cb:
			return str(da.get("name", a)) < str(db.get("name", b))
		return ca < cb
	)
	return ids


func add_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	if capacity > 0 and get_unique_item_count() >= capacity and GameState.item_count(item_id) <= 0:
		inventory_full.emit(item_id, amount)
		notification_requested.emit("Inventory is full.", "warning")
		return false
	var before := GameState.item_count(item_id)
	GameState.add_item(item_id, amount)
	var total := GameState.item_count(item_id)
	item_added.emit(item_id, amount, total)
	inventory_updated.emit()
	return total >= before + amount or amount == 0


func remove_item(item_id: String, amount: int = 1) -> bool:
	if not GameState.remove_item(item_id, amount):
		return false
	var total := GameState.item_count(item_id)
	item_removed.emit(item_id, amount, total)
	inventory_updated.emit()
	return true


func get_count(item_id: String) -> int:
	return GameState.item_count(item_id)


func get_unique_item_count() -> int:
	var n := 0
	for k in GameState.inventory.keys():
		if int(GameState.inventory[k]) > 0:
			n += 1
	return n


func select_item(item_id: String) -> void:
	item_selected.emit(item_id)


func inspect_item(item_id: String) -> void:
	item_inspected.emit(item_id)


func use_item(item_id: String) -> bool:
	var data := ContentDB.get_item(item_id)
	if data.is_empty():
		return false
	if str(data.get("category", "")) not in ["consumable"]:
		notification_requested.emit("This item cannot be used here.", "info")
		return false
	if get_count(item_id) <= 0:
		return false
	if not remove_item(item_id, 1):
		return false
	item_used.emit(item_id)
	notification_requested.emit("Used %s." % str(data.get("name", item_id)), "success")
	return true


func split_stack(item_id: String, amount: int) -> bool:
	# Logical split helper for UI workflows; GameState stores quantity by id.
	var have := get_count(item_id)
	return amount > 0 and amount < have


func move_item(from_index: int, to_index: int) -> void:
	item_moved.emit(from_index, to_index)
	inventory_updated.emit()

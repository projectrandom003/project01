class_name ItemDatabase
extends RefCounted
## Resolves item definitions from existing ContentDB data (single source of truth).

static func get_item_data(item_id: String) -> Dictionary:
	return ContentDB.get_item(item_id)


static func get_definition(item_id: String):
	var data := get_item_data(item_id)
	if data.is_empty():
		return null
	return (load("res://scripts/items/item_definition.gd") as GDScript).from_content_item(item_id, data)


static func get_category(item_id: String) -> String:
	return str(get_item_data(item_id).get("category", ""))


static func get_rarity(item_id: String) -> String:
	return str(get_item_data(item_id).get("rarity", "common"))


static func is_currency(item_id: String) -> bool:
	return get_category(item_id) == "currency"


static func is_equipment(item_id: String) -> bool:
	return get_category(item_id) == "equipment"


static func is_stackable(item_id: String) -> bool:
	return not is_equipment(item_id)


static func stack_limit(item_id: String) -> int:
	var data := get_item_data(item_id)
	if str(data.get("category", "")) == "equipment":
		return 1
	return maxi(1, int(data.get("stack_limit", 999)))

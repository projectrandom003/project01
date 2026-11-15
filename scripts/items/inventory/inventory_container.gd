class_name InventoryContainer
extends RefCounted
## Logical container view over the authoritative GameState inventory.

var filter_id: String = "all"
var sort_mode: String = "category_name"


func build_slots() -> Array:
	var slots: Array = []
	var ids: Array = []
	for key in GameState.inventory.keys():
		var item_id := str(key)
		var count := int(GameState.inventory[key])
		if count <= 0:
			continue
		var category := str(ContentDB.get_item(item_id).get("category", ""))
		if filter_id != "all" and category != filter_id and not (filter_id == "currency" and category == "currency"):
			continue
		ids.append(item_id)
	ids = _sorted(ids)
	var i := 0
	for item_id in ids:
		var slot_script := load("res://scripts/items/inventory/inventory_slot.gd") as GDScript
		var slot = slot_script.from_item(str(item_id), GameState.item_count(str(item_id)), i)
		if str(ContentDB.get_item(str(item_id)).get("category", "")) == "equipment":
			slot.equipped_count = _equipped_count(str(item_id))
		slots.append(slot)
		i += 1
	return slots


func _sorted(ids: Array[String]) -> Array[String]:
	ids.sort_custom(func(a: String, b: String) -> bool:
		var da := ContentDB.get_item(a)
		var db := ContentDB.get_item(b)
		var ca := str(da.get("category", ""))
		var cb := str(db.get("category", ""))
		if ca == cb:
			var ra := str(da.get("rarity", "common"))
			var rb := str(db.get("rarity", "common"))
			if ra == rb:
				return str(da.get("name", a)) < str(db.get("name", b))
			return ra < rb
		return ca < cb
	)
	return ids


func _equipped_count(item_id: String) -> int:
	var n := 0
	for instance in GameState.roster:
		for slot in CharacterInstance.SLOTS:
			if instance.equipped_item(slot) == item_id:
				n += 1
	return n

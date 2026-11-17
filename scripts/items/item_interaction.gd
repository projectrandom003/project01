class_name ItemInteraction
extends RefCounted

signal completed(action: String, item_id: String, ok: bool, message: String)

static func inspect(item_id: String) -> Dictionary:
	return ContentDB.get_item(item_id).duplicate(true)


static func can_equip(uid: String, item_id: String) -> Dictionary:
	var data := ContentDB.get_item(item_id)
	if str(data.get("category", "")) != "equipment":
		return {"ok": false, "reason": "Not equipment."}
	if not CharacterInstance.SLOTS.has(str(data.get("slot", ""))):
		return {"ok": false, "reason": "Invalid slot."}
	if GameState.inventory_domain.item_count(item_id) <= 0:
		return {"ok": false, "reason": "Item not owned."}
	return {"ok": true, "reason": ""}


static func equip(uid: String, item_id: String) -> Dictionary:
	var check := can_equip(uid, item_id)
	if not bool(check.get("ok", false)):
		return check
	var ok := GameState.roster_domain.equip_item(uid, item_id)
	return {"ok": ok, "reason": "" if ok else "Equip failed."}


static func unequip(uid: String, slot: String) -> Dictionary:
	var ok := GameState.roster_domain.unequip_item(uid, slot)
	return {"ok": ok, "reason": "" if ok else "Unequip failed."}


static func use(item_id: String) -> Dictionary:
	var data := ContentDB.get_item(item_id)
	var category := str(data.get("category", ""))
	if category != "consumable":
		return {"ok": false, "reason": "This item cannot be used here."}
	if GameState.inventory_domain.item_count(item_id) <= 0:
		return {"ok": false, "reason": "Item not available."}
	# Preserve existing behavior: consume count; effects can be extended by data.
	GameState.inventory_domain.remove_item(item_id, 1)
	return {"ok": true, "reason": "Used %s." % str(data.get("name", item_id))}


static func consume(item_id: String) -> Dictionary:
	return use(item_id)


static func drop_item(item_id: String, amount: int = 1) -> Dictionary:
	if GameState.inventory_domain.item_count(item_id) < amount:
		return {"ok": false, "reason": "Not enough items."}
	var category := str(ContentDB.get_item(item_id).get("category", ""))
	if category in ["currency", "quest_item"]:
		return {"ok": false, "reason": "Cannot drop this item."}
	GameState.inventory_domain.remove_item(item_id, amount)
	return {"ok": true, "reason": "Dropped %s." % str(ContentDB.get_item(item_id).get("name", item_id))}


static func sell(item_id: String, amount: int = 1) -> Dictionary:
	var data := ContentDB.get_item(item_id)
	if data.is_empty():
		return {"ok": false, "reason": "Unknown item."}
	var value := int(data.get("sell_value", data.get("value", 0)))
	if value <= 0:
		return {"ok": false, "reason": "This item cannot be sold."}
	if GameState.inventory_domain.item_count(item_id) < amount:
		return {"ok": false, "reason": "Not enough items."}
	if not GameState.inventory_domain.remove_item(item_id, amount):
		return {"ok": false, "reason": "Could not sell item."}
	GameState.inventory_domain.add_currency("gold", value * amount)
	return {"ok": true, "reason": "Sold for %d gold." % (value * amount)}


static func compare(uid: String, item_id: String) -> Dictionary:
	return {"ok": true, "item": ContentDB.get_item(item_id), "uid": uid}


static func upgrade(uid: String, slot: String) -> Dictionary:
	if GameState.roster_domain.enhance_gear(uid, slot):
		return {"ok": true, "reason": "Equipment enhanced."}
	var info := GameState.roster_domain.gear_upgrade_info(uid, slot)
	return {"ok": false, "reason": str(info.get("reason", "Cannot upgrade."))}


static func transfer(item_id: String, amount: int = 1) -> Dictionary:
	return {"ok": amount > 0 and GameState.inventory_domain.item_count(item_id) >= amount, "reason": ""}

class_name ShopService
extends RefCounted
## Local merchant stock and purchases for the offline single-player economy.

const STOCK: Dictionary = {
	"glade_sap": {"price": 35},
	"moonpetal": {"price": 60},
	"dew_of_awakening": {"price": 300},
	"hollow_heart": {"price": 850},
	"gladewood_bow": {"price": 500},
	"mossweave_vest": {"price": 650},
	"wayfarer_charm": {"price": 800},
	"sunfire_blade": {"price": 1800}
}


static func stock_ids() -> Array[String]:
	var result: Array[String] = []
	for item_id in STOCK.keys():
		result.append(str(item_id))
	result.sort()
	return result


static func stock_entry(item_id: String) -> Dictionary:
	return (STOCK.get(item_id, {}) as Dictionary).duplicate(true)


static func purchase(item_id: String) -> Dictionary:
	var entry := stock_entry(item_id)
	if entry.is_empty():
		return {"ok": false, "reason": "That item is not in the caravan stock."}
	var item: Dictionary = ContentDB.get_item(item_id)
	if item.is_empty():
		return {"ok": false, "reason": "The merchant's stock references an unknown item."}
	var price := int(entry.get("price", -1))
	if price <= 0:
		return {"ok": false, "reason": "This item has an invalid price."}
	if GameState.inventory_domain.currency("gold") < price:
		return {"ok": false, "reason": "Not enough Gold."}
	if not GameState.inventory_domain.spend_currency("gold", price):
		return {"ok": false, "reason": "Your Gold balance changed. Try again."}
	GameState.inventory_domain.add_item(item_id, 1)
	return {
		"ok": true,
		"item_id": item_id,
		"price": price,
		"reason": "Purchased %s." % str(item.get("name", item_id))
	}

class_name ItemTransfer
extends RefCounted

static func transfer(from_inventory_owner: Variant, to_inventory_owner: Variant, item_id: String, amount: int) -> bool:
	# Current authoritative inventory is global in GameState; transfers operate as move/remove+add hooks.
	if amount <= 0:
		return false
	if not GameState.remove_item(item_id, amount):
		return false
	GameState.add_item(item_id, amount)
	return true


static func can_transfer(item_id: String, amount: int) -> bool:
	return amount > 0 and GameState.item_count(item_id) >= amount

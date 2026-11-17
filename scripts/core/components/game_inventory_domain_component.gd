class_name GameInventoryDomainComponent
extends Node
## Owns wallet and item-inventory mutations for the persistent offline profile.

var state: Node
var inventory: Dictionary = {}


func _ready() -> void:
	state = get_parent()


func currency(kind: String) -> int:
	var profile: Dictionary = GameState.profile_domain.profile
	return int(profile.get(kind, 0))


func add_currency(kind: String, amount: int) -> void:
	var profile: Dictionary = GameState.profile_domain.profile
	profile[kind] = currency(kind) + amount
	EventBus.currency_changed.emit()
	state.call("queue_save")


func spend_currency(kind: String, amount: int) -> bool:
	if amount < 0 or currency(kind) < amount:
		return false
	var profile: Dictionary = GameState.profile_domain.profile
	profile[kind] = currency(kind) - amount
	EventBus.currency_changed.emit()
	state.call("queue_save")
	return true


func add_item(item_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	inventory[item_id] = int(inventory.get(item_id, 0)) + amount
	EventBus.inventory_changed.emit()
	state.call("queue_save")


func grant_reward_items(rewards: Dictionary) -> void:
	for item_id in rewards.keys():
		var id := str(item_id)
		var amount := int(rewards[item_id])
		if amount <= 0:
			continue
		if str(ContentDB.get_item(id).get("category", "")) == "currency":
			add_currency(id, amount)
		else:
			add_item(id, amount)


func item_count(item_id: String) -> int:
	return int(inventory.get(item_id, 0))


func remove_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0 or item_count(item_id) < amount:
		return false
	var remaining := item_count(item_id) - amount
	if remaining <= 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = remaining
	EventBus.inventory_changed.emit()
	state.call("queue_save")
	return true

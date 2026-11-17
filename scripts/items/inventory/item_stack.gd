class_name ItemStack
extends RefCounted

var item_id: String = ""
var quantity: int = 0
var max_stack: int = 999
var metadata: Dictionary = {}


static func from_state(item_id_value: String, qty: int):
	var s = (load("res://scripts/items/inventory/item_stack.gd") as GDScript).new()
	s.item_id = item_id_value
	s.quantity = maxi(0, qty)
	var data := ContentDB.get_item(item_id_value)
	s.max_stack = 1 if str(data.get("category", "")) == "equipment" else maxi(1, int(data.get("stack_limit", 999)))
	return s


func can_stack_with(other_id: String) -> bool:
	if item_id != other_id:
		return false
	return str(ContentDB.get_item(item_id).get("category", "")) != "equipment"


func space_left() -> int:
	return maxi(0, max_stack - quantity)


func add(amount: int) -> int:
	var addable := mini(maxi(0, amount), space_left())
	quantity += addable
	return amount - addable


func remove(amount: int) -> int:
	var removable := mini(maxi(0, amount), quantity)
	quantity -= removable
	return amount - removable


func is_empty() -> bool:
	return quantity <= 0

class_name ItemFilter
extends RefCounted

static func matches(item_id: String, filter_id: String) -> bool:
	if filter_id == "all" or filter_id.is_empty():
		return true
	var category := str(ContentDB.get_item(item_id).get("category", ""))
	if filter_id == "currency":
		return category == "currency"
	return category == filter_id

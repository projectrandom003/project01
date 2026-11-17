class_name ItemSorter
extends RefCounted

static func sort_ids(ids: Array[String], mode: String = "category_name") -> Array[String]:
	var out := ids.duplicate()
	out.sort_custom(func(a: String, b: String) -> bool:
		var da := ContentDB.get_item(a)
		var db := ContentDB.get_item(b)
		match mode:
			"name":
				return str(da.get("name", a)) < str(db.get("name", b))
			"rarity":
				return str(da.get("rarity", "")) < str(db.get("rarity", ""))
			"quantity":
				return GameState.inventory_domain.item_count(a) > GameState.inventory_domain.item_count(b)
			_:
				var ca := str(da.get("category", ""))
				var cb := str(db.get("category", ""))
				if ca == cb:
					return str(da.get("name", a)) < str(db.get("name", b))
				return ca < cb
	)
	return out

class_name ItemComparison
extends RefCounted

static func compare_equipment(item_data: Dictionary, current_item_data: Dictionary) -> Dictionary:
	var next_stats: Dictionary = item_data.get("stats", {})
	var old_stats: Dictionary = current_item_data.get("stats", {})
	var keys: Array = []
	for k in next_stats.keys():
		if not keys.has(k): keys.append(k)
	for k in old_stats.keys():
		if not keys.has(k): keys.append(k)
	var deltas: Dictionary = {}
	for k in keys:
		deltas[str(k)] = float(next_stats.get(k, 0.0)) - float(old_stats.get(k, 0.0))
	return {
		"keys": keys,
		"deltas": deltas,
		"current_name": str(current_item_data.get("name", "Empty slot")),
		"next_name": str(item_data.get("name", "")),
	}


static func build_comparison_box(item_data: Dictionary, uid: String) -> VBoxContainer:
	var box := UIFactory.vbox(4)
	box.name = "EquipmentComparison"
	box.add_child(UIFactory.label("COMPARISON — CURRENTLY EQUIPPED", 9, UITheme.TEXT_FAINT))
	var instance: CharacterInstance = null
	for candidate in GameState.roster:
		if candidate.uid == uid:
			instance = candidate
			break
	if instance == null:
		box.add_child(UIFactory.label("Select a character to compare gear.", 10, UITheme.TEXT_DIM))
		return box
	var slot := str(item_data.get("slot", ""))
	var current_id := instance.equipped_item(slot)
	var current: Dictionary = ContentDB.get_item(current_id) if not current_id.is_empty() else {}
	var result := compare_equipment(item_data, current)
	box.add_child(UIFactory.label("Equipped: %s" % str(result.get("current_name", "Empty slot")), 11, UITheme.TEXT))
	var deltas: Dictionary = result.get("deltas", {})
	for key in result.get("keys", []):
		var delta := float(deltas.get(str(key), 0.0))
		var sign := "+" if delta > 0.0 else "" if delta == 0.0 else ""
		var tint := UITheme.GREEN if delta > 0.0 else UITheme.DANGER if delta < 0.0 else UITheme.TEXT_DIM
		box.add_child(UIFactory.label("%s  %s%s" % [str(key).to_upper(), sign, str(delta)], 10, tint))
	if current_id == str(item_data.get("id", "")):
		box.add_child(UIFactory.label("Already equipped in this slot.", 10, UITheme.TEXT_DIM))
	return box

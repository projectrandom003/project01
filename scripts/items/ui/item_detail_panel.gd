class_name ItemDetailPanel
extends VBoxContainer

signal equip_requested(item_id: String, uid: String)
signal unequip_requested(uid: String, slot: String)
signal enhance_requested(uid: String, slot: String)
signal use_requested(item_id: String)

const INVENTORY_ITEM_ICON_SCENE: PackedScene = preload("res://scenes/ui/components/inventory_item_icon.tscn")
const EQUIPMENT_TARGET_PICKER_SCENE: PackedScene = preload("res://scenes/ui/components/equipment_target_picker.tscn")

var _item_id: String = ""
var _target_uid: String = ""


func show_item(item_id: String) -> void:
	_item_id = item_id
	UIFactory.clear(self)
	if item_id.is_empty():
		add_child(UIFactory.label("No item selected.", 13, UITheme.TEXT_DIM))
		return
	var item := ContentDB.get_item(item_id)
	if item.is_empty():
		add_child(UIFactory.label("Unknown item.", 13, UITheme.DANGER))
		return
	var c := str(item.get("color", ""))
	var color: Color = Color(c) if c.begins_with("#") else UITheme.rarity_color(str(item.get("rarity", "common")))
	var category := str(item.get("category", "material"))
	var rarity := str(item.get("rarity", "common"))

	var icon_center := INVENTORY_ITEM_ICON_SCENE.instantiate() as CenterContainer
	var icon_frame := icon_center.get_node("Frame") as PanelContainer
	icon_frame.add_theme_stylebox_override("panel", UITheme.style(color.darkened(0.62), color, 12, 1, 10))
	var letter := icon_center.get_node("Frame/Letter") as Label
	letter.text = str(item.get("name", "?")).substr(0, 1).to_upper()
	letter.add_theme_color_override("font_color", color)
	add_child(icon_center)

	var name_label := UIFactory.heading(str(item.get("name", item_id)), 22, UITheme.TEXT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(name_label)

	var chips := UIFactory.hbox(6)
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_child(UIFactory.chip(category.capitalize(), UITheme.TEXT_DIM))
	if category != "currency":
		chips.add_child(UIFactory.rarity_chip(rarity))
	if item.has("element"):
		chips.add_child(UIFactory.element_chip(str(item.get("element", "neutral"))))
	add_child(chips)

	var amount := GameState.currency(item_id) if category == "currency" else GameState.item_count(item_id)
	add_child(UIFactory.label("Owned: %s" % UIFactory.number(amount), 12, UITheme.TEXT_DIM))
	add_child(UIFactory.wrapped(str(item.get("description", "")), 12, UITheme.TEXT_DIM))
	add_child(UIFactory.separator())

	var stats: Dictionary = item.get("stats", {})
	if not stats.is_empty():
		add_child(UIFactory.label("STAT BONUSES", 10, UITheme.TEXT_FAINT))
		var stat_grid := UIFactory.grid(2, 4)
		for key in stats.keys():
			var row := UIFactory.panel(Color("#0d1524"), Color(0, 0, 0, 0), 6, 0, 6)
			var box := UIFactory.hbox(8)
			box.add_child(UIFactory.label(str(key).to_upper(), 11, UITheme.TEXT_FAINT))
			box.add_child(UIFactory.spacer())
			box.add_child(UIFactory.label("+%s" % str(stats[key]), 12, UITheme.GREEN))
			row.add_child(box)
			stat_grid.add_child(row)
		add_child(stat_grid)

	if category == "equipment":
		_build_equipment_actions(item, amount)
	elif category == "material":
		add_child(UIFactory.wrapped("Materials are used for ascension and future crafting. They are not consumed automatically.", 11, UITheme.TEXT_FAINT))
	elif category == "consumable":
		var use_button := UIFactory.button("Use", true)
		use_button.disabled = amount <= 0
		use_button.pressed.connect(func() -> void: use_requested.emit(_item_id))
		add_child(use_button)


func _build_equipment_actions(item: Dictionary, amount: int) -> void:
	var slot_id := str(item.get("slot", ""))
	add_child(UIFactory.chip("SLOT  " + slot_id.capitalize(), UITheme.TEAL))
	var equipped_by := _equipped_by(_item_id)
	if not equipped_by.is_empty():
		add_child(UIFactory.label("Equipped by: " + ", ".join(equipped_by), 11, UITheme.TEAL))
		for instance in GameState.roster:
			var definition: CharacterDef = ContentDB.get_character(instance.char_id)
			if definition == null:
				continue
			for slot in CharacterInstance.SLOTS:
				if instance.equipped_item(slot) == _item_id:
					var unequip_button := UIFactory.small_button("Unequip from " + definition.display_name)
					var uid_str: String = str(instance.uid)
					var slot_name_str: String = str(slot)
					unequip_button.pressed.connect(func() -> void: unequip_requested.emit(uid_str, slot_name_str))
					add_child(unequip_button)
	var target_row := UIFactory.vbox(4)
	target_row.add_child(UIFactory.label("Equip to", 11, UITheme.TEXT_FAINT))
	var picker := EQUIPMENT_TARGET_PICKER_SCENE.instantiate() as OptionButton
	var index := 0
	for instance in GameState.roster:
		var definition: CharacterDef = ContentDB.get_character(instance.char_id)
		if definition == null:
			continue
		picker.add_item("%s  ·  Lv %d" % [definition.display_name, instance.level])
		picker.set_item_metadata(index, instance.uid)
		index += 1
	if index == 0:
		picker.disabled = true
		target_row.add_child(picker)
	else:
		_target_uid = str(picker.get_item_metadata(0))
		target_row.add_child(picker)
		var comparison := _build_comparison(item, _target_uid)
		add_child(comparison)
		_maybe_add_enhancement(_target_uid, slot_id)
		picker.item_selected.connect(func(selected: int) -> void:
			_target_uid = str(picker.get_item_metadata(selected))
			var old_comparison := get_node_or_null("EquipmentComparison")
			if old_comparison != null:
				old_comparison.queue_free()
			var next_comparison := _build_comparison(item, _target_uid)
			next_comparison.name = "EquipmentComparison"
			add_child(next_comparison)
		)
	var equip_button := UIFactory.button("Equip", true)
	equip_button.disabled = amount <= 0 or index == 0
	equip_button.pressed.connect(func() -> void: equip_requested.emit(_item_id, _target_uid))
	target_row.add_child(equip_button)
	add_child(target_row)


func _maybe_add_enhancement(uid: String, slot_id: String) -> void:
	var target_instance: CharacterInstance = null
	for candidate in GameState.roster:
		if candidate.uid == uid:
			target_instance = candidate
			break
	if target_instance == null or target_instance.equipped_item(slot_id) != _item_id:
		return
	var enhancement := GameState.gear_level(uid, slot_id)
	add_child(UIFactory.label("ENHANCEMENT  +%d%% stats" % (enhancement * 8), 10, UITheme.GOLD))
	var upgrade_info := GameState.gear_upgrade_info(uid, slot_id)
	var upgrade_button := UIFactory.button("Enhance to +%d  ·  %d Gold  ·  %d Glade Sap" % [enhancement + 1, int(upgrade_info.get("gold", 0)), int(upgrade_info.get("sap", 0))], true)
	upgrade_button.disabled = not bool(upgrade_info.get("ok", false))
	upgrade_button.tooltip_text = str(upgrade_info.get("reason", "Raises this gear's stats by 8% per level."))
	upgrade_button.pressed.connect(func() -> void: enhance_requested.emit(uid, slot_id))
	add_child(upgrade_button)


func _equipped_by(item_id: String) -> Array:
	var result: Array = []
	for instance in GameState.roster:
		var definition: CharacterDef = ContentDB.get_character(instance.char_id)
		if definition == null:
			continue
		for slot in CharacterInstance.SLOTS:
			if instance.equipped_item(slot) == item_id:
				result.append(definition.display_name)
				break
	return result


func _build_comparison(item: Dictionary, uid: String) -> VBoxContainer:
	var box := UIFactory.vbox(4)
	box.name = "EquipmentComparison"
	box.add_child(UIFactory.label("COMPARISON · CURRENTLY EQUIPPED", 9, UITheme.TEXT_FAINT))
	var instance: CharacterInstance = null
	for candidate in GameState.roster:
		if candidate.uid == uid:
			instance = candidate
			break
	if instance == null:
		box.add_child(UIFactory.label("Select a character to compare gear.", 10, UITheme.TEXT_DIM))
		return box
	var slot := str(item.get("slot", ""))
	var current_id := instance.equipped_item(slot)
	var current: Dictionary = ContentDB.get_item(current_id) if not current_id.is_empty() else {}
	box.add_child(UIFactory.label("Equipped: %s" % str(current.get("name", "Empty slot")), 11, UITheme.TEXT))
	var next_stats: Dictionary = item.get("stats", {})
	var old_stats: Dictionary = current.get("stats", {})
	var keys: Array = next_stats.keys()
	for key in old_stats.keys():
		if not keys.has(key):
			keys.append(key)
	for key in keys:
		var delta := float(next_stats.get(key, 0.0)) - float(old_stats.get(key, 0.0))
		var sign := "+" if delta > 0.0 else "" if delta == 0.0 else ""
		var tint := UITheme.GREEN if delta > 0.0 else UITheme.DANGER if delta < 0.0 else UITheme.TEXT_DIM
		box.add_child(UIFactory.label("%s  %s%s" % [str(key).to_upper(), sign, str(delta)], 10, tint))
	if current_id == str(item.get("id", _item_id)):
		box.add_child(UIFactory.label("Already equipped in this slot.", 10, UITheme.TEXT_DIM))
	return box

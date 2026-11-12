class_name InventoryScreen
extends OverlayScreen
## Inventory and equipment management. Equipment is real: equipping removes one
## copy from the bag, returns the previously equipped piece, and changes combat
## stats through CombatFactory.

var _grid: GridContainer
var _detail: VBoxContainer
var _cards: Dictionary = {}
var _selected_item: String = ""
var _filter: String = "all"
var _equip_target_uid: String = ""


func _init() -> void:
	screen_title = "Inventory"
	screen_subtitle = "Materials, gear and currencies carried by the party"


func _build_content() -> void:
	var top := UIFactory.hbox(8)
	top.add_child(UIFactory.chip("Gold  " + UIFactory.number(GameState.currency("gold")), UITheme.GOLD))
	top.add_child(UIFactory.chip("Crystals  " + UIFactory.number(GameState.currency("crystals")), UITheme.TEAL))
	top.add_child(UIFactory.chip("Gems  " + UIFactory.number(GameState.currency("gems")), UITheme.VIOLET))
	content.add_child(top)

	var filters := UIFactory.hbox(8)
	for entry in [["all", "All"], ["material", "Materials"], ["equipment", "Equipment"], ["currency", "Currencies"]]:
		var filter_id := str(entry[0])
		var button := UIFactory.small_button(str(entry[1]))
		button.pressed.connect(func() -> void: _set_filter(filter_id))
		filters.add_child(button)
	filters.add_child(UIFactory.spacer())
	filters.add_child(UIFactory.label("Equipment changes combat stats immediately", 11, UITheme.TEXT_FAINT))
	content.add_child(filters)

	var split := UIFactory.hbox(14)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(split)

	var left := UIFactory.vbox(10)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.custom_minimum_size = Vector2(560, 0)
	split.add_child(left)
	var scroll := UIFactory.scroll()
	left.add_child(scroll)
	_grid = UIFactory.grid(4, 10)
	scroll.add_child(_grid)

	var detail_panel := UIFactory.panel(Color("#0a101d"), UITheme.BORDER_SOFT, 12, 1, 12)
	detail_panel.custom_minimum_size = Vector2(400, 0)
	split.add_child(detail_panel)
	var detail_scroll := UIFactory.scroll()
	detail_panel.add_child(detail_scroll)
	_detail = UIFactory.vbox(10)
	detail_scroll.add_child(_detail)


func _set_filter(value: String) -> void:
	_filter = value
	_rebuild_grid()


func _refresh() -> void:
	_rebuild_grid()


func _rebuild_grid() -> void:
	if _grid == null:
		return
	UIFactory.clear(_grid)
	_cards.clear()
	var ids: Array = []
	match _filter:
		"currency":
			for currency_id in ["gold", "gems", "crystals", "guild_tokens", "ancient_coins", "event_tokens"]:
				if GameState.currency(currency_id) > 0:
					ids.append(currency_id)
		_:
			for item_id in GameState.inventory.keys():
				if int(GameState.inventory[item_id]) <= 0:
					continue
				var item: Dictionary = ContentDB.get_item(str(item_id))
				if item.is_empty():
					continue
				var category := str(item.get("category", "material"))
				if _filter == "all" or category == _filter:
					ids.append(str(item_id))
	ids.sort_custom(func(a, b) -> bool:
		var item_a: Dictionary = ContentDB.get_item(a)
		var item_b: Dictionary = ContentDB.get_item(b)
		var cat_a := str(item_a.get("category", ""))
		var cat_b := str(item_b.get("category", ""))
		if cat_a == cat_b:
			return str(item_a.get("name", a)) < str(item_b.get("name", b))
		return cat_a < cat_b
	)
	if ids.is_empty():
		_grid.add_child(UIFactory.label("Nothing in this category.", 13, UITheme.TEXT_DIM))
		_selected_item = ""
		_show_detail("")
		return
	if _selected_item.is_empty() or not ids.has(_selected_item):
		_selected_item = str(ids[0])
	for item_id in ids:
		_grid.add_child(_make_card(str(item_id)))
	_show_detail(_selected_item)


func _make_card(item_id: String) -> PanelContainer:
	var item: Dictionary = ContentDB.get_item(item_id)
	var color := Color(str(item.get("color", "#9aa8c2")))
	var card := UIFactory.panel(Color("#111a2d"), UITheme.BORDER_SOFT, 10, 1, 8)
	card.custom_minimum_size = Vector2(126, 132)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var box := UIFactory.vbox(4)
	card.add_child(box)

	var icon_center := CenterContainer.new()
	var icon := UIFactory.panel(color.darkened(0.62), color, 8, 1, 4)
	icon.custom_minimum_size = Vector2(52, 52)
	var letter := UIFactory.label(str(item.get("name", "?")).substr(0, 1).to_upper(), 22, color)
	letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_child(letter)
	icon_center.add_child(icon)
	box.add_child(icon_center)

	var name_label := UIFactory.label(str(item.get("name", item_id)), 11, UITheme.TEXT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(name_label)
	var count := GameState.currency(item_id) if str(item.get("category", "")) == "currency" else GameState.item_count(item_id)
	var count_label := UIFactory.label("×%s" % UIFactory.number(count), 10, UITheme.TEXT_DIM)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(count_label)

	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_selected_item = item_id
			_rebuild_grid()
			_show_detail(item_id)
	)
	_cards[item_id] = card
	if item_id == _selected_item:
		card.add_theme_stylebox_override("panel", UITheme.style(Color("#1a2947"), color, 10, 2, 8))
	return card


func _show_detail(item_id: String) -> void:
	UIFactory.clear(_detail)
	if item_id.is_empty():
		_detail.add_child(UIFactory.label("No item selected.", 13, UITheme.TEXT_DIM))
		return
	var item: Dictionary = ContentDB.get_item(item_id)
	if item.is_empty():
		_detail.add_child(UIFactory.label("Unknown item.", 13, UITheme.DANGER))
		return
	var color := Color(str(item.get("color", "#9aa8c2")))
	var category := str(item.get("category", "material"))
	var rarity := str(item.get("rarity", "common"))

	var icon_center := CenterContainer.new()
	var icon := UIFactory.panel(color.darkened(0.62), color, 12, 1, 10)
	icon.custom_minimum_size = Vector2(88, 88)
	var letter := UIFactory.label(str(item.get("name", "?")).substr(0, 1).to_upper(), 38, color)
	letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_child(letter)
	icon_center.add_child(icon)
	_detail.add_child(icon_center)

	var name_label := UIFactory.heading(str(item.get("name", item_id)), 22, UITheme.TEXT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail.add_child(name_label)

	var chips := UIFactory.hbox(6)
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_child(UIFactory.chip(category.capitalize(), UITheme.TEXT_DIM))
	if category != "currency":
		chips.add_child(UIFactory.rarity_chip(rarity))
	if item.has("element"):
		chips.add_child(UIFactory.element_chip(str(item.get("element", "neutral"))))
	_detail.add_child(chips)

	var amount := GameState.currency(item_id) if category == "currency" else GameState.item_count(item_id)
	_detail.add_child(UIFactory.label("Owned: %s" % UIFactory.number(amount), 12, UITheme.TEXT_DIM))
	_detail.add_child(UIFactory.wrapped(str(item.get("description", "")), 12, UITheme.TEXT_DIM))
	_detail.add_child(UIFactory.separator())

	var stats: Dictionary = item.get("stats", {})
	if not stats.is_empty():
		_detail.add_child(UIFactory.label("STAT BONUSES", 10, UITheme.TEXT_FAINT))
		var stat_grid := UIFactory.grid(2, 4)
		for key in stats.keys():
			stat_grid.add_child(_stat_row(str(key).to_upper(), str(stats[key])))
		_detail.add_child(stat_grid)

	if category == "equipment":
		var equipped_by := _equipped_by(item_id)
		if not equipped_by.is_empty():
			_detail.add_child(UIFactory.label("Equipped by: " + ", ".join(equipped_by), 11, UITheme.TEAL))
			for instance in GameState.roster:
				var definition: CharacterDef = ContentDB.get_character(instance.char_id)
				if definition == null:
					continue
				for slot in CharacterInstance.SLOTS:
					if instance.equipped_item(slot) == item_id:
						var unequip_button := UIFactory.small_button("Unequip from " + definition.display_name)
						var uid: String = instance.uid
						var slot_name: String = slot
						unequip_button.pressed.connect(func() -> void: _unequip(uid, slot_name))
						_detail.add_child(unequip_button)
		var target_row := UIFactory.vbox(4)
		target_row.add_child(UIFactory.label("Equip to", 11, UITheme.TEXT_FAINT))
		var picker := OptionButton.new()
		picker.custom_minimum_size = Vector2(0, 36)
		picker.add_theme_font_size_override("font_size", 12)
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
		else:
			picker.item_selected.connect(func(selected: int) -> void:
				_equip_target_uid = str(picker.get_item_metadata(selected))
			)
			_equip_target_uid = str(picker.get_item_metadata(0))
		target_row.add_child(picker)
		var equip_button := UIFactory.button("Equip", true)
		equip_button.disabled = amount <= 0 or index == 0
		equip_button.pressed.connect(func() -> void: _equip(item_id))
		target_row.add_child(equip_button)
		_detail.add_child(target_row)
	elif category == "material":
		_detail.add_child(UIFactory.wrapped(
			"Materials are used for ascension and future crafting. They are not consumed automatically.",
			11,
			UITheme.TEXT_FAINT
		))


func _stat_row(title: String, value: String) -> PanelContainer:
	var row := UIFactory.panel(Color("#0d1524"), Color(0, 0, 0, 0), 6, 0, 6)
	var box := UIFactory.hbox(8)
	box.add_child(UIFactory.label(title, 11, UITheme.TEXT_FAINT))
	box.add_child(UIFactory.spacer())
	box.add_child(UIFactory.label("+" + value, 12, UITheme.GREEN))
	row.add_child(box)
	return row


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


func _unequip(uid: String, slot: String) -> void:
	if GameState.unequip_item(uid, slot):
		EventBus.toast_requested.emit("Item unequipped.")
		_rebuild_grid()
		_show_detail(_selected_item)
	else:
		EventBus.toast_requested.emit("Could not unequip that item.")


func _equip(item_id: String) -> void:
	if _equip_target_uid.is_empty():
		EventBus.toast_requested.emit("Choose a character first.")
		return
	if GameState.equip_item(_equip_target_uid, item_id):
		EventBus.toast_requested.emit("Equipment updated.")
		_rebuild_grid()
		_show_detail(item_id)
	else:
		EventBus.toast_requested.emit("Could not equip that item.")

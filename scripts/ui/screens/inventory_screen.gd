class_name InventoryScreen
extends OverlayScreen
## Inventory and equipment management refactored into reusable item/inventory/equipment modules.
## GameState remains the authoritative source for inventory, equipment, upgrades, and saves.

const ITEM_CARD_SCENE: PackedScene = preload("res://scenes/ui/components/inventory_item_card.tscn")
const INVENTORY_LAYOUT_SCENE: PackedScene = preload("res://scenes/ui/components/inventory_screen_layout.tscn")
const ITEM_DETAIL_PANEL_SCENE: PackedScene = preload("res://scenes/items/ui/item_detail_panel.tscn")
const ITEM_ACQUISITION_NOTIFICATION_SCENE: PackedScene = preload("res://scenes/items/ui/item_acquisition_notification.tscn")
const _InventoryControllerScript = preload("res://scripts/items/inventory/inventory_controller.gd")
const _InventoryContainerScript = preload("res://scripts/items/inventory/inventory_container.gd")
const _InventorySelectionScript = preload("res://scripts/items/inventory/inventory_selection.gd")
const _InventoryNotificationsScript = preload("res://scripts/items/inventory/inventory_notifications.gd")
const _ItemSorterScript = preload("res://scripts/items/inventory/item_sorter.gd")
const _ItemPresentationScript = preload("res://scripts/items/ui/item_presentation.gd")
const _ItemInteractionScript = preload("res://scripts/items/item_interaction.gd")
const _ItemDatabaseScript = preload("res://scripts/items/item_database.gd")

var _grid: GridContainer
var _detail_panel = null
var _notification = null
var _cards: Dictionary = {}
var _controller = null
var _container = null
var _selection = null
var _notifications = null
var _filter: String = "all"


func _init() -> void:
	screen_title = "Inventory"
	screen_subtitle = "Materials, gear and currencies carried by the party"


func _build_content() -> void:
	_controller = _InventoryControllerScript.new()
	_container = _InventoryContainerScript.new()
	_selection = _InventorySelectionScript.new()
	_notifications = _InventoryNotificationsScript.new()
	add_child(_controller)
	_controller.inventory_updated.connect(_refresh)
	_selection.changed.connect(func(item_id: String) -> void:
		if _detail_panel != null:
			_detail_panel.show_item(item_id)
	)

	var layout := INVENTORY_LAYOUT_SCENE.instantiate() as VBoxContainer
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(layout)

	var wallet := layout.get_node("Wallet") as HBoxContainer
	wallet.add_child(UIFactory.chip("Gold  " + UIFactory.number(GameState.currency("gold")), UITheme.GOLD))
	wallet.add_child(UIFactory.chip("Crystals  " + UIFactory.number(GameState.currency("crystals")), UITheme.TEAL))
	wallet.add_child(UIFactory.chip("Gems  " + UIFactory.number(GameState.currency("gems")), UITheme.VIOLET))

	var filters := layout.get_node("Filters") as HBoxContainer
	var filter_buttons := {
		"all": filters.get_node("AllButton") as Button,
		"material": filters.get_node("MaterialsButton") as Button,
		"equipment": filters.get_node("EquipmentButton") as Button,
		"currency": filters.get_node("CurrenciesButton") as Button,
	}
	for filter_id in filter_buttons:
		var button: Button = filter_buttons[filter_id]
		button.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		button.add_theme_stylebox_override("normal", UITheme.style(Color("#111a2d"), UITheme.BORDER_SOFT, 8, 1, 8))
		button.pressed.connect(func() -> void: _set_filter(str(filter_id)))
	(filters.get_node("FilterHint") as Label).add_theme_color_override("font_color", UITheme.TEXT_FAINT)

	_grid = layout.get_node("Split/Left/GridScroll/ItemGrid") as GridContainer
	var detail_scroll := layout.get_node("Split/DetailPanel/DetailScroll") as ScrollContainer
	var existing_detail := layout.get_node_or_null("Split/DetailPanel/DetailScroll/DetailContent")
	if existing_detail != null:
		existing_detail.queue_free()
	_detail_panel = ITEM_DETAIL_PANEL_SCENE.instantiate()
	_detail_panel.equip_requested.connect(_on_equip_requested)
	_detail_panel.unequip_requested.connect(_on_unequip_requested)
	_detail_panel.enhance_requested.connect(_on_enhance_requested)
	_detail_panel.use_requested.connect(_on_use_requested)
	detail_scroll.add_child(_detail_panel)

	_notification = ITEM_ACQUISITION_NOTIFICATION_SCENE.instantiate()
	content.add_child(_notification)


func _set_filter(value: String) -> void:
	_filter = value
	_container.filter_id = value
	_rebuild_grid()


func _refresh() -> void:
	_rebuild_grid()


func _rebuild_grid() -> void:
	if _grid == null:
		return
	UIFactory.clear(_grid)
	_cards.clear()
	var ids: Array[String] = _collect_item_ids()
	if ids.is_empty():
		_grid.add_child(UIFactory.label("Nothing in this category.", 13, UITheme.TEXT_DIM))
		_selection.clear()
		if _detail_panel != null:
			_detail_panel.show_item("")
		return
	if _selection.selected_item_id.is_empty() or not ids.has(_selection.selected_item_id):
		_selection.select(str(ids[0]))
	for item_id in ids:
		_grid.add_child(_make_card(str(item_id)))
	if _detail_panel != null:
		_detail_panel.show_item(_selection.selected_item_id)


func _collect_item_ids() -> Array[String]:
	var ids: Array[String] = []
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
	for instance in GameState.roster:
		for slot in CharacterInstance.SLOTS:
			var equipped_id: String = instance.equipped_item(slot)
			if equipped_id.is_empty() or ids.has(equipped_id):
				continue
			var equipped_item: Dictionary = ContentDB.get_item(equipped_id)
			if _filter == "all" or _filter == str(equipped_item.get("category", "")):
				ids.append(equipped_id)
	return _ItemSorterScript.sort_ids(ids, "category_name")


func _make_card(item_id: String) -> PanelContainer:
	var item: Dictionary = ContentDB.get_item(item_id)
	var color: Color = _ItemPresentationScript.item_color(item)
	var card := ITEM_CARD_SCENE.instantiate() as InventoryItemCard
	var is_currency := str(item.get("category", "")) == "currency"
	var is_equipment := str(item.get("category", "")) == "equipment"
	var count := GameState.currency(item_id) if is_currency else GameState.item_count(item_id)
	var equipped_count := _equipped_by(item_id).size() if is_equipment else 0
	var count_text: String = _ItemPresentationScript.format_count_text(count, equipped_count)
	card.setup(
		item_id,
		str(item.get("name", item_id)),
		count_text,
		color,
		item_id == _selection.selected_item_id
	)
	card.selected.connect(func(selected_id: String) -> void:
		_selection.select(selected_id)
		_controller.select_item(selected_id)
		_controller.inspect_item(selected_id)
		_rebuild_grid()
	)
	_cards[item_id] = card
	return card


func _show_detail(item_id: String) -> void:
	if _detail_panel != null:
		_detail_panel.show_item(item_id)


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


func _on_enhance_requested(uid: String, slot: String) -> void:
	var result: Dictionary = _ItemInteractionScript.upgrade(uid, slot)
	EventBus.toast_requested.emit(str(result.get("reason", "Equipment enhanced! Stats increased by 8%." if result.get("ok", false) else "Could not enhance equipment.")))
	_rebuild_grid()


func _on_unequip_requested(uid: String, slot: String) -> void:
	var result: Dictionary = _ItemInteractionScript.unequip(uid, slot)
	EventBus.toast_requested.emit("Item unequipped." if bool(result.get("ok", false)) else str(result.get("reason", "Could not unequip that item.")))
	_rebuild_grid()


func _on_equip_requested(item_id: String, uid: String) -> void:
	if uid.is_empty():
		EventBus.toast_requested.emit("Choose a character first.")
		return
	var result: Dictionary = _ItemInteractionScript.equip(uid, item_id)
	EventBus.toast_requested.emit("Equipment updated." if bool(result.get("ok", false)) else str(result.get("reason", "Could not equip that item.")))
	_rebuild_grid()


func _on_use_requested(item_id: String) -> void:
	var result: Dictionary = _ItemInteractionScript.use(item_id)
	EventBus.toast_requested.emit(str(result.get("reason", "Could not use item.")))
	_rebuild_grid()


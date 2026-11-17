class_name InventoryGridComponent
extends Node
## Owns inventory filtering, item-card creation, selection and detail presentation.

const ITEM_CARD_SCENE: PackedScene = preload("res://scenes/ui/components/inventory_item_card.tscn")
const ITEM_DETAIL_PANEL_SCENE: PackedScene = preload("res://scenes/items/ui/item_detail_panel.tscn")
const _InventoryContainerScript = preload("res://scripts/items/inventory/inventory_container.gd")
const _InventorySelectionScript = preload("res://scripts/items/inventory/inventory_selection.gd")
const _ItemSorterScript = preload("res://scripts/items/inventory/item_sorter.gd")
const _ItemPresentationScript = preload("res://scripts/items/ui/item_presentation.gd")

var screen
var _grid: GridContainer
var _detail_panel
var _cards: Dictionary = {}
var _container
var _selection
var _filter: String = "all"


func bind(owner_screen) -> void:
	screen = owner_screen


func build(layout: VBoxContainer) -> void:
	if screen == null:
		return
	_container = _InventoryContainerScript.new()
	_selection = _InventorySelectionScript.new()
	_selection.changed.connect(_on_selection_changed)

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
		button.pressed.connect(func() -> void: set_filter(str(filter_id)))
	(filters.get_node("FilterHint") as Label).add_theme_color_override("font_color", UITheme.TEXT_FAINT)

	_grid = layout.get_node("Split/Left/GridScroll/ItemGrid") as GridContainer
	var detail_scroll := layout.get_node("Split/DetailPanel/DetailScroll") as ScrollContainer
	var existing_detail := layout.get_node_or_null("Split/DetailPanel/DetailScroll/DetailContent")
	if existing_detail != null:
		existing_detail.queue_free()
	_detail_panel = ITEM_DETAIL_PANEL_SCENE.instantiate()
	_detail_panel.equip_requested.connect(screen._on_equip_requested)
	_detail_panel.unequip_requested.connect(screen._on_unequip_requested)
	_detail_panel.enhance_requested.connect(screen._on_enhance_requested)
	_detail_panel.use_requested.connect(screen._on_use_requested)
	detail_scroll.add_child(_detail_panel)


func set_filter(value: String) -> void:
	_filter = value
	_container.filter_id = value
	rebuild_grid()


func refresh() -> void:
	rebuild_grid()


func rebuild_grid() -> void:
	if _grid == null:
		return
	UIFactory.clear(_grid)
	_cards.clear()
	var ids: Array[String] = collect_item_ids()
	if ids.is_empty():
		_grid.add_child(UIFactory.label("Nothing in this category.", 13, UITheme.TEXT_DIM))
		_selection.clear()
		if _detail_panel != null:
			_detail_panel.show_item("")
		return
	if _selection.selected_item_id.is_empty() or not ids.has(_selection.selected_item_id):
		_selection.select(str(ids[0]))
	for item_id in ids:
		_grid.add_child(make_card(str(item_id)))
	if _detail_panel != null:
		_detail_panel.show_item(_selection.selected_item_id)


func collect_item_ids() -> Array[String]:
	var ids: Array[String] = []
	match _filter:
		"currency":
			for currency_id in ["gold", "gems", "crystals", "guild_tokens", "ancient_coins", "event_tokens"]:
				if GameState.inventory_domain.currency(currency_id) > 0:
					ids.append(currency_id)
		_:
			for item_id in GameState.inventory_domain.inventory.keys():
				if int(GameState.inventory_domain.inventory[item_id]) <= 0:
					continue
				var item: Dictionary = ContentDB.get_item(str(item_id))
				if item.is_empty():
					continue
				var category := str(item.get("category", "material"))
				if _filter == "all" or category == _filter:
					ids.append(str(item_id))
	for instance in GameState.roster_domain.roster:
		for slot in CharacterInstance.SLOTS:
			var equipped_id: String = instance.equipped_item(slot)
			if equipped_id.is_empty() or ids.has(equipped_id):
				continue
			var equipped_item: Dictionary = ContentDB.get_item(equipped_id)
			if _filter == "all" or _filter == str(equipped_item.get("category", "")):
				ids.append(equipped_id)
	return _ItemSorterScript.sort_ids(ids, "category_name")


func make_card(item_id: String) -> PanelContainer:
	var item: Dictionary = ContentDB.get_item(item_id)
	var color: Color = _ItemPresentationScript.item_color(item)
	var card := ITEM_CARD_SCENE.instantiate() as InventoryItemCard
	var is_currency := str(item.get("category", "")) == "currency"
	var is_equipment := str(item.get("category", "")) == "equipment"
	var count := GameState.inventory_domain.currency(item_id) if is_currency else GameState.inventory_domain.item_count(item_id)
	var equipped_count := equipped_by(item_id).size() if is_equipment else 0
	var count_text: String = _ItemPresentationScript.format_count_text(count, equipped_count)
	card.setup(
		item_id,
		str(item.get("name", item_id)),
		count_text,
		color,
		item_id == _selection.selected_item_id
	)
	card.selected.connect(_on_card_selected)
	_cards[item_id] = card
	return card


func _on_card_selected(selected_id: String) -> void:
	_selection.select(selected_id)
	screen._controller.select_item(selected_id)
	screen._controller.inspect_item(selected_id)
	rebuild_grid()


func _on_selection_changed(item_id: String) -> void:
	if _detail_panel != null:
		_detail_panel.show_item(item_id)


func show_detail(item_id: String) -> void:
	if _detail_panel != null:
		_detail_panel.show_item(item_id)


func equipped_by(item_id: String) -> Array:
	var result: Array = []
	for instance in GameState.roster_domain.roster:
		var definition: CharacterDef = ContentDB.get_character(instance.char_id)
		if definition == null:
			continue
		for slot in CharacterInstance.SLOTS:
			if instance.equipped_item(slot) == item_id:
				result.append(definition.display_name)
				break
	return result

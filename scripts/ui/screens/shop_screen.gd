class_name ShopScreen
extends OverlayScreen
## A compact local merchant interface. All purchases route through ShopService.

const _ShopServiceScript = preload("res://scripts/economy/shop_service.gd")
const SHOP_LAYOUT_SCENE: PackedScene = preload("res://scenes/ui/components/shop_screen_layout.tscn")

var _wallet_label: Label
var _stock_list: VBoxContainer


func _init() -> void:
	screen_title = "Sera's Caravan"
	screen_subtitle = "Useful supplies and equipment, bought with Gold"


func _build_content() -> void:
	var layout := SHOP_LAYOUT_SCENE.instantiate() as VBoxContainer
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(layout)
	_wallet_label = layout.get_node("WalletLabel") as Label
	_stock_list = layout.get_node("StockScroll/StockList") as VBoxContainer
	EventBus.currency_changed.connect(_refresh_stock)
	EventBus.inventory_changed.connect(_refresh_stock)
	_refresh_stock()


func _exit_tree() -> void:
	if EventBus.currency_changed.is_connected(_refresh_stock):
		EventBus.currency_changed.disconnect(_refresh_stock)
	if EventBus.inventory_changed.is_connected(_refresh_stock):
		EventBus.inventory_changed.disconnect(_refresh_stock)


func _refresh_stock() -> void:
	if _wallet_label != null:
		_wallet_label.text = "Gold  " + UIFactory.number(GameState.inventory_domain.currency("gold"))
	if _stock_list == null:
		return
	UIFactory.clear(_stock_list)
	for item_id in _ShopServiceScript.stock_ids():
		var item: Dictionary = ContentDB.get_item(item_id)
		var entry: Dictionary = _ShopServiceScript.stock_entry(item_id)
		var price := int(entry.get("price", 0))
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UITheme.style(Color("#19243a"), UITheme.BORDER_SOFT, 8, 1, 8))
		_stock_list.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		info.add_child(UIFactory.label(str(item.get("name", item_id)), 15, UITheme.TEXT))
		var description := UIFactory.label(str(item.get("description", "")), 12, UITheme.TEXT_DIM)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(description)
		info.add_child(UIFactory.label("Owned: %d" % GameState.inventory_domain.item_count(item_id), 11, UITheme.TEXT_FAINT))
		var buy := UIFactory.button("Buy  %s G" % UIFactory.number(price), true)
		buy.disabled = GameState.inventory_domain.currency("gold") < price
		row.add_child(buy)
		buy.pressed.connect(func() -> void: _buy_item(item_id))


func _buy_item(item_id: String) -> void:
	var result: Dictionary = _ShopServiceScript.purchase(item_id)
	EventBus.toast_requested.emit(str(result.get("reason", "Purchase failed.")))
	_refresh_stock()

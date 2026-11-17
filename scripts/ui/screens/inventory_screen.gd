class_name InventoryScreen
extends OverlayScreen
## Inventory and equipment management refactored into reusable item/inventory/equipment modules.
## GameState remains the authoritative source for inventory, equipment, upgrades, and saves.

const INVENTORY_LAYOUT_SCENE: PackedScene = preload("res://scenes/ui/components/inventory_screen_layout.tscn")
const ITEM_ACQUISITION_NOTIFICATION_SCENE: PackedScene = preload("res://scenes/items/ui/item_acquisition_notification.tscn")
const _InventoryControllerScript = preload("res://scripts/items/inventory/inventory_controller.gd")
const _ItemInteractionScript = preload("res://scripts/items/item_interaction.gd")

var _controller = null
var _notification = null
var grid_component: InventoryGridComponent
var crafting_component: InventoryCraftingComponent
var _crafting_window: PanelContainer:
	get:
		return crafting_component._window if crafting_component != null else null
var _crafting_list: VBoxContainer:
	get:
		return crafting_component._list if crafting_component != null else null


func _init() -> void:
	screen_title = "Inventory"
	screen_subtitle = "Materials, gear and currencies carried by the party"


func _build_content() -> void:
	_controller = _InventoryControllerScript.new()
	add_child(_controller)
	_controller.inventory_updated.connect(_refresh)

	var layout := INVENTORY_LAYOUT_SCENE.instantiate() as VBoxContainer
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(layout)

	var wallet := layout.get_node("Wallet") as HBoxContainer
	wallet.add_child(UIFactory.chip("Gold  " + UIFactory.number(GameState.inventory_domain.currency("gold")), UITheme.GOLD))
	wallet.add_child(UIFactory.chip("Crystals  " + UIFactory.number(GameState.inventory_domain.currency("crystals")), UITheme.TEAL))
	wallet.add_child(UIFactory.chip("Gems  " + UIFactory.number(GameState.inventory_domain.currency("gems")), UITheme.VIOLET))

	grid_component = layout.get_node("GridComponent") as InventoryGridComponent
	crafting_component = layout.get_node("CraftingComponent") as InventoryCraftingComponent
	if grid_component != null:
		grid_component.bind(self)
		grid_component.build(layout)
		grid_component.refresh()
	if crafting_component != null:
		crafting_component.bind(self)
		crafting_component.build(layout.get_node("Filters") as HBoxContainer)

	_notification = ITEM_ACQUISITION_NOTIFICATION_SCENE.instantiate() as ItemAcquisitionNotification
	content.add_child(_notification)
	_controller.notification_requested.connect(_notification.show_message)

func _set_filter(value: String) -> void:
	if grid_component != null:
		grid_component.set_filter(value)

func _refresh() -> void:
	if grid_component != null:
		grid_component.refresh()

func _rebuild_grid() -> void:
	if grid_component != null:
		grid_component.rebuild_grid()

func _collect_item_ids() -> Array[String]:
	return grid_component.collect_item_ids() if grid_component != null else []

func _make_card(item_id: String) -> PanelContainer:
	return grid_component.make_card(item_id) if grid_component != null else PanelContainer.new()

func _show_detail(item_id: String) -> void:
	if grid_component != null:
		grid_component.show_detail(item_id)

func _equipped_by(item_id: String) -> Array:
	return grid_component.equipped_by(item_id) if grid_component != null else []

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



func _refresh_crafting_window() -> void:
	if crafting_component != null:
		crafting_component.refresh()


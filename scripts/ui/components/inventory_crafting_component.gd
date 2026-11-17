class_name InventoryCraftingComponent
extends Node
## Owns the crafting panel, recipe presentation and craft-action feedback.

const _CraftingServiceScript = preload("res://scripts/items/crafting_service.gd")
const CRAFTING_PANEL_SCENE: PackedScene = preload("res://scenes/ui/components/inventory_crafting_panel.tscn")

var screen
var _window: PanelContainer
var _list: VBoxContainer


func bind(owner_screen) -> void:
	screen = owner_screen


func build(filters: HBoxContainer) -> void:
	var crafting_button := UIFactory.button("Crafting", true)
	filters.add_child(crafting_button)
	crafting_button.pressed.connect(open)
	_build_window()


func _build_window() -> void:
	_window = CRAFTING_PANEL_SCENE.instantiate() as PanelContainer
	if _window == null:
		push_error("InventoryCraftingComponent could not instantiate its authored panel scene.")
		return
	_window.name = "CraftingPanel"
	_window.set_anchors_preset(Control.PRESET_CENTER)
	_window.offset_left = -260
	_window.offset_top = -190
	_window.offset_right = 260
	_window.offset_bottom = 190
	_window.z_index = 20
	_window.add_theme_stylebox_override("panel", UITheme.style(Color("#111a2d"), UITheme.BORDER_SOFT, 10, 1, 16))
	_list = _window.get_node("Body/Scroll/RecipeList") as VBoxContainer
	var close_button := _window.get_node("Body/CloseButton") as Button
	if _list == null or close_button == null:
		push_error("Authored crafting panel is missing its recipe list or close button.")
		return
	close_button.pressed.connect(func() -> void: _window.hide())
	screen.content.add_child(_window)


func open() -> void:
	refresh()
	_window.visible = true


func refresh() -> void:
	if _list == null:
		return
	UIFactory.clear(_list)
	for recipe_id in _CraftingServiceScript.recipe_ids():
		var recipe: Dictionary = _CraftingServiceScript.get_recipe(recipe_id)
		var status: Dictionary = _CraftingServiceScript.recipe_status(recipe_id)
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UITheme.style(Color("#19243a"), UITheme.BORDER_SOFT, 8, 1, 8))
		_list.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		info.add_child(UIFactory.label(str(recipe.get("name", recipe_id)), 16, UITheme.TEXT))
		var description := UIFactory.label(str(recipe.get("description", "")), 12, UITheme.TEXT_DIM)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(description)
		var cost_parts: PackedStringArray = []
		for material_id in recipe.get("materials", {}):
			var material: Dictionary = ContentDB.get_item(str(material_id))
			cost_parts.append("%s %d/%d" % [str(material.get("name", material_id)), GameState.inventory_domain.item_count(str(material_id)), int(recipe["materials"][material_id])])
		cost_parts.append("Gold %d/%d" % [GameState.inventory_domain.currency("gold"), int(recipe.get("gold", 0))])
		var cost_label := UIFactory.label("Cost — " + ", ".join(cost_parts), 12, UITheme.TEXT_DIM)
		cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(cost_label)
		var craft_button := UIFactory.button("Craft", bool(status.get("ok", false)))
		craft_button.disabled = not bool(status.get("ok", false))
		row.add_child(craft_button)
		craft_button.pressed.connect(func() -> void:
			var result: Dictionary = _CraftingServiceScript.craft(recipe_id)
			EventBus.toast_requested.emit(str(result.get("reason", "Crafting failed.")))
			refresh()
			screen._refresh()
		)

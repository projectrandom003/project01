class_name ItemDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: String = ""
@export var icon_texture: Texture2D
@export var rarity: String = "common"
@export var category: String = "material" # weapon/armor/accessory/consumable/material/quest_item/collectible/upgrade_material/special/legendary/currency/equipment
@export var item_type: String = ""
@export var stack_limit: int = 999
@export var sell_value: int = 0
@export var equipment_slot: String = ""
@export var equipment_compatible: Array[String] = []
@export var stat_modifiers: Dictionary = {}
@export var effects: Dictionary = {}
@export var upgrade_properties: Dictionary = {}
@export var color: Color = Color("#9aa8c2")
@export var metadata: Dictionary = {}


static func from_content_item(item_id: String, data: Dictionary):
	var def = (load("res://scripts/items/item_definition.gd") as GDScript).new()
	def.id = item_id
	def.display_name = str(data.get("name", item_id))
	def.description = str(data.get("description", ""))
	def.icon = str(data.get("icon", ""))
	def.rarity = str(data.get("rarity", "common"))
	def.category = str(data.get("category", "material"))
	def.item_type = str(data.get("slot", data.get("type", "")))
	def.stack_limit = int(data.get("stack_limit", 1 if str(data.get("category", "")) == "equipment" else 999))
	def.sell_value = int(data.get("sell_value", data.get("value", 0)))
	def.equipment_slot = str(data.get("slot", ""))
	def.stat_modifiers = (data.get("stats", {}) as Dictionary).duplicate(true)
	def.effects = (data.get("effects", {}) as Dictionary).duplicate(true)
	def.upgrade_properties = (data.get("upgrade", {}) as Dictionary).duplicate(true)
	var c := str(data.get("color", "#9aa8c2"))
	if c.begins_with("#"):
		def.color = Color(c)
	def.metadata = data.duplicate(true)
	return def

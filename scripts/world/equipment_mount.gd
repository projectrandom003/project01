class_name EquipmentMount
extends Node2D
## Small presenter for one EquipmentDefinition. Does not own inventory or stats.

@onready var visual: Sprite2D = $Visual

var equipped_definition: EquipmentDefinition


func _ready() -> void:
	if equipped_definition == null:
		clear_equipment()


func equip(definition: EquipmentDefinition) -> void:
	equipped_definition = definition
	if not is_node_ready():
		await ready
	_apply_definition()


func clear_equipment() -> void:
	equipped_definition = null
	if not is_node_ready():
		return
	visual.texture = null
	visual.position = Vector2.ZERO
	visual.scale = Vector2.ONE
	visual.z_index = 0
	visual.centered = true
	visual.flip_h = false
	visual.modulate = Color.WHITE
	visual.visible = false


func set_equipment_visible(value: bool) -> void:
	if is_node_ready():
		visual.visible = value and equipped_definition != null and equipped_definition.enabled


func _apply_definition() -> void:
	if equipped_definition == null:
		clear_equipment()
		return
	visual.texture = equipped_definition.texture
	visual.position = equipped_definition.sprite_offset
	visual.scale = equipped_definition.sprite_scale
	visual.z_index = equipped_definition.sprite_z_index
	visual.centered = equipped_definition.centered
	visual.flip_h = equipped_definition.flip_h
	visual.modulate = equipped_definition.modulate
	visual.visible = equipped_definition.enabled and equipped_definition.texture != null

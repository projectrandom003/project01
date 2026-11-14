class_name ModularVegetation
extends Node2D
## Composable vegetation container that can hold reusable part scenes and apply variations.
## Designed to coexist with existing procedural/approved vegetation without replacing layouts.

signal variation_applied(variation: VegetationVariation)

@export var vegetation_kind: String = "tree"
@export var variation: VegetationVariation
@export var auto_apply_on_ready: bool = true

@onready var trunk: Node2D = get_node_or_null("Trunk") as Node2D
@onready var canopy: Node2D = get_node_or_null("Canopy") as Node2D
@onready var branches: Node2D = get_node_or_null("Branches") as Node2D
@onready var leaves: Node2D = get_node_or_null("Leaves") as Node2D
@onready var shadow: Node2D = get_node_or_null("Shadow") as Node2D
@onready var base: Node2D = get_node_or_null("Base") as Node2D


func _ready() -> void:
	if auto_apply_on_ready and variation != null:
		apply_variation(variation)


func get_part(part_name: StringName) -> Node2D:
	match String(part_name):
		"trunk": return trunk
		"canopy": return canopy
		"branches": return branches
		"leaves": return leaves
		"shadow": return shadow
		"base": return base
	return get_node_or_null(NodePath(String(part_name))) as Node2D


func apply_variation(v: VegetationVariation) -> void:
	variation = v
	if variation == null:
		return
	for child in get_children():
		if child.has_method("apply_variation"):
			child.call("apply_variation", variation)
	if shadow != null:
		shadow.visible = variation.shadow_enabled
	variation_applied.emit(variation)

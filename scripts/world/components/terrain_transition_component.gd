class_name TerrainTransitionComponent
extends Node2D

@export var transition_kind: String = "blend"
@export var from_surface: String = ""
@export var to_surface: String = ""
@export_range(0.0, 1.0, 0.01) var blend_strength: float = 0.8
@export var enabled: bool = true

@onready var blend_mask: Sprite2D = get_node_or_null("BlendMask") as Sprite2D
@onready var edge_detail: Node2D = get_node_or_null("EdgeDetail") as Node2D


func _ready() -> void:
	_apply()


func _apply() -> void:
	visible = enabled
	if blend_mask != null:
		blend_mask.modulate.a = blend_strength
	if edge_detail != null:
		edge_detail.visible = enabled

class_name BridgeSegment
extends Node2D

signal bridge_enabled_changed(enabled: bool)

@export var bridge_kind: String = "wooden_bridge"
@export var variant: int = 0
@export var enabled: bool = true:
	set(value):
		enabled = value
		visible = value
		bridge_enabled_changed.emit(value)
@export var walkable: bool = true
@export var span_length: float = 96.0

@onready var deck: Sprite2D = $Visual/Deck
@onready var walkable_area: Area2D = $WalkableArea
@onready var walk_shape: CollisionShape2D = $WalkableArea/CollisionShape2D


func _ready() -> void:
	_apply()


func _apply() -> void:
	if deck != null and not bridge_kind.is_empty():
		var tex := ProceduralArt.prop_texture(bridge_kind, variant)
		if tex != null:
			deck.texture = tex
			deck.centered = false
			deck.offset = Vector2(-float(tex.get_width()) * 0.5, -float(tex.get_height()) + 6.0)
	if walk_shape != null and walk_shape.shape is RectangleShape2D:
		(walk_shape.shape as RectangleShape2D).size = Vector2(span_length, 28.0)
	if walkable_area != null:
		walkable_area.monitoring = false
		walkable_area.monitorable = false
	visible = enabled


func set_enabled(value: bool) -> void:
	enabled = value

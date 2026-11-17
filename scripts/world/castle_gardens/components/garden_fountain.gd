class_name GardenFountain
extends Node2D
## Fountain presentation uses its authored Sprite and collision children.
@export var fountain_texture: Texture2D

func _ready() -> void:
	var sprite := get_node_or_null("Sprite") as Sprite2D
	var body := get_node_or_null("Body") as StaticBody2D
	if sprite == null or body == null:
		push_error("GardenFountain requires authored Sprite and Body children.")
		return
	if fountain_texture == null:
		fountain_texture = load("res://assets/environment/castle_gardens/fountain.png") as Texture2D
	sprite.texture = fountain_texture
	sprite.offset = Vector2(0, -12)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var shape := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null:
		push_error("GardenFountain requires an authored CollisionShape2D.")
		return
	var circle := CircleShape2D.new()
	circle.radius = 22.0
	shape.shape = circle
	shape.position = Vector2(0, 4)

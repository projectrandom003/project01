class_name GardenFountain
extends Node2D
## Reusable fountain component.
@export var fountain_texture: Texture2D

func _ready() -> void:
	if fountain_texture == null:
		fountain_texture = load("res://assets/environment/castle_gardens/fountain.png")
	if get_node_or_null("Sprite") == null:
		var s := Sprite2D.new()
		s.name = "Sprite"
		s.texture = fountain_texture
		s.centered = true
		s.offset = Vector2(0, -12)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(s)
		var body := StaticBody2D.new()
		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 22.0
		col.shape = shape
		col.position = Vector2(0, 4)
		body.add_child(col)
		add_child(body)

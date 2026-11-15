class_name GardenHedges
extends Node2D
## Reusable hedge layout component with collision.
@export var hedge_texture: Texture2D

func _ready() -> void:
	if hedge_texture == null:
		hedge_texture = load("res://assets/environment/castle_gardens/hedge_block.png")

func add_hedge(world_pos: Vector2, with_collision: bool = true) -> Node2D:
	var root := Node2D.new()
	root.position = world_pos
	var s := Sprite2D.new()
	s.texture = hedge_texture
	s.centered = true
	s.offset = Vector2(0, -8)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(s)
	if with_collision:
		var body := StaticBody2D.new()
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(34, 18)
		col.shape = shape
		col.position = Vector2(0, 2)
		body.add_child(col)
		root.add_child(body)
	add_child(root)
	return root

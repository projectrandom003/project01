class_name CastleExterior
extends Node2D
## Reusable castle exterior component (walls/towers framing the entrance area).

func build_default(center: Vector2) -> void:
	var wall_tex := load("res://assets/environment/castle_gardens/castle_wall.png") as Texture2D
	if wall_tex == null:
		return
	for i in range(-2, 3):
		if i == 0:
			continue
		var seg := Sprite2D.new()
		seg.texture = wall_tex
		seg.centered = true
		seg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		seg.position = center + Vector2(i * 92, 0)
		seg.offset = Vector2(0, -20)
		add_child(seg)
		_add_collision_box(center + Vector2(i * 92, 8), Vector2(84, 24))

func _add_collision_box(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)

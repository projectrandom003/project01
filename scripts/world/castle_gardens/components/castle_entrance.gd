class_name CastleEntrance
extends Node2D
## Gothic castle entrance centerpiece.

func build_default(center: Vector2) -> void:
	var gate_tex := load("res://assets/environment/castle_gardens/castle_gate.png") as Texture2D
	if gate_tex == null:
		return
	var gate := Sprite2D.new()
	gate.texture = gate_tex
	gate.centered = true
	gate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	gate.position = center
	gate.offset = Vector2(0, -40)
	add_child(gate)
	# Side collision blocks (leave opening in center)
	_add_collision_box(center + Vector2(-52, 20), Vector2(48, 28))
	_add_collision_box(center + Vector2(52, 20), Vector2(48, 28))

func _add_collision_box(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)

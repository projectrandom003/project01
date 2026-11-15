class_name CastleEntrance
extends Node2D
## Gothic castle entrance centerpiece.

func build_default(center: Vector2) -> void:
	var gate_tex := load("res://assets/environment/castle_gardens/castle_gate_detailed.png") as Texture2D
	if gate_tex == null:
		gate_tex = load("res://assets/environment/castle_gardens/castle_gate.png") as Texture2D
	if gate_tex == null:
		return
	var gate := Sprite2D.new()
	gate.texture = gate_tex
	gate.centered = true
	gate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	gate.position = center
	gate.offset = Vector2(0, -44)
	gate.scale = Vector2(1.05, 1.05)
	add_child(gate)

	# Decorative stairs/platform hint (visual, no collision blocking entry)
	var step := ColorRect.new()
	step.position = center + Vector2(-34, 18)
	step.size = Vector2(68, 8)
	step.color = Color(0.52, 0.48, 0.44, 0.55)
	step.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(step)

	# Side collision blocks (leave opening in center)
	_add_collision_box(center + Vector2(-58, 22), Vector2(46, 28))
	_add_collision_box(center + Vector2(58, 22), Vector2(46, 28))

func _add_collision_box(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)


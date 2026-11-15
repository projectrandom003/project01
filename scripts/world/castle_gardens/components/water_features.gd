class_name WaterFeatures
extends Node2D
## Ponds, canals, waterfalls and bridge placements.

func add_pond(world_pos: Vector2) -> Node2D:
	var tex := load("res://assets/environment/castle_gardens/pond_round.png") as Texture2D
	var root := Node2D.new()
	root.position = world_pos
	if tex != null:
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = true
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.offset = Vector2(0, -4)
		root.add_child(s)
		var body := StaticBody2D.new()
		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 20.0
		col.shape = shape
		col.position = Vector2(0, 2)
		body.add_child(col)
		root.add_child(body)
	add_child(root)
	return root

func add_waterfall(world_pos: Vector2) -> Node2D:
	var tex := load("res://assets/environment/castle_gardens/waterfall.png") as Texture2D
	var root := Node2D.new()
	root.position = world_pos
	if tex != null:
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = true
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.offset = Vector2(0, -20)
		root.add_child(s)
		var body := StaticBody2D.new()
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(34, 18)
		col.shape = shape
		col.position = Vector2(0, 10)
		body.add_child(col)
		root.add_child(body)
	add_child(root)
	return root

func add_bridge(world_pos: Vector2) -> Node2D:
	var tex := load("res://assets/environment/castle_gardens/stone_bridge.png") as Texture2D
	var root := Node2D.new()
	root.position = world_pos
	if tex != null:
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = true
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.offset = Vector2(0, -8)
		root.add_child(s)
	add_child(root)
	return root

class_name RoyalGarden
extends Node2D
## Symmetrical royal garden layout component (flower beds, greenery accents).

func build_symmetrical(origin: Vector2) -> void:
	var flower_tex := load("res://assets/environment/castle_gardens/flower_bed.png") as Texture2D
	var urn_tex := load("res://assets/environment/castle_gardens/urn_planter.png") as Texture2D
	if flower_tex == null:
		return
	var offsets := [Vector2(-140, 40), Vector2(140, 40), Vector2(-140, 120), Vector2(140, 120), Vector2(-220, 80), Vector2(220, 80)]
	for off in offsets:
		var s := Sprite2D.new()
		s.texture = flower_tex
		s.centered = true
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = origin + off
		s.offset = Vector2(0, -4)
		add_child(s)
	if urn_tex != null:
		for off in [Vector2(-80, 0), Vector2(80, 0), Vector2(-80, 160), Vector2(80, 160)]:
			var u := Sprite2D.new()
			u.texture = urn_tex
			u.centered = true
			u.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			u.position = origin + off
			u.offset = Vector2(0, -10)
			add_child(u)
			_add_collision_circle(origin + off + Vector2(0, 2), 8.0)

func _add_collision_circle(pos: Vector2, radius: float) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	col.shape = shape
	body.add_child(col)
	add_child(body)

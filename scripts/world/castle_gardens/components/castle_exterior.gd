class_name CastleExterior
extends Node2D
## Reusable castle exterior component (walls/towers framing the entrance area).

func build_default(center: Vector2) -> void:
	var wall_tex := load("res://assets/environment/castle_gardens/castle_wall.png") as Texture2D
	var tower_tex := load("res://assets/environment/castle_gardens/castle_tower.png") as Texture2D
	if wall_tex == null:
		return

	# Side wall segments framing the central entrance (modular, editable)
	for i in range(-2, 3):
		if i == 0:
			continue
		var seg := Sprite2D.new()
		seg.texture = wall_tex
		seg.centered = true
		seg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		seg.position = center + Vector2(i * 92, 2)
		seg.offset = Vector2(0, -18)
		seg.scale = Vector2(1.05, 1.05)
		add_child(seg)
		_add_collision_box(center + Vector2(i * 92, 10), Vector2(84, 22))

	# Corner/outer towers for a real castle silhouette
	if tower_tex != null:
		for tx in [-220.0, 220.0]:
			var tower := Sprite2D.new()
			tower.texture = tower_tex
			tower.centered = true
			tower.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tower.position = center + Vector2(tx, -4)
			tower.offset = Vector2(0, -40)
			add_child(tower)
			_add_collision_box(center + Vector2(tx, 12), Vector2(60, 24))

func _add_collision_box(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)


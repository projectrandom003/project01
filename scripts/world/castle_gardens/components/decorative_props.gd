class_name DecorativeProps
extends Node2D
## Benches, lanterns, urns and other decorative props.

func add_bench(world_pos: Vector2, flip_h: bool = false) -> Node2D:
	return _add_sprite_prop("res://assets/environment/castle_gardens/bench.png", world_pos, Vector2(0, -8), flip_h, Vector2(28, 10))

func add_lantern(world_pos: Vector2) -> Node2D:
	var path := "res://assets/environment/castle_gardens/lantern_tall.png"
	if not ResourceLoader.exists(path):
		path = "res://assets/environment/castle_gardens/lantern.png"
	var root := _add_sprite_prop(path, world_pos, Vector2(0, -24), false, Vector2(8, 8))
	# subtle warm glow
	var glow := PointLight2D.new()
	glow.position = Vector2(0, -28)
	glow.color = Color(1.0, 0.9, 0.65, 0.7)
	glow.energy = 0.35
	glow.texture_scale = 0.5
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		for x in range(32):
			var d := Vector2(x, y).distance_to(Vector2(16, 16)) / 16.0
			var a := pow(clampf(1.0 - d, 0.0, 1.0), 2.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	glow.texture = ImageTexture.create_from_image(img)
	root.add_child(glow)
	return root


func add_urn(world_pos: Vector2) -> Node2D:
	return _add_sprite_prop("res://assets/environment/castle_gardens/urn_planter.png", world_pos, Vector2(0, -10), false, Vector2(10, 8))

func _add_sprite_prop(path: String, world_pos: Vector2, offset: Vector2, flip_h: bool, collision_size: Vector2) -> Node2D:
	var tex := load(path) as Texture2D
	var root := Node2D.new()
	root.position = world_pos
	if tex != null:
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = true
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.offset = offset
		s.flip_h = flip_h
		root.add_child(s)
	if collision_size.x > 0.0 and collision_size.y > 0.0:
		var body := StaticBody2D.new()
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = collision_size
		col.shape = shape
		col.position = Vector2(0, 2)
		body.add_child(col)
		root.add_child(body)
	add_child(root)
	return root

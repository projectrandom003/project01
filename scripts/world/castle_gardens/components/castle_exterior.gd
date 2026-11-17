class_name CastleExterior
extends Node2D
## Castle exterior assembly composed from reusable authored prop/collider scenes.

const PROP_SCENE: PackedScene = preload("res://scenes/world/castle_gardens/components/garden_sprite_prop.tscn")
const BOX_SCENE: PackedScene = preload("res://scenes/world/castle_gardens/components/garden_collision_box.tscn")

func build_default(center: Vector2) -> void:
	var wall_tex := load("res://assets/environment/castle_gardens/castle_wall.png") as Texture2D
	var tower_tex := load("res://assets/environment/castle_gardens/castle_tower.png") as Texture2D
	if wall_tex == null:
		return
	for i in range(-2, 3):
		if i == 0:
			continue
		_add_sprite(wall_tex, center + Vector2(i * 92, 2), Vector2(0, -18), Vector2(1.05, 1.05))
		_add_box(center + Vector2(i * 92, 10), Vector2(84, 22))
	if tower_tex != null:
		for tx in [-220.0, 220.0]:
			_add_sprite(tower_tex, center + Vector2(tx, -4), Vector2(0, -40), Vector2.ONE)
			_add_box(center + Vector2(tx, 12), Vector2(60, 24))

func _add_sprite(texture: Texture2D, pos: Vector2, offset: Vector2, scale_value: Vector2) -> void:
	var prop := PROP_SCENE.instantiate() as Node2D
	prop.position = pos
	var sprite := prop.get_node("Sprite") as Sprite2D
	sprite.texture = texture
	sprite.offset = offset
	sprite.scale = scale_value
	prop.get_node("Body").queue_free()
	prop.get_node("LanternGlow").queue_free()
	$Visuals.add_child(prop)

func _add_box(pos: Vector2, size: Vector2) -> void:
	var body := BOX_SCENE.instantiate() as StaticBody2D
	body.position = pos
	var shape := body.get_node("CollisionShape2D") as CollisionShape2D
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	$Collisions.add_child(body)

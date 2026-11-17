class_name WaterFeatures
extends Node2D
## Water feature placements use authored reusable prop assemblies.

const PROP_SCENE: PackedScene = preload("res://scenes/world/castle_gardens/components/garden_sprite_prop.tscn")

func add_pond(world_pos: Vector2) -> Node2D:
	var circle := CircleShape2D.new()
	circle.radius = 20.0
	return _add_feature("res://assets/environment/castle_gardens/pond_round.png", world_pos, Vector2(0, -4), circle)

func add_waterfall(world_pos: Vector2) -> Node2D:
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(34, 18)
	return _add_feature("res://assets/environment/castle_gardens/waterfall.png", world_pos, Vector2(0, -20), rectangle, Vector2(0, 10))

func add_bridge(world_pos: Vector2) -> Node2D:
	var root := PROP_SCENE.instantiate() as Node2D
	root.position = world_pos
	var sprite := root.get_node("Sprite") as Sprite2D
	sprite.texture = load("res://assets/environment/castle_gardens/stone_bridge.png") as Texture2D
	sprite.offset = Vector2(0, -8)
	root.get_node("Body").queue_free()
	root.get_node("LanternGlow").queue_free()
	$WaterVisuals.add_child(root)
	return root

func _add_feature(path: String, world_pos: Vector2, offset: Vector2, shape: Shape2D, collision_offset: Vector2 = Vector2(0, 2)) -> Node2D:
	var root := PROP_SCENE.instantiate() as Node2D
	root.position = world_pos
	var sprite := root.get_node("Sprite") as Sprite2D
	sprite.texture = load(path) as Texture2D
	sprite.offset = offset
	var collision := root.get_node("Body/CollisionShape2D") as CollisionShape2D
	collision.shape = shape
	collision.position = collision_offset
	root.get_node("LanternGlow").queue_free()
	$WaterVisuals.add_child(root)
	return root

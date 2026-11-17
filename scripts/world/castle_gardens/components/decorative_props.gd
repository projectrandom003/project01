class_name DecorativeProps
extends Node2D
## Data-driven placement of authored reusable prop assemblies.

const PROP_SCENE: PackedScene = preload("res://scenes/world/castle_gardens/components/garden_sprite_prop.tscn")

func add_bench(world_pos: Vector2, flip_h: bool = false) -> Node2D:
	return _add_sprite_prop("res://assets/environment/castle_gardens/bench.png", world_pos, Vector2(0, -8), flip_h, Vector2(28, 10))

func add_lantern(world_pos: Vector2) -> Node2D:
	var path := "res://assets/environment/castle_gardens/lantern_tall.png"
	if not ResourceLoader.exists(path):
		path = "res://assets/environment/castle_gardens/lantern.png"
	var root := _add_sprite_prop(path, world_pos, Vector2(0, -24), false, Vector2(8, 8))
	(root.get_node("LanternGlow") as PointLight2D).enabled = true
	return root

func add_urn(world_pos: Vector2) -> Node2D:
	return _add_sprite_prop("res://assets/environment/castle_gardens/urn_planter.png", world_pos, Vector2(0, -10), false, Vector2(10, 8))

func _add_sprite_prop(path: String, world_pos: Vector2, offset: Vector2, flip_h: bool, collision_size: Vector2) -> Node2D:
	var root := PROP_SCENE.instantiate() as Node2D
	root.position = world_pos
	var sprite := root.get_node("Sprite") as Sprite2D
	sprite.texture = load(path) as Texture2D
	sprite.offset = offset
	sprite.flip_h = flip_h
	var shape := root.get_node("Body/CollisionShape2D") as CollisionShape2D
	var rectangle := RectangleShape2D.new()
	rectangle.size = collision_size
	shape.shape = rectangle
	$PropInstances.add_child(root)
	return root

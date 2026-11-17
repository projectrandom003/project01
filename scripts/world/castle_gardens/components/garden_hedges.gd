class_name GardenHedges
extends Node2D
## Hedge placement instances an authored visual/collision assembly.
@export var hedge_texture: Texture2D
const PROP_SCENE: PackedScene = preload("res://scenes/world/castle_gardens/components/garden_sprite_prop.tscn")

func _ready() -> void:
	if hedge_texture == null:
		hedge_texture = load("res://assets/environment/castle_gardens/hedge_block.png") as Texture2D

func add_hedge(world_pos: Vector2, with_collision: bool = true) -> Node2D:
	var root := PROP_SCENE.instantiate() as Node2D
	root.position = world_pos
	var sprite := root.get_node("Sprite") as Sprite2D
	sprite.texture = hedge_texture
	sprite.offset = Vector2(0, -8)
	var glow := root.get_node("LanternGlow")
	glow.queue_free()
	if with_collision:
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(34, 18)
		(root.get_node("Body/CollisionShape2D") as CollisionShape2D).shape = rectangle
	else:
		root.get_node("Body").queue_free()
	$HedgeInstances.add_child(root)
	return root

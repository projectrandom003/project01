class_name CastleEntrance
extends Node2D
## Castle entrance assembly. Visual and collision pieces are reusable authored scenes.

const PROP_SCENE: PackedScene = preload("res://scenes/world/castle_gardens/components/garden_sprite_prop.tscn")
const BOX_SCENE: PackedScene = preload("res://scenes/world/castle_gardens/components/garden_collision_box.tscn")

func build_default(center: Vector2) -> void:
	var gate_tex := load("res://assets/environment/castle_gardens/castle_gate_detailed.png") as Texture2D
	if gate_tex == null:
		gate_tex = load("res://assets/environment/castle_gardens/castle_gate.png") as Texture2D
	if gate_tex == null:
		return
	var gate := PROP_SCENE.instantiate() as Node2D
	gate.position = center
	var sprite := gate.get_node("Sprite") as Sprite2D
	sprite.texture = gate_tex
	sprite.offset = Vector2(0, -44)
	sprite.scale = Vector2(1.05, 1.05)
	gate.get_node("Body").queue_free()
	gate.get_node("LanternGlow").queue_free()
	$Visuals.add_child(gate)
	_add_box(center + Vector2(-58, 22), Vector2(46, 28))
	_add_box(center + Vector2(58, 22), Vector2(46, 28))

func _add_box(pos: Vector2, size: Vector2) -> void:
	var body := BOX_SCENE.instantiate() as StaticBody2D
	body.position = pos
	(body.get_node("CollisionShape2D") as CollisionShape2D).shape = RectangleShape2D.new()
	(body.get_node("CollisionShape2D").shape as RectangleShape2D).size = size
	$Collisions.add_child(body)

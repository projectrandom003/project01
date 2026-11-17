class_name StonePathways
extends Node2D
## Connected pathway placement from an authored reusable sprite-prop scene.
@export var tile_texture: Texture2D
@export var tile_size: Vector2 = Vector2(64, 32)
@export var positions: Array[Vector2] = []
const PROP_SCENE: PackedScene = preload("res://scenes/world/castle_gardens/components/garden_sprite_prop.tscn")

func _ready() -> void:
	if tile_texture == null:
		tile_texture = load("res://assets/environment/castle_gardens/path_tile.png") as Texture2D
	for p in positions:
		_add_tile(p)

func add_path_tile(world_pos: Vector2) -> void:
	_add_tile(world_pos)

func _add_tile(world_pos: Vector2) -> void:
	var prop := PROP_SCENE.instantiate() as Node2D
	prop.position = world_pos
	(prop.get_node("Sprite") as Sprite2D).texture = tile_texture
	prop.get_node("Body").queue_free()
	prop.get_node("LanternGlow").queue_free()
	$Tiles.add_child(prop)

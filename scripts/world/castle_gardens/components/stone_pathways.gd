class_name StonePathways
extends Node2D
## Reusable connected stone pathway layout component.
@export var tile_texture: Texture2D
@export var tile_size: Vector2 = Vector2(64, 32)
@export var positions: Array[Vector2] = []

func _ready() -> void:
	if tile_texture == null:
		tile_texture = load("res://assets/environment/castle_gardens/path_tile.png")
	for p in positions:
		_add_tile(p)

func add_path_tile(world_pos: Vector2) -> void:
	_add_tile(world_pos)

func _add_tile(world_pos: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = tile_texture
	s.centered = true
	s.position = world_pos
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(s)

class_name VillageProp
extends Node2D
## Reusable village prop with an authored sprite and optional physical footprint.
## The node origin remains the ground-contact/Y-sort point.

@export var prop_kind: String = ""
@export var variant: int = 0
@export var prop_scale: float = 1.0
@export var flip_h: bool = false
@export var apply_wind: bool = false
@export var blocks_movement: bool = false:
	set(value):
		blocks_movement = value
		_update_collision()
@export var collision_size: Vector2 = Vector2(28.0, 18.0)
@export var collision_offset: Vector2 = Vector2(0.0, -6.0)

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _solid_body: StaticBody2D = $Collision/StaticBody2D
@onready var _solid_shape: CollisionShape2D = $Collision/StaticBody2D/CollisionShape

func _ready() -> void:
	_apply()
	_update_collision()

func _apply() -> void:
	if _sprite == null:
		_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _sprite == null or prop_kind.is_empty():
		return
	var tex := ProceduralArt.prop_texture(prop_kind, variant)
	if tex == null:
		return
	_sprite.texture = tex
	_sprite.centered = false
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.offset = Vector2(-float(tex.get_width()) * 0.5, -float(tex.get_height()) + 6.0)
	_sprite.scale = Vector2.ONE * prop_scale
	_sprite.flip_h = flip_h
	_sprite.material = null
	if apply_wind and prop_kind in ["glade_tree", "ancient_tree", "bush", "flower_cluster", "fern", "birch_tree", "willow_tree", "pine_tree", "blossom_tree", "berry_bush", "reeds"]:
		var world := get_tree().get_first_node_in_group("world") if is_inside_tree() else null
		if world != null and world.get("wind_material") != null:
			_sprite.material = world.get("wind_material")

func _update_collision() -> void:
	var body := get_node_or_null("Collision/StaticBody2D") as StaticBody2D
	var shape := get_node_or_null("Collision/StaticBody2D/CollisionShape") as CollisionShape2D
	if body == null or shape == null:
		return
	if shape.shape != null and not shape.shape.resource_local_to_scene:
		shape.shape = shape.shape.duplicate(true)
	body.collision_layer = 1 if blocks_movement else 0
	body.collision_mask = 0
	shape.disabled = not blocks_movement
	shape.position = collision_offset
	var rectangle := shape.shape as RectangleShape2D
	if rectangle == null:
		rectangle = RectangleShape2D.new()
		shape.shape = rectangle
	rectangle.size = collision_size

class_name VillageProp
extends Node2D
## Reusable, authored village prop/decor element. Renders existing ProceduralArt
## prop textures as a bottom-anchored sprite so the node's world position acts as
## the ground-contact/Y-sort point when placed as a direct child of a y-sorted parent.

@export var prop_kind: String = ""
@export var variant: int = 0
@export var prop_scale: float = 1.0
@export var flip_h: bool = false
@export var apply_wind: bool = false

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_apply()

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
	# Optional: wind material only if available in context; keep safe for authored scene use.
	if apply_wind and prop_kind in ["glade_tree", "ancient_tree", "bush", "flower_cluster", "fern", "birch_tree", "willow_tree", "pine_tree", "blossom_tree", "berry_bush", "reeds"]:
		var world := get_tree().get_first_node_in_group("world") if is_inside_tree() else null
		if world != null and world.get("wind_material") != null:
			_sprite.material = world.get("wind_material")
class_name VegetationPart
extends Node2D
## Reusable modular vegetation part (trunk/canopy/branch/leaf/bush/flower/grass/rock/plant/shadow).

@export var part_kind: String = "canopy"
@export var texture_kind: String = ""
@export var variant: int = 0
@export_range(0.1, 4.0, 0.01) var part_scale: float = 1.0
@export var flip_h: bool = false
@export var tint: Color = Color.WHITE
@export var use_procedural_texture: bool = true
@export var custom_texture: Texture2D

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D


func _ready() -> void:
	_apply()


func configure(p_texture_kind: String, p_variant: int = 0, p_scale: float = 1.0, p_flip: bool = false, p_tint: Color = Color.WHITE) -> void:
	texture_kind = p_texture_kind
	variant = p_variant
	part_scale = p_scale
	flip_h = p_flip
	tint = p_tint
	_apply()


func apply_variation(v: VegetationVariation) -> void:
	if v == null:
		return
	variant = v.variant
	part_scale = v.scale
	flip_h = v.flip_h
	tint = v.tint
	if not v.kind.is_empty():
		texture_kind = v.kind
	_apply()


func _apply() -> void:
	if sprite == null:
		sprite = get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	var tex: Texture2D = custom_texture
	if tex == null and use_procedural_texture and not texture_kind.is_empty() and Engine.has_singleton("ProceduralArt") == false:
		# ProceduralArt is a script class/autoload-style utility in project; call directly.
		tex = ProceduralArt.prop_texture(texture_kind, variant)
	elif tex == null and use_procedural_texture and not texture_kind.is_empty():
		tex = ProceduralArt.prop_texture(texture_kind, variant)
	sprite.texture = tex
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.flip_h = flip_h
	sprite.scale = Vector2.ONE * part_scale
	sprite.modulate = tint
	if tex != null:
		sprite.offset = Vector2(-float(tex.get_width()) * 0.5, -float(tex.get_height()) + 6.0)

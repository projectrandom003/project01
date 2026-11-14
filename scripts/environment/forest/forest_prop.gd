class_name ModularForestProp
extends Node2D
## Reusable node-based forest prop. Visuals are replaceable textures; the scene
## owns the visual anchor, optional shadow and optional authored animation.

@export var prop_kind: String = "fern"
@export_range(0, 32) var variant: int = 0
@export_range(0.1, 3.0, 0.05) var prop_scale: float = 1.0
@export var flip_h: bool = false
@export var shadow_enabled: bool = false
@export var sway_enabled: bool = false
@export_range(0.0, 0.12, 0.005) var sway_amount: float = 0.025
@export var glow_enabled: bool = false
@export var glow_color: Color = Color(0.42, 0.95, 0.78, 1.0)
@export_range(0.0, 3.0, 0.05) var glow_energy: float = 1.0

@onready var visual: Sprite2D = get_node_or_null("Visual") as Sprite2D
@onready var shadow: Sprite2D = get_node_or_null("Shadow") as Sprite2D
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer") as AnimationPlayer

var _wind_material: Material
var _glow_activity: float = 1.0


func _ready() -> void:
	_apply_visual()
	if shadow != null:
		shadow.visible = shadow_enabled
	if sway_enabled and animation_player != null and animation_player.has_animation("sway"):
		animation_player.play("sway")
	_apply_wind_material()
	_apply_glow()


func configure(kind: String, p_variant: int, p_scale: float, p_flip: bool) -> void:
	prop_kind = kind
	variant = p_variant
	prop_scale = maxf(0.1, p_scale)
	flip_h = p_flip
	if is_node_ready():
		_apply_visual()


func set_wind_material(value: Material) -> void:
	_wind_material = value
	if is_node_ready():
		_apply_wind_material()


func set_glow_activity(value: float) -> void:
	_glow_activity = clampf(value, 0.0, 1.0)
	_apply_glow()


func _apply_visual() -> void:
	if visual == null:
		return
	var texture := ProceduralArt.prop_texture(prop_kind, variant)
	if texture == null:
		return
	visual.texture = texture
	visual.centered = false
	visual.offset = Vector2(-float(texture.get_width()) * 0.5, -float(texture.get_height()) + 6.0)
	visual.scale = Vector2.ONE * prop_scale
	visual.flip_h = flip_h
	if shadow != null:
		shadow.texture = texture
		shadow.centered = false
		shadow.offset = visual.offset + Vector2(5.0, 7.0)
		shadow.scale = Vector2.ONE * prop_scale
		shadow.flip_h = flip_h
		shadow.modulate = Color(0.025, 0.045, 0.035, 0.24)


func _apply_wind_material() -> void:
	if visual != null and sway_enabled and _wind_material != null:
		visual.material = _wind_material


func _apply_glow() -> void:
	if visual == null or not glow_enabled:
		return
	var energy := glow_energy * _glow_activity
	visual.self_modulate = Color(
		lerpf(1.0, glow_color.r, energy),
		lerpf(1.0, glow_color.g, energy),
		lerpf(1.0, glow_color.b, energy),
		1.0
	)

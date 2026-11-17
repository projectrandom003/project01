class_name WorldFogComponent
extends Node2D
## Owns the world-space fog quad and its shader parameters.

var fog_material: ShaderMaterial
var quad: Sprite2D
var enabled: bool = true
var density_scale: float = 1.0


func configure(initial_position: Vector2, fog_size: Vector2, initial_color: Color, initial_density: float, enabled: bool) -> void:
	fog_material = ShaderMaterial.new()
	fog_material.shader = load("res://resources/shaders/fog.gdshader")
	apply_appearance(initial_color, initial_density)
	quad = get_node_or_null("FogQuad") as Sprite2D
	if quad == null:
		quad = Sprite2D.new()
		quad.name = "FogQuad"
		quad.centered = true
		quad.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(quad)
	quad.texture = ProceduralArt.white_pixel()
	quad.scale = fog_size / 2.0
	quad.z_index = 20
	quad.material = fog_material
	quad.position = initial_position
	quad.visible = enabled


func set_enabled(value: bool) -> void:
	enabled = value
	if quad != null:
		quad.visible = enabled


func set_density_scale(value: float) -> void:
	density_scale = clampf(value, 0.0, 3.0)


func apply_appearance(fog_color: Color, density: float) -> void:
	if fog_material == null:
		return
	fog_material.set_shader_parameter("fog_color", Color(fog_color.r, fog_color.g, fog_color.b, 1.0))
	fog_material.set_shader_parameter("density", clampf(density * density_scale, 0.0, 0.6))

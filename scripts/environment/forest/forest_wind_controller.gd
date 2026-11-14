class_name ForestWindController
extends Node
## Shared, low-cost wind field for every foliage sprite in one forest scene.

@export_range(0.0, 8.0, 0.1) var base_strength: float = 2.4
@export_range(0.0, 4.0, 0.05) var base_speed: float = 1.15
@export_range(0.0, 1.0, 0.01) var gust_amount: float = 0.28
@export_range(0.1, 12.0, 0.1) var gust_period: float = 4.8

var wind_material: ShaderMaterial
var elapsed: float = 0.0
var wind_intensity: float = 1.0


func _ready() -> void:
	wind_material = ShaderMaterial.new()
	wind_material.shader = load("res://resources/shaders/wind_sway.gdshader") as Shader
	_apply_wind()


func _process(delta: float) -> void:
	elapsed += delta
	_apply_wind()


func set_wind_intensity(value: float) -> void:
	wind_intensity = clampf(value, 0.0, 2.0)
	_apply_wind()


func _apply_wind() -> void:
	if wind_material == null:
		return
	var gust := 1.0 + sin(elapsed * TAU / maxf(0.1, gust_period)) * gust_amount
	wind_material.set_shader_parameter("sway_strength", base_strength * wind_intensity * gust)
	wind_material.set_shader_parameter("sway_speed", base_speed * lerpf(0.55, 1.0, wind_intensity))

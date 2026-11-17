class_name WorldLightingComponent
extends Node
## Owns bounded localized point lights and their day/night/environment response.

const WORLD_POINT_LIGHT_SCENE: PackedScene = preload("res://scenes/world/components/world_point_light.tscn")

var light_root: Node2D
var max_lights: int = 20
var lights: Array = []
var enabled: bool = true


func configure(root: Node2D, light_cap: int = 20) -> void:
	light_root = root
	max_lights = maxi(0, light_cap)


func add_light(grid_position: Vector2, color: Color, energy: float, light_scale: float) -> bool:
	if light_root == null or lights.size() >= max_lights:
		return false
	var light := WORLD_POINT_LIGHT_SCENE.instantiate() as PointLight2D
	if light == null:
		return false
	light.texture = ProceduralArt.soft_glow(color, 128)
	light.color = color
	light.energy = energy
	light.texture_scale = light_scale
	light.blend_mode = Light2D.BLEND_MODE_ADD
	light.visible = enabled
	light.position = IsoMath.grid_to_world(grid_position.x, grid_position.y) + Vector2(0, -36)
	light_root.add_child(light)
	lights.append({"light": light, "energy": energy, "color": color})
	return true


func set_enabled(value: bool) -> void:
	enabled = value
	for entry in lights:
		var light: PointLight2D = entry.light
		if is_instance_valid(light):
			light.visible = enabled


func apply_atmosphere(phase_energy: float, phase_tint: Color, environment_tint: Color, zone_tint: Color) -> void:
	for entry in lights:
		var light: PointLight2D = entry.light
		if not is_instance_valid(light):
			continue
		light.energy = float(entry.energy) * (0.55 + phase_energy * 0.7)
		var base_color: Color = entry.color
		light.color = base_color.lerp(phase_tint, 0.10).lerp(environment_tint, 0.06).lerp(zone_tint, 0.05)

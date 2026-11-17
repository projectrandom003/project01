class_name WorldResourceSetupComponent
extends Node
## Owns creation and configuration of per-world shader materials and terrain noise.

var world: GreenwardWorld

func configure(owner_world: GreenwardWorld) -> void:
	world = owner_world

func setup_materials() -> void:
	if world == null:
		return
	world.terrain_material = ShaderMaterial.new()
	world.terrain_material.shader = load("res://resources/shaders/terrain.gdshader")
	world.water_material = ShaderMaterial.new()
	world.water_material.shader = load("res://resources/shaders/water.gdshader")
	world.wind_material = ShaderMaterial.new()
	world.wind_material.shader = load("res://resources/shaders/wind_sway.gdshader")

func setup_noise() -> void:
	if world == null:
		return
	world.elevation = FastNoiseLite.new()
	world.elevation.seed = int(world.region.get("noise_seed", 1337))
	world.elevation.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	world.elevation.frequency = 0.032
	world.elevation.fractal_octaves = 3
	if world.navigation_component != null:
		world.navigation_component.set_elevation_noise(world.elevation)
	world.moisture = FastNoiseLite.new()
	world.moisture.seed = int(world.region.get("noise_seed", 1337)) + 91
	world.moisture.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	world.moisture.frequency = 0.055
	world.moisture.fractal_octaves = 2

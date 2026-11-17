class_name WorldAtmosphereComponent
extends Node
## Applies phase, weather, environment and zone data to fog, lights and ambient effects.

var world: GreenwardWorld


func configure(owner: GreenwardWorld) -> void:
	world = owner


func apply_atmosphere() -> void:
	if world == null:
		return
	var phase := GreenwardStyle.phase(world.day_phase())
	var weather_params := world.weather.params() if world.weather != null else {}
	var mobile := GreenwardStyle.performance_tier() == "mobile"
	var particle_cap := GreenwardStyle.MAX_PARTICLES
	var environment := world._environment()
	var environment_fog := float(environment.get("fog_density", 0.0))
	var environment_tint := Color(str(environment.get("ambient_tint", "#ffffff")))
	var zone_tint := Color(str(world.ZONE_TINTS.get(world.current_zone(), "#ffffff")))

	if world.fog_material != null:
		var base_density := float(phase.get("fog_density", 0.10))
		var weather_fog := float(weather_params.get("fog_density", 0.0))
		var density := clampf(base_density + weather_fog + environment_fog * 0.25, 0.0, 0.6)
		if mobile:
			density *= 0.3
		var fog_color: Color = phase.get("fog", Color(0.8, 0.88, 0.95, 1.0))
		fog_color = fog_color.lerp(zone_tint, 0.08)
		if world._visual_standards_applied:
			fog_color = fog_color.lerp(world._visual_standards_tint, 0.06)
		if world.fog_component != null:
			world.fog_component.apply_appearance(fog_color, density)
		else:
			world.fog_material.set_shader_parameter("fog_color", Color(fog_color.r, fog_color.g, fog_color.b, 1.0))
			world.fog_material.set_shader_parameter("density", density)

	var light_energy := float(phase.get("light_energy", 1.0))
	var tint: Color = phase.get("tint", Color.WHITE)
	if world.lighting_component != null:
		world.lighting_component.apply_atmosphere(light_energy, tint, environment_tint, zone_tint)
	else:
		for entry in world._lights:
			var light: PointLight2D = entry.light
			if not is_instance_valid(light):
				continue
			light.energy = float(entry.energy) * (0.55 + light_energy * 0.7)
			var color: Color = entry.color
			light.color = color.lerp(tint, 0.10).lerp(environment_tint, 0.06).lerp(zone_tint, 0.05)

	if world.ambient_effects_component != null:
		world.ambient_effects_component.apply_atmosphere(
			phase, weather_params, mobile, particle_cap, environment_tint, zone_tint,
			world._visual_standards_applied, world._visual_standards_tint
		)
	else:
		apply_rain(weather_params)


func apply_rain(weather_params: Dictionary) -> void:
	if world == null:
		return
	if world.ambient_effects_component != null:
		world.ambient_effects_component.apply_rain(
			weather_params, GreenwardStyle.performance_tier() == "mobile", GreenwardStyle.MAX_PARTICLES
		)
		return
	if world.rain == null:
		return
	var desired := int(weather_params.get("rain_amount", 0))
	if GreenwardStyle.performance_tier() == "mobile":
		desired = 0
	desired = clampi(desired, 0, GreenwardStyle.MAX_PARTICLES)
	world.rain.amount = maxi(1, desired)
	world.rain.emitting = desired > 0
	var rain_color := GreenwardStyle.WATER.glint
	world.rain.color = Color(rain_color.r, rain_color.g, rain_color.b, 0.45)

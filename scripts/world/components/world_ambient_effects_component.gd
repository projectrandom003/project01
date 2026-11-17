class_name WorldAmbientEffectsComponent
extends Node
## Owns the bounded pollen, firefly and rain particle emitters.

var ambient: CPUParticles2D
var fireflies: CPUParticles2D
var rain: CPUParticles2D
var ambient_enabled: bool = true
var weather_enabled: bool = true
var presentation_tint: Color = Color.WHITE


func set_presentation_options(enable_ambient: bool, enable_weather: bool, tint: Color) -> void:
	ambient_enabled = enable_ambient
	weather_enabled = enable_weather
	presentation_tint = tint
	if ambient != null:
		ambient.visible = ambient_enabled
	if fireflies != null:
		fireflies.visible = ambient_enabled
	if rain != null:
		if not weather_enabled:
			rain.emitting = false
		rain.visible = weather_enabled


func configure(effect_root: Node2D, is_night: bool) -> void:
	ambient = effect_root.get_node_or_null("PollenMotes") as CPUParticles2D
	fireflies = effect_root.get_node_or_null("Fireflies") as CPUParticles2D
	rain = effect_root.get_node_or_null("Rain") as CPUParticles2D
	if ambient != null:
		ambient.texture = ProceduralArt.soft_glow(Color(1.0, 0.95, 0.72), 32)
	if fireflies != null:
		fireflies.texture = ProceduralArt.soft_glow(Color(0.65, 1.0, 0.9), 32)
		fireflies.emitting = is_night
	if rain != null:
		rain.texture = ProceduralArt.soft_glow(GreenwardStyle.WATER.glint, 16)
		rain.emitting = false


func apply_atmosphere(phase: Dictionary, weather_params: Dictionary, mobile: bool, particle_cap: int, environment_tint: Color, zone_tint: Color, standards_applied: bool, standards_tint: Color) -> void:
	if ambient != null:
		var pollen_scale := float(weather_params.get("particle_scale", 1.0))
		var pollen_amount := int(particle_cap * 0.09 * pollen_scale)
		if bool(phase.get("fireflies", false)):
			pollen_amount = int(pollen_amount * 0.55)
		if mobile:
			pollen_amount = int(pollen_amount * 0.5)
		ambient.amount = maxi(1, clampi(pollen_amount, 0, particle_cap))
		ambient.emitting = pollen_amount > 0
		var pollen_color := GreenwardStyle.ACCENTS.petal_alt.lerp(presentation_tint, 0.12)
		var weather_tint: Variant = weather_params.get("tint", null)
		if weather_tint is Color:
			pollen_color = pollen_color.lerp(weather_tint, 0.25)
		pollen_color = pollen_color.lerp(environment_tint, 0.10).lerp(zone_tint, 0.12)
		if standards_applied:
			pollen_color = pollen_color.lerp(standards_tint, 0.08)
		ambient.color = Color(pollen_color.r, pollen_color.g, pollen_color.b, 0.5)

	if fireflies != null:
		var night := bool(phase.get("fireflies", false))
		var firefly_amount := int(particle_cap * 0.06) if night else 0
		if mobile:
			firefly_amount = int(firefly_amount * 0.5)
		fireflies.amount = maxi(1, clampi(firefly_amount, 0, particle_cap))
		fireflies.emitting = night and firefly_amount > 0
		var firefly_color := GreenwardStyle.ACCENTS.firefly
		fireflies.color = Color(firefly_color.r, firefly_color.g, firefly_color.b, 0.7)

	apply_rain(weather_params, mobile, particle_cap)


func apply_rain(weather_params: Dictionary, mobile: bool, particle_cap: int) -> void:
	if rain == null or not weather_enabled:
		return
	var desired := int(weather_params.get("rain_amount", 0))
	if mobile:
		desired = 0
	desired = clampi(desired, 0, particle_cap)
	rain.amount = maxi(1, desired)
	rain.emitting = desired > 0
	var rain_color := GreenwardStyle.WATER.glint
	rain.color = Color(rain_color.r, rain_color.g, rain_color.b, 0.45)

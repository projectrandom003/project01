class_name WorldPresentationConfigComponent
extends Node
## Applies the authored environment-presentation resource to world-owned systems.

var applied_config: EnvironmentPresentationConfig


func configure(config: Resource, day_night: DayNight, ambient_effects: WorldAmbientEffectsComponent, fog: WorldFogComponent, lighting: WorldLightingComponent, water_root: Node2D, sound_root: Node2D) -> bool:
	if not config is EnvironmentPresentationConfig:
		return false
	applied_config = config as EnvironmentPresentationConfig
	if day_night != null:
		day_night.set_process(applied_config.day_night_enabled)
	if ambient_effects != null:
		ambient_effects.set_presentation_options(
			applied_config.ambient_particles_enabled,
			applied_config.weather_enabled,
			applied_config.ambient_tint
		)
	if fog != null:
		fog.set_enabled(applied_config.fog_enabled)
		fog.set_density_scale(applied_config.fog_density_scale)
	if lighting != null:
		lighting.set_enabled(applied_config.localized_lights_enabled)
	if water_root != null:
		water_root.visible = applied_config.water_presentation_enabled
	if sound_root != null:
		sound_root.visible = applied_config.environmental_sound_enabled
	return true

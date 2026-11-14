class_name EnvironmentPresentationConfig
extends Resource

@export var day_night_enabled: bool = true
@export var ambient_particles_enabled: bool = true
@export var weather_enabled: bool = true
@export var fog_enabled: bool = true
@export var water_presentation_enabled: bool = true
@export var localized_lights_enabled: bool = true
@export var environmental_sound_enabled: bool = true
@export var fog_density_scale: float = 1.0
@export var ambient_tint: Color = Color.WHITE
@export var weather_bias: Array[String] = []
@export var metadata: Dictionary = {}

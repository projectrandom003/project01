class_name EnvironmentPresentationRoot
extends Node2D

signal presentation_config_applied(config: EnvironmentPresentationConfig)

@export var config: EnvironmentPresentationConfig

@onready var day_night_node: Node = $DayNight
@onready var ambient_particles_node: Node2D = $AmbientParticles
@onready var weather_effects_node: Node2D = $WeatherEffects
@onready var fog_node: Node2D = $Fog
@onready var water_presentation_node: Node2D = $WaterPresentation
@onready var localized_lights_node: Node2D = $LocalizedLights
@onready var environmental_sounds_node: Node2D = $EnvironmentalSounds


func _ready() -> void:
	_apply_config()


func _apply_config() -> void:
	if config == null:
		return
	if day_night_node != null:
		day_night_node.set_process(config.day_night_enabled)
	if ambient_particles_node != null:
		ambient_particles_node.visible = config.ambient_particles_enabled
	if weather_effects_node != null:
		weather_effects_node.visible = config.weather_enabled
	if fog_node != null:
		fog_node.visible = config.fog_enabled
	if water_presentation_node != null:
		water_presentation_node.visible = config.water_presentation_enabled
	if localized_lights_node != null:
		localized_lights_node.visible = config.localized_lights_enabled
	if environmental_sounds_node != null:
		environmental_sounds_node.visible = config.environmental_sound_enabled
		for child in environmental_sounds_node.get_children():
			if child.has_method("set_enabled"):
				child.call("set_enabled", config.environmental_sound_enabled)
	presentation_config_applied.emit(config)


func apply_config(new_config: EnvironmentPresentationConfig) -> void:
	config = new_config
	_apply_config()

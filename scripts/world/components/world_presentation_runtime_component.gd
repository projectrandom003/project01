class_name WorldPresentationRuntimeComponent
extends Node
## Coordinates per-frame world presentation updates without owning their systems.

var world: GreenwardWorld


func configure(owner_world: GreenwardWorld) -> void:
	world = owner_world


func follow_player_and_tick_weather(player_position: Vector2, delta: float) -> void:
	if world == null:
		return
	if world.effect_follow_component != null:
		world.effect_follow_component.follow_player(player_position)
	if world.weather_component != null:
		world.weather_component.tick(delta)


func update_nearby_animated_props() -> void:
	if world != null and world.day_night_presentation_component != null:
		world.day_night_presentation_component.gate_animated_props()

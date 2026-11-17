class_name WorldEffectFollowComponent
extends Node
## Keeps bounded world-space atmosphere effects centered on the active player.

var ambient_particles: Node2D
var fireflies: Node2D
var rain: Node2D
var fog: Node2D
var rain_offset := Vector2(0.0, -420.0)


func configure(ambient: Node2D, firefly_effect: Node2D, rain_effect: Node2D, fog_effect: Node2D) -> void:
	ambient_particles = ambient
	fireflies = firefly_effect
	rain = rain_effect
	fog = fog_effect


func follow_player(player_world_position: Vector2) -> void:
	if is_instance_valid(ambient_particles):
		ambient_particles.global_position = player_world_position
	if is_instance_valid(fireflies):
		fireflies.global_position = player_world_position
	if is_instance_valid(rain):
		rain.global_position = player_world_position + rain_offset
	if is_instance_valid(fog):
		fog.global_position = player_world_position

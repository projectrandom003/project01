class_name WorldRuntimeComponent
extends Node
## Owns the active-world frame loop: chunk movement, ambient following,
## weather simulation, periodic position persistence and atmosphere refresh.

const SAVE_INTERVAL := 1.0
const ATMOSPHERE_INTERVAL := 0.25

var world: GreenwardWorld
var _save_accumulator := 0.0
var _atmosphere_accumulator := 0.0

func configure(owner_world: GreenwardWorld) -> void:
	world = owner_world

func tick(delta: float) -> void:
	if world == null or not is_instance_valid(world):
		return
	var player := world.player
	if player == null or not is_instance_valid(player):
		return
	var grid := IsoMath.world_to_grid(player.position)
	var center := world.streamer.center_chunk(grid)
	if center != world.current_center:
		world.current_center = center
		world._update_streaming(grid)
	if world.effect_follow_component != null:
		world.effect_follow_component.follow_player(player.position)
	if world.weather_component != null:
		world.weather_component.tick(delta)
	_save_accumulator += delta
	if _save_accumulator >= SAVE_INTERVAL:
		_save_accumulator = 0.0
		GameState.session_domain.set_player_position(player.position)
		GameState.session_domain.set_region_position(world.region_id, player.position)
	_atmosphere_accumulator += delta
	if _atmosphere_accumulator >= ATMOSPHERE_INTERVAL:
		_atmosphere_accumulator = 0.0
		world._apply_atmosphere()
	if world.day_night_presentation_component != null:
		world.day_night_presentation_component.gate_animated_props()
	if world.chunk_streaming_component != null:
		world.chunk_streaming_component.prepare_one_chunk(grid)

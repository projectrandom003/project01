class_name WorldSessionPersistenceComponent
extends Node
## Owns the cadence for persisting the active player's world position.

const SAVE_INTERVAL := 1.0

var world: GreenwardWorld
var _save_accumulator := 0.0


func configure(owner_world: GreenwardWorld) -> void:
	world = owner_world


func tick(delta: float, player_position: Vector2) -> void:
	if world == null:
		return
	_save_accumulator += delta
	if _save_accumulator < SAVE_INTERVAL:
		return
	_save_accumulator = 0.0
	GameState.session_domain.set_player_position(player_position)
	GameState.session_domain.set_region_position(world.region_id, player_position)

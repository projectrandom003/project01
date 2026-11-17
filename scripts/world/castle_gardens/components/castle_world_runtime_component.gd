class_name CastleWorldRuntimeComponent
extends Node
## Owns periodic persistence for the active Royal Gardens player.

@export_range(0.1, 10.0, 0.1, "suffix:s") var save_position_interval := 1.0

var world: CastleRoyalGardens
var _save_accumulator := 0.0


func bind(owner_world: CastleRoyalGardens) -> void:
	world = owner_world


func _process(delta: float) -> void:
	if world == null or world.player == null or not is_instance_valid(world.player):
		return
	GameState.session_domain.set_player_position(world.player.position)
	GameState.session_domain.set_region_position(world.region_id, world.player.position)
	_save_accumulator += delta
	if _save_accumulator >= save_position_interval:
		_save_accumulator = 0.0
		GameState.save_now()

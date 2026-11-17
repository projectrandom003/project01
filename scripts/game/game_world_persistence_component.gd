class_name GameWorldPersistenceComponent
extends Node
## Owns durable world/session position and facing persistence.

var session: GameWorldSessionComponent

func configure(owner_session: GameWorldSessionComponent) -> void:
	session = owner_session

func persist_current_world_state() -> void:
	if session == null or session.world == null or not is_instance_valid(session.world):
		return
	if not session.current_region_id.is_empty():
		GameState.session_domain.set_player_region(session.current_region_id)
		GameState.session_domain.set_active_world(session.current_region_id)
	var player: Node = session.world.get("player") if "player" in session.world else null
	if player != null and is_instance_valid(player):
		var player_position: Vector2 = player.get("position")
		GameState.session_domain.set_region_position(session.current_region_id, player_position)
		GameState.session_domain.set_player_position(player_position)
		var facing := Vector2(0.0, 1.0)
		var saved_facing: Variant = player.get("facing_direction")
		if saved_facing is Vector2:
			facing = saved_facing
		GameState.session_domain.set_player_facing(facing)
	GameState.save_now()

class_name GameWorldActivationComponent
extends Node
## Owns process gating and input activation for the current world.

var session: GameWorldSessionComponent

func configure(owner_session: GameWorldSessionComponent) -> void:
	session = owner_session

func set_active(active: bool) -> void:
	if session == null or session.world == null or not is_instance_valid(session.world):
		return
	session.world.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	var player: Node = session.world.get("player") if "player" in session.world else null
	if player != null and is_instance_valid(player):
		player.set("input_enabled", active)
	TouchInput.release()

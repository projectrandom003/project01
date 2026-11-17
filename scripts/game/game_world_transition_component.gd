class_name GameWorldTransitionComponent
extends Node
## Owns route validation and the atomic world-to-world transition sequence.

var session: GameWorldSessionComponent
var _changing_region := false

func configure(owner_session: GameWorldSessionComponent) -> void:
	session = owner_session

func transition_to(target_region_id: String, entry_point: String) -> Dictionary:
	if session == null or _changing_region or session.world == null or not is_instance_valid(session.world):
		return {"ok": false, "reason": "World transition is already in progress."}
	var player: Node = session.world.get("player") if "player" in session.world else null
	if player == null or not is_instance_valid(player):
		return {"ok": false, "reason": "The current world has no active player."}
	var destination_id := session.resolve_region_id(target_region_id)
	var can_transition := session.has_region_scene(destination_id)
	var destination_name := destination_id
	var graph := RegionGraph.new(ContentDB.regions)
	if graph.has_region(session.current_region_id) and graph.has_region(destination_id):
		destination_name = graph.region_name(destination_id)
		can_transition = false
		for connection in graph.connections_from(session.current_region_id):
			if typeof(connection) == TYPE_DICTIONARY and str(connection.get("to", "")) == destination_id:
				can_transition = true
				break
	elif graph.has_region(destination_id):
		destination_name = graph.region_name(destination_id)
	if not can_transition:
		return {"ok": false, "reason": "No route to " + destination_name}

	_changing_region = true
	var player_position: Vector2 = player.get("position")
	GameState.session_domain.set_region_position(session.current_region_id, player_position)
	GameState.session_domain.set_player_region(destination_id)
	GameState.save_now()
	var previous_world := session.world
	session.world = null
	previous_world.queue_free()
	session.build_world(destination_id, entry_point)
	GameState.save_now()
	_changing_region = false
	session.region_arrived.emit(destination_id, destination_name)
	return {"ok": true, "region_id": destination_id, "display_name": destination_name, "world": session.world}

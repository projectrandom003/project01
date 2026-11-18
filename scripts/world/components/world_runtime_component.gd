class_name WorldRuntimeComponent
extends Node
## Composition root for active-world frame updates.
## Dedicated child nodes own chunk movement, presentation, persistence and refresh cadence.

@onready var chunk_runtime: Node = get_node_or_null("ChunkRuntime")
@onready var presentation_runtime: Node = get_node_or_null("PresentationRuntime")
@onready var session_persistence: Node = get_node_or_null("SessionPersistence")
@onready var atmosphere_refresh: Node = get_node_or_null("AtmosphereRefresh")

var world: GreenwardWorld


func configure(owner_world: GreenwardWorld) -> void:
	world = owner_world
	var components: Array = [chunk_runtime, presentation_runtime, session_persistence, atmosphere_refresh]
	for component in components:
		if component == null:
			push_error("WorldRuntime is missing an authored runtime child component")
			return
		component.configure(world)


func tick(delta: float) -> void:
	if world == null or not is_instance_valid(world):
		return
	var player := world.player
	if player == null or not is_instance_valid(player):
		return

	var player_position := player.position
	var player_grid := IsoMath.world_to_grid(player_position)

	# Preserve the established update order while keeping each responsibility in
	# its own editor-visible node.
	chunk_runtime.update_player_chunk(player_grid)
	presentation_runtime.follow_player_and_tick_weather(player_position, delta)
	session_persistence.tick(delta, player_position)
	atmosphere_refresh.tick(delta)
	presentation_runtime.update_nearby_animated_props()
	chunk_runtime.prepare_next_chunk(player_grid)

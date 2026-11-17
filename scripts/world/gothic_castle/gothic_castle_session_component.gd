class_name GothicCastleSessionComponent
extends Node
## Owns periodic player persistence, exploration discovery rewards and weather ticks.

var world: GothicCastleBossZone
var _save_accumulator: float = 0.0
var _reward_accumulator: float = 0.0

func bind(owner: GothicCastleBossZone) -> void:
	world = owner

func _process(delta: float) -> void:
	if world == null or world.player == null or not is_instance_valid(world.player):
		return
	_save_accumulator += delta
	if _save_accumulator >= 1.0:
		_save_accumulator = 0.0
		GameState.session_domain.set_player_position(world.player.global_position)
	_reward_accumulator += delta
	if _reward_accumulator >= 0.25:
		_reward_accumulator = 0.0
		_check_exploration_rewards()
	if world.weather != null and world.weather.has_method("tick"):
		world.weather.tick(delta)

func _check_exploration_rewards() -> void:
	var player_grid := IsoMath.world_to_grid(world.player.global_position)
	for discovery in ReverieRouteData.DISCOVERIES:
		var d: Dictionary = discovery
		var flag := str(d["flag"])
		if GameState.flags.has(flag):
			continue
		var cell: Vector2i = d["grid"]
		if Vector2(player_grid).distance_to(Vector2(cell)) > 2.5:
			continue
		GameState.flags[flag] = true
		var xp := int(d.get("xp", 0))
		if xp > 0:
			GameState.roster_domain.add_party_xp(xp)
		EventBus.toast_requested.emit("Discovered %s  —  +%d XP" % [str(d["name"]), xp])
		GameState.queue_save()

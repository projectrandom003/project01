class_name GameStateLifecycleComponent
extends Node
## Owns GameState startup, new-journey bootstrap, autosave cadence and reset lifecycle.

var state: Node
@onready var save_timer: Timer = get_node_or_null("../SaveTimer") as Timer
@onready var autosave_timer: Timer = get_node_or_null("../AutosaveTimer") as Timer


func configure(owner_state: Node) -> void:
	state = owner_state


func initialize() -> void:
	if state == null:
		return
	if save_timer == null or autosave_timer == null:
		push_error("GameStateLifecycleComponent requires authored SaveTimer and AutosaveTimer siblings")
		return
	if not save_timer.timeout.is_connected(save_now):
		save_timer.timeout.connect(save_now)
	if not autosave_timer.timeout.is_connected(save_now):
		autosave_timer.timeout.connect(save_now)
	autosave_timer.start()
	if SaveService.has_save():
		var data := SaveService.load_save()
		if not data.is_empty():
			state._load_from_dict(data)
			state.loaded_from_save = true
	if state.profile.is_empty():
		new_game()
	print("[GameState] %s ? %d characters, %d in party." % [
		"loaded save" if state.loaded_from_save else "new journey",
		state.roster.size(), state.party.size()
	])


func new_game(player_name: String = "Wanderer") -> void:
	if state == null:
		return
	state.loaded_from_save = false
	state.profile = {
		"name": player_name,
		"level": 1,
		"xp": 0,
		"gold": 500,
		"gems": 0,
		"crystals": 1500,
		"guild_tokens": 0,
		"ancient_coins": 0,
		"event_tokens": 0,
		"created_at": Time.get_unix_time_from_system(),
	}
	state.roster.clear()
	state.party.clear()
	state.inventory = { "glade_sap": 3, "mossweave_vest": 1 }
	state.quests = {}
	state.pity = {}
	state.daily_rewards = {}
	state.flags = {}
	state.player_position = Vector2.ZERO
	state.has_player_position = false
	state.player_facing = Vector2(0.0, 1.0)
	state.player_region = "greenward"
	state.active_world_id = "greenward"
	state.region_positions = {}
	state.roster_domain.reset_uid_counter()
	for character_id in state.STARTING_CHARACTERS:
		state.add_character(character_id)
	save_now()
	EventBus.roster_changed.emit()
	EventBus.party_changed.emit()
	EventBus.currency_changed.emit()


func save_now() -> void:
	if state == null or state.profile.is_empty():
		return
	SaveService.write_save(state._to_dict())


func queue_save() -> void:
	if save_timer != null:
		save_timer.start()


func reset_progress() -> void:
	SaveService.delete_save()
	new_game()

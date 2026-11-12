extends Node
## Global signal bus. Systems talk through this instead of holding direct
## references to each other, which keeps world, combat and UI decoupled.

signal toast_requested(message: String)
signal roster_changed
signal party_changed
signal currency_changed
signal inventory_changed
signal quest_updated(quest_id: String)
signal dialogue_requested(dialogue_id: String)
signal dialogue_finished(dialogue_id: String)
signal encounter_requested(enemy_group_id: String, source: Node)
signal battle_requested(enemy_group_id: String)
signal battle_finished(result: Dictionary)
signal screen_changed(screen_id: String)
signal world_ready
signal player_moved(world_position: Vector2)
signal day_phase_changed(phase_name: String)
signal region_change_requested(target_region_id: String, entry_point: String)

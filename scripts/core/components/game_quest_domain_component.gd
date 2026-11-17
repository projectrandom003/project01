class_name GameQuestDomainComponent
extends Node
## Owns quest progression, objective navigation, readiness and reward completion.

var quests: Dictionary = {}
var flags: Dictionary = {}

func quest_state(quest_id: String) -> String:
	var entry: Dictionary = quests.get(quest_id, {})
	return str(entry.get("state", "not_started"))


func quest_step_index(quest_id: String) -> int:
	var entry: Dictionary = quests.get(quest_id, {})
	return int(entry.get("step", 0))


func quest_step(quest_id: String) -> Dictionary:
	var definition: Dictionary = ContentDB.get_quest(quest_id)
	var steps: Array = definition.get("steps", [])
	var index := quest_step_index(quest_id)
	if index < 0 or index >= steps.size():
		return {}
	return steps[index]


func tracked_quest() -> String:
	return str(flags.get("tracked_quest", ""))


func set_tracked_quest(quest_id: String) -> void:
	if quest_id.is_empty():
		untrack_quest()
		return
	if not ContentDB.quests.has(quest_id):
		push_warning("[GameState] Cannot track unknown quest: " + quest_id)
		return
	var previous := tracked_quest()
	flags["tracked_quest"] = quest_id
	GameState.queue_save()
	if not previous.is_empty() and previous != quest_id:
		EventBus.quest_updated.emit(previous)
	EventBus.quest_updated.emit(quest_id)


func untrack_quest() -> void:
	var previous := tracked_quest()
	flags.erase("tracked_quest")
	GameState.queue_save()
	if not previous.is_empty():
		EventBus.quest_updated.emit(previous)


func quest_destination(quest_id: String) -> Vector2:
	if quest_id.is_empty():
		return Vector2.ZERO
	var step := quest_step(quest_id)
	if step.is_empty():
		return Vector2.ZERO
	var grid: Variant = step.get("grid", null)
	if typeof(grid) == TYPE_ARRAY and (grid as Array).size() == 2:
		var coordinates: Array = grid
		return IsoMath.grid_to_world(float(coordinates[0]), float(coordinates[1]))
	var definition: Dictionary = ContentDB.get_quest(quest_id)
	var region: Dictionary = ContentDB.get_region(str(definition.get("region", "greenward")))
	var spawn: Array = region.get("spawn_grid", [8, 8])
	return IsoMath.grid_to_world(float(spawn[0]), float(spawn[1]))


func quest_target_position(quest_id: String) -> Vector2:
	var step := quest_step(quest_id)
	if str(step.get("type", "")) == "kill":
		var target_id := str(step.get("target", ""))
		var player_pos := _find_player_position()
		var best_position := Vector2.ZERO
		var best_distance := INF
		for node in get_tree().get_nodes_in_group("interactables"):
			if not is_instance_valid(node) or not (node is RoamingMonster):
				continue
			var monster := node as RoamingMonster
			if monster.defeated or not monster.visible:
				continue
			var visual_id := str(monster.visual_definition.get("id", ""))
			if monster.group_id != target_id and visual_id != target_id:
				continue
			var distance := player_pos.distance_to(monster.global_position)
			if distance < best_distance:
				best_distance = distance
				best_position = monster.global_position
		if best_distance < INF:
			return best_position
	return quest_destination(quest_id)


func distance_to_tracked() -> float:
	var quest_id := tracked_quest()
	if quest_id.is_empty() or quest_state(quest_id) == "complete":
		return 0.0
	return _find_player_position().distance_to(quest_target_position(quest_id))


func direction_to_tracked() -> Vector2:
	var quest_id := tracked_quest()
	if quest_id.is_empty() or quest_state(quest_id) == "complete":
		return Vector2.ZERO
	var delta := quest_target_position(quest_id) - _find_player_position()
	if delta.length_squared() < 0.0001:
		return Vector2.ZERO
	return delta.normalized()


func _find_player_position() -> Vector2:
	var live_player := get_tree().get_first_node_in_group("player")
	if live_player is Node2D:
		return (live_player as Node2D).global_position
	if GameState.session_domain.has_player_position:
		return GameState.session_domain.player_position
	return Vector2.ZERO


func start_quest(quest_id: String, giver_id: String = "") -> bool:
	var definition: Dictionary = ContentDB.get_quest(quest_id)
	if definition.is_empty() or quest_state(quest_id) != "not_started":
		return false
	var requires := str(definition.get("requires", ""))
	if not requires.is_empty() and quest_state(requires) != "complete":
		return false
	quests[quest_id] = {"state": "active", "step": 0, "progress": 0}
	var first := quest_step(quest_id)
	if str(first.get("type", "")) == "talk" and str(first.get("target", "")) == giver_id:
		quests[quest_id].step = 1
	set_tracked_quest(quest_id)
	EventBus.quest_updated.emit(quest_id)
	GameState.queue_save()
	return true


func quest_ready(quest_id: String) -> bool:
	if quest_state(quest_id) != "active":
		return false
	var step := quest_step(quest_id)
	if step.is_empty():
		return true
	var definition: Dictionary = ContentDB.get_quest(quest_id)
	var steps: Array = definition.get("steps", [])
	return str(step.get("type", "")) == "talk" and quest_step_index(quest_id) == steps.size() - 1


func record_kill(enemy_id: String, count: int = 1) -> void:
	var changed := false
	for quest_id in quests.keys():
		if quest_state(str(quest_id)) != "active":
			continue
		var step := quest_step(str(quest_id))
		if step.is_empty() or str(step.get("type", "")) != "kill":
			continue
		if str(step.get("target", "")) != enemy_id:
			continue
		var entry: Dictionary = quests[quest_id]
		entry.progress = int(entry.get("progress", 0)) + count
		if int(entry.progress) >= int(step.get("count", 1)):
			entry.progress = 0
			entry.step = int(entry.step) + 1
			EventBus.toast_requested.emit("Objective complete: %s" % str(step.get("text", "Target defeated")))
		quests[quest_id] = entry
		changed = true
		EventBus.quest_updated.emit(str(quest_id))
	if changed:
		GameState.queue_save()


func advance_quest(quest_id: String) -> void:
	if quest_state(quest_id) != "active":
		return
	var entry: Dictionary = quests[quest_id]
	entry.step = int(entry.get("step", 0)) + 1
	entry.progress = 0
	quests[quest_id] = entry
	EventBus.quest_updated.emit(quest_id)
	GameState.queue_save()


func complete_quest(quest_id: String) -> bool:
	if not quest_ready(quest_id):
		return false
	var definition: Dictionary = ContentDB.get_quest(quest_id)
	var rewards: Dictionary = definition.get("rewards", {})
	GameState.inventory_domain.add_currency("gold", int(rewards.get("gold", 0)))
	GameState.inventory_domain.add_currency("crystals", int(rewards.get("crystals", 0)))
	GameState.inventory_domain.grant_reward_items(rewards.get("items", {}))
	if int(rewards.get("xp", 0)) > 0:
		GameState.roster_domain.add_party_xp(int(rewards.get("xp", 0)))
	for uid in GameState.roster_domain.party:
		GameState.roster_domain.add_bond(uid, 5)
	var entry: Dictionary = quests[quest_id]
	entry.state = "complete"
	entry.step = definition.get("steps", []).size()
	quests[quest_id] = entry
	if tracked_quest() == quest_id:
		flags.erase("tracked_quest")
		for next_id in quests.keys():
			if quest_state(str(next_id)) == "active":
				flags["tracked_quest"] = str(next_id)
				break
	EventBus.quest_updated.emit(quest_id)
	EventBus.toast_requested.emit("Quest complete: %s" % definition.get("name", quest_id))
	GameState.queue_save()
	return true


func quest_marker_for_npc(npc_id: String) -> String:
	var npc_quests := {
		"elder_maelin": ["glade_whisper", "hollow_roots", "elder_memory", "matron_bloom"],
		"merchant_sera": ["sera_caravan"],
		"wanderer_pip": ["pip_whispers"],
		"road_warden": ["royal_road_supplies"],
		"blight_warden": ["blight_purification"],
		"arena_gatekeeper": ["baltoria_summoning"],
		"royal_gardener": ["garden_shadows"]
	}
	var linked: Array = npc_quests.get(npc_id, [])
	for quest_id in linked:
		if quest_state(str(quest_id)) == "active" and quest_ready(str(quest_id)):
			return "ready"
	for quest_id in linked:
		if quest_state(str(quest_id)) != "not_started":
			continue
		var definition: Dictionary = ContentDB.get_quest(str(quest_id))
		var requirement := str(definition.get("requires", ""))
		if requirement.is_empty() or quest_state(requirement) == "complete":
			return "available"
	for quest_id in linked:
		if quest_state(str(quest_id)) == "active":
			return "active"
	return ""


func active_quests() -> Array:
	var result: Array = []
	for quest_id in quests.keys():
		if quest_state(str(quest_id)) == "active":
			result.append(quest_id)
	return result


func check_condition(condition: String) -> bool:
	if condition.is_empty():
		return true
	var parts := condition.split(":")
	match parts[0]:
		"quest_state":
			return parts.size() >= 3 and quest_state(parts[1]) == parts[2]
		"quest_ready":
			return parts.size() >= 2 and quest_ready(parts[1])
		"quest_active":
			return parts.size() >= 2 and quest_state(parts[1]) == "active"
		"quest_complete":
			return parts.size() >= 2 and quest_state(parts[1]) == "complete"
		"has_character":
			return parts.size() >= 2 and GameState.roster_domain.owns_character(parts[1])
		"level_at_least":
			return parts.size() >= 2 and int(GameState.profile_domain.profile.get("level", 1)) >= int(parts[1])
	return false

class_name CombatTurnLifecycleResolver
extends RefCounted
## Resolves per-actor turn-start effects without owning the battle or scene tree.
## CombatEngine remains responsible for scheduling turns and recording log text.

static func begin_actor_turn(actor: Combatant) -> Dictionary:
	if actor == null:
		return {"events": [], "log_messages": [], "skipped": true}
	var events: Array = []
	var log_messages: Array[String] = []
	for ready_skill_id in actor.tick_skill_cooldowns():
		events.append({
			"type": "cooldown_ready",
			"actor_uid": actor.uid,
			"skill_id": ready_skill_id,
		})
	var was_stunned := actor.has_status("stun")
	if was_stunned:
		events.append({
			"type": "skip",
			"actor_uid": actor.uid,
			"actor_name": actor.display_name,
			"reason": "stunned",
		})
		log_messages.append("%s is stunned and loses the turn." % actor.display_name)
	else:
		events.append_array(_tick_statuses(actor, log_messages))
	_tick_durations(actor)
	if not actor.is_alive():
		events.append({"type": "death", "target_uid": actor.uid, "target_name": actor.display_name})
	return {
		"events": events,
		"log_messages": log_messages,
		"skipped": was_stunned or not actor.is_alive(),
	}


static func _tick_statuses(actor: Combatant, log_messages: Array[String]) -> Array:
	var events: Array = []
	for status in actor.statuses:
		var status_id := str(status.get("id", ""))
		var potency := float(status.get("potency", 0.0))
		if status_id in ["burn", "poison"]:
			var amount := maxf(1.0, roundf(actor.max_hp * potency))
			var result := actor.take_damage(amount)
			events.append({
				"type": "status_tick",
				"status": status_id,
				"target_uid": actor.uid,
				"target_name": actor.display_name,
				"amount": int(round(result.damage)),
			})
			log_messages.append("%s suffers %d %s damage." % [
				actor.display_name, int(round(result.damage)), status_id
			])
			if result.dead:
				events.append({"type": "death", "target_uid": actor.uid, "target_name": actor.display_name})
				break
		elif status_id == "regen":
			var healed := actor.heal(actor.max_hp * potency)
			if healed > 0.5:
				events.append({
					"type": "heal",
					"status": "regen",
					"target_uid": actor.uid,
					"target_name": actor.display_name,
					"amount": int(round(healed)),
				})
	return events


static func _tick_durations(actor: Combatant) -> void:
	var kept: Array = []
	for status in actor.statuses:
		status.turns = int(status.get("turns", 0)) - 1
		if int(status.turns) > 0:
			kept.append(status)
	actor.statuses = kept

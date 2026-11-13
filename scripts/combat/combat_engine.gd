class_name CombatEngine
extends RefCounted
## Deterministic, scene-independent turn-based battle engine.
##
## The engine owns no nodes and no UI. It consumes Combatants and Skills and
## returns an event stream that the battle scene animates. That separation is
## deliberate: the same engine will run on an authoritative server for PvP/raids
## while the client only replays validated events.

const PLAYER_TEAM := 0
const ENEMY_TEAM := 1
const DAMAGE_SCALE := 1.6
const CRIT_MULTIPLIER := 1.6
const DEFEND_DAMAGE_REDUCTION := 0.5
# Equipment element resonance: a skill matching the equipped element deals 8%
# more damage; a weapon matching the wielder's own element adds another 4%.
const EQUIPMENT_RESONANCE := 1.08
const EQUIPMENT_ATTUNEMENT := 1.04

var combatants: Array = []
var order: Array = []
var turn_pointer: int = 0
var round_number: int = 1
var current_actor_index: int = -1
var finished: bool = false
var winner_team: int = -1
var log: Array = []
var rng := RandomNumberGenerator.new()

var _dawnkeeper_used: Dictionary = {}


func setup(player_units: Array, enemy_units: Array, battle_seed: int = 12345) -> void:
	combatants.clear()
	for unit in player_units:
		unit.team = PLAYER_TEAM
		combatants.append(unit)
	for unit in enemy_units:
		unit.team = ENEMY_TEAM
		combatants.append(unit)
	for index in combatants.size():
		combatants[index].combat_index = index
		combatants[index].triggered_phases.clear()
	rng.seed = battle_seed
	finished = false
	winner_team = -1
	round_number = 1
	log.clear()
	_dawnkeeper_used.clear()
	_apply_battle_start_passives()
	_build_order()
	turn_pointer = -1
	current_actor_index = -1


func start() -> Array:
	if combatants.is_empty():
		return []
	_build_order()
	turn_pointer = -1
	return advance_turn()


func advance_turn() -> Array:
	if finished:
		return []
	var events: Array = []
	var guard := 0
	var max_guard := maxi(4, combatants.size() * 3)
	while guard < max_guard:
		guard += 1
		turn_pointer += 1
		if turn_pointer >= order.size():
			round_number += 1
			_build_order()
			turn_pointer = 0
			events.append({ "type": "round", "round": round_number })
		if order.is_empty():
			_check_finish()
			return events + _finish_events()
		var index: int = int(order[turn_pointer])
		var actor: Combatant = combatants[index]
		if not actor.is_alive():
			continue
		current_actor_index = index
		var beginning := _begin_actor_turn(actor)
		events.append_array(beginning.events)
		if _check_finish():
			return events + _finish_events()
		if beginning.skipped:
			continue
		events.append({
			"type": "turn",
			"actor_uid": actor.uid,
			"actor_name": actor.display_name,
			"actor_index": index,
			"round": round_number,
		})
		return events
	current_actor_index = -1
	return events


func _begin_actor_turn(actor: Combatant) -> Dictionary:
	var events: Array = []
	var was_stunned := actor.has_status("stun")
	if was_stunned:
		events.append({
			"type": "skip",
			"actor_uid": actor.uid,
			"actor_name": actor.display_name,
			"reason": "stunned",
		})
		_append_log("%s is stunned and loses the turn." % actor.display_name)
	else:
		events.append_array(_tick_statuses(actor))
	# Status durations tick once per actor turn.
	_tick_durations(actor)
	if not actor.is_alive():
		events.append({ "type": "death", "target_uid": actor.uid, "target_name": actor.display_name })
	return { "events": events, "skipped": was_stunned or not actor.is_alive() }


func _tick_statuses(actor: Combatant) -> Array:
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
			_append_log("%s suffers %d %s damage." % [actor.display_name, int(round(result.damage)), status_id])
			if result.dead:
				events.append({ "type": "death", "target_uid": actor.uid, "target_name": actor.display_name })
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


func _tick_durations(actor: Combatant) -> void:
	var kept: Array = []
	for status in actor.statuses:
		status.turns = int(status.get("turns", 0)) - 1
		if int(status.turns) > 0:
			kept.append(status)
	actor.statuses = kept


func execute(actor_index: int, skill_id: String, target_indices: Array = []) -> Array:
	var events: Array = []
	if finished:
		return events
	if actor_index < 0 or actor_index >= combatants.size():
		return events
	if actor_index != current_actor_index:
		return events
	var actor: Combatant = combatants[actor_index]
	if not actor.is_alive():
		return events
	var skill: SkillDef = ContentDB.get_skill(skill_id)
	if skill == null:
		_append_log("Unknown skill: " + skill_id)
		return events
	if skill.ultimate:
		if not actor.ultimate_ready():
			return events
		actor.energy = 0.0
	else:
		actor.add_energy(skill.energy_gain)

	var targets := resolve_targets(actor, skill, target_indices)
	events.append({
		"type": "action",
		"actor_uid": actor.uid,
		"actor_name": actor.display_name,
		"actor_index": actor_index,
		"skill_id": skill.id,
		"skill_name": skill.display_name,
		"element": skill.element,
		"ultimate": skill.ultimate,
		"target_uids": _uids_of(targets),
	})
	_append_log("%s uses %s." % [actor.display_name, skill.display_name])

	for target in targets:
		if not target.is_alive() and skill.kind != "heal":
			continue
		events.append_array(_apply_skill(actor, skill, target))

	if _check_finish():
		return events + _finish_events()
	events.append_array(advance_turn())
	return events


func resolve_targets(actor: Combatant, skill: SkillDef, chosen: Array) -> Array:
	var result: Array = []
	var enemy_team := 1 - actor.team
	match skill.target:
		"self":
			result = [actor]
		"all_enemies":
			result = living(enemy_team)
		"all_allies":
			result = living(actor.team)
		"single_ally":
			var ally := _pick_valid(chosen, actor.team)
			if ally == null:
				ally = _lowest_health(actor.team)
			result = [ally] if ally != null else []
		"single_enemy":
			var foe := _pick_valid(chosen, enemy_team)
			if foe == null:
				foe = _first_living(enemy_team)
			result = [foe] if foe != null else []
		_:
			result = []
	return result


func _pick_valid(chosen: Array, team: int) -> Combatant:
	for value in chosen:
		var index := int(value)
		if index >= 0 and index < combatants.size():
			var candidate: Combatant = combatants[index]
			if candidate.team == team and candidate.is_alive():
				return candidate
	return null


func _first_living(team: int) -> Combatant:
	for unit in living(team):
		return unit
	return null


func _lowest_health(team: int) -> Combatant:
	var best: Combatant = null
	for unit in living(team):
		if best == null or unit.hp_ratio() < best.hp_ratio():
			best = unit
	return best


func _apply_skill(actor: Combatant, skill: SkillDef, target: Combatant) -> Array:
	var events: Array = []
	match skill.kind:
		"damage":
			events.append_array(_deal_damage(actor, skill, target))
		"heal":
			var amount := target.max_hp * skill.power / 100.0
			var healed := target.heal(amount)
			if skill.cleanse:
				target.cleanse()
			events.append({
				"type": "heal",
				"target_uid": target.uid,
				"target_name": target.display_name,
				"amount": int(round(healed)),
				"cleanse": skill.cleanse,
			})
			_append_log("%s heals %s for %d." % [actor.display_name, target.display_name, int(round(healed))])
			if _has_passive(actor, "tidecall"):
				var shield_amount := target.max_hp * PassiveEffects.TIDECALL_SHIELD
				target.shield += shield_amount
				events.append({
					"type": "shield",
					"target_uid": target.uid,
					"target_name": target.display_name,
					"amount": int(round(shield_amount)),
					"source": "tidecall",
				})
				_append_log("%s's tide shields %s for %d." % [
					actor.display_name, target.display_name, int(round(shield_amount))
				])
			if _has_passive(actor, "dawnkeeper") and not bool(_dawnkeeper_used.get(actor.uid, false)):
				_dawnkeeper_used[actor.uid] = true
				actor.add_energy(PassiveEffects.DAWNKEEPER_ENERGY)
				events.append({
					"type": "passive",
					"passive": "dawnkeeper",
					"actor_uid": actor.uid,
					"actor_name": actor.display_name,
					"amount": int(PassiveEffects.DAWNKEEPER_ENERGY),
				})
				_append_log("%s's dawnlight refunds %d energy." % [
					actor.display_name, int(PassiveEffects.DAWNKEEPER_ENERGY)
				])
		"shield":
			var shield_amount := target.max_hp * skill.power / 100.0
			target.shield += shield_amount
			events.append({
				"type": "shield",
				"target_uid": target.uid,
				"target_name": target.display_name,
				"amount": int(round(shield_amount)),
			})
			_append_log("%s shields %s for %d." % [actor.display_name, target.display_name, int(round(shield_amount))])
		_:
			events.append({
				"type": "status",
				"target_uid": target.uid,
				"target_name": target.display_name,
				"status": "focus",
				"turns": 0,
			})
	for status_data in skill.statuses:
		if not target.is_alive() and skill.kind == "damage":
			continue
		var chance := float(status_data.get("chance", 1.0))
		if rng.randf() < chance:
			var status_id := str(status_data.get("id", ""))
			target.apply_status(status_id, int(status_data.get("turns", 1)), float(status_data.get("potency", 0.0)))
			events.append({
				"type": "status",
				"target_uid": target.uid,
				"target_name": target.display_name,
				"status": status_id,
				"turns": int(status_data.get("turns", 1)),
			})
			_append_log("%s gains %s." % [target.display_name, status_id])
	return events


func _deal_damage(actor: Combatant, skill: SkillDef, target: Combatant) -> Array:
	var events: Array = []
	if not target.is_alive():
		return events

	# Blind can cause the attack to miss entirely.
	if actor.has_status("blind") and rng.randf() < 0.3:
		events.append({
			"type": "miss",
			"target_uid": target.uid,
			"target_name": target.display_name,
			"actor_uid": actor.uid,
		})
		_append_log("%s's attack misses." % actor.display_name)
		return events

	var element_mult := ElementTable.multiplier(skill.element, target.element)
	var attack := actor.effective_atk()
	var defense := unit_defense(target)
	var raw := skill.power * (attack / (attack + defense)) * DAMAGE_SCALE
	raw *= element_mult
	raw *= outgoing_multiplier(actor, skill.element, target)
	raw *= rng.randf_range(0.95, 1.05)

	var crit := false
	var crit_chance := clampf(actor.crit_chance + skill.crit_bonus, 0.0, 1.0)
	if rng.randf() < crit_chance:
		crit = true
		raw *= CRIT_MULTIPLIER

	# Defensive passives are applied after crit so their mitigation is readable
	# in one place.
	var damage := maxf(1.0, roundf(raw * incoming_multiplier(target)))
	var result := target.take_damage(damage)
	target.add_energy(8.0)
	actor.add_energy(6.0)

	events.append({
		"type": "damage",
		"actor_uid": actor.uid,
		"target_uid": target.uid,
		"target_name": target.display_name,
		"amount": int(round(result.damage)),
		"absorbed": int(round(result.absorbed)),
		"crit": crit,
		"element": skill.element,
		"skill_id": skill.id,
		"element_mult": element_mult,
		"advantage": ElementTable.label(element_mult),
	})
	_append_log("%s hits %s for %d%s." % [
		actor.display_name, target.display_name, int(round(result.damage)),
		" (crit)" if crit else ""
	])

	if crit and _has_passive(actor, "ashen_wake") and target.is_alive():
		target.apply_status(
			"burn",
			PassiveEffects.ASHEN_WAKE_BURN_TURNS,
			PassiveEffects.ASHEN_WAKE_BURN_POTENCY
		)
		events.append({
			"type": "status",
			"target_uid": target.uid,
			"target_name": target.display_name,
			"status": "burn",
			"turns": PassiveEffects.ASHEN_WAKE_BURN_TURNS,
			"source": "ashen_wake",
		})
		_append_log("%s's cinders set %s burning." % [actor.display_name, target.display_name])

	var lifesteal := skill.lifesteal
	if _has_passive(actor, "sanguine_waltz"):
		lifesteal += PassiveEffects.SANGUINE_WALTZ_LIFESTEAL
	if lifesteal > 0.0:
		var healed := actor.heal(result.damage * lifesteal)
		if healed > 0.5:
			events.append({
				"type": "heal",
				"status": "lifesteal",
				"target_uid": actor.uid,
				"target_name": actor.display_name,
				"amount": int(round(healed)),
			})

	events.append_array(_check_boss_phases(target))

	if result.dead:
		events.append({
			"type": "death",
			"target_uid": target.uid,
			"target_name": target.display_name,
		})
		_append_log("%s falls." % target.display_name)
	return events


func _check_boss_phases(unit: Combatant) -> Array:
	var events: Array = []
	if not unit.is_boss or unit.phases.is_empty() or not unit.is_alive():
		return events
	var ratio := unit.hp_ratio()
	for phase_index in unit.phases.size():
		if unit.triggered_phases.has(phase_index):
			continue
		var phase: Dictionary = unit.phases[phase_index]
		if ratio <= float(phase.get("hp_below", 0.0)):
			unit.triggered_phases.append(phase_index)
			var status: Dictionary = phase.get("status", {})
			if not status.is_empty():
				unit.apply_status(
					str(status.get("id", "")),
					int(status.get("turns", 99)),
					float(status.get("potency", 0.0))
				)
			var message := str(phase.get("message", "The boss changes."))
			events.append({ "type": "phase", "actor_uid": unit.uid, "message": message })
			_append_log(message)
	return events


func _check_finish() -> bool:
	if finished:
		return true
	if living(ENEMY_TEAM).is_empty():
		finished = true
		winner_team = PLAYER_TEAM
		return true
	if living(PLAYER_TEAM).is_empty():
		finished = true
		winner_team = ENEMY_TEAM
		return true
	return false


func _finish_events() -> Array:
	if not finished:
		return []
	if winner_team == PLAYER_TEAM:
		_append_log("Victory.")
		return [{ "type": "victory", "winner_team": winner_team }]
	_append_log("Defeat.")
	return [{ "type": "defeat", "winner_team": winner_team }]


func living(team: int) -> Array:
	var result: Array = []
	for unit in combatants:
		if unit.team == team and unit.is_alive():
			result.append(unit)
	return result


func living_indices(team: int) -> Array:
	var result: Array = []
	for index in combatants.size():
		var unit: Combatant = combatants[index]
		if unit.team == team and unit.is_alive():
			result.append(index)
	return result


func current_actor() -> Combatant:
	if current_actor_index < 0 or current_actor_index >= combatants.size():
		return null
	return combatants[current_actor_index]


func get_by_uid(uid_value: String) -> Combatant:
	for unit in combatants:
		if unit.uid == uid_value:
			return unit
	return null


# ------------------------------------------------------------ passive helpers

func _apply_battle_start_passives() -> void:
	for team in [PLAYER_TEAM, ENEMY_TEAM]:
		if _team_has_passive(team, "small_miracles"):
			for unit in living(team):
				unit.add_energy(PassiveEffects.SMALL_MIRACLES_ENERGY)


func _has_passive(unit: Combatant, passive_id: String) -> bool:
	return unit != null and unit.passive_id == passive_id


func _team_has_passive(team: int, passive_id: String) -> bool:
	for unit in living(team):
		if unit.passive_id == passive_id:
			return true
	return false


func _team_has_passive_excluding(team: int, passive_id: String, excluded: Combatant) -> bool:
	for unit in living(team):
		if unit != excluded and unit.passive_id == passive_id:
			return true
	return false


func _has_debuff(unit: Combatant) -> bool:
	for status in unit.statuses:
		if PassiveEffects.is_debuff(str(status.get("id", ""))):
			return true
	return false


func unit_speed(unit: Combatant) -> float:
	var speed := unit.effective_speed()
	if _team_has_passive(unit.team, "whisperstep"):
		speed *= PassiveEffects.WHISPERSTEP_SPEED
	return speed


func unit_defense(unit: Combatant) -> float:
	var defense := unit.effective_defense()
	if _has_passive(unit, "deep_roots"):
		defense *= PassiveEffects.DEEP_ROOTS_DEFENSE
	return defense


## Damage multiplier from the attacker's passives and equipment resonance.
func outgoing_multiplier(actor: Combatant, skill_element: String, target: Combatant) -> float:
	var multiplier := 1.0
	if _has_passive(actor, "nothing_to_lose") and actor.hp_ratio() < PassiveEffects.NOTHING_TO_LOSE_THRESHOLD:
		multiplier *= PassiveEffects.NOTHING_TO_LOSE_DAMAGE
	if _has_passive(actor, "hollow_crown") and skill_element == "dark" and _has_debuff(target):
		multiplier *= PassiveEffects.HOLLOW_CROWN_DAMAGE
	if _has_passive(actor, "patient_weaver") and target.has_status("stun"):
		multiplier *= PassiveEffects.PATIENT_WEAVER_DAMAGE
	if not actor.equipment_element.is_empty():
		if skill_element == actor.equipment_element:
			multiplier *= EQUIPMENT_RESONANCE
		if actor.equipment_element == actor.element:
			multiplier *= EQUIPMENT_ATTUNEMENT
	return multiplier


## Damage multiplier applied to incoming damage from the defender's passives.
func incoming_multiplier(target: Combatant) -> float:
	var multiplier := 1.0
	if _has_passive(target, "rooted") and target.hp_ratio() < PassiveEffects.ROOTED_THRESHOLD:
		multiplier *= PassiveEffects.ROOTED_REDUCTION
	if _team_has_passive_excluding(target.team, "hold_the_line", target):
		multiplier *= PassiveEffects.HOLD_THE_LINE_REDUCTION
	return multiplier


func _build_order() -> void:
	var alive_indices := living_indices(PLAYER_TEAM) + living_indices(ENEMY_TEAM)
	alive_indices.sort_custom(func(a, b):
		var unit_a: Combatant = combatants[a]
		var unit_b: Combatant = combatants[b]
		var speed_a := unit_speed(unit_a)
		var speed_b := unit_speed(unit_b)
		if is_equal_approx(speed_a, speed_b):
			return a < b
		return speed_a > speed_b
	)
	order = alive_indices


func upcoming_turns(count: int = 6) -> Array:
	var result: Array = []
	var preview_order := order.duplicate()
	var pointer := turn_pointer
	var safety := 0
	while result.size() < count and safety < count * 3 + 6:
		safety += 1
		pointer += 1
		if pointer >= preview_order.size():
			preview_order = living_indices(PLAYER_TEAM) + living_indices(ENEMY_TEAM)
			preview_order.sort_custom(func(a, b):
				return unit_speed(combatants[a]) > unit_speed(combatants[b])
			)
			pointer = 0
		if preview_order.is_empty():
			break
		var unit: Combatant = combatants[int(preview_order[pointer])]
		if unit.is_alive():
			result.append({
				"uid": unit.uid,
				"name": unit.display_name,
				"team": unit.team,
				"element": unit.element,
			})
	return result


func _uids_of(units: Array) -> Array:
	var result: Array = []
	for unit in units:
		result.append(unit.uid)
	return result


func _append_log(message: String) -> void:
	log.append(message)
	if log.size() > 80:
		log.pop_front()

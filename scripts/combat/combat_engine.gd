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
var skill_resolver := CombatSkillResolver.new()

func _init() -> void:
	skill_resolver.bind(self)



func _apply_skill(actor: Combatant, skill: SkillDef, target: Combatant) -> Array:
	return skill_resolver.apply_skill(actor, skill, target)


func _deal_damage(actor: Combatant, skill: SkillDef, target: Combatant) -> Array:
	return skill_resolver.deal_damage(actor, skill, target)


func _check_boss_phases(unit: Combatant) -> Array:
	return skill_resolver.check_boss_phases(unit)


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
		combatants[index].skill_cooldowns.clear()
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
	var result := CombatTurnLifecycleResolver.begin_actor_turn(actor)
	for message in result.get("log_messages", []):
		_append_log(str(message))
	return {
		"events": result.get("events", []),
		"skipped": bool(result.get("skipped", true)),
	}

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
	if actor.is_skill_on_cooldown(skill.id):
		return events
	# Validate target availability before consuming energy or starting cooldowns.
	# Invalid/empty target rules must leave the actor's resources untouched.
	var targets := resolve_targets(actor, skill, target_indices)
	if targets.is_empty():
		return events
	if skill.ultimate:
		if not actor.ultimate_ready():
			return events
	else:
		actor.add_energy(skill.energy_gain)
	actor.start_skill_cooldown(skill.id, skill.cooldown_turns)
	if skill.ultimate:
		actor.energy = 0.0
	events.append({
		"type": "action",
		"actor_uid": actor.uid,
		"actor_name": actor.display_name,
		"actor_index": actor_index,
		"skill_id": skill.id,
		"skill_name": skill.display_name,
		"element": skill.element,
		"ultimate": skill.ultimate,
		"animation_key": skill.animation_key,
		"vfx_key": skill.vfx_key,
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
	return CombatPassiveResolver.has_passive(unit, passive_id)


func _team_has_passive(team: int, passive_id: String) -> bool:
	return CombatPassiveResolver.team_has_passive(living(team), passive_id)


func _team_has_passive_excluding(team: int, passive_id: String, excluded: Combatant) -> bool:
	return CombatPassiveResolver.team_has_passive_excluding(living(team), passive_id, excluded)


func _has_debuff(unit: Combatant) -> bool:
	return CombatPassiveResolver.has_debuff(unit)


func unit_speed(unit: Combatant) -> float:
	return CombatPassiveResolver.unit_speed(unit, living(unit.team))


func unit_defense(unit: Combatant) -> float:
	return CombatPassiveResolver.unit_defense(unit)


## Damage multiplier from the attacker's passives and equipment resonance.
func outgoing_multiplier(actor: Combatant, skill_element: String, target: Combatant) -> float:
	return CombatPassiveResolver.outgoing_multiplier(actor, skill_element, target, EQUIPMENT_RESONANCE, EQUIPMENT_ATTUNEMENT)

## Damage multiplier applied to incoming damage from the defender's passives.
func incoming_multiplier(target: Combatant) -> float:
	return CombatPassiveResolver.incoming_multiplier(target, living(target.team))

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

class_name CombatSkillResolver
extends RefCounted
## Resolves skill effects while CombatEngine retains battle-state ownership.

var _engine_ref: WeakRef
var engine: CombatEngine:
	get:
		return _engine_ref.get_ref() as CombatEngine if _engine_ref != null else null

func bind(owner: CombatEngine) -> void:
	_engine_ref = weakref(owner)

func apply_skill(actor: Combatant, skill: SkillDef, target: Combatant) -> Array:
	if engine == null:
		return []
	var events: Array = []
	match skill.kind:
		"damage":
			events.append_array(deal_damage(actor, skill, target))
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
			engine._append_log("%s heals %s for %d." % [actor.display_name, target.display_name, int(round(healed))])
			if engine._has_passive(actor, "tidecall"):
				var shield_amount := target.max_hp * PassiveEffects.TIDECALL_SHIELD
				target.shield += shield_amount
				events.append({
					"type": "shield",
					"target_uid": target.uid,
					"target_name": target.display_name,
					"amount": int(round(shield_amount)),
					"source": "tidecall",
				})
				engine._append_log("%s's tide shields %s for %d." % [
					actor.display_name, target.display_name, int(round(shield_amount))
				])
			if engine._has_passive(actor, "dawnkeeper") and not bool(engine._dawnkeeper_used.get(actor.uid, false)):
				engine._dawnkeeper_used[actor.uid] = true
				actor.add_energy(PassiveEffects.DAWNKEEPER_ENERGY)
				events.append({
					"type": "passive",
					"passive": "dawnkeeper",
					"actor_uid": actor.uid,
					"actor_name": actor.display_name,
					"amount": int(PassiveEffects.DAWNKEEPER_ENERGY),
				})
				engine._append_log("%s's dawnlight refunds %d energy." % [
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
			engine._append_log("%s shields %s for %d." % [actor.display_name, target.display_name, int(round(shield_amount))])
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
		if engine.rng.randf() < chance:
			var status_id := str(status_data.get("id", ""))
			target.apply_status(status_id, int(status_data.get("turns", 1)), float(status_data.get("potency", 0.0)))
			events.append({
				"type": "status",
				"target_uid": target.uid,
				"target_name": target.display_name,
				"status": status_id,
				"turns": int(status_data.get("turns", 1)),
			})
			engine._append_log("%s gains %s." % [target.display_name, status_id])
	return events



static func effective_scaling_value(actor: Combatant, scaling_stat: String) -> float:
	if actor == null:
		return 1.0
	match scaling_stat:
		"def":
			return actor.effective_defense()
		"hp":
			return maxf(1.0, actor.max_hp)
		"spd":
			return actor.effective_speed()
		_:
			return actor.effective_atk()


func deal_damage(actor: Combatant, skill: SkillDef, target: Combatant) -> Array:
	if engine == null:
		return []
	var events: Array = []
	if not target.is_alive():
		return events

	# Blind can cause the attack to miss entirely.
	if actor.has_status("blind") and engine.rng.randf() < 0.3:
		events.append({
			"type": "miss",
			"target_uid": target.uid,
			"target_name": target.display_name,
			"actor_uid": actor.uid,
		})
		engine._append_log("%s's attack misses." % actor.display_name)
		return events

	var element_mult := ElementTable.multiplier(skill.element, target.element)
	var scaling_value := effective_scaling_value(actor, skill.scaling_stat)
	var defense: float = float(engine.unit_defense(target))
	var raw: float = skill.power * (scaling_value / (scaling_value + defense)) * engine.DAMAGE_SCALE
	raw *= element_mult
	raw *= engine.outgoing_multiplier(actor, skill.element, target)
	raw *= engine.rng.randf_range(0.95, 1.05)

	var crit := false
	var crit_chance := clampf(actor.crit_chance + skill.crit_bonus, 0.0, 1.0)
	if engine.rng.randf() < crit_chance:
		crit = true
		raw *= engine.CRIT_MULTIPLIER

	# Defensive passives are applied after crit so their mitigation is readable
	# in one place.
	var damage := maxf(1.0, roundf(raw * engine.incoming_multiplier(target)))
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
	engine._append_log("%s hits %s for %d%s." % [
		actor.display_name, target.display_name, int(round(result.damage)),
		" (crit)" if crit else ""
	])

	if crit and engine._has_passive(actor, "ashen_wake") and target.is_alive():
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
		engine._append_log("%s's cinders set %s burning." % [actor.display_name, target.display_name])

	var lifesteal := skill.lifesteal
	if engine._has_passive(actor, "sanguine_waltz"):
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

	events.append_array(check_boss_phases(target))

	if result.dead:
		events.append({
			"type": "death",
			"target_uid": target.uid,
			"target_name": target.display_name,
		})
		engine._append_log("%s falls." % target.display_name)
	return events



func check_boss_phases(unit: Combatant) -> Array:
	if engine == null:
		return []
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
			engine._append_log(message)
	return events




class_name CombatAI
extends RefCounted
## Deterministic, readable enemy decision-making. Kept separate from the engine
## so bosses can later receive scripted phase AIs without touching combat math.

const HEAL_THRESHOLD := 0.62


static func choose(engine: CombatEngine, actor_index: int) -> Dictionary:
	var actor: Combatant = engine.combatants[actor_index]
	var enemies := engine.living(1 - actor.team)
	var allies := engine.living(actor.team)
	if enemies.is_empty():
		return { "skill_id": "", "targets": [] }

	var best: Dictionary = { "skill_id": "", "targets": [], "score": -INF }
	var lowest_ally := _lowest_health(allies)
	var lowest_enemy := _lowest_health(enemies)

	var candidates: Array = actor.skills.duplicate()
	if actor.ultimate_ready() and not actor.ultimate.is_empty():
		candidates.append(actor.ultimate)

	for skill_id in candidates:
		var skill: SkillDef = ContentDB.get_skill(skill_id)
		if skill == null:
			continue
		if skill.ultimate and not actor.ultimate_ready():
			continue
		var option := _evaluate(engine, actor, skill, enemies, allies, lowest_ally, lowest_enemy)
		if float(option.score) > float(best.score):
			best = option
	return best


static func _evaluate(
	engine: CombatEngine,
	actor: Combatant,
	skill: SkillDef,
	enemies: Array,
	allies: Array,
	lowest_ally: Combatant,
	lowest_enemy: Combatant
) -> Dictionary:
	var score := 0.0
	var targets: Array = []

	if skill.kind == "heal" or skill.kind == "shield":
		var missing := 1.0 - (lowest_ally.hp_ratio() if lowest_ally != null else 1.0)
		score = 40.0 + missing * 300.0
		if lowest_ally != null and lowest_ally.hp_ratio() < HEAL_THRESHOLD:
			score += 500.0
		if skill.target == "all_allies":
			for ally in allies:
				score += (1.0 - ally.hp_ratio()) * 60.0
			targets = _indices_of(allies)
		else:
			targets = [lowest_ally.combat_index] if lowest_ally != null else []
		if skill.ultimate:
			score += 200.0
	elif skill.kind == "buff":
		score = 60.0
		for status_data in skill.statuses:
			var status_id := str(status_data.get("id", ""))
			if actor.has_status(status_id):
				score -= 45.0
		if skill.target == "all_allies":
			targets = _indices_of(allies)
		else:
			targets = [actor.combat_index]
		if skill.ultimate:
			score += 200.0
	else:
		var target: Combatant = lowest_enemy
		if skill.target == "all_enemies":
			targets = _indices_of(enemies)
			for enemy in enemies:
				score += _damage_score(engine, actor, skill, enemy)
			score = score / maxf(1.0, float(enemies.size())) + float(enemies.size()) * 18.0
		else:
			if target != null:
				targets = [target.combat_index]
				score = _damage_score(engine, actor, skill, target)
		if skill.ultimate:
			score += 400.0

	return { "skill_id": skill.id, "targets": targets, "score": score }


static func _damage_score(engine: CombatEngine, actor: Combatant, skill: SkillDef, target: Combatant) -> float:
	if target == null:
		return 0.0
	var element := ElementTable.multiplier(skill.element, target.element)
	var attack := actor.effective_atk()
	var defense := engine.unit_defense(target)
	var estimate := skill.power * (attack / (attack + defense)) * element
	estimate *= 1.0 + (1.0 - target.hp_ratio()) * 0.3
	# Prefer finishing blows.
	if estimate >= target.hp:
		estimate += 120.0
	return estimate


static func _lowest_health(units: Array) -> Combatant:
	var best: Combatant = null
	for unit in units:
		if best == null or unit.hp_ratio() < best.hp_ratio():
			best = unit
	return best


static func _indices_of(units: Array) -> Array:
	var result: Array = []
	for unit in units:
		result.append(unit.combat_index)
	return result

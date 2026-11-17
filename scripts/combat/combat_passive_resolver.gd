class_name CombatPassiveResolver
extends RefCounted
## Pure passive/equipment combat modifiers. The engine supplies the living
## team snapshot so this resolver never owns or retains a CombatEngine.

static func has_passive(unit: Combatant, passive_id: String) -> bool:
	return unit != null and unit.passive_id == passive_id


static func team_has_passive(units: Array, passive_id: String) -> bool:
	for unit in units:
		if unit != null and unit.passive_id == passive_id:
			return true
	return false


static func team_has_passive_excluding(units: Array, passive_id: String, excluded: Combatant) -> bool:
	for unit in units:
		if unit != null and unit != excluded and unit.passive_id == passive_id:
			return true
	return false


static func has_debuff(unit: Combatant) -> bool:
	if unit == null:
		return false
	for status in unit.statuses:
		if PassiveEffects.is_debuff(str(status.get("id", ""))):
			return true
	return false


static func unit_speed(unit: Combatant, allies: Array) -> float:
	var speed := unit.effective_speed()
	if team_has_passive(allies, "whisperstep"):
		speed *= PassiveEffects.WHISPERSTEP_SPEED
	return speed


static func unit_defense(unit: Combatant) -> float:
	var defense := unit.effective_defense()
	if has_passive(unit, "deep_roots"):
		defense *= PassiveEffects.DEEP_ROOTS_DEFENSE
	return defense


static func outgoing_multiplier(actor: Combatant, skill_element: String, target: Combatant, resonance: float, attunement: float) -> float:
	var multiplier := 1.0
	if has_passive(actor, "nothing_to_lose") and actor.hp_ratio() < PassiveEffects.NOTHING_TO_LOSE_THRESHOLD:
		multiplier *= PassiveEffects.NOTHING_TO_LOSE_DAMAGE
	if has_passive(actor, "hollow_crown") and skill_element == "dark" and has_debuff(target):
		multiplier *= PassiveEffects.HOLLOW_CROWN_DAMAGE
	if has_passive(actor, "patient_weaver") and target.has_status("stun"):
		multiplier *= PassiveEffects.PATIENT_WEAVER_DAMAGE
	if not actor.equipment_element.is_empty():
		if skill_element == actor.equipment_element:
			multiplier *= resonance
		if actor.equipment_element == actor.element:
			multiplier *= attunement
	return multiplier


static func incoming_multiplier(target: Combatant, allies: Array) -> float:
	var multiplier := 1.0
	if has_passive(target, "rooted") and target.hp_ratio() < PassiveEffects.ROOTED_THRESHOLD:
		multiplier *= PassiveEffects.ROOTED_REDUCTION
	if team_has_passive_excluding(allies, "hold_the_line", target):
		multiplier *= PassiveEffects.HOLD_THE_LINE_REDUCTION
	return multiplier

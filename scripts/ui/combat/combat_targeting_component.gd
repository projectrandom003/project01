class_name CombatTargetingComponent
extends Node
## Owns skill selection and valid combat-target selection for a battle screen.

var screen: CombatScreen
var pending_skill: SkillDef
var target_team: int = -1
var targeting: bool = false


func bind(owner_screen: CombatScreen) -> void:
	screen = owner_screen


func reset() -> void:
	pending_skill = null
	target_team = -1
	targeting = false


func is_targeting() -> bool:
	return targeting


func select_skill(skill: SkillDef) -> void:
	if screen == null or screen._resolved or screen.engine == null:
		return
	var actor: Combatant = screen.engine.current_actor()
	if actor == null or actor.team != CombatEngine.PLAYER_TEAM:
		return
	if skill.ultimate and not actor.ultimate_ready():
		return
	if skill.target == "single_enemy" or skill.target == "single_ally":
		pending_skill = skill
		targeting = true
		target_team = CombatEngine.ENEMY_TEAM if skill.target == "single_enemy" else CombatEngine.PLAYER_TEAM
		screen._hint_label.text = "Tap a gold-ringed foe to target · Esc cancels" if target_team == CombatEngine.ENEMY_TEAM else "Choose an ally in the party list · Esc cancels"
		if screen._battlefield != null:
			screen._battlefield.set_target_team(target_team, true)
		screen._refresh_cards()
	else:
		screen._execute_current(skill.id, [])


func on_battlefield_actor_clicked(actor: BattlefieldActor) -> void:
	if not targeting or pending_skill == null or actor == null:
		return
	if actor.unit == null or actor.unit.team != target_team or not actor.unit.is_alive():
		return
	screen._execute_current(pending_skill.id, [actor.unit.combat_index])


func on_roster_clicked(unit: Combatant) -> void:
	if not targeting or pending_skill == null or unit == null:
		return
	if unit.team != target_team or not unit.is_alive():
		return
	screen._execute_current(pending_skill.id, [unit.combat_index])


func cancel_targeting() -> void:
	pending_skill = null
	targeting = false
	if screen != null and screen._battlefield != null:
		screen._battlefield.set_target_team(target_team, false)
	target_team = -1
	if screen != null and screen._hint_label != null:
		screen._hint_label.text = ""
		screen._refresh_cards()

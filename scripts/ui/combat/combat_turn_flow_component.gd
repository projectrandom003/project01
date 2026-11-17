class_name CombatTurnFlowComponent
extends Node
## Owns delayed enemy/auto-player turn execution for a combat screen.

var screen: CombatScreen


func bind(owner_screen: CombatScreen) -> void:
	screen = owner_screen


func schedule_enemy_turn() -> void:
	if screen == null or not is_instance_valid(screen):
		return
	screen._turn_token += 1
	var token := screen._turn_token
	var actor: Combatant = screen.engine.current_actor() if screen.engine != null else null
	if actor == null or actor.team != CombatEngine.ENEMY_TEAM:
		return
	var decision := CombatAI.choose(screen.engine, screen.engine.current_actor_index)
	var skill_id := str(decision.get("skill_id", ""))
	if skill_id.is_empty():
		return
	var skill: SkillDef = ContentDB.get_skill(skill_id)
	var skill_name := skill.display_name if skill != null else "Attack"
	var telegraph_actor := screen._actor_for_uid(actor.uid)
	if telegraph_actor != null:
		telegraph_actor.set_intent(skill_name)
	if screen._battlefield != null:
		screen._battlefield.set_target_team(CombatEngine.PLAYER_TEAM, true)
	screen._hint_label.text = "%s is preparing %s — brace for impact" % [actor.display_name, skill_name]
	# Keep the already-selected action stable throughout the readable reaction window.
	await screen.get_tree().create_timer((CombatScreen.TURN_DELAY + 0.72) / screen._speed).timeout
	if not is_instance_valid(screen) or not screen.is_inside_tree() or token != screen._turn_token or screen._resolved or screen.engine == null:
		return
	if telegraph_actor != null and is_instance_valid(telegraph_actor):
		telegraph_actor.set_intent("")
	if screen._battlefield != null:
		screen._battlefield.set_target_team(-1, false)
	var current: Combatant = screen.engine.current_actor()
	if current == null or current.team != CombatEngine.ENEMY_TEAM:
		return
	screen._hint_label.text = ""
	var events := screen.engine.execute(screen.engine.current_actor_index, skill_id, decision.get("targets", []))
	await screen._process_events(events)


func schedule_auto_player() -> void:
	if screen == null or not is_instance_valid(screen):
		return
	screen._turn_token += 1
	var token := screen._turn_token
	await screen.get_tree().create_timer(CombatScreen.TURN_DELAY / screen._speed).timeout
	if not is_instance_valid(screen) or not screen.is_inside_tree() or token != screen._turn_token or screen._resolved or screen.engine == null:
		return
	var actor: Combatant = screen.engine.current_actor()
	if actor == null or actor.team != CombatEngine.PLAYER_TEAM:
		return
	var decision := CombatAI.choose(screen.engine, screen.engine.current_actor_index)
	var skill_id := str(decision.get("skill_id", ""))
	# Auto must never silently stall when a character has no evaluated action.
	if skill_id.is_empty() and not actor.skills.is_empty():
		skill_id = str(actor.skills[0])
		var fallback_skill: SkillDef = ContentDB.get_skill(skill_id)
		if fallback_skill != null and fallback_skill.target == "single_enemy":
			var first_enemy := screen.engine.living_indices(CombatEngine.ENEMY_TEAM)
			decision["targets"] = [first_enemy[0]] if not first_enemy.is_empty() else []
	if skill_id.is_empty():
		screen._log("[color=#ffbf69]Auto could not find a usable skill for %s.[/color]" % actor.display_name)
		return
	var events := screen.engine.execute(screen.engine.current_actor_index, skill_id, decision.get("targets", []))
	await screen._process_events(events)

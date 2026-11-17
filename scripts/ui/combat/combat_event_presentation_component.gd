class_name CombatEventPresentationComponent
extends Node
## Converts deterministic combat events into battle presentation and timed hit reactions.

var screen: CombatScreen


func bind(owner_screen: CombatScreen) -> void:
	screen = owner_screen

func process_events(events: Array) -> void:
	if screen._resolved:
		return
	var pending_deaths: Array[BattlefieldActor] = []
	for event in events:
		var event_type := str(event.get("type", ""))
		match event_type:
			"round":
				screen._round_label.text = "Round %d" % int(event.get("round", 1))
				screen._log("[color=#9aa8c2]— Round %d —[/color]" % int(event.get("round", 1)))
			"turn":
				screen._log("[color=#e9eef9]%s's turn.[/color]" % str(event.get("actor_name", "Unit")))
			"action":
				var actor_name := str(event.get("actor_name", "Unit"))
				var skill_name := str(event.get("skill_name", "skill"))
				screen._log("[color=#7fe3e0]%s uses %s.[/color]" % [actor_name, skill_name])
				var actor: BattlefieldActor = screen._actor_for_uid(str(event.get("actor_uid", "")))
				var target_uids: Array = event.get("target_uids", [])
				var target_uid := str(target_uids[0]) if not target_uids.is_empty() else ""
				var target: BattlefieldActor = screen._actor_for_uid(target_uid) if not target_uid.is_empty() else null
				animate_attack(actor, target, str(event.get("skill_id", "")), bool(event.get("ultimate", false)))
			"damage":
				handle_damage(event)
			"heal":
				var heal_actor: BattlefieldActor = screen._actor_for_uid(str(event.get("target_uid", "")))
				var heal_amount := int(event.get("amount", 0))
				if heal_amount > 0:
					screen._log("[color=#8fe3a0]%s recovers %d HP.[/color]" % [str(event.get("target_name", "Unit")), heal_amount])
					screen._float_text(heal_actor, "+%d" % heal_amount, UITheme.GREEN)
			"shield":
				screen._log("[color=#7fe3e0]%s gains a %d shield.[/color]" % [str(event.get("target_name", "Unit")), int(event.get("amount", 0))])
			"status":
				screen._log("[color=#b78bff]%s: %s[/color]" % [str(event.get("target_name", "Unit")), str(event.get("status", "")).replace("_", " ").capitalize()])
			"status_tick":
				screen._log("[color=#ff9f9f]%s takes %d %s damage.[/color]" % [
					str(event.get("target_name", "Unit")), int(event.get("amount", 0)), str(event.get("status", ""))
				])
				var tick_actor: BattlefieldActor = screen._actor_for_uid(str(event.get("target_uid", "")))
				if tick_actor != null:
					tick_actor.take_hit()
					screen._float_text(tick_actor, "-%d" % int(event.get("amount", 0)), UITheme.DANGER)
			"miss":
				screen._log("[color=#9aa8c2]%s misses.[/color]" % str(event.get("target_name", "Unit")))
			"skip":
				screen._log("[color=#9aa8c2]%s loses the turn (%s).[/color]" % [
					str(event.get("actor_name", "Unit")), str(event.get("reason", "stunned"))
				])
			"death":
				screen._log("[color=#ff7a8a]%s falls.[/color]" % str(event.get("target_name", "Unit")))
				var fallen: BattlefieldActor = screen._actor_for_uid(str(event.get("target_uid", "")))
				if screen._cinematic_finish_delay > 0.0:
					if fallen != null:
						pending_deaths.append(fallen)
				elif screen._battlefield != null:
					screen._battlefield.play_death(fallen)
			"phase":
				screen._log("[color=#ffc95e]%s[/color]" % str(event.get("message", "The boss changes.")))
				screen._show_banner(str(event.get("message", "PHASE CHANGE")))
				screen._camera_shake(10.0, 0.5)
				if screen._battlefield != null:
					var phase_number := 2
					if screen.engine != null:
						for combatant in screen.engine.combatants:
							if combatant.is_boss and combatant.def_id == "fallen_matron":
								phase_number = combatant.triggered_phases.size() + 1
								break
					screen._battlefield.play_matron_phase(phase_number)
			"victory":
				await screen._wait_for_cinematic_impact()
				if not screen.is_inside_tree():
					return
				screen._flush_pending_deaths(pending_deaths)
				screen._refresh_cards()
				if screen._battlefield != null:
					screen._battlefield.play_victory_animations()
				screen._finish_battle(true)
				return
			"defeat":
				await screen._wait_for_cinematic_impact()
				if not screen.is_inside_tree():
					return
				screen._flush_pending_deaths(pending_deaths)
				screen._refresh_cards()
				screen._finish_battle(false)
				return
	# Keep the party HUD / turn progression in lockstep with the Matron's
	# telegraphed pillar impact before exposing the next actor.
	await screen._wait_for_cinematic_impact()
	if not screen.is_inside_tree() or screen._resolved:
		return
	screen._flush_pending_deaths(pending_deaths)
	screen._refresh_cards()
	screen._update_turn_order()
	if screen._resolved:
		return
	var actor: Combatant = screen.engine.current_actor()
	if actor == null:
		return
	screen._refresh_skills()
	if actor.team == CombatEngine.ENEMY_TEAM:
		screen._schedule_enemy_turn()
	elif screen._auto:
		screen._schedule_auto_player()


func handle_damage(event: Dictionary) -> void:
	var actor := screen._actor_for_uid(str(event.get("target_uid", "")))
	var amount := int(event.get("amount", 0))
	var crit := bool(event.get("crit", false))
	var advantage := str(event.get("advantage", "Neutral"))
	var suffix := ""
	if crit:
		suffix += " CRIT"
	if advantage == "Advantage":
		suffix += " WEAK"
	elif advantage == "Resisted":
		suffix += " RESIST"
	screen._log("[color=#ff9f9f]%s takes %d damage%s.[/color]" % [str(event.get("target_name", "Unit")), amount, suffix])
	if actor != null:
		var element := str(event.get("element", "neutral"))
		var color := UITheme.element_color(element)
		if color == UITheme.TEXT_DIM:
			color = UITheme.DANGER
		if crit:
			color = UITheme.GOLD_BRIGHT
		elif advantage == "Advantage":
			color = UITheme.GREEN
		elif advantage == "Resisted":
			color = UITheme.TEXT_DIM
		var elem_color := UITheme.element_color(element)
		if elem_color == UITheme.TEXT_DIM:
			elem_color = Color(1.4, 0.9, 0.9, 1.0)
		# The attack choreography reaches impact after its anticipation and
		# lunge. Delay the hit reaction to that exact point; status ticks keep
		# their separate immediate reaction path.
		var impact_delay := CombatScreen.IMPACT_DELAY
		var source: Combatant = screen.engine.get_by_uid(str(event.get("actor_uid", ""))) if screen.engine != null else null
		if source != null and source.def_id == "fallen_matron" and str(event.get("skill_id", "")) == "matron_verdict":
			# The Matron's cinematic telegraph lasts ~1.84s; land the damage on
			# the vertical corruption pillars, not during the warning sigils.
			impact_delay = 1.88
			screen._cinematic_finish_delay = maxf(screen._cinematic_finish_delay, impact_delay)
		screen.get_tree().create_timer(impact_delay).timeout.connect(func() -> void:
			if not is_instance_valid(actor):
				return
			actor.take_hit()
			if screen._battlefield != null and is_instance_valid(screen._battlefield):
				screen._battlefield.spawn_elemental_burst(actor.position + Vector2(0, -18.0), element)
			if crit or amount > 50:
				screen._camera_shake(4.0 if crit else 2.0, 0.2))
		# Damage numbers share the exact same per-skill impact beat.
		screen._float_text(actor, "-%d%s" % [amount, "!" if crit else ""], color, impact_delay)


func animate_attack(attacker: BattlefieldActor, target: BattlefieldActor,
		skill_id: String = "", ultimate: bool = false) -> void:
	if screen._battlefield == null or attacker == null:
		return
	var element := "neutral"
	if screen.engine != null and attacker.unit != null:
		var combat_index := attacker.unit.combat_index
		if combat_index >= 0 and combat_index < screen.engine.combatants.size():
			var source: Combatant = screen.engine.combatants[combat_index]
			element = str(source.element)
	screen._battlefield.play_attack(attacker, target, element, skill_id, ultimate)
	if attacker.unit != null and attacker.unit.def_id == "fallen_matron" and (ultimate or skill_id == "matron_verdict"):
		screen._camera_shake(8.0, 0.42)
	elif attacker.unit != null and attacker.unit.def_id == "kael" and ultimate:
		# A short anticipation tremor followed by the larger final-impact shake.
		screen._camera_shake(3.0, 0.24)
		screen.get_tree().create_timer(0.78).timeout.connect(func() -> void:
			if is_instance_valid(screen):
				screen._camera_shake(10.0, 0.52)
		)



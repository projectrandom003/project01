extends Node

func _ready() -> void:
	var checks := [
		{ "group": "corrupted_treant", "enemy": "corrupted_treant" },
		{ "group": "elder_hollow", "enemy": "elder_hollow" },
		{ "group": "fallen_matron_encounter", "enemy": "fallen_matron" }
	]
	var failures: Array[String] = []
	for check in checks:
		var units: Array = CombatFactory.enemy_units(str(check.group))
		if units.is_empty():
			failures.append("No enemy units were built for %s." % str(check.group))
			continue
		var found := false
		for unit in units:
			if unit.def_id != str(check.enemy):
				continue
			found = true
			if not unit.is_boss:
				failures.append("%s is not flagged as a boss/elite." % str(check.enemy))
			var actor := BattlefieldActor.new()
			add_child(actor)
			actor.setup(unit, false)
			await get_tree().process_frame
			if actor.visual == null or actor.visual.def_id != str(check.enemy):
				failures.append("%s did not reach its custom battlefield visual." % str(check.enemy))
			if str(check.enemy) == "fallen_matron":
				if actor._matron_art == null:
					failures.append("Fallen Matron original cutout was not loaded.")
				else:
					actor.unit.hp = actor.unit.max_hp * 0.65
					actor.refresh()
					if actor._matron_phase != 2 or actor._matron_art.texture.resource_path != "res://assets/enemies/fallen_matron/phase_2.png":
						failures.append("Fallen Matron did not switch to her phase 2 cutout at 66% HP.")
					actor.unit.hp = actor.unit.max_hp * 0.32
					actor.refresh()
					if actor._matron_phase != 3 or actor._matron_art.texture.resource_path != "res://assets/enemies/fallen_matron/phase_3.png":
						failures.append("Fallen Matron did not switch to her phase 3 cutout at 33% HP.")
					actor.take_hit()
					actor.play_attack()
			actor.queue_free()
			await get_tree().process_frame
		if not found:
			failures.append("Expected enemy %s missing from %s." % [str(check.enemy), str(check.group)])
	await _verify_matron_cinematic(failures)
	if failures.is_empty():
		print("[boss-actors] OK — boss visuals, Matron phases and Verdict cinematic all verified.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("[boss-actors] " + failure)
		get_tree().quit(1)


func _verify_matron_cinematic(failures: Array[String]) -> void:
	var party := CombatFactory.player_units()
	var enemies := CombatFactory.enemy_units("fallen_matron_encounter")
	if party.is_empty() or enemies.is_empty():
		failures.append("Matron cinematic test could not build both battle teams.")
		return
	var stage := Battlefield.new()
	stage.arena_id = "fallen_matron_encounter"
	stage.size = Vector2(1280, 520)
	add_child(stage)
	await get_tree().process_frame
	stage.setup(party, enemies)
	await get_tree().process_frame
	var boss_actor := stage.actor_for_uid(enemies[0].uid)
	var target_actor := stage.actor_for_uid(party[0].uid)
	if boss_actor == null or target_actor == null:
		failures.append("Matron cinematic actors were not registered on the battlefield.")
		stage.queue_free()
		return
	var impacts: Array = []
	stage.cinematic_impact.connect(func(intensity: float, duration: float) -> void:
		impacts.append({"intensity": intensity, "duration": duration}))
	stage.play_attack(boss_actor, target_actor, "dark", "matron_verdict", true)
	await get_tree().create_timer(1.92).timeout
	if impacts.is_empty():
		failures.append("Matron Verdict did not emit its synchronized cinematic impact.")
	var pillar_found := false
	for child in stage.get_children():
		if child.name == "MatronVerdictColumn":
			pillar_found = true
	if not pillar_found:
		failures.append("Matron Verdict did not create its impact pillars at the damage beat.")
	await get_tree().create_timer(0.85).timeout
	for child in stage.get_children():
		if child.name in ["MatronVerdictVeil", "MatronVerdictTitle", "MatronVerdictColumn"]:
			failures.append("Matron Verdict left temporary cinematic node behind: " + str(child.name))
	stage.queue_free()
	await get_tree().process_frame

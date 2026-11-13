extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen := CombatScreen.new()
	screen.group_id = "fallen_matron_encounter"
	add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	if screen.engine == null or screen._turn_box == null:
		push_error("[turn-timeline] Combat screen did not initialize.")
		get_tree().quit(1)
		return
	var portraits := _portrait_nodes(screen)
	var living_count := screen.engine.living(CombatEngine.PLAYER_TEAM).size() + screen.engine.living(CombatEngine.ENEMY_TEAM).size()
	if portraits.size() != living_count:
		push_error("[turn-timeline] Expected one portrait per living combatant; got %d for %d." % [portraits.size(), living_count])
		get_tree().quit(1)
		return
	if portraits.is_empty() or str(portraits[0].tooltip_text).is_empty():
		push_error("[turn-timeline] Portraits or identity tooltips are missing.")
		get_tree().quit(1)
		return
	var first_name := str(portraits[0].tooltip_text)
	screen.engine.advance_turn()
	screen._update_turn_order()
	await get_tree().process_frame
	var next_portraits := _portrait_nodes(screen)
	if next_portraits.is_empty() or str(next_portraits[0].tooltip_text) == first_name:
		push_error("[turn-timeline] Active portrait did not advance with initiative.")
		get_tree().quit(1)
		return
	var player_unit: Combatant = null
	var boss_unit: Combatant = null
	for unit in screen.engine.combatants:
		if unit.team == CombatEngine.PLAYER_TEAM and player_unit == null:
			player_unit = unit
		if unit.is_boss:
			boss_unit = unit
	if player_unit == null or boss_unit == null:
		push_error("[turn-timeline] Could not locate a party member and boss for attack-direction test.")
		get_tree().quit(1)
		return
	var player_actor: BattlefieldActor = screen._battlefield.actor_for_uid(player_unit.uid)
	var boss_actor: BattlefieldActor = screen._battlefield.actor_for_uid(boss_unit.uid)
	var home_distance := player_actor.position.distance_to(boss_actor.position)
	screen._battlefield.play_attack(player_actor, boss_actor, "fire", "test_strike", false)
	await get_tree().create_timer(0.52).timeout
	var approach_distance := player_actor.position.distance_to(boss_actor.position)
	if approach_distance >= home_distance:
		push_error("[turn-timeline] Party attack did not visibly approach the boss target.")
		get_tree().quit(1)
		return
	if boss_actor._matron_art == null or boss_actor.visual.visible:
		push_error("[turn-timeline] Fallen Matron's original cutout did not replace the placeholder.")
		get_tree().quit(1)
		return
	if boss_actor._matron_art.texture.get_size().x < 300.0:
		push_error("[turn-timeline] Fallen Matron cutout texture is unexpectedly small.")
		get_tree().quit(1)
		return
	boss_unit.hp = boss_unit.max_hp * 0.65
	boss_actor.refresh()
	if boss_actor._matron_phase != 2 or not boss_actor._matron_art.texture.resource_path.ends_with("phase_2.png"):
		push_error("[turn-timeline] Matron did not switch to her phase-2 artwork at 70% HP.")
		get_tree().quit(1)
		return
	boss_unit.hp = boss_unit.max_hp * 0.25
	boss_actor.refresh()
	if boss_actor._matron_phase != 3 or not boss_actor._matron_art.texture.resource_path.ends_with("phase_3.png"):
		push_error("[turn-timeline] Matron did not switch to her phase-3 artwork at 30% HP.")
		get_tree().quit(1)
		return
	print("[turn-timeline] OK — dynamic turn portraits, target-reaching strikes, original Matron cutout, and all three corruption phases.")
	screen.queue_free()
	get_tree().quit(0)

func _portrait_nodes(screen: CombatScreen) -> Array:
	var result: Array = []
	for child in screen._turn_box.get_children():
		if child is PortraitView:
			result.append(child)
	return result

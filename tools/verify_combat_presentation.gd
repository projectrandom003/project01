extends Node

func _ready() -> void:
	call_deferred("_run")


func _portrait_names(screen: CombatScreen) -> Array[String]:
	var names: Array[String] = []
	for child in screen._turn_box.get_children():
		if child is PortraitView:
			names.append(child.tooltip_text)
	return names


func _has_unique_names(names: Array[String]) -> bool:
	var seen: Dictionary = {}
	for name in names:
		if seen.has(name):
			return false
		seen[name] = true
	return true


func _run() -> void:
	var screen := CombatScreen.new()
	screen.group_id = "fallen_matron_encounter"
	get_tree().root.add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var checks := 0
	var failures := 0
	if screen._auto_button != null and screen._auto_button.is_inside_tree():
		checks += 1
		print("[combat-ui] PASS Auto control is visible before selecting a skill")
	else:
		failures += 1
		push_error("[combat-ui] FAIL Auto control missing")
	# Align the chosen test actor with the engine's actual initiative pointer.
	var test_player: Combatant = null
	for order_position in screen.engine.order.size():
		var candidate: Combatant = screen.engine.combatants[int(screen.engine.order[order_position])]
		if candidate.team == CombatEngine.PLAYER_TEAM and order_position < screen.engine.order.size() - 1:
			test_player = candidate
			screen.engine.turn_pointer = order_position
			break
	if test_player == null:
		test_player = screen.engine.living(CombatEngine.PLAYER_TEAM)[0]
		screen.engine.turn_pointer = screen.engine.order.find(test_player.combat_index)
	screen.engine.current_actor_index = test_player.combat_index
	screen._update_turn_order()
	var initial_names := _portrait_names(screen)
	if _has_unique_names(initial_names):
		checks += 1
		print("[combat-ui] PASS turn queue contains no duplicate combatant icons")
	else:
		failures += 1
		push_error("[combat-ui] FAIL duplicate combatant icon in turn queue")
	# Auto must execute a player action without manual skill selection.
	screen._auto_button.button_pressed = true
	await get_tree().create_timer(1.15).timeout
	var auto_executed := false
	for line in screen.engine.log:
		if str(line).begins_with(test_player.display_name + " uses "):
			auto_executed = true
	if auto_executed:
		checks += 1
		print("[combat-ui] PASS Auto chooses and executes a player action without manual skill selection")
	else:
		failures += 1
		push_error("[combat-ui] FAIL Auto did not execute a player action")
	# The acting portrait must now be at the back of the one-cycle queue.
	screen._update_turn_order()
	var next_names := _portrait_names(screen)
	if not next_names.is_empty() and next_names[next_names.size() - 1] == test_player.display_name:
		checks += 1
		print("[combat-ui] PASS completed actor moves to the back of the turn queue")
	else:
		failures += 1
		push_error("[combat-ui] FAIL completed actor did not move to queue tail: " + str(next_names))
	var boss: BattlefieldActor = null
	for actor in screen._battlefield.actors():
		if actor.unit != null and actor.unit.def_id == "fallen_matron":
			boss = actor
			break
	if boss != null and boss._matron_art != null and boss.get_node_or_null("MatronCorruptionMotes") != null:
		checks += 1
		print("[combat-ui] PASS Fallen Matron uses her artwork and active idle motes")
	else:
		failures += 1
		push_error("[combat-ui] FAIL Fallen Matron visual/idle animation missing")
	var matron_icon := false
	for child in screen._turn_box.get_children():
		if child is PortraitView and child.tooltip_text == "The Fallen Matron" and child.portrait_texture != null:
			matron_icon = true
	if matron_icon:
		checks += 1
		print("[combat-ui] PASS Fallen Matron initiative icon uses her portrait artwork")
	else:
		failures += 1
		push_error("[combat-ui] FAIL Fallen Matron initiative portrait missing")
	# Both result states must be authored scenes with their dynamic content bound correctly.
	screen._pending_rewards = {"gold": 12, "crystals": 3, "xp": 45, "items": {}}
	screen._show_result(true)
	var victory_overlay_ok := screen._result_layer != null and screen._result_layer.scene_file_path.ends_with("battle_result_overlay.tscn")
	if victory_overlay_ok:
		var victory_content := screen._result_layer.get_node("Center/Panel/Content")
		victory_overlay_ok = victory_content.get_node("Title").text == "VICTORY" and victory_content.get_node("RewardsRow").get_child_count() == 3 and victory_content.get_node("Actions").get_child_count() == 1
	if victory_overlay_ok:
		checks += 1
		print("[combat-ui] PASS authored victory overlay binds rewards and claim action")
	else:
		failures += 1
		push_error("[combat-ui] FAIL authored victory overlay or reward binding")
	screen._result_layer.queue_free()
	screen._result_layer = null
	await get_tree().process_frame
	screen._show_result(false)
	var defeat_overlay_ok: bool = screen._result_layer != null and str(screen._result_layer.get_node("Center/Panel/Content/Title").text) == "DEFEAT"
	if defeat_overlay_ok:
		var defeat_content := screen._result_layer.get_node("Center/Panel/Content")
		defeat_overlay_ok = defeat_content.get_node("DefeatDetails").visible and defeat_content.get_node("Actions").get_child_count() == 2
	if defeat_overlay_ok:
		checks += 1
		print("[combat-ui] PASS authored defeat overlay binds retry and retreat actions")
	else:
		failures += 1
		push_error("[combat-ui] FAIL authored defeat overlay or action binding")
	screen._confirm_retreat()
	var retreat_overlay_ok := screen._confirm_layer != null and screen._confirm_layer.scene_file_path.ends_with("retreat_confirmation_overlay.tscn")
	if retreat_overlay_ok:
		retreat_overlay_ok = screen._confirm_layer.get_node("Center/Panel/Content/Actions").get_child_count() == 2
	if retreat_overlay_ok:
		checks += 1
		print("[combat-ui] PASS authored retreat confirmation binds stay and leave actions")
	else:
		failures += 1
		push_error("[combat-ui] FAIL authored retreat confirmation overlay")
	if screen._confirm_layer != null:
		screen._confirm_layer.queue_free()
		screen._confirm_layer = null
	print("[combat-ui] %d passed, %d failed" % [checks, failures])
	get_tree().quit(1 if failures > 0 else 0)

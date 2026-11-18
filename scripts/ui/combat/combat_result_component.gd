class_name CombatResultComponent
extends Node
## Owns victory/defeat presentation, retreat confirmation and reward claiming.

var screen: CombatScreen


func bind(owner_screen: CombatScreen) -> void:
	screen = owner_screen


func finish_battle(victory: bool) -> void:
	if screen == null or screen._resolved:
		return
	screen._resolved = true
	screen._turn_token += 1
	screen._targeting_component.reset()
	if screen._cinematic_finish_delay > 0.0:
		var finish_delay := screen._cinematic_finish_delay
		screen._cinematic_finish_delay = 0.0
		await screen.get_tree().create_timer(finish_delay).timeout
		if not is_instance_valid(screen) or not screen.is_inside_tree():
			return
	screen._refresh_cards()
	UIFactory.clear(screen._skills_box)
	screen._actor_label.text = "Victory" if victory else "Defeat"
	screen._hint_label.text = ""
	screen._pending_rewards = GameState.reward_domain.build_battle_rewards(screen.group_id, true) if victory else {}
	show_result(victory)


func show_result(victory: bool) -> void:
	if screen == null:
		return
	if screen._result_layer != null and is_instance_valid(screen._result_layer):
		screen._result_layer.queue_free()
	screen._result_layer = preload("res://scenes/ui/combat/components/battle_result_overlay.tscn").instantiate() as Control
	screen.add_child(screen._result_layer)
	var panel := screen._result_layer.get_node("Center/Panel") as PanelContainer
	screen._style_combat_panel(panel, Color("#0b1120"), 16, 24)
	var panel_style := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	panel_style.border_color = Color(UITheme.GOLD.r, UITheme.GOLD.g, UITheme.GOLD.b, 0.5) if victory else Color(UITheme.DANGER.r, UITheme.DANGER.g, UITheme.DANGER.b, 0.5)
	panel.add_theme_stylebox_override("panel", panel_style)

	var content := screen._result_layer.get_node("Center/Panel/Content") as VBoxContainer
	var title := content.get_node("Title") as Label
	title.text = "VICTORY" if victory else "DEFEAT"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT if victory else UITheme.DANGER)
	var subtitle := content.get_node("Subtitle") as Label
	subtitle.text = "The glade breathes easier." if victory else "The roots remember your name. Try again."
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", UITheme.TEXT_DIM)

	var rewards_caption := content.get_node("RewardsCaption") as Label
	var rewards_row := content.get_node("RewardsRow") as HBoxContainer
	var details := content.get_node("Details") as VBoxContainer
	var defeat_details := content.get_node("DefeatDetails") as Label
	rewards_caption.visible = victory
	rewards_row.visible = victory
	defeat_details.visible = not victory
	if victory:
		rewards_caption.add_theme_font_size_override("font_size", 10)
		rewards_caption.add_theme_color_override("font_color", UITheme.TEXT_FAINT)
		rewards_row.add_child(UIFactory.chip("+%s Gold" % UIFactory.number(int(screen._pending_rewards.get("gold", 0))), UITheme.GOLD))
		rewards_row.add_child(UIFactory.chip("+%s Crystals" % UIFactory.number(int(screen._pending_rewards.get("crystals", 0))), UITheme.TEAL))
		if int(screen._pending_rewards.get("ancient_coins", 0)) > 0:
			rewards_row.add_child(UIFactory.chip("+%s Ancient Coins" % UIFactory.number(int(screen._pending_rewards.get("ancient_coins", 0))), Color("#d9ff9f")))
		rewards_row.add_child(UIFactory.chip("+%s XP" % UIFactory.number(int(screen._pending_rewards.get("xp", 0))), UITheme.GREEN))
		for item_id in screen._pending_rewards.get("items", {}).keys():
			var item: Dictionary = ContentDB.get_item(str(item_id))
			details.add_child(UIFactory.label("• %s ×%d" % [str(item.get("name", item_id)), int(screen._pending_rewards["items"][item_id])], 12, UITheme.TEXT_DIM))
	else:
		defeat_details.add_theme_font_size_override("font_size", 12)
		defeat_details.add_theme_color_override("font_color", UITheme.TEXT_DIM)

	var actions := content.get_node("Actions") as HBoxContainer
	if victory:
		var claim_button := UIFactory.button("Claim Rewards", true)
		claim_button.custom_minimum_size = Vector2(220, 46)
		claim_button.pressed.connect(func() -> void: claim(true))
		actions.add_child(claim_button)
	else:
		var retry_button := UIFactory.button("Retry", true)
		retry_button.custom_minimum_size = Vector2(160, 46)
		retry_button.pressed.connect(retry)
		actions.add_child(retry_button)
		var retreat_button := UIFactory.button("Retreat", false, true)
		retreat_button.custom_minimum_size = Vector2(160, 46)
		retreat_button.pressed.connect(func() -> void: claim(false))
		actions.add_child(retreat_button)


func retry() -> void:
	if screen == null:
		return
	if screen._result_layer != null and is_instance_valid(screen._result_layer):
		screen._result_layer.queue_free()
		screen._result_layer = null
	screen._start_battle()


func confirm_retreat() -> void:
	if screen == null or screen._resolved or screen._confirm_layer != null:
		return
	screen._confirm_layer = preload("res://scenes/ui/combat/components/retreat_confirmation_overlay.tscn").instantiate() as Control
	screen.add_child(screen._confirm_layer)
	var panel := screen._confirm_layer.get_node("Center/Panel") as PanelContainer
	screen._style_combat_panel(panel, Color("#0b1120"), 14, 20)
	var panel_style := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	panel_style.border_color = Color(UITheme.DANGER.r, UITheme.DANGER.g, UITheme.DANGER.b, 0.5)
	panel.add_theme_stylebox_override("panel", panel_style)
	var content := screen._confirm_layer.get_node("Center/Panel/Content") as VBoxContainer
	var title := content.get_node("Title") as Label
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", UITheme.DANGER)
	var description := content.get_node("Description") as Label
	description.add_theme_font_size_override("font_size", 12)
	description.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	var stay := content.get_node("Actions/StayButton") as Button
	stay.add_theme_stylebox_override("normal", UIFactory.button_stylebox(true))
	stay.pressed.connect(func() -> void:
		screen._confirm_layer.queue_free()
		screen._confirm_layer = null
	)
	var leave := content.get_node("Actions/LeaveButton") as Button
	leave.add_theme_stylebox_override("normal", UIFactory.button_stylebox(false, true))
	leave.pressed.connect(func() -> void: claim(false))


func claim(victory: bool) -> void:
	if screen == null or screen._claimed:
		return
	screen._claimed = true
	if screen._confirm_layer != null and is_instance_valid(screen._confirm_layer):
		screen._confirm_layer.queue_free()
		screen._confirm_layer = null
	if screen._result_layer != null and is_instance_valid(screen._result_layer):
		screen._result_layer.queue_free()
		screen._result_layer = null
	if victory:
		GameState.reward_domain.apply_battle_result(screen.group_id, true, screen._pending_rewards)
	EventBus.battle_finished.emit({
		"group_id": screen.group_id,
		"victory": victory,
		"rewards": screen._pending_rewards,
	})
	screen.closed.emit()
	screen.queue_free()

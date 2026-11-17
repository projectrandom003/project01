class_name GachaSummonFlowComponent
extends Control
## Owns pull requests, summon reveal timing and the results-card presentation.

var screen: GachaScreen


func bind(owner_screen: GachaScreen) -> void:
	screen = owner_screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func pull(count: int) -> void:
	if not is_instance_valid(screen) or screen._summon_busy == false:
		return
	var result := GameState.reward_domain.pull_banner(screen._selected_banner, count)
	if not bool(result.get("ok", false)):
		EventBus.toast_requested.emit(str(result.get("error", "Summon failed.")))
		return
	var rolls: Array = result.get("results", [])
	await play_summon_reveal(rolls)
	if not is_instance_valid(screen) or not screen.is_inside_tree():
		return
	show_results(rolls)



func play_summon_reveal(results: Array) -> void:
	if screen._results_layer != null and is_instance_valid(screen._results_layer):
		screen._results_layer.queue_free()
	screen._results_layer = GachaScreen.SUMMON_REVEAL_SCENE.instantiate() as Control
	screen.add_child(screen._results_layer)
	var reveal_close := screen._results_layer.get_node_or_null("CloseSummonButton") as Button
	if reveal_close != null:
		reveal_close.pressed.connect(screen.close_screen)
	var sigil := screen._results_layer.get_node("SigilCenter/SummonSigil") as SummonSigil
	var best_rank := 0
	for roll in results:
		best_rank = maxi(best_rank, int(GachaService.RARITY_RANK.get(str(roll.get("rarity", "common")), 0)))
	if best_rank >= int(GachaService.RARITY_RANK.get("legendary", 4)):
		sigil.glow = Color("#ffd47a")
	elif best_rank >= int(GachaService.RARITY_RANK.get("epic", 2)):
		sigil.glow = Color("#c18cff")
	else:
		sigil.glow = Color("#78c9e8")
	await screen.get_tree().create_timer(2.15).timeout
	if not is_instance_valid(screen) or not screen.is_inside_tree():
		return
	if is_instance_valid(screen._results_layer):
		screen._results_layer.queue_free()
	screen._results_layer = null



func show_results(results: Array) -> void:
	screen._reveal_animations = 0
	screen._result_cards = results.size()
	if screen._results_layer != null and is_instance_valid(screen._results_layer):
		screen._results_layer.queue_free()
	screen._results_layer = GachaScreen.SUMMON_RESULTS_SCENE.instantiate() as Control
	screen.add_child(screen._results_layer)

	var panel := screen._results_layer.get_node("Center/Panel") as PanelContainer
	var viewport_width := screen.get_viewport_rect().size.x
	var panel_width := clampf(viewport_width - 48.0, 320.0, 1120.0)
	panel.custom_minimum_size = Vector2(panel_width, 0.0)
	panel.add_theme_stylebox_override(
		"panel",
		UITheme.style(Color("#0b1120"), Color(UITheme.GOLD.r, UITheme.GOLD.g, UITheme.GOLD.b, 0.45), 16, 1, 20, true)
	)
	var header_chip_slot := screen._results_layer.get_node("Center/Panel/Content/Header/BestChipSlot") as HBoxContainer
	var best_rank := -1
	for roll in results:
		best_rank = maxi(best_rank, int(GachaService.RARITY_RANK.get(str(roll.get("rarity", "common")), 0)))
	var best_name := "Common"
	for rarity in GachaService.RARITY_ORDER:
		if int(GachaService.RARITY_RANK.get(rarity, 0)) == best_rank:
			best_name = rarity.capitalize()
	header_chip_slot.add_child(UIFactory.chip("Best: " + best_name, UITheme.rarity_color(best_name.to_lower())))
	if UITheme.is_premium_rarity(best_name.to_lower()):
		var best_effect := UITheme.rarity_effect(best_name.to_lower())
		var best_glow: Color = best_effect.get("glow", UITheme.GOLD_BRIGHT)
		header_chip_slot.add_child(UIFactory.label("✦ " + UITheme.rarity_tier_label(best_name.to_lower()) + " ✦", 13, best_glow))

	var grid := screen._results_layer.get_node("Center/Panel/Content/ResultGrid") as GridContainer
	var column_limit := 5
	if panel_width < 520.0:
		column_limit = 2
	elif panel_width < 760.0:
		column_limit = 3
	elif panel_width < 960.0:
		column_limit = 4
	grid.columns = mini(column_limit, maxi(1, results.size()))
	var card_width := clampf((panel_width - 40.0 - float(grid.columns - 1) * 10.0) / float(grid.columns), 118.0, 172.0)
	for index in results.size():
		var roll: Dictionary = results[index]
		var card := GachaScreen.SUMMON_RESULT_CARD_SCENE.instantiate() as SummonResultCard
		card.custom_minimum_size = Vector2(card_width, 238.0)
		var portrait := card.get_node("Content/Portrait") as PortraitView
		portrait.custom_minimum_size = Vector2(minf(150.0, card_width - 16.0), minf(150.0, card_width - 16.0))
		card.setup(roll)
		grid.add_child(card)
		card.modulate = Color(1, 1, 1, 0)
		var is_premium := card.premium
		var tween := create_tween()
		if is_premium:
			tween.tween_interval(index * 0.09)
			tween.tween_property(card, "modulate:a", 1.0, 0.16)
			card.pivot_offset = card.custom_minimum_size * 0.5
			card.scale = Vector2(0.9, 0.9)
			tween.tween_property(card, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			screen._reveal_animations += 1
		else:
			tween.tween_interval(index * 0.055)
			tween.tween_property(card, "modulate:a", 1.0, 0.16)

	var footer := screen._results_layer.get_node("Center/Panel/Content/Footer") as HBoxContainer
	var again := footer.get_node("SummonAgainButton") as Button
	var next_count := 10 if results.size() >= 10 else 1
	var banner: Dictionary = ContentDB.get_banner(screen._selected_banner)
	var cost_data: Dictionary = banner.get("cost", {})
	var currency_id := str(cost_data.get("currency", "crystals"))
	var next_cost := int(cost_data.get("ten" if next_count == 10 else "single", 0))
	var available_currency := GameState.inventory_domain.currency(currency_id)
	again.disabled = available_currency < next_cost
	if again.disabled:
		again.tooltip_text = "Need %d more %s to summon again." % [next_cost - available_currency, ContentDB.get_item(currency_id).get("name", currency_id)]
	else:
		again.tooltip_text = "Perform another %d-pull." % next_count
	again.pressed.connect(func() -> void:
		if screen._results_layer != null:
			screen._results_layer.queue_free()
			screen._results_layer = null
		screen._pull(next_count)
	)
	var close := footer.get_node("ContinueButton") as Button
	close.pressed.connect(func() -> void:
		if screen._results_layer != null:
			screen._results_layer.queue_free()
			screen._results_layer = null
	)
	var exit_summon := footer.get_node("ExitSummonButton") as Button
	exit_summon.pressed.connect(screen.close_screen)



## Additive presentation report (Phase 5). ZERO final portraits exist; featured
## and result PortraitViews all render the procedural fallback.

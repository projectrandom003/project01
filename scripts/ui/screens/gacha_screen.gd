class_name GachaScreen
extends OverlayScreen
## Summon screen. Rates, pools, pity thresholds and costs are read verbatim from
## resources/data/banners.json. The pull itself is handled by GachaService.
##
## OFFLINE NOTE: this vertical slice rolls on the client. Phase 12 moves the RNG
## and ownership grant behind the authoritative server boundary.

var _tabs: HBoxContainer
var _main: HBoxContainer
var _selected_banner: String = ""
var _results_layer: Control

# Phase 5 presentation state. ZERO final portraits exist; featured / result
# PortraitViews here all render the procedural fallback.
var _featured_id: String = ""
var _featured_premium: bool = false
var _reveal_animations: int = 0
var _result_cards: int = 0


func _init() -> void:
	screen_title = "Summon"
	screen_subtitle = "Call a new bond into the glade"


func _build_content() -> void:
	var note := UIFactory.panel(Color("#161326"), Color(UITheme.VIOLET.r, UITheme.VIOLET.g, UITheme.VIOLET.b, 0.35), 8, 1, 8)
	note.add_child(UIFactory.wrapped(
		"Offline vertical slice: summon results, pity and ownership are generated locally. "
		+ "They are not authoritative and will move to the server in Phase 12.",
		11,
		UITheme.TEXT_DIM
	))
	content.add_child(note)

	_tabs = UIFactory.hbox(8)
	content.add_child(_tabs)

	_main = UIFactory.hbox(16)
	_main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_main)


func _refresh() -> void:
	if _tabs == null:
		return
	if _selected_banner.is_empty() or not ContentDB.banners.has(_selected_banner):
		var keys := ContentDB.banners.keys()
		_selected_banner = str(keys[0]) if not keys.is_empty() else ""
	UIFactory.clear(_tabs)
	for banner_id in ContentDB.banners.keys():
		var banner: Dictionary = ContentDB.banners[banner_id]
		var button := UIFactory.button(str(banner.get("name", banner_id)), str(banner_id) == _selected_banner)
		button.custom_minimum_size = Vector2(220, 38)
		button.pressed.connect(func() -> void: _select_banner(str(banner_id)))
		_tabs.add_child(button)
	_rebuild_main()


func _select_banner(banner_id: String) -> void:
	_selected_banner = banner_id
	_refresh()


func _rebuild_main() -> void:
	UIFactory.clear(_main)
	_featured_id = ""
	_featured_premium = false
	var banner: Dictionary = ContentDB.get_banner(_selected_banner)
	if banner.is_empty():
		_main.add_child(UIFactory.label("No summon banners are configured.", 13, UITheme.DANGER))
		return

	# ---------------------------------------------------------------- banner art
	var art_panel := UIFactory.panel(Color("#0a0f1c"), Color(UITheme.GOLD.r, UITheme.GOLD.g, UITheme.GOLD.b, 0.28), 14, 1, 16)
	art_panel.custom_minimum_size = Vector2(390, 0)
	_main.add_child(art_panel)
	var art := UIFactory.vbox(8)
	art_panel.add_child(art)

	var featured: Array = banner.get("featured", [])
	var featured_id := str(featured[0]) if not featured.is_empty() else ""
	var featured_def: CharacterDef = ContentDB.get_character(featured_id)
	var featured_rarity := featured_def.rarity if featured_def != null else "legendary"
	_featured_id = featured_id
	_featured_premium = UITheme.is_premium_rarity(featured_rarity)
	var portrait_center := CenterContainer.new()
	var portrait := PortraitView.new()
	portrait.custom_minimum_size = Vector2(260, 310)
	if featured_def != null:
		portrait.setup_character(featured_def)  # ZERO final portraits -> procedural fallback
	else:
		portrait.setup({}, "Human", "neutral", "legendary", 0)
	portrait_center.add_child(portrait)

	# Rarity-tinted backdrop panel behind the featured PortraitView. Pure UI
	# decoration from UITheme.rarity_effect; it implies NO real artwork.
	var featured_effect := UITheme.rarity_effect(featured_rarity)
	var featured_glow: Color = featured_effect.get("glow", UITheme.GOLD_BRIGHT)
	var featured_aura := clampf(float(featured_effect.get("aura", 0.0)), 0.0, 1.0)
	var portrait_backdrop := UIFactory.panel(
		Color("#0a0f1c").lerp(Color(featured_glow.r, featured_glow.g, featured_glow.b, 1.0), 0.05 + featured_aura * 0.10),
		Color(featured_glow.r, featured_glow.g, featured_glow.b, 0.30 + featured_aura * 0.35),
		14,
		1 + (1 if _featured_premium else 0),
		8
	)
	portrait_backdrop.add_child(portrait_center)
	art.add_child(portrait_backdrop)

	var banner_name := UIFactory.heading(str(banner.get("name", _selected_banner)), 24, UITheme.GOLD_BRIGHT)
	banner_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art.add_child(banner_name)
	var subtitle := UIFactory.label(str(banner.get("subtitle", "")), 12, UITheme.TEXT_DIM)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	art.add_child(subtitle)
	var chips := UIFactory.hbox(6)
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_child(UIFactory.chip(str(banner.get("type", "standard")).capitalize(), UITheme.VIOLET))
	if featured_def != null:
		chips.add_child(UIFactory.rarity_chip(featured_def.rarity))
	art.add_child(chips)
	if featured_def != null:
		var featured_label := UIFactory.label("Featured · " + featured_def.display_name, 13, UITheme.GOLD)
		featured_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		art.add_child(featured_label)

	# visual_theme line from the art-spec contract (guard null / unknown id).
	if featured_def != null:
		var art_spec := CharacterArtSpec.for_id(featured_def.id) as RefCounted
		if art_spec != null:
			var theme_text := str(art_spec.get("visual_theme"))
			if not theme_text.is_empty():
				var theme_line := UIFactory.wrapped("ART THEME · " + theme_text, 10, UITheme.TEXT_FAINT)
				theme_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				art.add_child(theme_line)

	# --------------------------------------------------------------- info column
	var info := UIFactory.vbox(10)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main.add_child(info)

	var wallet := UIFactory.hbox(8)
	wallet.add_child(UIFactory.chip("Crystals  " + UIFactory.number(GameState.currency("crystals")), UITheme.TEAL))
	wallet.add_child(UIFactory.chip("Gold  " + UIFactory.number(GameState.currency("gold")), UITheme.GOLD))
	info.add_child(wallet)

	var rates_panel := UIFactory.panel(Color("#0e1628"), UITheme.BORDER_SOFT, 10, 1, 12)
	var rates_box := UIFactory.vbox(5)
	rates_box.add_child(UIFactory.label("APPEARANCE RATES", 10, UITheme.TEXT_FAINT))
	var rates: Dictionary = banner.get("rates", {})
	for rarity in GachaService.RARITY_ORDER:
		var row := UIFactory.hbox(8)
		var color := UITheme.rarity_color(rarity)
		var dot := ColorRect.new()
		dot.color = color
		dot.custom_minimum_size = Vector2(8, 8)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(dot)
		row.add_child(UIFactory.label(rarity.capitalize(), 12, color))
		row.add_child(UIFactory.spacer())
		row.add_child(UIFactory.label(UIFactory.percent(float(rates.get(rarity, 0.0))), 12, UITheme.TEXT))
		rates_box.add_child(row)
	var guarantee := UIFactory.wrapped(
		"10-pull guarantees at least one Epic or better. Featured rate-up: %s. "
		% UIFactory.percent(float(banner.get("featured_rate", 0.5)), 0)
		+ "Hard pity: %d pulls. Featured guarantee: %d pulls." % [
			int(banner.get("hard_pity", 70)), int(banner.get("featured_pity", 140))
		],
		11,
		UITheme.TEXT_FAINT
	)
	rates_box.add_child(guarantee)
	rates_panel.add_child(rates_box)
	info.add_child(rates_panel)

	var pity: Dictionary = GameState.pity.get(_selected_banner, GachaService.empty_pity())
	var hard_pity := maxi(1, int(banner.get("hard_pity", 70)))
	var featured_pity := maxi(1, int(banner.get("featured_pity", 140)))
	var legendary_count := int(pity.get("legendary", 0))
	var featured_count := int(pity.get("featured", 0))
	var pity_panel := UIFactory.panel(Color("#0e1628"), UITheme.BORDER_SOFT, 10, 1, 12)
	var pity_box := UIFactory.vbox(6)
	pity_box.add_child(UIFactory.label("PITY PROGRESS", 10, UITheme.TEXT_FAINT))
	pity_box.add_child(_pity_row(
		"Legendary guarantee",
		legendary_count,
		hard_pity,
		"%d more pulls" % maxi(0, hard_pity - legendary_count),
		UITheme.GOLD
	))
	pity_box.add_child(_pity_row(
		"Featured guarantee",
		featured_count,
		featured_pity,
		"%d more pulls" % maxi(0, featured_pity - featured_count),
		UITheme.VIOLET
	))
	pity_panel.add_child(pity_box)
	info.add_child(pity_panel)

	info.add_child(UIFactory.spacer(true))
	var cost: Dictionary = banner.get("cost", {})
	var currency_id := str(cost.get("currency", "crystals"))
	var currency_name := str(ContentDB.get_item(currency_id).get("name", currency_id))
	var single_cost := int(cost.get("single", 0))
	var ten_cost := int(cost.get("ten", 0))
	var buttons := UIFactory.hbox(10)
	var single := UIFactory.button("Summon ×1 — %s %s" % [UIFactory.number(single_cost), currency_name])
	single.custom_minimum_size = Vector2(0, 48)
	single.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	single.disabled = GameState.currency(currency_id) < single_cost
	single.pressed.connect(func() -> void: _pull(1))
	buttons.add_child(single)
	var ten := UIFactory.button("Summon ×10 — %s %s" % [UIFactory.number(ten_cost), currency_name], true)
	ten.custom_minimum_size = Vector2(0, 48)
	ten.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ten.disabled = GameState.currency(currency_id) < ten_cost
	ten.pressed.connect(func() -> void: _pull(10))
	buttons.add_child(ten)
	info.add_child(buttons)


func _pity_row(title: String, value: int, maximum: int, caption: String, color: Color) -> VBoxContainer:
	var box := UIFactory.vbox(3)
	var header := UIFactory.hbox(8)
	header.add_child(UIFactory.label(title, 11, UITheme.TEXT_DIM))
	header.add_child(UIFactory.spacer())
	header.add_child(UIFactory.label(caption, 10, color))
	box.add_child(header)
	var bar := UIFactory.bar(color, 8)
	bar.max_value = maximum
	bar.value = clampi(value, 0, maximum)
	box.add_child(bar)
	return box


func _pull(count: int) -> void:
	var result := GameState.pull_banner(_selected_banner, count)
	if not bool(result.get("ok", false)):
		EventBus.toast_requested.emit(str(result.get("error", "Summon failed.")))
		return
	_show_results(result.get("results", []))
	_refresh()


func _show_results(results: Array) -> void:
	_reveal_animations = 0
	_result_cards = results.size()
	if _results_layer != null and is_instance_valid(_results_layer):
		_results_layer.queue_free()
	_results_layer = Control.new()
	UIFactory.set_full_rect(_results_layer)
	_results_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_results_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.05, 0.82)
	UIFactory.set_full_rect(dim)
	_results_layer.add_child(dim)

	var center := CenterContainer.new()
	UIFactory.set_full_rect(center)
	_results_layer.add_child(center)

	var panel := UIFactory.panel(Color("#0b1120"), Color(UITheme.GOLD.r, UITheme.GOLD.g, UITheme.GOLD.b, 0.45), 16, 1, 20, true)
	panel.custom_minimum_size = Vector2(minf(1120, 1180), 0)
	center.add_child(panel)
	var box := UIFactory.vbox(12)
	panel.add_child(box)

	var header := UIFactory.hbox(10)
	header.add_child(UIFactory.heading("Summon Results", 24, UITheme.GOLD_BRIGHT))
	header.add_child(UIFactory.spacer())
	var best_rank := -1
	for roll in results:
		best_rank = maxi(best_rank, int(GachaService.RARITY_RANK.get(str(roll.get("rarity", "common")), 0)))
	var best_name := "Common"
	for rarity in GachaService.RARITY_ORDER:
		if int(GachaService.RARITY_RANK.get(rarity, 0)) == best_rank:
			best_name = rarity.capitalize()
	header.add_child(UIFactory.chip("Best: " + best_name, UITheme.rarity_color(best_name.to_lower())))
	# Premium "Best:" flourish when the top rarity is legendary / mythic.
	if UITheme.is_premium_rarity(best_name.to_lower()):
		var best_effect := UITheme.rarity_effect(best_name.to_lower())
		var best_glow: Color = best_effect.get("glow", UITheme.GOLD_BRIGHT)
		var best_flourish := UIFactory.label("✦ " + UITheme.rarity_tier_label(best_name.to_lower()) + " ✦", 13, best_glow)
		header.add_child(best_flourish)
	box.add_child(header)
	box.add_child(UIFactory.separator())

	var grid := UIFactory.grid(mini(5, maxi(1, results.size())), 10)
	box.add_child(grid)
	for index in results.size():
		var roll: Dictionary = results[index]
		var card := _result_card(roll)
		grid.add_child(card)
		card.modulate = Color(1, 1, 1, 0)
		var is_premium := bool(card.get_meta("premium", false))
		var tween := create_tween()
		if is_premium:
			# Longer stagger + a subtle scale pop for legendary / mythic reveals.
			tween.tween_interval(index * 0.09)
			tween.tween_property(card, "modulate:a", 1.0, 0.16)
			card.pivot_offset = card.custom_minimum_size * 0.5
			card.scale = Vector2(0.9, 0.9)
			tween.tween_property(card, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_reveal_animations += 1
		else:
			# Existing staggered fade-in, unchanged.
			tween.tween_interval(index * 0.055)
			tween.tween_property(card, "modulate:a", 1.0, 0.16)

	var footer := UIFactory.hbox(10)
	footer.add_child(UIFactory.wrapped(
		"Duplicates raise Awakening. This result is already saved locally.",
		11,
		UITheme.TEXT_FAINT
	))
	footer.add_child(UIFactory.spacer())
	var again := UIFactory.button("Summon Again", false)
	again.pressed.connect(func() -> void:
		if _results_layer != null:
			_results_layer.queue_free()
			_results_layer = null
		_pull(10 if results.size() >= 10 else 1)
	)
	footer.add_child(again)
	var close := UIFactory.button("Continue", true)
	close.custom_minimum_size = Vector2(140, 40)
	close.pressed.connect(func() -> void:
		if _results_layer != null:
			_results_layer.queue_free()
			_results_layer = null
	)
	footer.add_child(close)
	box.add_child(footer)


func _result_card(roll: Dictionary) -> PanelContainer:
	var character_id := str(roll.get("character_id", ""))
	var definition: CharacterDef = ContentDB.get_character(character_id)
	var rarity := str(roll.get("rarity", "common"))
	var color := UITheme.rarity_color(rarity)
	var premium := UITheme.is_premium_rarity(rarity)
	var effect := UITheme.rarity_effect(rarity)
	var glow: Color = effect.get("glow", UITheme.GOLD_BRIGHT)
	# Premium cards get a wider, glow-tinted border + brighter background.
	var card_bg := Color("#0d1526")
	var card_border := color
	var card_width := 2
	if premium:
		card_bg = Color("#0d1526").lerp(Color(glow.r, glow.g, glow.b, 1.0), 0.10)
		card_border = Color(glow.r, glow.g, glow.b, 0.95)
		card_width = int(effect.get("border_width", 3))
	var card := UIFactory.panel(card_bg, card_border, 10, card_width, 8)
	card.set_meta("premium", premium)
	card.custom_minimum_size = Vector2(172, 238)
	var box := UIFactory.vbox(4)
	card.add_child(box)
	var portrait := PortraitView.new()
	portrait.custom_minimum_size = Vector2(150, 150)
	if definition != null:
		portrait.setup_character(definition)
	else:
		portrait.setup({}, "Human", "neutral", rarity, 0)
	box.add_child(portrait)
	var name_label := UIFactory.label(definition.display_name if definition != null else character_id, 13, UITheme.TEXT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(name_label)
	var rarity_label := UIFactory.label(rarity.capitalize(), 10, color)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(rarity_label)
	# Premium tier flourish label ("LEGENDARY" / "MYTHIC").
	if premium:
		var tier_label := UIFactory.label("✦ " + UITheme.rarity_tier_label(rarity) + " ✦", 9, glow)
		tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(tier_label)
	if bool(roll.get("featured", false)):
		var featured_label := UIFactory.label("FEATURED", 9, UITheme.GOLD)
		featured_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(featured_label)
	elif bool(roll.get("is_new", false)):
		var new_label := UIFactory.label("NEW", 9, UITheme.GREEN)
		new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(new_label)
	elif int(roll.get("awakening_gain", 0)) > 0:
		var dupe_label := UIFactory.label("AWAKENING +1", 9, UITheme.TEAL)
		dupe_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(dupe_label)
	elif bool(roll.get("guaranteed", false)):
		var guaranteed_label := UIFactory.label("GUARANTEED", 9, UITheme.VIOLET)
		guaranteed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(guaranteed_label)
	return card


## Additive presentation report (Phase 5). ZERO final portraits exist; featured
## and result PortraitViews all render the procedural fallback.
func presentation_report() -> Dictionary:
	return {
		"screen": "summon",
		"featured_id": _featured_id,
		"featured_premium": _featured_premium,
		"rarity_effects_enabled": true,
		"reveal_animations": _reveal_animations,
		"result_cards": _result_cards,
	}

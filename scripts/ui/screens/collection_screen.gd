class_name CollectionScreen
extends OverlayScreen
## Roster, party management, ascension and character detail.

var _grid: GridContainer
var _detail: VBoxContainer
var _cards: Dictionary = {}
var _selected_uid: String = ""
var _filter: String = "all"
var _ascend_armed: bool = false
var _ascend_armed_uid: String = ""

# Phase 5 presentation counters. ZERO final portraits exist; every PortraitView
# here still renders the procedural fallback. These track the additive rarity
# / art-spec presentation only.
var _premium_count: int = 0
var _visual_theme_lines: int = 0


func _init() -> void:
	screen_title = "Roster"
	screen_subtitle = "Every bond you have made in Aetheria"


func _build_content() -> void:
	var split := UIFactory.hbox(14)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(split)

	var left := UIFactory.vbox(10)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.custom_minimum_size = Vector2(560, 0)
	split.add_child(left)

	var filters := UIFactory.hbox(8)
	var all_button := UIFactory.small_button("All characters")
	all_button.pressed.connect(func() -> void: _set_filter("all"))
	filters.add_child(all_button)
	var party_button := UIFactory.small_button("Party only")
	party_button.pressed.connect(func() -> void: _set_filter("party"))
	filters.add_child(party_button)
	filters.add_child(UIFactory.spacer())
	filters.add_child(UIFactory.label("Click a character to inspect", 11, UITheme.TEXT_FAINT))
	left.add_child(filters)

	var scroll := UIFactory.scroll()
	left.add_child(scroll)
	_grid = UIFactory.grid(4, 10)
	scroll.add_child(_grid)

	var detail_panel := UIFactory.panel(Color("#0a101d"), UITheme.BORDER_SOFT, 12, 1, 12)
	detail_panel.custom_minimum_size = Vector2(400, 0)
	split.add_child(detail_panel)
	var detail_scroll := UIFactory.scroll()
	detail_panel.add_child(detail_scroll)
	_detail = UIFactory.vbox(10)
	detail_scroll.add_child(_detail)

	_rebuild_grid()


func _set_filter(value: String) -> void:
	_filter = value
	_rebuild_grid()


func _rebuild_grid() -> void:
	if _grid == null:
		return
	_premium_count = 0
	UIFactory.clear(_grid)
	_cards.clear()
	var instances: Array = []
	for instance in GameState.roster:
		if _filter == "party" and not GameState.party.has(instance.uid):
			continue
		instances.append(instance)
	instances.sort_custom(func(a, b) -> bool:
		var def_a: CharacterDef = ContentDB.get_character(a.char_id)
		var def_b: CharacterDef = ContentDB.get_character(b.char_id)
		var rank_a: int = int(GachaService.RARITY_RANK.get(def_a.rarity, 0)) if def_a != null else 0
		var rank_b: int = int(GachaService.RARITY_RANK.get(def_b.rarity, 0)) if def_b != null else 0
		if rank_a == rank_b:
			return a.char_id < b.char_id
		return rank_a > rank_b
	)
	if instances.is_empty():
		_grid.add_child(UIFactory.label("No characters match this filter.", 13, UITheme.TEXT_DIM))
		_show_detail("")
		return
	if _selected_uid.is_empty() or not _has_uid(instances, _selected_uid):
		_selected_uid = instances[0].uid
	for instance in instances:
		_grid.add_child(_make_card(instance))
	_show_detail(_selected_uid)


func _has_uid(instances: Array, uid: String) -> bool:
	for instance in instances:
		if instance.uid == uid:
			return true
	return false


func _make_card(instance: CharacterInstance) -> PanelContainer:
	var definition: CharacterDef = ContentDB.get_character(instance.char_id)
	var effect := UITheme.rarity_effect(definition.rarity) if definition != null else UITheme.rarity_effect("common")
	var premium := UITheme.is_premium_rarity(definition.rarity) if definition != null else false
	var glow: Color = effect.get("glow", UITheme.GOLD_BRIGHT)
	# Premium cards get a wider border + a brighter, glow-tinted background.
	var card_bg := Color("#111a2d")
	var card_border := UITheme.BORDER_SOFT
	var card_width := 1
	if premium:
		card_bg = Color("#16203a")
		card_border = Color(glow.r, glow.g, glow.b, 0.55)
		card_width = int(effect.get("border_width", 3))
	var card := UIFactory.panel(card_bg, card_border, 10, card_width, 8)
	card.custom_minimum_size = Vector2(126, 174)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.set_meta("premium", premium)
	card.set_meta("rarity", definition.rarity if definition != null else "common")
	if premium:
		_premium_count += 1
	var box := UIFactory.vbox(4)
	card.add_child(box)

	var portrait := PortraitView.new()
	portrait.custom_minimum_size = Vector2(108, 108)
	portrait.setup_character(definition)  # ZERO final portraits -> procedural fallback
	box.add_child(portrait)

	var name_label := UIFactory.label(definition.display_name if definition != null else instance.char_id, 12, UITheme.TEXT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(name_label)

	var subtitle := "Lv %d · %s" % [instance.level, definition.rarity.capitalize() if definition != null else "?"]
	var sub_label := UIFactory.label(subtitle, 10, UITheme.TEXT_DIM)
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub_label)

	# Small premium tier label ("LEGENDARY" / "MYTHIC").
	if premium:
		var tier_text := UITheme.rarity_tier_label(definition.rarity)
		if not tier_text.is_empty():
			var tier_label := UIFactory.label("✦ " + tier_text, 9, glow)
			tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			box.add_child(tier_label)

	if GameState.party.has(instance.uid):
		var badge := UIFactory.label("IN PARTY", 9, UITheme.GOLD)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(badge)

	var uid := instance.uid
	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_select(uid)
	)
	card.mouse_entered.connect(func() -> void:
		if _selected_uid != uid:
			card.add_theme_stylebox_override("panel", UITheme.style(Color("#17233c"), UITheme.GOLD, 10, 1, 8))
	)
	card.mouse_exited.connect(func() -> void: _style_card(card, uid))
	_cards[uid] = card
	_style_card(card, uid)
	return card


func _style_card(card: PanelContainer, uid: String) -> void:
	var instance := _find_instance(uid)
	if instance == null:
		return
	var definition: CharacterDef = ContentDB.get_character(instance.char_id)
	var border := UITheme.rarity_color(definition.rarity) if definition != null else UITheme.BORDER_SOFT
	if uid != _selected_uid:
		border = Color(border.r, border.g, border.b, 0.35)
	var width := 2 if uid == _selected_uid else 1
	var bg := Color("#111a2d") if uid != _selected_uid else Color("#1a2947")
	# Extend (do not replace) the resting style for premium rarities: a wider,
	# glow-tinted border and brighter background. Non-premium remains identical.
	if definition != null and UITheme.is_premium_rarity(definition.rarity):
		var effect := UITheme.rarity_effect(definition.rarity)
		var glow: Color = effect.get("glow", UITheme.GOLD_BRIGHT)
		width = int(effect.get("border_width", 3))
		bg = Color("#1a2947") if uid == _selected_uid else Color("#16203a")
		border = border.lerp(Color(glow.r, glow.g, glow.b, border.a), 0.40)
	card.add_theme_stylebox_override("panel", UITheme.style(
		bg,
		border,
		10,
		width,
		8
	))


func _select(uid: String) -> void:
	_selected_uid = uid
	for card_uid in _cards.keys():
		_style_card(_cards[card_uid], str(card_uid))
	_show_detail(uid)


func _show_detail(uid: String) -> void:
	UIFactory.clear(_detail)
	_visual_theme_lines = 0
	var instance := _find_instance(uid)
	if instance == null:
		_ascend_armed_uid = ""
		_ascend_armed = false
		_detail.add_child(UIFactory.label("No character selected.", 13, UITheme.TEXT_DIM))
		return
	var definition: CharacterDef = ContentDB.get_character(instance.char_id)
	if definition == null:
		_detail.add_child(UIFactory.label("Missing character definition.", 13, UITheme.DANGER))
		return
	_ascend_armed = (_ascend_armed_uid == instance.uid)

	var portrait_center := CenterContainer.new()
	var portrait := PortraitView.new()
	# Premium rarities get a larger detail portrait.
	if UITheme.is_premium_rarity(definition.rarity):
		portrait.custom_minimum_size = Vector2(196, 232)
	else:
		portrait.custom_minimum_size = Vector2(168, 196)
	portrait.setup_character(definition)  # ZERO final portraits -> procedural fallback
	portrait_center.add_child(portrait)
	_detail.add_child(portrait_center)

	var name_label := UIFactory.heading(definition.display_name, 23, UITheme.TEXT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail.add_child(name_label)
	var title_label := UIFactory.label(definition.title, 12, UITheme.GOLD)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail.add_child(title_label)

	# Premium rarity flourish near the heading.
	if UITheme.is_premium_rarity(definition.rarity):
		var flourish_effect := UITheme.rarity_effect(definition.rarity)
		var flourish_glow: Color = flourish_effect.get("glow", UITheme.GOLD_BRIGHT)
		var flourish := UIFactory.label("✦  " + UITheme.rarity_tier_label(definition.rarity) + "  ✦", 12, flourish_glow)
		flourish.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_detail.add_child(flourish)

	# Short labelled visual_theme line from the art-spec contract (guard null).
	var art_spec := CharacterArtSpec.for_id(definition.id) as RefCounted
	if art_spec != null:
		var theme_text := str(art_spec.get("visual_theme"))
		if not theme_text.is_empty():
			var theme_line := UIFactory.wrapped("ART THEME · " + theme_text, 10, UITheme.TEXT_FAINT)
			theme_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_detail.add_child(theme_line)
			_visual_theme_lines = 1

	var chips := UIFactory.hbox(6)
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_child(UIFactory.rarity_chip(definition.rarity))
	chips.add_child(UIFactory.element_chip(definition.element))
	chips.add_child(UIFactory.chip(definition.race, UITheme.TEXT_DIM))
	chips.add_child(UIFactory.chip(definition.role, UITheme.TEAL))
	_detail.add_child(chips)
	_detail.add_child(UIFactory.separator())

	var progression := UIFactory.hbox(8)
	progression.add_child(UIFactory.chip("Lv %d / %d" % [instance.level, instance.level_cap()], UITheme.GOLD))
	progression.add_child(UIFactory.chip("Ascension %d / %d" % [instance.ascension, CharacterInstance.MAX_ASCENSION], UITheme.VIOLET))
	progression.add_child(UIFactory.chip("Awakening %d / %d" % [instance.awakening, CharacterInstance.MAX_AWAKENING], UITheme.TEAL))
	_detail.add_child(progression)

	# XP / level-up progress (P2).
	var xp_needed := GameState.xp_to_next(instance.level)
	var xp_bar := UIFactory.bar(UITheme.TEAL, 8)
	xp_bar.max_value = maxf(1.0, float(xp_needed))
	xp_bar.value = clampf(float(instance.xp), 0.0, float(xp_needed))
	_detail.add_child(xp_bar)
	_detail.add_child(UIFactory.label("XP %d / %d" % [instance.xp, xp_needed], 10, UITheme.TEXT_FAINT))

	var multiplier := instance.power_multiplier() * GameState.collection_bonus()
	var stats := UIFactory.grid(2, 4)
	stats.add_child(_stat_row("HP", int(round(definition.stat("hp") * multiplier))))
	stats.add_child(_stat_row("Attack", int(round(definition.stat("atk") * multiplier))))
	stats.add_child(_stat_row("Defense", int(round(definition.stat("def") * multiplier))))
	stats.add_child(_stat_row("Speed", int(round(definition.stat("spd") * (1.0 + 0.02 * (instance.level - 1))))))
	stats.add_child(_stat_row("Crit", "%.1f%%" % (definition.stat("crit") * 100.0)))
	stats.add_child(_stat_row("Power", int(round(_power_score(definition, multiplier)))))
	_detail.add_child(stats)

	# Equipped items (P3).
	_detail.add_child(UIFactory.label("EQUIPPED", 10, UITheme.TEXT_FAINT))
	var equip_box := UIFactory.vbox(4)
	for slot in CharacterInstance.SLOTS:
		var item_id := instance.equipped_item(slot)
		var item_name := "—"
		if not item_id.is_empty():
			var item: Dictionary = ContentDB.get_item(item_id)
			item_name = str(item.get("name", item_id))
		var row := UIFactory.hbox(6)
		row.add_child(UIFactory.label(slot.capitalize(), 11, UITheme.TEXT_DIM))
		row.add_child(UIFactory.spacer())
		row.add_child(UIFactory.label(item_name, 11, UITheme.TEXT if not item_id.is_empty() else UITheme.TEXT_FAINT))
		equip_box.add_child(row)
	_detail.add_child(equip_box)

	var skill_ids: Array = definition.skills.duplicate()
	if not definition.ultimate.is_empty():
		skill_ids.append(definition.ultimate)
	for skill_id in skill_ids:
		var skill: SkillDef = ContentDB.get_skill(str(skill_id))
		if skill == null:
			continue
		var skill_panel := UIFactory.panel(Color("#0e1628"), Color(UITheme.BORDER_SOFT.r, UITheme.BORDER_SOFT.g, UITheme.BORDER_SOFT.b, 0.8), 8, 1, 8)
		var skill_box := UIFactory.vbox(2)
		var skill_header := UIFactory.hbox(6)
		skill_header.add_child(UIFactory.label(skill.display_name, 13, UITheme.GOLD_BRIGHT if skill.ultimate else UITheme.TEXT))
		skill_header.add_child(UIFactory.chip(skill.element.capitalize(), UITheme.element_color(skill.element)))
		if skill.ultimate:
			skill_header.add_child(UIFactory.chip("Ultimate", UITheme.GOLD))
		skill_box.add_child(skill_header)
		skill_box.add_child(UIFactory.wrapped(skill.description, 11, UITheme.TEXT_DIM))
		skill_panel.add_child(skill_box)
		_detail.add_child(skill_panel)

	if not definition.passive_name.is_empty():
		var passive := UIFactory.panel(Color("#131b2c"), Color(UITheme.TEAL.r, UITheme.TEAL.g, UITheme.TEAL.b, 0.35), 8, 1, 8)
		var passive_box := UIFactory.vbox(2)
		passive_box.add_child(UIFactory.label("Passive · " + definition.passive_name, 12, UITheme.TEAL))
		passive_box.add_child(UIFactory.wrapped(definition.passive_text, 11, UITheme.TEXT_DIM))
		passive.add_child(passive_box)
		_detail.add_child(passive)

	_detail.add_child(UIFactory.rich("[i]%s[/i]" % definition.lore, 11, UITheme.TEXT_FAINT))
	_detail.add_child(UIFactory.separator())

	var actions := UIFactory.vbox(6)
	var in_party := GameState.party.has(instance.uid)
	var party_button := UIFactory.button("Remove from Party" if in_party else "Add to Party", not in_party)
	if not in_party and GameState.party.size() >= GameState.PARTY_MAX:
		party_button.disabled = true
		party_button.tooltip_text = "Party is full."
	if in_party and GameState.party.size() <= 1:
		party_button.disabled = true
		party_button.tooltip_text = "You must keep at least one character in the party."
	party_button.pressed.connect(func() -> void: _toggle_party(instance.uid))
	actions.add_child(party_button)

	var ascension := GameState.ascension_info(instance.uid)
	var levelup_button := UIFactory.button("Gain 100 XP", true)
	levelup_button.pressed.connect(func() -> void:
		var result: Dictionary = GameState.add_xp_to_character(instance, 100)
		var gained := int(result.get("levels", 0))
		if gained > 0:
			EventBus.toast_requested.emit("Level up! +%d level(s)" % gained)
		else:
			EventBus.toast_requested.emit("+100 XP")
		_show_detail(instance.uid)
	)
	actions.add_child(levelup_button)

	var ascend_button := UIFactory.button("Ascend", false)
	if not bool(ascension.get("ok", false)):
		ascend_button.disabled = true
		ascend_button.tooltip_text = str(ascension.get("reason", "Cannot ascend yet."))
		ascend_button.text = "Ascend — locked"
	elif _ascend_armed and _ascend_armed_uid == instance.uid:
		ascend_button.text = "Press again to Ascend"
		ascend_button.add_theme_color_override("font_color", UITheme.DANGER)
	else:
		ascend_button.text = "Ascend — %s gold · %d dew" % [UIFactory.number(int(ascension.gold)), int(ascension.dew)]
	ascend_button.pressed.connect(func() -> void: _ascend(instance.uid))
	actions.add_child(ascend_button)
	_detail.add_child(actions)


func _stat_row(title: String, value: Variant) -> PanelContainer:
	var row := UIFactory.panel(Color("#0d1524"), Color(0, 0, 0, 0), 6, 0, 6)
	var box := UIFactory.hbox(8)
	box.add_child(UIFactory.label(title, 11, UITheme.TEXT_FAINT))
	box.add_child(UIFactory.spacer())
	box.add_child(UIFactory.label(str(value), 12, UITheme.TEXT))
	row.add_child(box)
	return row


func _power_score(definition: CharacterDef, multiplier: float) -> float:
	return (
		definition.stat("hp") * 0.20
		+ definition.stat("atk") * 3.0
		+ definition.stat("def") * 2.2
		+ definition.stat("spd") * 1.4
	) * multiplier


func _toggle_party(uid: String) -> void:
	var next: Array = GameState.party.duplicate()
	if next.has(uid):
		next.erase(uid)
	else:
		next.append(uid)
	if GameState.set_party(next):
		EventBus.toast_requested.emit("Party updated.")
	else:
		EventBus.toast_requested.emit("That party change is not valid.")
	_rebuild_grid()
	_show_detail(uid)


func _ascend(uid: String) -> void:
	if _ascend_armed_uid != uid:
		_ascend_armed_uid = uid
		_ascend_armed = true
		_show_detail(uid)
		return
	_ascend_armed_uid = ""
	_ascend_armed = false
	if GameState.ascend(uid):
		EventBus.toast_requested.emit("Ascension successful.")
		_rebuild_grid()
		_show_detail(uid)
	else:
		EventBus.toast_requested.emit("Ascension failed.")
		_show_detail(uid)


func _find_instance(uid: String) -> CharacterInstance:
	for instance in GameState.roster:
		if instance.uid == uid:
			return instance
	return null


func _refresh() -> void:
	_rebuild_grid()


## Additive presentation report (Phase 5). ZERO final portraits exist; every
## PortraitView counted here is the procedural fallback.
func presentation_report() -> Dictionary:
	return {
		"screen": "collection",
		"portrait_count": _count_portrait_views(self),
		"premium_count": _premium_count,
		"rarity_effects_enabled": true,
		"visual_theme_lines": _visual_theme_lines,
		"cards": _cards.size(),
	}


func _count_portrait_views(node: Node) -> int:
	var total := 0
	if node is PortraitView:
		total += 1
	for child in node.get_children():
		total += _count_portrait_views(child)
	return total

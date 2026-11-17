class_name CollectionDetailComponent
extends Node
## Owns the selected-character detail panel, stats, skills and progression preview.

var screen: CollectionScreen


func bind(owner_screen: CollectionScreen) -> void:
	screen = owner_screen

func show_detail(uid: String) -> void:
	UIFactory.clear(screen._detail)
	screen._visual_theme_lines = 0
	var instance := screen._find_instance(uid)
	if instance == null:
		screen._ascend_armed_uid = ""
		screen._ascend_armed = false
		screen._detail.add_child(UIFactory.label("No character selected.", 13, UITheme.TEXT_DIM))
		return
	var definition: CharacterDef = ContentDB.get_character(instance.char_id)
	if definition == null:
		screen._detail.add_child(UIFactory.label("Missing character definition.", 13, UITheme.DANGER))
		return
	screen._ascend_armed = (screen._ascend_armed_uid == instance.uid)

	var portrait_slot := CollectionScreen.CENTERED_PORTRAIT_SLOT_SCENE.instantiate() as CenterContainer
	var portrait := portrait_slot.get_node("Portrait") as PortraitView
	# Premium rarities get a larger detail portrait.
	if UITheme.is_premium_rarity(definition.rarity):
		portrait.custom_minimum_size = Vector2(196, 232)
	else:
		portrait.custom_minimum_size = Vector2(168, 196)
	portrait.setup_character(definition)  # ZERO final portraits -> procedural fallback
	screen._detail.add_child(portrait_slot)

	var name_label := UIFactory.heading(definition.display_name, 23, UITheme.TEXT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen._detail.add_child(name_label)
	var title_label := UIFactory.label(definition.title, 12, UITheme.GOLD)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen._detail.add_child(title_label)

	# Premium rarity flourish near the heading.
	if UITheme.is_premium_rarity(definition.rarity):
		var flourish_effect := UITheme.rarity_effect(definition.rarity)
		var flourish_glow: Color = flourish_effect.get("glow", UITheme.GOLD_BRIGHT)
		var flourish := UIFactory.label("✦  " + UITheme.rarity_tier_label(definition.rarity) + "  ✦", 12, flourish_glow)
		flourish.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		screen._detail.add_child(flourish)

	# Short labelled visual_theme line from the art-spec contract (guard null).
	var art_spec := CharacterArtSpec.for_id(definition.id) as RefCounted
	if art_spec != null:
		var theme_text := str(art_spec.get("visual_theme"))
		if not theme_text.is_empty():
			var theme_line := UIFactory.wrapped("ART THEME · " + theme_text, 10, UITheme.TEXT_FAINT)
			theme_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			screen._detail.add_child(theme_line)
			screen._visual_theme_lines = 1

	var chips := UIFactory.hbox(6)
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_child(UIFactory.rarity_chip(definition.rarity))
	chips.add_child(UIFactory.element_chip(definition.element))
	chips.add_child(UIFactory.chip(definition.race, UITheme.TEXT_DIM))
	chips.add_child(UIFactory.chip(definition.role, UITheme.TEAL))
	screen._detail.add_child(chips)
	screen._detail.add_child(UIFactory.separator())

	var progression := UIFactory.hbox(8)
	progression.add_child(UIFactory.chip("Lv %d / %d" % [instance.level, instance.level_cap()], UITheme.GOLD))
	progression.add_child(UIFactory.chip("Ascension %d / %d" % [instance.ascension, CharacterInstance.MAX_ASCENSION], UITheme.VIOLET))
	progression.add_child(UIFactory.chip("Awakening %d / %d" % [instance.awakening, CharacterInstance.MAX_AWAKENING], UITheme.TEAL))
	screen._detail.add_child(progression)

	# XP / level-up progress (P2).
	var xp_needed := GameState.roster_domain.xp_to_next(instance.level)
	var xp_bar := UIFactory.bar(UITheme.TEAL, 8)
	xp_bar.max_value = maxf(1.0, float(xp_needed))
	xp_bar.value = clampf(float(instance.xp), 0.0, float(xp_needed))
	screen._detail.add_child(xp_bar)
	screen._detail.add_child(UIFactory.label("XP %d / %d" % [instance.xp, xp_needed], 10, UITheme.TEXT_FAINT))

	var multiplier := instance.power_multiplier() * GameState.roster_domain.collection_bonus()
	var stats := UIFactory.grid(2, 4)
	stats.add_child(stat_row("HP", int(round(definition.effective_stat("hp", instance.level, instance.ascension) * multiplier))))
	stats.add_child(stat_row("Attack", int(round(definition.effective_stat("atk", instance.level, instance.ascension) * multiplier))))
	stats.add_child(stat_row("Defense", int(round(definition.effective_stat("def", instance.level, instance.ascension) * multiplier))))
	stats.add_child(stat_row("Speed", int(round(definition.effective_stat("spd", instance.level, instance.ascension) * (1.0 + 0.02 * (instance.level - 1))))))
	stats.add_child(stat_row("Crit", "%.1f%%" % (definition.effective_stat("crit", instance.level, instance.ascension) * 100.0)))
	stats.add_child(stat_row("Crit Dmg", "%.2fx" % definition.effective_stat("crit_dmg", instance.level, instance.ascension)))
	stats.add_child(stat_row("Power", int(round(power_score(definition, multiplier)))))
	screen._detail.add_child(stats)

	# Stat preview: next level.
	if not instance.is_max_level():
		var next_level := instance.level + 1
		var next_mult := instance.power_multiplier() * GameState.roster_domain.collection_bonus()
		var next_hp := int(round(definition.effective_stat("hp", next_level, instance.ascension) * next_mult))
		var next_atk := int(round(definition.effective_stat("atk", next_level, instance.ascension) * next_mult))
		var next_def := int(round(definition.effective_stat("def", next_level, instance.ascension) * next_mult))
		var next_spd := int(round(definition.effective_stat("spd", next_level, instance.ascension) * (1.0 + 0.02 * (next_level - 1))))
		screen._detail.add_child(UIFactory.label("NEXT LEVEL (Lv %d)" % next_level, 10, UITheme.TEXT_FAINT))
		var preview := UIFactory.hbox(8)
		preview.add_child(UIFactory.label("HP %d" % next_hp, 10, UITheme.GREEN))
		preview.add_child(UIFactory.label("ATK %d" % next_atk, 10, UITheme.GREEN))
		preview.add_child(UIFactory.label("DEF %d" % next_def, 10, UITheme.GREEN))
		preview.add_child(UIFactory.label("SPD %d" % next_spd, 10, UITheme.GREEN))
		screen._detail.add_child(preview)

	# Equipped items (P3).
	screen._detail.add_child(UIFactory.label("EQUIPPED", 10, UITheme.TEXT_FAINT))
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
	screen._detail.add_child(equip_box)

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
		screen._detail.add_child(skill_panel)

	if not definition.passive_name.is_empty():
		var passive := UIFactory.panel(Color("#131b2c"), Color(UITheme.TEAL.r, UITheme.TEAL.g, UITheme.TEAL.b, 0.35), 8, 1, 8)
		var passive_box := UIFactory.vbox(2)
		passive_box.add_child(UIFactory.label("Passive · " + definition.passive_name, 12, UITheme.TEAL))
		passive_box.add_child(UIFactory.wrapped(definition.passive_text, 11, UITheme.TEXT_DIM))
		passive.add_child(passive_box)
		screen._detail.add_child(passive)

	screen._detail.add_child(UIFactory.rich("[i]%s[/i]" % definition.lore, 11, UITheme.TEXT_FAINT))
	screen._detail.add_child(UIFactory.separator())

	var actions := UIFactory.vbox(6)
	var in_party := GameState.roster_domain.party.has(instance.uid)
	var party_button := UIFactory.button("Remove from Party" if in_party else "Add to Party", not in_party)
	if not in_party and GameState.roster_domain.party.size() >= GameState.PARTY_MAX:
		party_button.disabled = true
		party_button.tooltip_text = "Party is full."
	if in_party and GameState.roster_domain.party.size() <= 1:
		party_button.disabled = true
		party_button.tooltip_text = "You must keep at least one character in the party."
	party_button.pressed.connect(func() -> void: screen._toggle_party(instance.uid))
	actions.add_child(party_button)

	var ascension := GameState.roster_domain.ascension_info(instance.uid)
	var levelup_button := UIFactory.button("Gain 100 XP", true)
	levelup_button.pressed.connect(func() -> void:
		var result: Dictionary = GameState.roster_domain.add_xp_to_character(instance, 100)
		var gained := int(result.get("levels", 0))
		if gained > 0:
			EventBus.toast_requested.emit("Level up! +%d level(s)" % gained)
		else:
			EventBus.toast_requested.emit("+100 XP")
		show_detail(instance.uid)
	)
	actions.add_child(levelup_button)

	var ascend_button := UIFactory.button("Ascend", false)
	if not bool(ascension.get("ok", false)):
		ascend_button.disabled = true
		ascend_button.tooltip_text = str(ascension.get("reason", "Cannot ascend yet."))
		ascend_button.text = "Ascend — locked"
	elif screen._ascend_armed and screen._ascend_armed_uid == instance.uid:
		ascend_button.text = "Press again to Ascend"
		ascend_button.add_theme_color_override("font_color", UITheme.DANGER)
	else:
		ascend_button.text = "Ascend — %s gold · %d dew" % [UIFactory.number(int(ascension.gold)), int(ascension.dew)]
	ascend_button.pressed.connect(func() -> void: screen._ascend(instance.uid))
	actions.add_child(ascend_button)

	# Awakening interface.
	var awaken_info := GameState.roster_domain.awakening_info(instance.uid)
	var awaken_button := UIFactory.button("Awaken", false)
	if not bool(awaken_info.get("ok", false)):
		awaken_button.disabled = true
		awaken_button.tooltip_text = str(awaken_info.get("reason", "Cannot awaken."))
		awaken_button.text = "Awaken — locked"
	else:
		awaken_button.text = "Awaken (%d dupes)" % int(awaken_info.dupes_needed)
	awaken_button.pressed.connect(func() -> void: screen._awaken(instance.uid))
	actions.add_child(awaken_button)
	screen._detail.add_child(UIFactory.label("Awakening %d / %d  ·  Bond %d (Lv %d)" % [instance.awakening, CharacterInstance.MAX_AWAKENING, instance.bond, GameState.roster_domain.bond_level(instance.uid)], 10, UITheme.TEXT_FAINT))

	screen._detail.add_child(actions)



func stat_row(title: String, value: Variant) -> PanelContainer:
	var row := UIFactory.panel(Color("#0d1524"), Color(0, 0, 0, 0), 6, 0, 6)
	var box := UIFactory.hbox(8)
	box.add_child(UIFactory.label(title, 11, UITheme.TEXT_FAINT))
	box.add_child(UIFactory.spacer())
	box.add_child(UIFactory.label(str(value), 12, UITheme.TEXT))
	row.add_child(box)
	return row



func power_score(definition: CharacterDef, multiplier: float) -> float:
	return (
		definition.stat("hp") * 0.20
		+ definition.stat("atk") * 3.0
		+ definition.stat("def") * 2.2
		+ definition.stat("spd") * 1.4
	) * multiplier



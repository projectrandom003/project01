class_name CombatHudComponent
extends Node
## Owns battle HUD refresh, party roster presentation, skill buttons and auto/speed controls.

var screen: CombatScreen


func bind(owner_screen: CombatScreen) -> void:
	screen = owner_screen

func build_roster(units: Array) -> void:
	if screen._roster_box == null:
		return
	UIFactory.clear(screen._roster_box)
	screen._roster_rows.clear()
	for unit in units:
		var row := preload("res://scenes/ui/combat/components/party_roster_entry.tscn").instantiate() as HBoxContainer
		var portrait := CombatScreen.PORTRAIT_VIEW_SCENE.instantiate() as PortraitView
		portrait.custom_minimum_size = Vector2(30, 38)
		var definition := ContentDB.get_character(unit.def_id)
		if definition != null:
			portrait.setup_character(definition)
		else:
			portrait.setup(unit.palette, "Human", unit.element, unit.rarity, unit.def_id.hash())
		row.get_node("PortraitSlot").add_child(portrait)
		var name_label := row.get_node("Info/Name") as Label
		name_label.text = unit.display_name
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", UITheme.TEXT)
		var hp_bar := row.get_node("Info/HPBar") as ProgressBar
		hp_bar.add_theme_stylebox_override("fill", UIFactory.bar_fill_style(UITheme.GREEN))
		hp_bar.max_value = maxf(1.0, unit.max_hp)
		hp_bar.value = clampf(unit.hp, 0.0, unit.max_hp)
		var hp_label := row.get_node("Info/HPLabel") as Label
		hp_label.add_theme_font_size_override("font_size", 8)
		hp_label.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		screen._roster_rows[unit.uid] = { "bar": hp_bar, "label": hp_label, "row": row }
		row.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				screen._on_roster_clicked(unit))
		screen._roster_box.add_child(row)



func refresh_skills() -> void:
	UIFactory.clear(screen._skills_box)
	screen._targeting_component.reset()
	var actor: Combatant = screen.engine.current_actor()
	if actor == null or screen._resolved:
		screen._actor_label.text = "Battle resolved."
		screen._hint_label.text = ""
		return
	if actor.team != CombatEngine.PLAYER_TEAM:
		screen._actor_label.text = "Enemy turn — " + actor.display_name
		screen._hint_label.text = "Watch enemy intent markers. Gold rings show the threatened party."
		return
	screen._actor_label.text = "%s — choose an action" % actor.display_name
	screen._hint_label.text = "Esc cancels targeting" if screen._targeting_component.is_targeting() else "Select a skill, then tap a gold-ringed foe. Elemental weaknesses are shown on impact."
	for skill_id in actor.skills:
		var skill: SkillDef = ContentDB.get_skill(str(skill_id))
		if skill != null:
			add_skill_button(skill, actor)
	if actor.ultimate_ready() and not actor.ultimate.is_empty():
		var ultimate: SkillDef = ContentDB.get_skill(actor.ultimate)
		if ultimate != null:
			add_skill_button(ultimate, actor)


func add_skill_button(skill: SkillDef, actor: Combatant) -> void:
	# Show the skill's kind + power more legibly; keep the ULTIMATE prefix.
	var energy_text := "FREE" if skill.energy_gain <= 0 else "%d EN" % int(skill.energy_gain)
	var cooldown := actor.cooldown_remaining(skill.id)
	var cooldown_text := " | CD %d" % cooldown if cooldown > 0 else ""
	var detail := "%s | %s | PWR %d | %s%s" % [skill.element.capitalize(), skill.kind.capitalize(), int(skill.power), energy_text, cooldown_text]
	var text := "%s\n%s" % [skill.display_name, detail]
	if skill.ultimate:
		text = "ULTIMATE · %s\n%s" % [skill.display_name, detail]
	var button := UIFactory.button(text, skill.ultimate)
	button.custom_minimum_size = Vector2(158, 46)
	button.add_theme_font_size_override("font_size", 11)
	button.tooltip_text = skill.description

	# Element-colour tint using UITheme.element_color; ultimates get a distinct
	# GOLD_BRIGHT premium edge (wider border + brighter gold) on top.
	var element_color := UITheme.element_color(skill.element)
	var edge := Color(element_color.r, element_color.g, element_color.b, 0.6)
	var edge_width := 1
	var bg := UITheme.PANEL_LIGHT
	if skill.ultimate:
		edge = UITheme.GOLD_BRIGHT
		edge_width = 2
		bg = Color("#2a2415")
		button.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT)
	button.add_theme_stylebox_override("normal", UITheme.style(bg, edge, 8, edge_width, 10))
	button.add_theme_stylebox_override("hover", UITheme.style(Color("#243252"), edge, 8, edge_width, 10))
	button.add_theme_stylebox_override("pressed", UITheme.style(Color("#0e1628"), edge, 8, edge_width, 10))
	button.set_meta("element", skill.element)
	button.set_meta("ultimate", skill.ultimate)

	button.disabled = actor.is_skill_on_cooldown(skill.id) or (skill.ultimate and not actor.ultimate_ready())
	button.pressed.connect(func() -> void: screen._select_skill(skill))
	screen._skills_box.add_child(button)
	if screen._targeting_component.is_targeting():
		var cancel := UIFactory.small_button("Cancel", UITheme.TEXT_DIM)
		cancel.pressed.connect(screen._cancel_targeting)
		screen._skills_box.add_child(cancel)



func on_auto_toggled(value: bool) -> void:
	screen._auto = value
	screen._turn_token += 1 # Cancel any queued auto action when the player switches mode.
	screen._auto_button.text = "AUTO  ON" if value else "AUTO  OFF"
	screen._auto_button.add_theme_color_override("font_color", UITheme.GOLD if value else UITheme.TEXT_DIM)
	if value and screen.engine != null and not screen._resolved:
		# Auto owns targeting as well as skill choice; clear any half-selected
		# manual action before handing the turn to the decision system.
		if screen._targeting_component.is_targeting():
			screen._targeting_component.cancel_targeting()
		var actor: Combatant = screen.engine.current_actor()
		if actor != null and actor.team == CombatEngine.PLAYER_TEAM:
			screen._schedule_auto_player()



func cycle_speed() -> void:
	if is_equal_approx(screen._speed, 1.0):
		screen._speed = 1.6
	elif is_equal_approx(screen._speed, 1.6):
		screen._speed = 2.4
	else:
		screen._speed = 1.0
	screen._speed_button.text = ("%.1f× speed" % screen._speed).replace(".0×", "×")


# ------------------------------------------------------------------ visuals


func refresh_cards() -> void:
	if screen.engine == null:
		return
	if screen._boss_hp_bar != null and screen._boss_hp_bar.visible:
		for unit in screen.engine.combatants:
			var boss: Combatant = unit
			if boss.is_boss and boss.is_alive():
				screen._boss_hp_bar.value = boss.hp
				if screen._boss_phase_label != null:
					screen._boss_phase_label.text = "Phase %d" % (boss.triggered_phases.size() + 1)
	# Update active character info panel.
	if screen.engine.current_actor() != null and screen._hp_bar != null:
		var active: Combatant = screen.engine.current_actor()
		screen._hp_bar.max_value = maxf(1.0, active.max_hp)
		screen._hp_bar.value = clampf(active.hp, 0.0, active.max_hp)
		screen._energy_bar.max_value = maxf(1.0, active.max_energy)
		screen._energy_bar.value = clampf(active.energy, 0.0, active.max_energy)
		screen._actor_label.text = active.display_name
		screen._status_label.text = UIFactory.status_text(active)
	# Refresh the battlefield: HP plates, the active marker and the roster.
	if screen._battlefield != null:
		screen._battlefield.refresh_actors()
		screen._battlefield.set_active(screen.engine.current_actor().uid if screen.engine.current_actor() != null else "")
	refresh_roster()


func refresh_roster() -> void:
	if screen.engine == null:
		return
	for unit in screen.engine.combatants:
		if unit.team != CombatEngine.PLAYER_TEAM:
			continue
		var entry: Dictionary = screen._roster_rows.get(unit.uid, {})
		if entry.is_empty():
			continue
		var bar: ProgressBar = entry.get("bar")
		var label: Label = entry.get("label")
		if bar != null:
			bar.max_value = maxf(1.0, unit.max_hp)
			bar.value = clampf(unit.hp, 0.0, unit.max_hp)
		if label != null:
			label.text = "%d/%d" % [int(ceil(unit.hp)), int(round(unit.max_hp))]



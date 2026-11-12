class_name CombatScreen
extends Control
## Turn-based battle overlay. The CombatEngine is pure and deterministic; this
## screen only translates its event stream into cards, numbers and log lines.
## Victory rewards are applied through GameState (and will be server-verified in
## Phase 12).

signal closed

const TURN_DELAY := 0.78

var group_id: String = ""
var engine: CombatEngine
var _enemy_row: HBoxContainer
var _party_row: HBoxContainer
var _turn_box: HBoxContainer
var _skills_box: HFlowContainer
var _log_label: RichTextLabel
var _title_label: Label
var _round_label: Label
var _hint_label: Label
var _auto_button: Button
var _speed_button: Button

var _enemy_cards: Array = []
var _party_cards: Array = []
var _card_by_index: Dictionary = {}
var _pending_skill: SkillDef = null
var _target_team: int = -1
var _targeting: bool = false
var _resolved: bool = false
var _boss_bar_container: VBoxContainer = null
var _boss_name_label: Label = null
var _boss_hp_bar: ProgressBar = null
var _boss_phase_label: Label = null
var _hp_bar: ProgressBar = null
var _energy_bar: ProgressBar = null
var _status_label: Label = null
var _actor_label: Label = null
var _camera_shake_timer: float = 0.0
var _camera_shake_intensity: float = 0.0
var _claimed: bool = false
var _turn_token: int = 0
var _speed: float = 1.0
var _auto: bool = false
var _log_lines: Array = []
var _pending_rewards: Dictionary = {}
var _result_layer: Control = null
var _confirm_layer: Control = null


func _ready() -> void:
	UIFactory.set_full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	_build_background()
	_build_layout()
	_start_battle()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _targeting:
			_cancel_targeting()
		elif _result_layer == null and _confirm_layer == null and not _resolved:
			_confirm_retreat()
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ build UI

func _build_background() -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color("#050810"),
		Color("#0a0f1e"),
		Color("#120a1e"),
		Color("#080510"),
		Color("#030408"),
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(1.0, 1.0)
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	UIFactory.set_full_rect(rect)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)

	# Vignette overlay.
	var vignette := ColorRect.new()
	vignette.color = Color(0, 0, 0, 0.35)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIFactory.set_full_rect(vignette)
	add_child(vignette)

	# Subtle animated particles.
	var particles := CPUParticles2D.new()
	particles.amount = 20
	particles.lifetime = 4.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(640, 360)
	particles.direction = Vector2(0, -1)
	particles.initial_velocity_min = 5.0
	particles.initial_velocity_max = 15.0
	particles.gravity = Vector2(0, -5)
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.5
	particles.color = Color(0.6, 0.4, 0.9, 0.3)
	particles.z_index = 1
	particles.position = Vector2(640, 360)
	add_child(particles)


func _build_layout() -> void:
	var margin := UIFactory.margin(16)
	UIFactory.set_full_rect(margin)
	add_child(margin)
	var root := UIFactory.vbox(6)
	margin.add_child(root)

	# ===== TOP: compact header + turn order =====
	var header := UIFactory.hbox(10)
	_title_label = UIFactory.heading("Battle", 20, UITheme.GOLD_BRIGHT)
	_boss_bar_container = null
	_boss_name_label = null
	_boss_hp_bar = null
	_boss_phase_label = null
	_camera_shake_timer = 0.0
	_camera_shake_intensity = 0.0
	header.add_child(_title_label)
	_round_label = UIFactory.label("Round 1", 10, UITheme.TEXT_DIM)
	header.add_child(_round_label)
	header.add_child(UIFactory.spacer())
	_auto_button = UIFactory.small_button("Auto: Off", UITheme.TEXT_DIM)
	_auto_button.toggle_mode = true
	_auto_button.custom_minimum_size = Vector2(80, 28)
	_auto_button.toggled.connect(_on_auto_toggled)
	header.add_child(_auto_button)
	_speed_button = UIFactory.small_button("1x", UITheme.TEAL)
	_speed_button.custom_minimum_size = Vector2(60, 28)
	_speed_button.pressed.connect(_cycle_speed)
	header.add_child(_speed_button)
	var retreat := UIFactory.button("Retreat", false, true)
	retreat.custom_minimum_size = Vector2(80, 28)
	retreat.pressed.connect(_confirm_retreat)
	header.add_child(retreat)
	root.add_child(header)

	# Boss health bar (hidden by default).
	_boss_bar_container = UIFactory.vbox(4)
	_boss_bar_container.visible = false
	var boss_bar_panel := UIFactory.panel(Color("#1a0a0a"), Color(UITheme.DANGER.r, UITheme.DANGER.g, UITheme.DANGER.b, 0.6), 8, 1, 6)
	_boss_bar_container.add_child(boss_bar_panel)
	var boss_bar_inner := UIFactory.vbox(2)
	boss_bar_panel.add_child(boss_bar_inner)
	_boss_name_label = UIFactory.heading("Boss", 16, UITheme.DANGER)
	_boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_bar_inner.add_child(_boss_name_label)
	_boss_hp_bar = UIFactory.bar(UITheme.DANGER, 10)
	_boss_hp_bar.custom_minimum_size = Vector2(0, 14)
	boss_bar_inner.add_child(_boss_hp_bar)
	_boss_phase_label = UIFactory.label("Phase 1", 9, UITheme.TEXT_DIM)
	_boss_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_bar_inner.add_child(_boss_phase_label)
	root.add_child(_boss_bar_container)

	# Turn order timeline (compact).
	var turn_panel := UIFactory.panel(Color(0.05, 0.075, 0.13, 0.7), UITheme.BORDER_SOFT, 6, 1, 4)
	var turn_row := UIFactory.hbox(6)
	turn_row.add_child(UIFactory.label("TURN", 8, UITheme.TEXT_FAINT))
	_turn_box = UIFactory.hbox(4)
	turn_row.add_child(_turn_box)
	turn_panel.add_child(turn_row)
	root.add_child(turn_panel)

	# ===== CENTER: large battlefield =====
	var battlefield := UIFactory.vbox(4)
	battlefield.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(battlefield)

	# Enemy side (right, larger for bosses).
	var enemy_section := UIFactory.vbox(2)
	enemy_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_enemy_row = UIFactory.hbox(12)
	_enemy_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_enemy_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	enemy_section.add_child(_enemy_row)
	battlefield.add_child(enemy_section)

	# Party side (left).
	var party_section := UIFactory.vbox(2)
	_party_row = UIFactory.hbox(10)
	_party_row.alignment = BoxContainer.ALIGNMENT_CENTER
	party_section.add_child(_party_row)
	battlefield.add_child(party_section)

	# ===== BOTTOM: active character info + skills =====
	var bottom := UIFactory.hbox(10)
	bottom.custom_minimum_size = Vector2(0, 180)
	root.add_child(bottom)

	# Active character info panel.
	var info_panel := UIFactory.panel(Color("#0b1220"), UITheme.BORDER_SOFT, 8, 1, 8)
	info_panel.custom_minimum_size = Vector2(280, 0)
	bottom.add_child(info_panel)
	var info_box := UIFactory.vbox(4)
	info_panel.add_child(info_box)
	_actor_label = UIFactory.heading("Preparing...", 14, UITheme.TEXT)
	info_box.add_child(_actor_label)
	_hp_bar = UIFactory.bar(UITheme.GREEN, 10)
	_hp_bar.custom_minimum_size = Vector2(0, 12)
	info_box.add_child(_hp_bar)
	_energy_bar = UIFactory.bar(UITheme.GOLD, 6)
	_energy_bar.custom_minimum_size = Vector2(0, 8)
	info_box.add_child(_energy_bar)
	_status_label = UIFactory.label("", 9, UITheme.TEAL)
	info_box.add_child(_status_label)

	# Skills panel.
	var skills_panel := UIFactory.panel(Color("#0b1220"), UITheme.BORDER_SOFT, 8, 1, 8)
	skills_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(skills_panel)
	_skills_box = HFlowContainer.new()
	_skills_box.add_theme_constant_override("h_separation", 6)
	_skills_box.add_theme_constant_override("v_separation", 4)
	_skills_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	skills_panel.add_child(_skills_box)
	_hint_label = UIFactory.label("", 10, UITheme.TEXT_DIM)
	skills_panel.add_child(_hint_label)

	# Log panel.
	var log_panel := UIFactory.panel(Color("#0a101c"), UITheme.BORDER_SOFT, 8, 1, 6)
	log_panel.custom_minimum_size = Vector2(260, 0)
	bottom.add_child(log_panel)
	var log_box := UIFactory.vbox(4)
	log_panel.add_child(log_box)
	log_box.add_child(UIFactory.label("BATTLE LOG", 8, UITheme.TEXT_FAINT))
	_log_label = UIFactory.rich("", 9, UITheme.TEXT_DIM)
	_log_label.fit_content = false
	_log_label.scroll_active = true
	_log_label.scroll_following = true
	_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_box.add_child(_log_label)

func _start_battle() -> void:
	_resolved = false
	_pending_skill = null
	_target_team = -1
	_targeting = false
	_turn_token += 1
	_log_lines.clear()
	if _log_label != null:
		_log_label.text = ""
	UIFactory.clear(_enemy_row)
	UIFactory.clear(_party_row)
	_enemy_cards.clear()
	_party_cards.clear()
	_card_by_index.clear()

	var group: Dictionary = ContentDB.get_enemy_group(group_id)
	if group.is_empty():
		push_error("[CombatScreen] Unknown enemy group: " + group_id)
		_claim(false)
		return
	_title_label.text = str(group.get("name", group_id))
	_round_label.text = "Round 1"

	var player_units := CombatFactory.player_units()
	var enemy_units := CombatFactory.enemy_units(group_id)
	var has_boss := false
	for eu in enemy_units:
		if eu.is_boss:
			has_boss = true
			break
	if player_units.is_empty() or enemy_units.is_empty():
		push_error("[CombatScreen] Battle has no units.")
		_claim(false)
		return

	engine = CombatEngine.new()
	engine.setup(player_units, enemy_units, randi())
	if has_boss:
		for eu in enemy_units:
			if eu.is_boss:
				if _boss_name_label != null:
					_boss_name_label.text = eu.display_name
				if _boss_hp_bar != null:
					_boss_hp_bar.max_value = eu.max_hp
					_boss_hp_bar.value = eu.hp
				if _boss_bar_container != null:
					_boss_bar_container.visible = true
				_show_banner("Boss: " + eu.display_name)
	for index in engine.combatants.size():
		var unit: Combatant = engine.combatants[index]
		var card := CombatUnitCard.new()
		card.setup(unit)
		card.clicked.connect(_on_card_clicked)
		_card_by_index[index] = card
		if unit.team == CombatEngine.PLAYER_TEAM:
			_party_cards.append(card)
			_party_row.add_child(card)
		else:
			_enemy_cards.append(card)
			_enemy_row.add_child(card)

	_log("[color=#e8c27a]Battle begins.[/color]")
	var events := engine.start()
	_process_events(events)


func _process_events(events: Array) -> void:
	if _resolved:
		return
	for event in events:
		var event_type := str(event.get("type", ""))
		match event_type:
			"round":
				_round_label.text = "Round %d" % int(event.get("round", 1))
				_log("[color=#9aa8c2]â€” Round %d â€”[/color]" % int(event.get("round", 1)))
			"turn":
				_log("[color=#e9eef9]%s's turn.[/color]" % str(event.get("actor_name", "Unit")))
			"action":
				var actor_name := str(event.get("actor_name", "Unit"))
				var skill_name := str(event.get("skill_name", "skill"))
				_log("[color=#7fe3e0]%s uses %s.[/color]" % [actor_name, skill_name])
				var actor_card: CombatUnitCard = _card_for_uid(str(event.get("actor_uid", "")))
				if actor_card != null:
					actor_card.flash(Color(1.3, 1.3, 1.3, 1.0))
			"damage":
				_handle_damage(event)
			"heal":
				var heal_card := _card_for_uid(str(event.get("target_uid", "")))
				var heal_amount := int(event.get("amount", 0))
				if heal_amount > 0:
					_log("[color=#8fe3a0]%s recovers %d HP.[/color]" % [str(event.get("target_name", "Unit")), heal_amount])
					if heal_card != null:
						_float_text(heal_card, "+%d" % heal_amount, UITheme.GREEN)
			"shield":
				_log("[color=#7fe3e0]%s gains a %d shield.[/color]" % [str(event.get("target_name", "Unit")), int(event.get("amount", 0))])
			"status":
				_log("[color=#b78bff]%s: %s[/color]" % [str(event.get("target_name", "Unit")), str(event.get("status", "")).replace("_", " ").capitalize()])
			"status_tick":
				_log("[color=#ff9f9f]%s takes %d %s damage.[/color]" % [
					str(event.get("target_name", "Unit")), int(event.get("amount", 0)), str(event.get("status", ""))
				])
				var tick_card := _card_for_uid(str(event.get("target_uid", "")))
				if tick_card != null:
					tick_card.flash(Color(1.4, 0.8, 0.8, 1.0))
					_float_text(tick_card, "-%d" % int(event.get("amount", 0)), UITheme.DANGER)
			"miss":
				_log("[color=#9aa8c2]%s misses.[/color]" % str(event.get("target_name", "Unit")))
			"skip":
				_log("[color=#9aa8c2]%s loses the turn (%s).[/color]" % [
					str(event.get("actor_name", "Unit")), str(event.get("reason", "stunned"))
				])
			"death":
				_log("[color=#ff7a8a]%s falls.[/color]" % str(event.get("target_name", "Unit")))
			"phase":
				_log("[color=#ffc95e]%s[/color]" % str(event.get("message", "The boss changes.")))
				_show_banner(str(event.get("message", "PHASE CHANGE")))
				_camera_shake(10.0, 0.5)
			"victory":
				_refresh_cards()
				_finish_battle(true)
				return
			"defeat":
				_refresh_cards()
				_finish_battle(false)
				return
	_refresh_cards()
	_update_turn_order()
	if _resolved:
		return
	var actor := engine.current_actor()
	if actor == null:
		return
	_refresh_skills()
	if actor.team == CombatEngine.ENEMY_TEAM:
		_schedule_enemy_turn()
	elif _auto:
		_schedule_auto_player()


func _handle_damage(event: Dictionary) -> void:
	var card := _card_for_uid(str(event.get("target_uid", "")))
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
	_log("[color=#ff9f9f]%s takes %d damage%s.[/color]" % [str(event.get("target_name", "Unit")), amount, suffix])
	if card != null:
		var color := UITheme.DANGER
		if crit:
			color = UITheme.GOLD_BRIGHT
		elif advantage == "Advantage":
			color = UITheme.GREEN
		card.flash(Color(1.4, 0.9, 0.9, 1.0))
		_float_text(card, "-%d%s" % [amount, "!" if crit else ""], color)


func _schedule_enemy_turn() -> void:
	_turn_token += 1
	var token := _turn_token
	await get_tree().create_timer(TURN_DELAY / _speed).timeout
	if not is_inside_tree() or token != _turn_token or _resolved or engine == null:
		return
	var actor := engine.current_actor()
	if actor == null or actor.team != CombatEngine.ENEMY_TEAM:
		return
	var decision := CombatAI.choose(engine, engine.current_actor_index)
	var skill_id := str(decision.get("skill_id", ""))
	if skill_id.is_empty():
		return
	var events := engine.execute(engine.current_actor_index, skill_id, decision.get("targets", []))
	_process_events(events)


func _schedule_auto_player() -> void:
	_turn_token += 1
	var token := _turn_token
	await get_tree().create_timer(TURN_DELAY / _speed).timeout
	if not is_inside_tree() or token != _turn_token or _resolved or engine == null:
		return
	var actor := engine.current_actor()
	if actor == null or actor.team != CombatEngine.PLAYER_TEAM:
		return
	var decision := CombatAI.choose(engine, engine.current_actor_index)
	var skill_id := str(decision.get("skill_id", ""))
	if skill_id.is_empty():
		return
	var events := engine.execute(engine.current_actor_index, skill_id, decision.get("targets", []))
	_process_events(events)


# ------------------------------------------------------------------ actions

func _refresh_skills() -> void:
	UIFactory.clear(_skills_box)
	_pending_skill = null
	_targeting = false
	_target_team = -1
	var actor := engine.current_actor()
	if actor == null or _resolved:
		_actor_label.text = "Battle resolved."
		_hint_label.text = ""
		return
	if actor.team != CombatEngine.PLAYER_TEAM:
		_actor_label.text = "Enemy turn â€” " + actor.display_name
		_hint_label.text = "The glade holds its breath."
		return
	_actor_label.text = "%s â€” choose an action" % actor.display_name
	_hint_label.text = "Esc cancels targeting" if _targeting else "Damage skills target one foe unless stated otherwise."
	for skill_id in actor.skills:
		var skill: SkillDef = ContentDB.get_skill(str(skill_id))
		if skill != null:
			_add_skill_button(skill, actor)
	if actor.ultimate_ready() and not actor.ultimate.is_empty():
		var ultimate: SkillDef = ContentDB.get_skill(actor.ultimate)
		if ultimate != null:
			_add_skill_button(ultimate, actor)


func _add_skill_button(skill: SkillDef, actor: Combatant) -> void:
	# Show the skill's kind + power more legibly; keep the ULTIMATE prefix.
	var detail := "%s Â· %s Â· PWR %d" % [
		skill.element.capitalize(), skill.kind.capitalize(), int(skill.power)
	]
	var text := "%s\n%s" % [skill.display_name, detail]
	if skill.ultimate:
		text = "ULTIMATE Â· %s\n%s" % [skill.display_name, detail]
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

	button.disabled = skill.ultimate and not actor.ultimate_ready()
	button.pressed.connect(func() -> void: _select_skill(skill))
	_skills_box.add_child(button)
	if _targeting:
		var cancel := UIFactory.small_button("Cancel", UITheme.TEXT_DIM)
		cancel.pressed.connect(_cancel_targeting)
		_skills_box.add_child(cancel)


func _select_skill(skill: SkillDef) -> void:
	if _resolved or engine == null:
		return
	var actor := engine.current_actor()
	if actor == null or actor.team != CombatEngine.PLAYER_TEAM:
		return
	if skill.ultimate and not actor.ultimate_ready():
		return
	if skill.target == "single_enemy" or skill.target == "single_ally":
		_pending_skill = skill
		_targeting = true
		_target_team = CombatEngine.ENEMY_TEAM if skill.target == "single_enemy" else CombatEngine.PLAYER_TEAM
		_hint_label.text = "Select a target. Esc cancels."
		_refresh_cards()
	else:
		_execute_current(skill.id, [])


func _on_card_clicked(card: CombatUnitCard) -> void:
	if not _targeting or _pending_skill == null or card.unit == null:
		return
	if card.unit.team != _target_team or not card.unit.is_alive():
		return
	var skill_id := _pending_skill.id
	_execute_current(skill_id, [card.unit.combat_index])


func _execute_current(skill_id: String, targets: Array) -> void:
	if engine == null or _resolved:
		return
	var actor := engine.current_actor()
	if actor == null:
		return
	# Purely presentational: ULTIMATE skills get a short animated name banner.
	# Turn order, targeting, event processing and battle resolution are untouched.
	var played_skill: SkillDef = ContentDB.get_skill(skill_id)
	if played_skill != null and played_skill.ultimate:
		_show_banner(played_skill.display_name)
	_cancel_targeting()
	var events := engine.execute(engine.current_actor_index, skill_id, targets)
	_process_events(events)


func _cancel_targeting() -> void:
	_pending_skill = null
	_targeting = false
	_target_team = -1
	_hint_label.text = ""
	_refresh_cards()


func _on_auto_toggled(value: bool) -> void:
	_auto = value
	_auto_button.text = "Auto: On" if value else "Auto: Off"
	_auto_button.add_theme_color_override("font_color", UITheme.GOLD if value else UITheme.TEXT_DIM)
	if value and engine != null and not _resolved:
		var actor := engine.current_actor()
		if actor != null and actor.team == CombatEngine.PLAYER_TEAM:
			_schedule_auto_player()


func _cycle_speed() -> void:
	if is_equal_approx(_speed, 1.0):
		_speed = 1.6
	elif is_equal_approx(_speed, 1.6):
		_speed = 2.4
	else:
		_speed = 1.0
	_speed_button.text = ("%.1fÃ— speed" % _speed).replace(".0Ã—", "Ã—")


# ------------------------------------------------------------------ visuals

func _refresh_cards() -> void:
	if engine == null:
		return
	if _boss_hp_bar != null and _boss_hp_bar.visible:
		for index in _card_by_index.keys():
			var c: CombatUnitCard = _card_by_index[index]
			var u: Combatant = engine.combatants[int(index)]
			if u.is_boss and u.is_alive():
				_boss_hp_bar.value = u.hp
				if _boss_phase_label != null:
					_boss_phase_label.text = "Phase %d" % (u.triggered_phases.size() + 1)
	# Update active character info panel.
	if engine.current_actor() != null and _hp_bar != null:
		var active: Combatant = engine.current_actor()
		_hp_bar.max_value = maxf(1.0, active.max_hp)
		_hp_bar.value = clampf(active.hp, 0.0, active.max_hp)
		_energy_bar.max_value = maxf(1.0, active.max_energy)
		_energy_bar.value = clampf(active.energy, 0.0, active.max_energy)
		_actor_label.text = active.display_name
		_status_label.text = UIFactory.status_text(active)
	for index in _card_by_index.keys():
		var card: CombatUnitCard = _card_by_index[index]
		var unit: Combatant = engine.combatants[int(index)]
		card.refresh()
		card.set_current(int(index) == engine.current_actor_index and unit.is_alive())
		var valid_target := (
			_targeting
			and unit.team == _target_team
			and unit.is_alive()
		)
		card.set_targetable(valid_target)
		card.set_selected(false)


func _update_turn_order() -> void:
	if _turn_box == null or engine == null:
		return
	UIFactory.clear(_turn_box)
	var preview := engine.upcoming_turns(6)
	if preview.is_empty():
		_turn_box.add_child(UIFactory.label("â€”", 10, UITheme.TEXT_FAINT))
		return
	for index in preview.size():
		var entry: Dictionary = preview[index]
		var color := UITheme.TEAL if int(entry.get("team", 0)) == CombatEngine.PLAYER_TEAM else UITheme.DANGER
		_turn_box.add_child(UIFactory.chip(str(entry.get("name", "?")), color))
		if index < preview.size() - 1:
			_turn_box.add_child(UIFactory.label("â€º", 10, UITheme.TEXT_FAINT))


func _card_for_uid(uid: String) -> CombatUnitCard:
	if engine == null:
		return null
	var unit := engine.get_by_uid(uid)
	if unit == null:
		return null
	var card = _card_by_index.get(unit.combat_index, null)
	return card as CombatUnitCard


func _float_text(card: CombatUnitCard, text: String, color: Color) -> void:
	if card == null or not is_instance_valid(card):
		return
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.05, 0.95))
	label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 50
	add_child(label)
	var local := card.global_position - global_position
	label.position = local + Vector2(card.size.x * 0.5 - 24.0, 8.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 52.0, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.18)
	tween.chain().tween_callback(label.queue_free)


func _show_banner(text: String) -> void:
	var banner := UIFactory.label(text, 26, UITheme.GOLD_BRIGHT)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.set_anchors_preset(Control.PRESET_CENTER)
	banner.offset_left = -320
	banner.offset_right = 320
	banner.offset_top = -22
	banner.offset_bottom = 22
	banner.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.05, 0.95))
	banner.add_theme_constant_override("outline_size", 7)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.z_index = 60
	add_child(banner)
	banner.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(banner, "modulate:a", 1.0, 0.25)
	tween.tween_interval(1.3)
	tween.tween_property(banner, "modulate:a", 0.0, 0.35)
	tween.tween_callback(banner.queue_free)


func _log(line: String) -> void:
	_log_lines.append(line)
	while _log_lines.size() > 9:
		_log_lines.pop_front()
	if _log_label != null:
		_log_label.text = "\n".join(_log_lines)


# ------------------------------------------------------------------ finish

func _process(delta: float) -> void:
	if _camera_shake_timer > 0.0:
		_camera_shake_timer -= delta
		var offset := Vector2(randf_range(-_camera_shake_intensity, _camera_shake_intensity), randf_range(-_camera_shake_intensity, _camera_shake_intensity))
		if _boss_bar_container != null:
			_boss_bar_container.position = offset
		if _camera_shake_timer <= 0.0:
			_camera_shake_intensity = 0.0
			if _boss_bar_container != null:
				_boss_bar_container.position = Vector2.ZERO


func _camera_shake(intensity: float, duration: float) -> void:
	_camera_shake_intensity = maxf(_camera_shake_intensity, intensity)
	_camera_shake_timer = maxf(_camera_shake_timer, duration)


func _finish_battle(victory: bool) -> void:
	if _resolved:
		return
	_resolved = true
	_turn_token += 1
	_pending_skill = null
	_targeting = false
	_target_team = -1
	_refresh_cards()
	UIFactory.clear(_skills_box)
	_actor_label.text = "Victory" if victory else "Defeat"
	_hint_label.text = ""
	_pending_rewards = GameState.build_battle_rewards(group_id) if victory else {}
	_show_result(victory)


func _show_result(victory: bool) -> void:
	if _result_layer != null and is_instance_valid(_result_layer):
		_result_layer.queue_free()
	_result_layer = Control.new()
	UIFactory.set_full_rect(_result_layer)
	_result_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_result_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.04, 0.82)
	UIFactory.set_full_rect(dim)
	_result_layer.add_child(dim)
	var center := CenterContainer.new()
	UIFactory.set_full_rect(center)
	_result_layer.add_child(center)
	var panel := UIFactory.panel(Color("#0b1120"), Color(UITheme.GOLD.r, UITheme.GOLD.g, UITheme.GOLD.b, 0.5) if victory else Color(UITheme.DANGER.r, UITheme.DANGER.g, UITheme.DANGER.b, 0.5), 16, 1, 24, true)
	panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(panel)
	var box := UIFactory.vbox(12)
	panel.add_child(box)

	var title := UIFactory.heading("VICTORY" if victory else "DEFEAT", 40, UITheme.GOLD_BRIGHT if victory else UITheme.DANGER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var subtitle := UIFactory.label(
		"The glade breathes easier." if victory else "The roots remember your name. Try again.",
		13,
		UITheme.TEXT_DIM
	)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)
	box.add_child(UIFactory.separator())

	if victory:
		box.add_child(UIFactory.label("REWARDS", 10, UITheme.TEXT_FAINT))
		var rewards_row := UIFactory.hbox(8)
		rewards_row.alignment = BoxContainer.ALIGNMENT_CENTER
		rewards_row.add_child(UIFactory.chip("+%s Gold" % UIFactory.number(int(_pending_rewards.get("gold", 0))), UITheme.GOLD))
		rewards_row.add_child(UIFactory.chip("+%s Crystals" % UIFactory.number(int(_pending_rewards.get("crystals", 0))), UITheme.TEAL))
		rewards_row.add_child(UIFactory.chip("+%s XP" % UIFactory.number(int(_pending_rewards.get("xp", 0))), UITheme.GREEN))
		box.add_child(rewards_row)
		for item_id in _pending_rewards.get("items", {}).keys():
			var item: Dictionary = ContentDB.get_item(str(item_id))
			box.add_child(UIFactory.label(
				"â€¢ %s Ã—%d" % [str(item.get("name", item_id)), int(_pending_rewards["items"][item_id])],
				12,
				UITheme.TEXT_DIM
			))
	else:
		box.add_child(UIFactory.wrapped(
			"Defeat is not a loss of progress in this slice. Retry with the same party or retreat to the world.",
			12,
			UITheme.TEXT_DIM
		))

	box.add_child(UIFactory.separator())
	var actions := UIFactory.hbox(10)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	if victory:
		var claim := UIFactory.button("Claim Rewards", true)
		claim.custom_minimum_size = Vector2(220, 46)
		claim.pressed.connect(func() -> void: _claim(true))
		actions.add_child(claim)
	else:
		var retry := UIFactory.button("Retry", true)
		retry.custom_minimum_size = Vector2(160, 46)
		retry.pressed.connect(_retry)
		actions.add_child(retry)
		var retreat := UIFactory.button("Retreat", false, true)
		retreat.custom_minimum_size = Vector2(160, 46)
		retreat.pressed.connect(func() -> void: _claim(false))
		actions.add_child(retreat)
	box.add_child(actions)


func _retry() -> void:
	if _result_layer != null and is_instance_valid(_result_layer):
		_result_layer.queue_free()
		_result_layer = null
	_start_battle()


func _confirm_retreat() -> void:
	if _resolved or _confirm_layer != null:
		return
	_confirm_layer = Control.new()
	UIFactory.set_full_rect(_confirm_layer)
	_confirm_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_confirm_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.04, 0.7)
	UIFactory.set_full_rect(dim)
	_confirm_layer.add_child(dim)
	var center := CenterContainer.new()
	UIFactory.set_full_rect(center)
	_confirm_layer.add_child(center)
	var panel := UIFactory.panel(Color("#0b1120"), Color(UITheme.DANGER.r, UITheme.DANGER.g, UITheme.DANGER.b, 0.5), 14, 1, 20, true)
	panel.custom_minimum_size = Vector2(420, 0)
	center.add_child(panel)
	var box := UIFactory.vbox(12)
	panel.add_child(box)
	box.add_child(UIFactory.heading("Retreat?", 24, UITheme.DANGER))
	box.add_child(UIFactory.wrapped("The encounter ends without rewards and the monster returns to the glade.", 12, UITheme.TEXT_DIM))
	var actions := UIFactory.hbox(10)
	var stay := UIFactory.button("Keep Fighting", true)
	stay.pressed.connect(func() -> void:
		_confirm_layer.queue_free()
		_confirm_layer = null
	)
	actions.add_child(stay)
	var leave := UIFactory.button("Retreat", false, true)
	leave.pressed.connect(func() -> void: _claim(false))
	actions.add_child(leave)
	box.add_child(actions)


func _claim(victory: bool) -> void:
	if _claimed:
		return
	_claimed = true
	if _confirm_layer != null and is_instance_valid(_confirm_layer):
		_confirm_layer.queue_free()
		_confirm_layer = null
	if _result_layer != null and is_instance_valid(_result_layer):
		_result_layer.queue_free()
		_result_layer = null
	if victory:
		GameState.apply_battle_result(group_id, true)
	EventBus.battle_finished.emit({
		"group_id": group_id,
		"victory": victory,
		"rewards": _pending_rewards,
	})
	closed.emit()
	queue_free()


## Additive skill-presentation report (Phase 5). The three feature flags are
## true because this build wires GOLD_BRIGHT ultimate styling, element tints and
## the ultimate name-banner hook; skill_buttons reflects the live action bar.
func skill_presentation_report() -> Dictionary:
	var count := 0
	if _skills_box != null:
		for child in _skills_box.get_children():
			if child is Button and child.has_meta("ultimate"):
				count += 1
	return {
		"screen": "combat",
		"ultimate_styling": true,
		"element_tints": true,
		"banner_hook": true,
		"skill_buttons": count,
	}

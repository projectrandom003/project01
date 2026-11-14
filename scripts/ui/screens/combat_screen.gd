class_name CombatScreen
extends Control
## Turn-based battle overlay. The CombatEngine is pure and deterministic; this
## screen only translates its event stream into cards, numbers and log lines.
## Victory rewards are applied through GameState (and will be server-verified in
## Phase 12).

signal closed

const TURN_DELAY := 0.78
const IMPACT_DELAY := 0.58
const BATTLEFIELD_SCENE: PackedScene = preload("res://scenes/ui/battlefield.tscn")

var group_id: String = ""
var engine: CombatEngine
var _battlefield: Battlefield = null
var _enemy_row: HBoxContainer
var _party_row: HBoxContainer
var _roster_box: VBoxContainer
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
var _roster_rows: Dictionary = {}
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
var _animating: bool = false
var _claimed: bool = false
var _turn_token: int = 0
var _speed: float = 1.0
var _auto: bool = false
var _log_lines: Array = []
var _pending_rewards: Dictionary = {}
var _cinematic_finish_delay: float = 0.0
var _result_layer: Control = null
var _confirm_layer: Control = null


func _ready() -> void:
	UIFactory.set_full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	# The arena backdrop is an authored child scene. Keep the old builder only
	# for direct CombatScreen.new() preview/test fixtures.
	if get_node_or_null("CombatScreenBackdrop") == null:
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
	# Deep gothic sky gradient.
	var sky_gradient := Gradient.new()
	sky_gradient.colors = PackedColorArray([
		Color("#03050a"),
		Color("#080c18"),
		Color("#0e0a1a"),
		Color("#06040e"),
		Color("#020306"),
	])
	sky_gradient.offsets = PackedFloat32Array([0.0, 0.2, 0.45, 0.75, 1.0])
	var sky_texture := GradientTexture2D.new()
	sky_texture.gradient = sky_gradient
	sky_texture.fill = GradientTexture2D.FILL_LINEAR
	sky_texture.fill_from = Vector2(0.0, 0.0)
	sky_texture.fill_to = Vector2(0.0, 1.0)
	var sky_rect := TextureRect.new()
	sky_rect.texture = sky_texture
	sky_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky_rect.stretch_mode = TextureRect.STRETCH_SCALE
	UIFactory.set_full_rect(sky_rect)
	sky_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky_rect)

	# Stone floor plane (bottom 35% of screen).
	var floor_rect := ColorRect.new()
	floor_rect.color = Color("#0d0b0f")
	floor_rect.anchor_left = 0.0
	floor_rect.anchor_right = 1.0
	floor_rect.anchor_top = 0.65
	floor_rect.anchor_bottom = 1.0
	floor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floor_rect)

	# Floor tile lines (horizontal).
	for i in range(6):
		var line := ColorRect.new()
		line.color = Color(0.15, 0.12, 0.18, 0.4)
		line.anchor_left = 0.0
		line.anchor_right = 1.0
		line.anchor_top = 0.65 + float(i) * 0.058
		line.anchor_bottom = 0.65 + float(i) * 0.058 + 0.002
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(line)

	# Floor tile lines (vertical, perspective).
	for i in range(8):
		var vline := ColorRect.new()
		vline.color = Color(0.12, 0.10, 0.15, 0.3)
		var x_pos := 0.05 + float(i) * 0.13
		vline.anchor_left = x_pos
		vline.anchor_right = x_pos + 0.003
		vline.anchor_top = 0.65
		vline.anchor_bottom = 1.0
		vline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(vline)

	# Ground shadow under characters (dark gradient).
	var shadow_gradient := Gradient.new()
	shadow_gradient.colors = PackedColorArray([Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.5)])
	shadow_gradient.offsets = PackedFloat32Array([0.0, 1.0])
	var shadow_tex := GradientTexture2D.new()
	shadow_tex.gradient = shadow_gradient
	shadow_tex.fill = GradientTexture2D.FILL_LINEAR
	shadow_tex.fill_from = Vector2(0.5, 0.0)
	shadow_tex.fill_to = Vector2(0.5, 1.0)
	var shadow_rect := TextureRect.new()
	shadow_rect.texture = shadow_tex
	shadow_rect.anchor_left = 0.0
	shadow_rect.anchor_right = 1.0
	shadow_rect.anchor_top = 0.6
	shadow_rect.anchor_bottom = 1.0
	shadow_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow_rect.stretch_mode = TextureRect.STRETCH_SCALE
	shadow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shadow_rect)

	# Vignette overlay (stronger).
	var vignette := ColorRect.new()
	vignette.color = Color(0, 0, 0, 0.45)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIFactory.set_full_rect(vignette)
	add_child(vignette)

	# Authored particle layers keep ambience editable independently of screen logic.
	var ambience := preload("res://scenes/ui/combat/components/combat_ambient_particles.tscn").instantiate() as Node2D
	add_child(ambience)


func _style_combat_panel(panel: PanelContainer, fill: Color, radius: int, margin: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = UITheme.BORDER_SOFT
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	panel.add_theme_stylebox_override("panel", style)


func _build_layout() -> void:
	var margin := UIFactory.margin(16)
	UIFactory.set_full_rect(margin)
	add_child(margin)
	var root := UIFactory.vbox(6)
	margin.add_child(root)

	# ===== TOP: authored, reusable combat header =====
	var header := preload("res://scenes/ui/combat/components/combat_header.tscn").instantiate() as HBoxContainer
	_title_label = header.get_node("TitleLabel") as Label
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT)
	_round_label = header.get_node("RoundLabel") as Label
	_round_label.add_theme_font_size_override("font_size", 10)
	_round_label.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	_auto_button = header.get_node("AutoButton") as Button
	_auto_button.add_theme_stylebox_override("normal", UIFactory.small_button("AUTO  OFF", UITheme.TEXT_DIM).get_theme_stylebox("normal").duplicate())
	_auto_button.toggled.connect(_on_auto_toggled)
	_speed_button = header.get_node("SpeedButton") as Button
	_speed_button.add_theme_stylebox_override("normal", UIFactory.small_button("1x", UITheme.TEAL).get_theme_stylebox("normal").duplicate())
	_speed_button.pressed.connect(_cycle_speed)
	var retreat := header.get_node("RetreatButton") as Button
	retreat.add_theme_stylebox_override("normal", UIFactory.button("Retreat", false, true).get_theme_stylebox("normal").duplicate())
	retreat.pressed.connect(_confirm_retreat)
	_boss_bar_container = null
	_boss_name_label = null
	_boss_hp_bar = null
	_boss_phase_label = null
	_camera_shake_timer = 0.0
	_camera_shake_intensity = 0.0
	root.add_child(header)

	# Boss health presentation is an independently editable PackedScene.
	_boss_bar_container = preload("res://scenes/ui/combat/components/boss_health_panel.tscn").instantiate() as VBoxContainer
	_boss_name_label = _boss_bar_container.get_node("Panel/Content/BossName") as Label
	_boss_name_label.add_theme_font_size_override("font_size", 16)
	_boss_name_label.add_theme_color_override("font_color", UITheme.DANGER)
	_boss_hp_bar = _boss_bar_container.get_node("Panel/Content/HealthBar") as ProgressBar
	_boss_hp_bar.add_theme_stylebox_override("fill", UIFactory.bar(UITheme.DANGER, 10).get_theme_stylebox("fill").duplicate())
	_boss_phase_label = _boss_bar_container.get_node("Panel/Content/PhaseLabel") as Label
	_boss_phase_label.add_theme_font_size_override("font_size", 9)
	_boss_phase_label.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	var boss_panel_style := StyleBoxFlat.new()
	boss_panel_style.bg_color = Color("#1a0a0a")
	boss_panel_style.border_color = Color(UITheme.DANGER.r, UITheme.DANGER.g, UITheme.DANGER.b, 0.6)
	boss_panel_style.set_border_width_all(1)
	boss_panel_style.set_corner_radius_all(8)
	boss_panel_style.content_margin_left = 6
	boss_panel_style.content_margin_right = 6
	boss_panel_style.content_margin_top = 6
	boss_panel_style.content_margin_bottom = 6
	(_boss_bar_container.get_node("Panel") as PanelContainer).add_theme_stylebox_override("panel", boss_panel_style)
	root.add_child(_boss_bar_container)

	# Turn order timeline is a reusable scene with a stable node contract.
	var turn_panel := preload("res://scenes/ui/combat/components/turn_order_panel.tscn").instantiate() as PanelContainer
	var turn_style := StyleBoxFlat.new()
	turn_style.bg_color = Color(0.05, 0.075, 0.13, 0.7)
	turn_style.border_color = UITheme.BORDER_SOFT
	turn_style.set_border_width_all(1)
	turn_style.set_corner_radius_all(6)
	turn_style.content_margin_left = 4
	turn_style.content_margin_right = 4
	turn_style.content_margin_top = 4
	turn_style.content_margin_bottom = 4
	turn_panel.add_theme_stylebox_override("panel", turn_style)
	var turn_caption := turn_panel.get_node("TurnRow/Caption") as Label
	turn_caption.add_theme_font_size_override("font_size", 8)
	turn_caption.add_theme_color_override("font_color", UITheme.TEXT_FAINT)
	_turn_box = turn_panel.get_node("TurnRow/TurnItems") as HBoxContainer
	root.add_child(turn_panel)

	# ===== CENTER: the battlefield =====
	# Party on the left, enemies on the right, real sprites on the stage.
	_battlefield = BATTLEFIELD_SCENE.instantiate() as Battlefield
	_battlefield.arena_id = group_id
	_battlefield.name = "Battlefield"
	_battlefield.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_battlefield.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_battlefield.custom_minimum_size = Vector2(0, 280)
	_battlefield.actor_clicked.connect(_on_battlefield_actor_clicked)
	_battlefield.cinematic_impact.connect(_camera_shake)
	root.add_child(_battlefield)

	# ===== BOTTOM: active character info + skills =====
	# Bottom combat HUD: authored panel hierarchy with script-owned data binding.
	var bottom := preload("res://scenes/ui/combat/components/combat_bottom_hud.tscn").instantiate() as HBoxContainer
	root.add_child(bottom)
	var info_panel := bottom.get_node("ActiveInfoPanel") as PanelContainer
	var roster_panel := bottom.get_node("RosterPanel") as PanelContainer
	var skills_panel := bottom.get_node("SkillsPanel") as PanelContainer
	var log_panel := bottom.get_node("LogPanel") as PanelContainer
	_style_combat_panel(info_panel, Color("#0b1220"), 8, 8)
	_style_combat_panel(roster_panel, Color("#0b1220"), 8, 8)
	_style_combat_panel(skills_panel, Color("#0b1220"), 8, 8)
	_style_combat_panel(log_panel, Color("#0a101c"), 8, 6)

	_actor_label = bottom.get_node("ActiveInfoPanel/InfoContent/ActorLabel") as Label
	_actor_label.add_theme_font_size_override("font_size", 14)
	_actor_label.add_theme_color_override("font_color", UITheme.TEXT)
	_hp_bar = bottom.get_node("ActiveInfoPanel/InfoContent/HPBar") as ProgressBar
	_hp_bar.add_theme_stylebox_override("fill", UIFactory.bar(UITheme.GREEN, 10).get_theme_stylebox("fill").duplicate())
	_energy_bar = bottom.get_node("ActiveInfoPanel/InfoContent/EnergyBar") as ProgressBar
	_energy_bar.add_theme_stylebox_override("fill", UIFactory.bar(UITheme.GOLD, 6).get_theme_stylebox("fill").duplicate())
	_status_label = bottom.get_node("ActiveInfoPanel/InfoContent/StatusLabel") as Label
	_status_label.add_theme_font_size_override("font_size", 9)
	_status_label.add_theme_color_override("font_color", UITheme.TEAL)

	var roster_caption := bottom.get_node("RosterPanel/RosterContent/RosterCaption") as Label
	roster_caption.add_theme_font_size_override("font_size", 8)
	roster_caption.add_theme_color_override("font_color", UITheme.TEXT_FAINT)
	_roster_box = bottom.get_node("RosterPanel/RosterContent/RosterItems") as VBoxContainer

	_skills_box = bottom.get_node("SkillsPanel/SkillsContent/SkillItems") as HFlowContainer
	_hint_label = bottom.get_node("SkillsPanel/SkillsContent/HintLabel") as Label
	_hint_label.add_theme_font_size_override("font_size", 10)
	_hint_label.add_theme_color_override("font_color", UITheme.TEXT_DIM)

	var log_caption := bottom.get_node("LogPanel/LogContent/LogCaption") as Label
	log_caption.add_theme_font_size_override("font_size", 8)
	log_caption.add_theme_color_override("font_color", UITheme.TEXT_FAINT)
	_log_label = bottom.get_node("LogPanel/LogContent/LogText") as RichTextLabel
	_log_label.add_theme_font_size_override("normal_font_size", 9)
	_log_label.add_theme_color_override("default_color", UITheme.TEXT_DIM)

func _start_battle() -> void:
	_resolved = false
	_pending_skill = null
	_target_team = -1
	_targeting = false
	_turn_token += 1
	_log_lines.clear()
	if _log_label != null:
		_log_label.text = ""

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

	# Stage the two teams: the party on the left, the enemies on the right.
	var party_units: Array = []
	var enemy_stage_units: Array = []
	for unit in engine.combatants:
		if unit.team == CombatEngine.PLAYER_TEAM:
			party_units.append(unit)
		else:
			enemy_stage_units.append(unit)
	if _battlefield != null:
		_battlefield.setup(party_units, enemy_stage_units)
	_build_roster(party_units)

	_log("[color=#e8c27a]Battle begins.[/color]")
	var events := engine.start()
	await _process_events(events)


## Compact party roster: portrait, name and HP for every ally.
func _build_roster(units: Array) -> void:
	if _roster_box == null:
		return
	UIFactory.clear(_roster_box)
	_roster_rows.clear()
	for unit in units:
		var row := preload("res://scenes/ui/combat/components/party_roster_entry.tscn").instantiate() as HBoxContainer
		var portrait := PortraitView.new()
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
		hp_bar.add_theme_stylebox_override("fill", UIFactory.bar(UITheme.GREEN, 6).get_theme_stylebox("fill").duplicate())
		hp_bar.max_value = maxf(1.0, unit.max_hp)
		hp_bar.value = clampf(unit.hp, 0.0, unit.max_hp)
		var hp_label := row.get_node("Info/HPLabel") as Label
		hp_label.add_theme_font_size_override("font_size", 8)
		hp_label.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		_roster_rows[unit.uid] = { "bar": hp_bar, "label": hp_label, "row": row }
		row.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_on_roster_clicked(unit))
		_roster_box.add_child(row)


func _process_events(events: Array) -> void:
	if _resolved:
		return
	var pending_deaths: Array[BattlefieldActor] = []
	for event in events:
		var event_type := str(event.get("type", ""))
		match event_type:
			"round":
				_round_label.text = "Round %d" % int(event.get("round", 1))
				_log("[color=#9aa8c2]— Round %d —[/color]" % int(event.get("round", 1)))
			"turn":
				_log("[color=#e9eef9]%s's turn.[/color]" % str(event.get("actor_name", "Unit")))
			"action":
				var actor_name := str(event.get("actor_name", "Unit"))
				var skill_name := str(event.get("skill_name", "skill"))
				_log("[color=#7fe3e0]%s uses %s.[/color]" % [actor_name, skill_name])
				var actor: BattlefieldActor = _actor_for_uid(str(event.get("actor_uid", "")))
				var target_uids: Array = event.get("target_uids", [])
				var target_uid := str(target_uids[0]) if not target_uids.is_empty() else ""
				var target: BattlefieldActor = _actor_for_uid(target_uid) if not target_uid.is_empty() else null
				_animate_attack(actor, target, str(event.get("skill_id", "")), bool(event.get("ultimate", false)))
			"damage":
				_handle_damage(event)
			"heal":
				var heal_actor: BattlefieldActor = _actor_for_uid(str(event.get("target_uid", "")))
				var heal_amount := int(event.get("amount", 0))
				if heal_amount > 0:
					_log("[color=#8fe3a0]%s recovers %d HP.[/color]" % [str(event.get("target_name", "Unit")), heal_amount])
					_float_text(heal_actor, "+%d" % heal_amount, UITheme.GREEN)
			"shield":
				_log("[color=#7fe3e0]%s gains a %d shield.[/color]" % [str(event.get("target_name", "Unit")), int(event.get("amount", 0))])
			"status":
				_log("[color=#b78bff]%s: %s[/color]" % [str(event.get("target_name", "Unit")), str(event.get("status", "")).replace("_", " ").capitalize()])
			"status_tick":
				_log("[color=#ff9f9f]%s takes %d %s damage.[/color]" % [
					str(event.get("target_name", "Unit")), int(event.get("amount", 0)), str(event.get("status", ""))
				])
				var tick_actor: BattlefieldActor = _actor_for_uid(str(event.get("target_uid", "")))
				if tick_actor != null:
					tick_actor.take_hit()
					_float_text(tick_actor, "-%d" % int(event.get("amount", 0)), UITheme.DANGER)
			"miss":
				_log("[color=#9aa8c2]%s misses.[/color]" % str(event.get("target_name", "Unit")))
			"skip":
				_log("[color=#9aa8c2]%s loses the turn (%s).[/color]" % [
					str(event.get("actor_name", "Unit")), str(event.get("reason", "stunned"))
				])
			"death":
				_log("[color=#ff7a8a]%s falls.[/color]" % str(event.get("target_name", "Unit")))
				var fallen: BattlefieldActor = _actor_for_uid(str(event.get("target_uid", "")))
				if _cinematic_finish_delay > 0.0:
					if fallen != null:
						pending_deaths.append(fallen)
				elif _battlefield != null:
					_battlefield.play_death(fallen)
			"phase":
				_log("[color=#ffc95e]%s[/color]" % str(event.get("message", "The boss changes.")))
				_show_banner(str(event.get("message", "PHASE CHANGE")))
				_camera_shake(10.0, 0.5)
				if _battlefield != null:
					var phase_number := 2
					if engine != null:
						for combatant in engine.combatants:
							if combatant.is_boss and combatant.def_id == "fallen_matron":
								phase_number = combatant.triggered_phases.size() + 1
								break
					_battlefield.play_matron_phase(phase_number)
			"victory":
				await _wait_for_cinematic_impact()
				if not is_inside_tree():
					return
				_flush_pending_deaths(pending_deaths)
				_refresh_cards()
				if _battlefield != null:
					_battlefield.play_victory_animations()
				_finish_battle(true)
				return
			"defeat":
				await _wait_for_cinematic_impact()
				if not is_inside_tree():
					return
				_flush_pending_deaths(pending_deaths)
				_refresh_cards()
				_finish_battle(false)
				return
	# Keep the party HUD / turn progression in lockstep with the Matron's
	# telegraphed pillar impact before exposing the next actor.
	await _wait_for_cinematic_impact()
	if not is_inside_tree() or _resolved:
		return
	_flush_pending_deaths(pending_deaths)
	_refresh_cards()
	_update_turn_order()
	if _resolved:
		return
	var actor: Combatant = engine.current_actor()
	if actor == null:
		return
	_refresh_skills()
	if actor.team == CombatEngine.ENEMY_TEAM:
		_schedule_enemy_turn()
	elif _auto:
		_schedule_auto_player()


func _handle_damage(event: Dictionary) -> void:
	var actor := _actor_for_uid(str(event.get("target_uid", "")))
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
	if actor != null:
		var element := str(event.get("element", "neutral"))
		var color := UITheme.element_color(element)
		if color == UITheme.TEXT_DIM:
			color = UITheme.DANGER
		if crit:
			color = UITheme.GOLD_BRIGHT
		elif advantage == "Advantage":
			color = UITheme.GREEN
		elif advantage == "Resisted":
			color = UITheme.TEXT_DIM
		var elem_color := UITheme.element_color(element)
		if elem_color == UITheme.TEXT_DIM:
			elem_color = Color(1.4, 0.9, 0.9, 1.0)
		# The attack choreography reaches impact after its anticipation and
		# lunge. Delay the hit reaction to that exact point; status ticks keep
		# their separate immediate reaction path.
		var impact_delay := IMPACT_DELAY
		var source: Combatant = engine.get_by_uid(str(event.get("actor_uid", ""))) if engine != null else null
		if source != null and source.def_id == "fallen_matron" and str(event.get("skill_id", "")) == "matron_verdict":
			# The Matron's cinematic telegraph lasts ~1.84s; land the damage on
			# the vertical corruption pillars, not during the warning sigils.
			impact_delay = 1.88
			_cinematic_finish_delay = maxf(_cinematic_finish_delay, impact_delay)
		get_tree().create_timer(impact_delay).timeout.connect(func() -> void:
			if not is_instance_valid(actor):
				return
			actor.take_hit()
			if _battlefield != null and is_instance_valid(_battlefield):
				_battlefield.spawn_elemental_burst(actor.position + Vector2(0, -18.0), element)
			if crit or amount > 50:
				_camera_shake(4.0 if crit else 2.0, 0.2))
		# Damage numbers share the exact same per-skill impact beat.
		_float_text(actor, "-%d%s" % [amount, "!" if crit else ""], color, impact_delay)


func _schedule_enemy_turn() -> void:
	_turn_token += 1
	var token := _turn_token
	var actor: Combatant = engine.current_actor() if engine != null else null
	if actor == null or actor.team != CombatEngine.ENEMY_TEAM:
		return
	var decision := CombatAI.choose(engine, engine.current_actor_index)
	var skill_id := str(decision.get("skill_id", ""))
	if skill_id.is_empty():
		return
	var skill: SkillDef = ContentDB.get_skill(skill_id)
	var skill_name := skill.display_name if skill != null else "Attack"
	var telegraph_actor := _actor_for_uid(actor.uid)
	if telegraph_actor != null:
		telegraph_actor.set_intent(skill_name)
	if _battlefield != null:
		_battlefield.set_target_team(CombatEngine.PLAYER_TEAM, true)
	_hint_label.text = "%s is preparing %s — brace for impact" % [actor.display_name, skill_name]
	# Give the player a readable reaction window before the already-selected
	# enemy action resolves. The intent is presentation only; CombatAI's chosen
	# skill and target payload remain unchanged during the telegraph.
	await get_tree().create_timer((TURN_DELAY + 0.72) / _speed).timeout
	if not is_inside_tree() or token != _turn_token or _resolved or engine == null:
		return
	if telegraph_actor != null and is_instance_valid(telegraph_actor):
		telegraph_actor.set_intent("")
	if _battlefield != null:
		_battlefield.set_target_team(-1, false)
	var current: Combatant = engine.current_actor()
	if current == null or current.team != CombatEngine.ENEMY_TEAM:
		return
	_hint_label.text = ""
	var events := engine.execute(engine.current_actor_index, skill_id, decision.get("targets", []))
	await _process_events(events)


func _schedule_auto_player() -> void:
	_turn_token += 1
	var token := _turn_token
	await get_tree().create_timer(TURN_DELAY / _speed).timeout
	if not is_inside_tree() or token != _turn_token or _resolved or engine == null:
		return
	var actor: Combatant = engine.current_actor()
	if actor == null or actor.team != CombatEngine.PLAYER_TEAM:
		return
	var decision := CombatAI.choose(engine, engine.current_actor_index)
	var skill_id := str(decision.get("skill_id", ""))
	# Defensive fallback for a newly added character with an incomplete AI
	# evaluation: Auto must never silently stall on a living player turn.
	if skill_id.is_empty() and not actor.skills.is_empty():
		skill_id = str(actor.skills[0])
		var fallback_skill: SkillDef = ContentDB.get_skill(skill_id)
		if fallback_skill != null and fallback_skill.target == "single_enemy":
			var first_enemy := engine.living_indices(CombatEngine.ENEMY_TEAM)
			decision["targets"] = [first_enemy[0]] if not first_enemy.is_empty() else []
	if skill_id.is_empty():
		_log("[color=#ffbf69]Auto could not find a usable skill for %s.[/color]" % actor.display_name)
		return
	var events := engine.execute(engine.current_actor_index, skill_id, decision.get("targets", []))
	await _process_events(events)


# ------------------------------------------------------------------ actions

func _refresh_skills() -> void:
	UIFactory.clear(_skills_box)
	_pending_skill = null
	_targeting = false
	_target_team = -1
	var actor: Combatant = engine.current_actor()
	if actor == null or _resolved:
		_actor_label.text = "Battle resolved."
		_hint_label.text = ""
		return
	if actor.team != CombatEngine.PLAYER_TEAM:
		_actor_label.text = "Enemy turn — " + actor.display_name
		_hint_label.text = "Watch enemy intent markers. Gold rings show the threatened party."
		return
	_actor_label.text = "%s — choose an action" % actor.display_name
	_hint_label.text = "Esc cancels targeting" if _targeting else "Select a skill, then tap a gold-ringed foe. Elemental weaknesses are shown on impact."
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
	var energy_text := "FREE" if skill.energy_gain <= 0 else "%d EN" % int(skill.energy_gain)
	var detail := "%s | %s | PWR %d | %s" % [skill.element.capitalize(), skill.kind.capitalize(), int(skill.power), energy_text]
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
	var actor: Combatant = engine.current_actor()
	if actor == null or actor.team != CombatEngine.PLAYER_TEAM:
		return
	if skill.ultimate and not actor.ultimate_ready():
		return
	if skill.target == "single_enemy" or skill.target == "single_ally":
		_pending_skill = skill
		_targeting = true
		_target_team = CombatEngine.ENEMY_TEAM if skill.target == "single_enemy" else CombatEngine.PLAYER_TEAM
		_hint_label.text = "Tap a gold-ringed foe to target · Esc cancels" if _target_team == CombatEngine.ENEMY_TEAM else "Choose an ally in the party list · Esc cancels"
		if _battlefield != null:
			_battlefield.set_target_team(_target_team, true)
		_refresh_cards()
	else:
		_execute_current(skill.id, [])


## Clicking a combatant on the battlefield (enemy) picks it as the target.
func _on_battlefield_actor_clicked(actor: BattlefieldActor) -> void:
	if not _targeting or _pending_skill == null or actor == null:
		return
	if actor.unit == null or actor.unit.team != _target_team or not actor.unit.is_alive():
		return
	_execute_current(_pending_skill.id, [actor.unit.combat_index])


## Clicking an ally in the party roster picks it as the target.
func _on_roster_clicked(unit: Combatant) -> void:
	if not _targeting or _pending_skill == null or unit == null:
		return
	if unit.team != _target_team or not unit.is_alive():
		return
	_execute_current(_pending_skill.id, [unit.combat_index])


## The attack choreography lives on the battlefield; the engine has already
## resolved the damage, so this never changes the outcome.
func _animate_attack(attacker: BattlefieldActor, target: BattlefieldActor,
		skill_id: String = "", ultimate: bool = false) -> void:
	if _battlefield == null or attacker == null:
		return
	var element := "neutral"
	if engine != null and attacker.unit != null:
		var combat_index := attacker.unit.combat_index
		if combat_index >= 0 and combat_index < engine.combatants.size():
			var source: Combatant = engine.combatants[combat_index]
			element = str(source.element)
	_battlefield.play_attack(attacker, target, element, skill_id, ultimate)
	if attacker.unit != null and attacker.unit.def_id == "fallen_matron" and (ultimate or skill_id == "matron_verdict"):
		_camera_shake(8.0, 0.42)
	elif attacker.unit != null and attacker.unit.def_id == "kael" and ultimate:
		# A short anticipation tremor followed by the larger final-impact shake.
		_camera_shake(3.0, 0.24)
		get_tree().create_timer(0.78).timeout.connect(func() -> void:
			if is_instance_valid(self):
				_camera_shake(10.0, 0.52)
		)


func _execute_current(skill_id: String, targets: Array) -> void:
	if engine == null or _resolved:
		return
	var actor: Combatant = engine.current_actor()
	if actor == null:
		return
	# Purely presentational: ULTIMATE skills get a short animated name banner.
	# Turn order, targeting, event processing and battle resolution are untouched.
	var played_skill: SkillDef = ContentDB.get_skill(skill_id)
	if played_skill != null and played_skill.ultimate:
		_show_banner(played_skill.display_name)
	_cancel_targeting()
	var events := engine.execute(engine.current_actor_index, skill_id, targets)
	await _process_events(events)


func _cancel_targeting() -> void:
	_pending_skill = null
	_targeting = false
	if _battlefield != null:
		_battlefield.set_target_team(_target_team, false)
	_target_team = -1
	_hint_label.text = ""
	_refresh_cards()

func _on_auto_toggled(value: bool) -> void:
	_auto = value
	_turn_token += 1 # Cancel any queued auto action when the player switches mode.
	_auto_button.text = "AUTO  ON" if value else "AUTO  OFF"
	_auto_button.add_theme_color_override("font_color", UITheme.GOLD if value else UITheme.TEXT_DIM)
	if value and engine != null and not _resolved:
		# Auto owns targeting as well as skill choice; clear any half-selected
		# manual action before handing the turn to the decision system.
		if _targeting:
			_pending_skill = null
			_targeting = false
			_target_team = -1
			if _battlefield != null:
				_battlefield.set_target_team(-1, false)
		var actor: Combatant = engine.current_actor()
		if actor != null and actor.team == CombatEngine.PLAYER_TEAM:
			_schedule_auto_player()


func _cycle_speed() -> void:
	if is_equal_approx(_speed, 1.0):
		_speed = 1.6
	elif is_equal_approx(_speed, 1.6):
		_speed = 2.4
	else:
		_speed = 1.0
	_speed_button.text = ("%.1f× speed" % _speed).replace(".0×", "×")


# ------------------------------------------------------------------ visuals

func _refresh_cards() -> void:
	if engine == null:
		return
	if _boss_hp_bar != null and _boss_hp_bar.visible:
		for unit in engine.combatants:
			var boss: Combatant = unit
			if boss.is_boss and boss.is_alive():
				_boss_hp_bar.value = boss.hp
				if _boss_phase_label != null:
					_boss_phase_label.text = "Phase %d" % (boss.triggered_phases.size() + 1)
	# Update active character info panel.
	if engine.current_actor() != null and _hp_bar != null:
		var active: Combatant = engine.current_actor()
		_hp_bar.max_value = maxf(1.0, active.max_hp)
		_hp_bar.value = clampf(active.hp, 0.0, active.max_hp)
		_energy_bar.max_value = maxf(1.0, active.max_energy)
		_energy_bar.value = clampf(active.energy, 0.0, active.max_energy)
		_actor_label.text = active.display_name
		_status_label.text = UIFactory.status_text(active)
	# Refresh the battlefield: HP plates, the active marker and the roster.
	if _battlefield != null:
		_battlefield.refresh_actors()
		_battlefield.set_active(engine.current_actor().uid if engine.current_actor() != null else "")
	_refresh_roster()


func _refresh_roster() -> void:
	if engine == null:
		return
	for unit in engine.combatants:
		if unit.team != CombatEngine.PLAYER_TEAM:
			continue
		var entry: Dictionary = _roster_rows.get(unit.uid, {})
		if entry.is_empty():
			continue
		var bar: ProgressBar = entry.get("bar")
		var label: Label = entry.get("label")
		if bar != null:
			bar.max_value = maxf(1.0, unit.max_hp)
			bar.value = clampf(unit.hp, 0.0, unit.max_hp)
		if label != null:
			label.text = "%d/%d" % [int(ceil(unit.hp)), int(round(unit.max_hp))]


func _update_turn_order() -> void:
	if _turn_box == null or engine == null:
		return
	UIFactory.clear(_turn_box)
	# The active actor is always first. The remaining portraits are the next
	# turns in the engine's real initiative order, so the strip advances after
	# every action instead of showing a static party list.
	# Build one complete initiative cycle from combatant indices, not portrait
	# names or UIDs. The active actor leads; after acting, the engine advances
	# the pointer and that actor naturally appears at the tail of the next cycle.
	# Index-based deduplication prevents any unit icon from appearing twice.
	var sequence: Array[int] = []
	var seen_indices: Dictionary = {}
	var living_count := engine.living(CombatEngine.PLAYER_TEAM).size() + engine.living(CombatEngine.ENEMY_TEAM).size()
	var active_index := engine.current_actor_index
	if active_index >= 0 and active_index < engine.combatants.size():
		var active_unit: Combatant = engine.combatants[active_index]
		if active_unit.is_alive():
			sequence.append(active_index)
			seen_indices[active_index] = true
	# Walk forward through the current initiative order and wrap once. This is
	# the same queue the engine is executing, not a separately reconstructed
	# list of portraits.
	if not engine.order.is_empty() and engine.turn_pointer >= 0:
		for offset in range(1, engine.order.size() + 1):
			var order_position := (engine.turn_pointer + offset) % engine.order.size()
			var next_index := int(engine.order[order_position])
			if next_index < 0 or next_index >= engine.combatants.size() or seen_indices.has(next_index):
				continue
			var next_unit: Combatant = engine.combatants[next_index]
			if next_unit.is_alive():
				sequence.append(next_index)
				seen_indices[next_index] = true
	# Include newly summoned / newly alive units that were not in the round's
	# original order, preserving deterministic speed order.
	if sequence.size() < living_count:
		var remaining_indices := engine.living_indices(CombatEngine.PLAYER_TEAM) + engine.living_indices(CombatEngine.ENEMY_TEAM)
		remaining_indices.sort_custom(func(a: int, b: int) -> bool:
			return engine.unit_speed(engine.combatants[a]) > engine.unit_speed(engine.combatants[b])
		)
		for next_index in remaining_indices:
			if not seen_indices.has(next_index):
				sequence.append(next_index)
				seen_indices[next_index] = true
	if sequence.is_empty():
		_turn_box.add_child(UIFactory.label("—", 10, UITheme.TEXT_FAINT))
		return
	for index in sequence.size():
		var unit: Combatant = engine.combatants[sequence[index]]
		if unit == null:
			continue
		var portrait := PortraitView.new()
		portrait.show_frame = true
		portrait.show_rarity_effect = false
		portrait.selected = index == 0
		portrait.dim = not unit.is_alive()
		var definition := ContentDB.get_character(unit.def_id) if unit.team == CombatEngine.PLAYER_TEAM else null
		if definition != null:
			portrait.setup_character(definition)
		else:
			portrait.setup(unit.palette, "Monster" if unit.team == CombatEngine.ENEMY_TEAM else "Human", unit.element, unit.rarity, unit.def_id.hash())
			if unit.def_id == "fallen_matron":
				var matron_phase := 1
				if unit.hp_ratio() <= 0.33:
					matron_phase = 3
				elif unit.hp_ratio() <= 0.66:
					matron_phase = 2
				var matron_atlas := load("res://assets/enemies/fallen_matron/phase_%d.png" % matron_phase) as Texture2D
				if matron_atlas != null:
					# Use a head-and-shoulders crop for the compact initiative icon.
					var matron_portrait := AtlasTexture.new()
					matron_portrait.atlas = matron_atlas
					matron_portrait.region = Rect2(62, 0, 296, 250)
					portrait.set_portrait_texture(matron_portrait)
		portrait.tooltip_text = unit.display_name
		_turn_box.add_child(portrait)
		# PortraitView's general-purpose default is 96px; override it after
		# entering the tree so the initiative strip stays compact.
		portrait.custom_minimum_size = Vector2(38, 42)
		portrait.size = Vector2(38, 42)
		if index < sequence.size() - 1:
			var arrow := UIFactory.label("›", 13, UITheme.GOLD if index == 0 else UITheme.TEXT_FAINT)
			arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_turn_box.add_child(arrow)


func _actor_for_uid(uid: String) -> BattlefieldActor:
	if _battlefield == null:
		return null
	return _battlefield.actor_for_uid(uid)


## A floating damage / heal number over a battlefield actor.
func _float_text(actor: BattlefieldActor, text: String, color: Color, delay: float = 0.16) -> void:
	if _battlefield == null or actor == null:
		return
	_battlefield.spawn_damage_number(actor, text, color, delay)


func _show_banner(text: String) -> void:
	var banner := preload("res://scenes/ui/combat/components/battle_event_banner.tscn").instantiate() as Label
	banner.text = text
	banner.add_theme_font_size_override("font_size", 26)
	banner.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT)
	banner.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.05, 0.95))
	banner.add_theme_constant_override("outline_size", 7)
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
	# If the Matron's Verdict ended the battle, let its telegraphed pillars land
	# before the result overlay replaces the arena.
	if _cinematic_finish_delay > 0.0:
		var finish_delay := _cinematic_finish_delay
		_cinematic_finish_delay = 0.0
		await get_tree().create_timer(finish_delay).timeout
		if not is_inside_tree():
			return
	_refresh_cards()
	UIFactory.clear(_skills_box)
	_actor_label.text = "Victory" if victory else "Defeat"
	_hint_label.text = ""
	_pending_rewards = GameState.build_battle_rewards(group_id, true) if victory else {}
	_show_result(victory)


func _show_result(victory: bool) -> void:
	if _result_layer != null and is_instance_valid(_result_layer):
		_result_layer.queue_free()
	_result_layer = preload("res://scenes/ui/combat/components/battle_result_overlay.tscn").instantiate() as Control
	add_child(_result_layer)
	var panel := _result_layer.get_node("Center/Panel") as PanelContainer
	_style_combat_panel(panel, Color("#0b1120"), 16, 24)
	var panel_style := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	panel_style.border_color = Color(UITheme.GOLD.r, UITheme.GOLD.g, UITheme.GOLD.b, 0.5) if victory else Color(UITheme.DANGER.r, UITheme.DANGER.g, UITheme.DANGER.b, 0.5)
	panel.add_theme_stylebox_override("panel", panel_style)

	var content := _result_layer.get_node("Center/Panel/Content") as VBoxContainer
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
		rewards_row.add_child(UIFactory.chip("+%s Gold" % UIFactory.number(int(_pending_rewards.get("gold", 0))), UITheme.GOLD))
		rewards_row.add_child(UIFactory.chip("+%s Crystals" % UIFactory.number(int(_pending_rewards.get("crystals", 0))), UITheme.TEAL))
		rewards_row.add_child(UIFactory.chip("+%s XP" % UIFactory.number(int(_pending_rewards.get("xp", 0))), UITheme.GREEN))
		for item_id in _pending_rewards.get("items", {}).keys():
			var item: Dictionary = ContentDB.get_item(str(item_id))
			details.add_child(UIFactory.label("• %s ×%d" % [str(item.get("name", item_id)), int(_pending_rewards["items"][item_id])], 12, UITheme.TEXT_DIM))
	else:
		defeat_details.add_theme_font_size_override("font_size", 12)
		defeat_details.add_theme_color_override("font_color", UITheme.TEXT_DIM)

	var actions := content.get_node("Actions") as HBoxContainer
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


func _retry() -> void:
	if _result_layer != null and is_instance_valid(_result_layer):
		_result_layer.queue_free()
		_result_layer = null
	_start_battle()


func _confirm_retreat() -> void:
	if _resolved or _confirm_layer != null:
		return
	_confirm_layer = preload("res://scenes/ui/combat/components/retreat_confirmation_overlay.tscn").instantiate() as Control
	add_child(_confirm_layer)
	var panel := _confirm_layer.get_node("Center/Panel") as PanelContainer
	_style_combat_panel(panel, Color("#0b1120"), 14, 20)
	var panel_style := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	panel_style.border_color = Color(UITheme.DANGER.r, UITheme.DANGER.g, UITheme.DANGER.b, 0.5)
	panel.add_theme_stylebox_override("panel", panel_style)
	var content := _confirm_layer.get_node("Center/Panel/Content") as VBoxContainer
	var title := content.get_node("Title") as Label
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", UITheme.DANGER)
	var description := content.get_node("Description") as Label
	description.add_theme_font_size_override("font_size", 12)
	description.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	var stay := content.get_node("Actions/StayButton") as Button
	stay.add_theme_stylebox_override("normal", UIFactory.button("Keep Fighting", true).get_theme_stylebox("normal").duplicate())
	stay.pressed.connect(func() -> void:
		_confirm_layer.queue_free()
		_confirm_layer = null
	)
	var leave := content.get_node("Actions/LeaveButton") as Button
	leave.add_theme_stylebox_override("normal", UIFactory.button("Retreat", false, true).get_theme_stylebox("normal").duplicate())
	leave.pressed.connect(func() -> void: _claim(false))


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
		GameState.apply_battle_result(group_id, true, _pending_rewards)
	EventBus.battle_finished.emit({
		"group_id": group_id,
		"victory": victory,
		"rewards": _pending_rewards,
	})
	closed.emit()
	queue_free()


## Battlefield presentation snapshot (presentation overhaul). Purely visual
## metadata; never read by the combat engine.
func presentation_report() -> Dictionary:
	var report := {
		"screen": "combat",
		"battlefield": _battlefield != null,
	}
	if _battlefield != null:
		report["battlefield_report"] = _battlefield.presentation_report()
	return report


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


func _wait_for_cinematic_impact() -> void:
	if _cinematic_finish_delay <= 0.0:
		return
	var impact_wait := _cinematic_finish_delay
	_cinematic_finish_delay = 0.0
	await get_tree().create_timer(impact_wait).timeout


func _flush_pending_deaths(pending_deaths: Array[BattlefieldActor]) -> void:
	if _battlefield == null:
		return
	for fallen in pending_deaths:
		if is_instance_valid(fallen):
			_battlefield.play_death(fallen)

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
const COMBAT_LAYOUT_SCENE: PackedScene = preload("res://scenes/ui/components/combat_screen_layout.tscn")
const PORTRAIT_VIEW_SCENE: PackedScene = preload("res://scenes/ui/components/portrait_view.tscn")

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
var _resolved: bool = false
var _boss_bar_container: VBoxContainer = null
var _boss_name_label: Label = null
var _boss_hp_bar: ProgressBar = null
var _boss_phase_label: Label = null
var _hp_bar: ProgressBar = null
var _energy_bar: ProgressBar = null
var _status_label: Label = null
var _actor_label: Label = null
var _animating: bool = false
var _claimed: bool = false
var _turn_token: int = 0
var _speed: float = 1.0
var _auto: bool = false
var _pending_rewards: Dictionary = {}
var _cinematic_finish_delay: float = 0.0
var _result_layer: Control = null
var _confirm_layer: Control = null
var _feedback: CombatFeedbackComponent
var _turn_flow: CombatTurnFlowComponent
var _targeting_component: CombatTargetingComponent
var _turn_order_component: CombatTurnOrderComponent
var _result_component: CombatResultComponent
var _event_presentation_component: CombatEventPresentationComponent
var _hud_component: CombatHudComponent
var _layout_component: CombatLayoutComponent
var _session_component: CombatSessionComponent
var _input_component: CombatInputComponent


func _ready() -> void:
	UIFactory.set_full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	_layout_component = get_node_or_null("LayoutBuilder") as CombatLayoutComponent
	_feedback = get_node_or_null("Feedback") as CombatFeedbackComponent
	_turn_flow = get_node_or_null("TurnFlow") as CombatTurnFlowComponent
	_targeting_component = get_node_or_null("Targeting") as CombatTargetingComponent
	_turn_order_component = get_node_or_null("TurnOrder") as CombatTurnOrderComponent
	_result_component = get_node_or_null("Results") as CombatResultComponent
	_event_presentation_component = get_node_or_null("Events") as CombatEventPresentationComponent
	_hud_component = get_node_or_null("HUD") as CombatHudComponent
	_session_component = get_node_or_null("Session") as CombatSessionComponent
	_input_component = get_node_or_null("Input") as CombatInputComponent
	if _layout_component == null or _feedback == null or _turn_flow == null or _targeting_component == null or _turn_order_component == null or _result_component == null or _event_presentation_component == null or _hud_component == null or _session_component == null or _input_component == null:
		push_error("CombatScreen is missing an authored component child.")
		return
	_layout_component.bind(self)
	_layout_component.build()
	_feedback.bind(self, _battlefield, _log_label, _boss_bar_container)
	_turn_flow.bind(self)
	_targeting_component.bind(self)
	_turn_order_component.bind(self)
	_result_component.bind(self)
	_event_presentation_component.bind(self)
	_hud_component.bind(self)
	_session_component.bind(self)
	_input_component.bind(self)
	_start_battle()


func _unhandled_input(event: InputEvent) -> void:
	if _input_component != null:
		_input_component.handle_unhandled_input(event)

# ------------------------------------------------------------------ build UI

func _build_background() -> void:
	if _layout_component != null:
		_layout_component.build_background()

func _style_combat_panel(panel: PanelContainer, fill: Color, radius: int, margin: int) -> void:
	if _layout_component != null:
		_layout_component.style_combat_panel(panel, fill, radius, margin)

func _build_layout() -> void:
	if _layout_component != null:
		_layout_component.build_layout()

func _start_battle() -> void:
	if _session_component != null:
		await _session_component.start_battle()

## Compact party roster: portrait, name and HP for every ally.
func _build_roster(units: Array) -> void:
	if _hud_component != null:
		_hud_component.build_roster(units)

func _process_events(events: Array) -> void:
	if _event_presentation_component != null:
		await _event_presentation_component.process_events(events)


func _handle_damage(event: Dictionary) -> void:
	if _event_presentation_component != null:
		_event_presentation_component.handle_damage(event)

func _schedule_enemy_turn() -> void:
	if _turn_flow != null:
		_turn_flow.schedule_enemy_turn()


func _schedule_auto_player() -> void:
	if _turn_flow != null:
		_turn_flow.schedule_auto_player()


# ------------------------------------------------------------------ actions

func _refresh_skills() -> void:
	if _hud_component != null:
		_hud_component.refresh_skills()

func _add_skill_button(skill: SkillDef, actor: Combatant) -> void:
	if _hud_component != null:
		_hud_component.add_skill_button(skill, actor)

func _select_skill(skill: SkillDef) -> void:
	if _targeting_component != null:
		_targeting_component.select_skill(skill)


func _on_battlefield_actor_clicked(actor: BattlefieldActor) -> void:
	if _targeting_component != null:
		_targeting_component.on_battlefield_actor_clicked(actor)


func _on_roster_clicked(unit: Combatant) -> void:
	if _targeting_component != null:
		_targeting_component.on_roster_clicked(unit)


## The attack choreography lives on the battlefield; the engine has already
## resolved the damage, so this never changes the outcome.
func _animate_attack(attacker: BattlefieldActor, target: BattlefieldActor, skill_id: String = "", ultimate: bool = false) -> void:
	if _event_presentation_component != null:
		_event_presentation_component.animate_attack(attacker, target, skill_id, ultimate)

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
	if _targeting_component != null:
		_targeting_component.cancel_targeting()


func _on_auto_toggled(value: bool) -> void:
	if _hud_component != null:
		_hud_component.on_auto_toggled(value)

func _cycle_speed() -> void:
	if _hud_component != null:
		_hud_component.cycle_speed()

func _refresh_cards() -> void:
	if _hud_component != null:
		_hud_component.refresh_cards()

func _refresh_roster() -> void:
	if _hud_component != null:
		_hud_component.refresh_roster()

func _update_turn_order() -> void:
	if _turn_order_component != null:
		_turn_order_component.refresh()

func _actor_for_uid(uid: String) -> BattlefieldActor:
	if _battlefield == null:
		return null
	return _battlefield.actor_for_uid(uid)


## Feedback is a child component so transient effects never own battle rules.
func _float_text(actor: BattlefieldActor, text: String, color: Color, delay: float = 0.16) -> void:
	if _feedback != null:
		_feedback.float_text(actor, text, color, delay)


func _show_banner(text: String) -> void:
	if _feedback != null:
		_feedback.show_banner(text)


func _log(line: String) -> void:
	if _feedback != null:
		_feedback.log(line)


func _camera_shake(intensity: float, duration: float) -> void:
	if _feedback != null:
		_feedback.camera_shake(intensity, duration)


# ------------------------------------------------------------------ finish


func _finish_battle(victory: bool) -> void:
	if _result_component != null:
		_result_component.finish_battle(victory)


func _show_result(victory: bool) -> void:
	if _result_component != null:
		_result_component.show_result(victory)


func _retry() -> void:
	if _result_component != null:
		_result_component.retry()


func _confirm_retreat() -> void:
	if _result_component != null:
		_result_component.confirm_retreat()


func _claim(victory: bool) -> void:
	if _result_component != null:
		_result_component.claim(victory)

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

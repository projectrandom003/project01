class_name BossController
extends Node

signal boss_initialized(boss_id: String)
signal phase_changed(from_phase: int, to_phase: int)
signal boss_defeated(boss_id: String)

@export var boss_config: Resource
@export var boss_id: String = ""
@export var phase_controller_path: NodePath
@export var state_machine_path: NodePath
@export var attack_controller_path: NodePath
@export var skill_controller_path: NodePath
@export var animation_controller_path: NodePath
@export var health_display_path: NodePath
@export var presentation_path: NodePath
@export var transition_effects_path: NodePath

var current_phase: int = 0
var phase_controller: Node = null
var state_machine: Node = null
var attack_controller: Node = null
var skill_controller: Node = null
var animation_controller: Node = null
var health_display: Node = null
var presentation: Node = null
var transition_effects: Node = null


func _ready() -> void:
	_resolve()
	boss_initialized.emit(boss_id)


func _resolve() -> void:
	var base := get_parent()
	phase_controller = get_node_or_null(phase_controller_path) if not phase_controller_path.is_empty() else base.get_node_or_null("BossPhaseController") if base else null
	state_machine = get_node_or_null(state_machine_path) if not state_machine_path.is_empty() else base.get_node_or_null("BossStateMachine") if base else null
	attack_controller = get_node_or_null(attack_controller_path) if not attack_controller_path.is_empty() else base.get_node_or_null("BossAttackController") if base else null
	skill_controller = get_node_or_null(skill_controller_path) if not skill_controller_path.is_empty() else base.get_node_or_null("BossSkillController") if base else null
	animation_controller = get_node_or_null(animation_controller_path) if not animation_controller_path.is_empty() else base.get_node_or_null("BossAnimationController") if base else null
	health_display = get_node_or_null(health_display_path) if not health_display_path.is_empty() else base.get_node_or_null("BossHealthDisplay") if base else null
	presentation = get_node_or_null(presentation_path) if not presentation_path.is_empty() else base.get_node_or_null("BossPresentation") if base else null
	transition_effects = get_node_or_null(transition_effects_path) if not transition_effects_path.is_empty() else base.get_node_or_null("BossTransitionEffects") if base else null


func set_phase(new_phase: int) -> void:
	if new_phase == current_phase:
		return
	var prev := current_phase
	current_phase = new_phase
	phase_changed.emit(prev, new_phase)
	if transition_effects != null and transition_effects.has_method("play_transition"):
		transition_effects.call("play_transition", prev, new_phase)
	if presentation != null and presentation.has_method("on_phase_changed"):
		presentation.call("on_phase_changed", prev, new_phase)


func mark_defeated() -> void:
	boss_defeated.emit(boss_id)

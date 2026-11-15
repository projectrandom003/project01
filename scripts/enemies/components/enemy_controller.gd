class_name EnemyController
extends Node

signal initialized
signal state_changed(from_state: StringName, to_state: StringName)
signal encounter_started
signal encounter_finished(victory: bool)
signal defeated
signal respawned

@export var stats_config: Resource
@export var detection_config: Resource
@export var movement_config: Resource
@export var aggro_config: Resource
@export var attack_config: Resource
@export var skill_config: Resource
@export var behaviour_config: Resource

@export var movement_path: NodePath
@export var detection_path: NodePath
@export var targeting_path: NodePath
@export var combat_path: NodePath
@export var health_path: NodePath
@export var status_path: NodePath
@export var animation_path: NodePath
@export var interaction_path: NodePath
@export var audio_path: NodePath
@export var vfx_path: NodePath
@export var visual_path: NodePath
@export var state_machine_path: NodePath

var owner_enemy: Node = null
var movement: Node = null
var detection: Node = null
var targeting: Node = null
var combat: Node = null
var health: Node = null
var status_effects: Node = null
var animation: Node = null
var interaction: Node = null
var audio: Node = null
var vfx: Node = null
var visual: Node = null
var state_machine: Node = null


func _ready() -> void:
	owner_enemy = get_parent()
	_resolve_components()
	initialized.emit()


func _resolve_components() -> void:
	movement = get_node_or_null(movement_path) if not movement_path.is_empty() else get_parent().get_node_or_null("Components/EnemyMovement")
	detection = get_node_or_null(detection_path) if not detection_path.is_empty() else get_parent().get_node_or_null("Components/EnemyDetection")
	targeting = get_node_or_null(targeting_path) if not targeting_path.is_empty() else get_parent().get_node_or_null("Components/EnemyTargeting")
	combat = get_node_or_null(combat_path) if not combat_path.is_empty() else get_parent().get_node_or_null("Components/EnemyCombat")
	health = get_node_or_null(health_path) if not health_path.is_empty() else get_parent().get_node_or_null("Components/EnemyHealth")
	status_effects = get_node_or_null(status_path) if not status_path.is_empty() else get_parent().get_node_or_null("Components/EnemyStatusEffects")
	animation = get_node_or_null(animation_path) if not animation_path.is_empty() else get_parent().get_node_or_null("Components/EnemyAnimation")
	interaction = get_node_or_null(interaction_path) if not interaction_path.is_empty() else get_parent().get_node_or_null("Components/EnemyInteraction")
	audio = get_node_or_null(audio_path) if not audio_path.is_empty() else get_parent().get_node_or_null("Components/EnemyAudio")
	vfx = get_node_or_null(vfx_path) if not vfx_path.is_empty() else get_parent().get_node_or_null("Components/EnemyVFX")
	visual = get_node_or_null(visual_path) if not visual_path.is_empty() else get_parent().get_node_or_null("Components/EnemyVisual")
	state_machine = get_node_or_null(state_machine_path) if not state_machine_path.is_empty() else get_parent().get_node_or_null("StateMachine")
	if state_machine != null and state_machine.has_signal("state_changed") and not state_machine.state_changed.is_connected(_on_state_changed):
		state_machine.state_changed.connect(_on_state_changed)


func request_state(state_name: StringName, context: Dictionary = {}) -> bool:
	if state_machine != null and state_machine.has_method("set_state"):
		return bool(state_machine.call("set_state", state_name, context))
	return false


func process_ai(delta: float, context: Dictionary = {}) -> void:
	if state_machine != null and state_machine.has_method("process_state"):
		state_machine.call("process_state", delta, context)


func physics_process_ai(delta: float, context: Dictionary = {}) -> void:
	if state_machine != null and state_machine.has_method("physics_process_state"):
		state_machine.call("physics_process_state", delta, context)


func emit_encounter_started() -> void:
	encounter_started.emit()


func emit_encounter_finished(victory: bool) -> void:
	encounter_finished.emit(victory)


func emit_defeated() -> void:
	defeated.emit()


func emit_respawned() -> void:
	respawned.emit()


func _on_state_changed(from_state: StringName, to_state: StringName) -> void:
	state_changed.emit(from_state, to_state)

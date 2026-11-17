class_name BossTransitionEffects
extends Node

signal transition_started(from_phase: int, to_phase: int)
signal transition_finished(from_phase: int, to_phase: int)

@export var animation_player_path: NodePath
var animation_player: AnimationPlayer = null


func _ready() -> void:
	if not animation_player_path.is_empty():
		animation_player = get_node_or_null(animation_player_path) as AnimationPlayer


func play_transition(from_phase: int, to_phase: int) -> void:
	transition_started.emit(from_phase, to_phase)
	if animation_player != null and animation_player.has_animation("phase_transition"):
		animation_player.play("phase_transition")
	transition_finished.emit(from_phase, to_phase)

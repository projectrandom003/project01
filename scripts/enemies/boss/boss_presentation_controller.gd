class_name BossPresentationController
extends Node

signal presentation_ready(boss_id: String)
signal phase_presentation_requested(boss_id: String, phase: int, message: String)

@export var boss_id: String = ""
@export var presentation_rig_path: NodePath
var presentation_rig: Node = null


func _ready() -> void:
	if not presentation_rig_path.is_empty():
		presentation_rig = get_node_or_null(presentation_rig_path)
	presentation_ready.emit(boss_id)


func on_phase_changed(_from_phase: int, to_phase: int, message: String = "") -> void:
	phase_presentation_requested.emit(boss_id, to_phase, message)
	if presentation_rig != null and presentation_rig.has_method("show_phase_transition"):
		presentation_rig.call("show_phase_transition", boss_id, to_phase, message)

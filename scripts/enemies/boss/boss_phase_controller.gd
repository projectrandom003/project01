class_name BossPhaseController
extends Node

signal phase_transition_requested(phase_index: int, reason: String)
signal phase_applied(phase_index: int)

@export var boss_config: Resource
var active_phase: int = 0


func evaluate_hp_ratio(hp_ratio: float) -> int:
	if boss_config == null or not ("phases" in boss_config) or (boss_config.phases as Array).is_empty():
		return active_phase
	var chosen := active_phase
	var phases: Array = boss_config.phases
	for i in phases.size():
		var p = phases[i]
		if p != null and ("hp_threshold_ratio" in p) and hp_ratio <= float(p.hp_threshold_ratio):
			chosen = maxi(chosen, i)
	if chosen != active_phase:
		phase_transition_requested.emit(chosen, "hp_threshold")
	return chosen


func apply_phase(index: int) -> void:
	active_phase = index
	phase_applied.emit(index)

class_name BossHealthDisplay
extends Node

signal health_display_updated(current_hp: float, max_hp: float)
signal phase_display_updated(phase: int, label_text: String)

@export var boss_name: String = ""
@export var show_phases: bool = true


func update_health(current_hp: float, max_hp: float) -> void:
	health_display_updated.emit(current_hp, max_hp)


func update_phase(phase: int, label_text: String = "") -> void:
	if not show_phases:
		return
	phase_display_updated.emit(phase, label_text)

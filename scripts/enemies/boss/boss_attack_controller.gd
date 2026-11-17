class_name BossAttackController
extends Node

signal attack_pattern_selected(pattern_id: String)
signal attack_executed(pattern_id: String, targets: Array)

@export var available_patterns: Array[String] = []


func select_pattern(context: Dictionary = {}) -> String:
	if available_patterns.is_empty():
		return ""
	var idx := int(context.get("pattern_index", 0)) % available_patterns.size()
	var pattern := available_patterns[idx]
	attack_pattern_selected.emit(pattern)
	return pattern


func execute_pattern(pattern_id: String, targets: Array = []) -> void:
	attack_executed.emit(pattern_id, targets)

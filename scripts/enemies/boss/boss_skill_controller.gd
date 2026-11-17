class_name BossSkillController
extends Node

signal skill_selected(skill_id: String)
signal skill_cast(skill_id: String, targets: Array)

@export var skill_ids: Array[String] = []


func select_skill(context: Dictionary = {}) -> String:
	if skill_ids.is_empty():
		return ""
	var idx := int(context.get("skill_index", 0)) % skill_ids.size()
	var skill_id := skill_ids[idx]
	skill_selected.emit(skill_id)
	return skill_id


func cast_skill(skill_id: String, targets: Array = []) -> void:
	skill_cast.emit(skill_id, targets)

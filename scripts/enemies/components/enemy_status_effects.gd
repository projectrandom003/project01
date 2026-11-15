class_name EnemyStatusEffects
extends Node

signal status_applied(status_id: String, duration: float, potency: float)
signal status_removed(status_id: String)
signal statuses_changed(active_statuses: Dictionary)

var statuses: Dictionary = {}


func apply_status(status_id: String, duration: float = 0.0, potency: float = 1.0) -> void:
	statuses[status_id] = {"duration": duration, "potency": potency}
	status_applied.emit(status_id, duration, potency)
	statuses_changed.emit(statuses.duplicate(true))


func remove_status(status_id: String) -> void:
	if statuses.has(status_id):
		statuses.erase(status_id)
		status_removed.emit(status_id)
		statuses_changed.emit(statuses.duplicate(true))


func clear_statuses() -> void:
	if statuses.is_empty():
		return
	var keys := statuses.keys()
	statuses.clear()
	for k in keys:
		status_removed.emit(str(k))
	statuses_changed.emit({})


func has_status(status_id: String) -> bool:
	return statuses.has(status_id)


func tick(delta: float) -> void:
	if statuses.is_empty():
		return
	var expired: Array[String] = []
	for k in statuses.keys():
		var data: Dictionary = statuses[k]
		var dur := float(data.get("duration", 0.0))
		if dur > 0.0:
			dur -= delta
			data["duration"] = dur
			statuses[k] = data
			if dur <= 0.0:
				expired.append(str(k))
	for k in expired:
		remove_status(k)

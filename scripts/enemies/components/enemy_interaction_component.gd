class_name EnemyInteractionComponent
extends Node

signal interaction_started(interactor: Node)
signal interaction_completed(interactor: Node)
signal interaction_enabled_changed(enabled: bool)

@export var enabled: bool = true
@export var prompt_text: String = "Fight"


func set_enabled(value: bool) -> void:
	if enabled == value:
		return
	enabled = value
	interaction_enabled_changed.emit(enabled)


func can_interact() -> bool:
	return enabled


func begin_interaction(interactor: Node = null) -> void:
	if not can_interact():
		return
	interaction_started.emit(interactor)


func complete_interaction(interactor: Node = null) -> void:
	interaction_completed.emit(interactor)

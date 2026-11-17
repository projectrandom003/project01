class_name NpcInteractionPoint
extends Interactable
## Reusable NPC interaction point / marker that can emit dialogue or custom signals.

signal interaction_triggered(point_id: StringName)
signal dialogue_requested(dialogue_id: String)

@export var point_id: StringName = &""
@export var dialogue_id: String = ""
@export var interaction_prompt: String = "Talk"


func _ready() -> void:
	super._ready()
	prompt = interaction_prompt


func interact() -> void:
	if not can_interact():
		return
	interaction_triggered.emit(point_id)
	if not dialogue_id.is_empty():
		dialogue_requested.emit(dialogue_id)
		EventBus.dialogue_requested.emit(dialogue_id)

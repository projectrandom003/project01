class_name EnvironmentTriggerArea
extends Area2D
## Reusable trigger area for environmental/gameplay signals.

signal actor_entered(actor: Node)
signal actor_exited(actor: Node)
signal triggered(payload: Dictionary)

@export var trigger_id: StringName = &""
@export var trigger_payload: Dictionary = {}
@export var one_shot: bool = false
@export var enabled: bool = true

var _fired: bool = false


func _ready() -> void:
	monitoring = enabled
	monitorable = false
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if not enabled or (one_shot and _fired):
		return
	actor_entered.emit(body)
	triggered.emit({"id": trigger_id, "body": body, "payload": trigger_payload.duplicate(true)})
	if one_shot:
		_fired = true
		monitoring = false


func _on_body_exited(body: Node) -> void:
	if not enabled:
		return
	actor_exited.emit(body)

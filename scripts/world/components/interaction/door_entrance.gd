class_name DoorEntrance
extends Interactable
## Reusable door/entrance interaction component.

signal door_opened
signal door_closed
signal entrance_used(target_scene: String, spawn_point: StringName)

@export var door_id: StringName = &""
@export var is_open: bool = false
@export var locked: bool = false
@export var target_scene_path: String = ""
@export var spawn_point: StringName = &""
@export var open_prompt: String = "Open"
@export var close_prompt: String = "Close"
@export var enter_prompt: String = "Enter"

@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer") as AnimationPlayer


func _ready() -> void:
	super._ready()
	_update_prompt()


func interact() -> void:
	if not can_interact():
		return
	if locked:
		EventBus.toast_requested.emit("Locked")
		return
	if not target_scene_path.is_empty():
		entrance_used.emit(target_scene_path, spawn_point)
		EventBus.toast_requested.emit(prompt)
		return
	set_open(not is_open)


func set_open(value: bool) -> void:
	is_open = value
	if is_open:
		if animation_player and animation_player.has_animation("open"):
			animation_player.play("open")
		door_opened.emit()
	else:
		if animation_player and animation_player.has_animation("close"):
			animation_player.play("close")
		door_closed.emit()
	_update_prompt()


func _update_prompt() -> void:
	if not target_scene_path.is_empty():
		prompt = enter_prompt
	else:
		prompt = close_prompt if is_open else open_prompt

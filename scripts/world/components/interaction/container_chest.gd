class_name ContainerChest
extends Interactable
## Reusable container/chest component with signal-driven rewards/open state.

signal opened
signal closed
signal loot_granted(rewards: Dictionary)

@export var container_id: StringName = &""
@export var rewards: Dictionary = {}
@export var one_time: bool = true
@export var opened_flag_key: String = ""

@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer") as AnimationPlayer

var _is_open: bool = false


func _ready() -> void:
	super._ready()
	prompt = "Open"
	var key := _flag_key()
	if not key.is_empty() and bool(GameState.flags.get(key, false)):
		_is_open = true
		enabled = not one_time
		if animation_player and animation_player.has_animation("opened"):
			animation_player.play("opened")


func interact() -> void:
	if not can_interact():
		return
	if _is_open and one_time:
		return
	_is_open = true
	if animation_player and animation_player.has_animation("open"):
		animation_player.play("open")
	opened.emit()
	if not rewards.is_empty():
		GameState.grant_reward_items(rewards)
		loot_granted.emit(rewards.duplicate(true))
	var key := _flag_key()
	if not key.is_empty():
		GameState.flags[key] = true
		GameState.queue_save()
	if one_time:
		enabled = false
	EventBus.toast_requested.emit("Opened")


func _flag_key() -> String:
	if not opened_flag_key.is_empty():
		return opened_flag_key
	return "container:%s" % String(container_id) if container_id != &"" else ""

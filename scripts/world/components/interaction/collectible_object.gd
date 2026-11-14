class_name CollectibleObject
extends Interactable
## Reusable collectible/environmental pickup component.

signal collected(collectible_id: StringName, rewards: Dictionary)

@export var collectible_id: StringName = &""
@export var rewards: Dictionary = {}
@export var flag_key: String = ""
@export var collect_prompt: String = "Collect"
@export var collect_message: String = "Collected"


func _ready() -> void:
	super._ready()
	prompt = collect_prompt
	var key := _key()
	if not key.is_empty() and bool(GameState.flags.get(key, false)):
		enabled = false
		visible = false


func interact() -> void:
	if not can_interact():
		return
	var key := _key()
	if not key.is_empty():
		GameState.flags[key] = true
	if not rewards.is_empty():
		GameState.grant_reward_items(rewards)
	GameState.queue_save()
	collected.emit(collectible_id, rewards.duplicate(true))
	EventBus.toast_requested.emit(collect_message)
	enabled = false
	visible = false


func _key() -> String:
	if not flag_key.is_empty():
		return flag_key
	return "collectible:%s" % String(collectible_id) if collectible_id != &"" else ""

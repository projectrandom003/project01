class_name DestructibleObject
extends Node2D
## Reusable destructible environmental object with signals and optional persistence.

signal damaged(amount: float, remaining: float)
signal destroyed

@export var object_id: StringName = &""
@export var max_health: float = 3.0
@export var current_health: float = 3.0
@export var persistent_flag_key: String = ""
@export var collision_path: NodePath

@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer") as AnimationPlayer


func _ready() -> void:
	current_health = clampf(current_health, 0.0, max_health)
	var key := _key()
	if not key.is_empty() and bool(GameState.flags.get(key, false)):
		_apply_destroyed_state(false)


func apply_damage(amount: float) -> void:
	if current_health <= 0.0:
		return
	current_health = maxf(0.0, current_health - maxf(0.0, amount))
	damaged.emit(amount, current_health)
	if current_health <= 0.0:
		destroy()


func destroy() -> void:
	if current_health > 0.0:
		current_health = 0.0
	var key := _key()
	if not key.is_empty():
		GameState.flags[key] = true
		GameState.queue_save()
	_apply_destroyed_state(true)
	destroyed.emit()


func _apply_destroyed_state(play_fx: bool) -> void:
	if play_fx and animation_player and animation_player.has_animation("destroy"):
		animation_player.play("destroy")
	visible = false
	if not collision_path.is_empty():
		var node := get_node_or_null(collision_path)
		if node is CollisionShape2D:
			(node as CollisionShape2D).disabled = true
		elif node is CollisionObject2D:
			(node as CollisionObject2D).set_deferred("collision_layer", 0)
			(node as CollisionObject2D).set_deferred("collision_mask", 0)


func _key() -> String:
	if not persistent_flag_key.is_empty():
		return persistent_flag_key
	return "destructible:%s" % String(object_id) if object_id != &"" else ""

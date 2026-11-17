class_name CharacterInteractionComponent
extends Node
## Reusable interaction helper for characters/world actors.
## Can scan nearby Interactable nodes and emit prompts/requests without owning movement.

signal interactable_changed(interactable: Node)
signal interaction_prompt_changed(prompt: String)
signal interaction_requested(interactable: Node)

@export var scan_enabled: bool = true
@export var scan_interval: float = 0.12
@export var interaction_group: StringName = &"interactables"

var _owner_node: Node2D
var _scan_accumulator: float = 0.0
var _current: Interactable


func _ready() -> void:
	_owner_node = get_parent() as Node2D


func _process(delta: float) -> void:
	if not scan_enabled or _owner_node == null:
		return
	_scan_accumulator += delta
	if _scan_accumulator >= scan_interval:
		_scan_accumulator = 0.0
		refresh_nearest()


func refresh_nearest() -> Interactable:
	if _owner_node == null or not _owner_node.is_inside_tree():
		return null
	var best: Interactable = null
	var best_distance := INF
	for node in _owner_node.get_tree().get_nodes_in_group(interaction_group):
		if not (node is Interactable):
			continue
		var candidate := node as Interactable
		if not candidate.can_interact():
			continue
		var distance := _owner_node.global_position.distance_to(candidate.global_position)
		if distance <= candidate.interaction_radius and distance < best_distance:
			best = candidate
			best_distance = distance
	_set_current(best)
	return _current


func get_current() -> Interactable:
	return _current


func try_interact() -> bool:
	if _owner_node == null or not is_instance_valid(_owner_node) or _current == null or not is_instance_valid(_current):
		_set_current(null)
		return false
	if not _current.can_interact() or _owner_node.global_position.distance_to(_current.global_position) > _current.interaction_radius:
		_set_current(null)
		return false
	var target := _current
	interaction_requested.emit(target)
	target.interact()
	return true


func current_prompt() -> String:
	return _current.prompt if _current != null and is_instance_valid(_current) else ""


func _set_current(value: Interactable) -> void:
	if _current == value:
		return
	_current = value
	interactable_changed.emit(_current)
	interaction_prompt_changed.emit(current_prompt())

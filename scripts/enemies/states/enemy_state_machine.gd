class_name EnemyStateMachine
extends Node

signal state_changed(from_state: StringName, to_state: StringName)
signal transition_blocked(from_state: StringName, to_state: StringName)

@export var initial_state: StringName = &"idle"
@export var controller_path: NodePath

var states: Dictionary = {}
var current_state: Node = null
var current_state_name: StringName = &""
var controller: Node = null


func _ready() -> void:
	controller = get_node_or_null(controller_path) if not controller_path.is_empty() else get_parent()
	_register_states()
	if initial_state != &"" and states.has(initial_state):
		set_state(initial_state, {})


func _register_states() -> void:
	states.clear()
	for child in get_children():
		if child != null and child.has_method("enter") and child.has_method("exit") and ("state_name" in child):
			var s: Node = child
			if s.state_name == &"":
				s.state_name = StringName(String(s.name).to_lower())
			if "controller" in s:
				s.controller = controller
			if s.has_signal("transition_requested") and not s.transition_requested.is_connected(_on_state_transition_requested):
				s.transition_requested.connect(_on_state_transition_requested)
			states[s.state_name] = s


func has_state(state_name: StringName) -> bool:
	return states.has(state_name)


func get_state(state_name: StringName) -> Node:
	return states.get(state_name, null) as Node


func set_state(target_state: StringName, context: Dictionary = {}) -> bool:
	if not states.has(target_state):
		return false
	var next: Node = states[target_state] as Node
	var prev_name := current_state_name
	if current_state != null:
		if current_state.has_method("can_transition_to") and not bool(current_state.call("can_transition_to", target_state, context)):
			transition_blocked.emit(prev_name, target_state)
			return false
		if current_state.has_method("exit"):
			current_state.call("exit", context)
	current_state = next
	current_state_name = target_state
	if current_state != null and current_state.has_method("enter"):
		current_state.call("enter", context)
	state_changed.emit(prev_name, target_state)
	return true


func process_state(delta: float, context: Dictionary = {}) -> void:
	if current_state != null:
		current_state.process_state(delta, context)


func physics_process_state(delta: float, context: Dictionary = {}) -> void:
	if current_state != null:
		current_state.physics_process_state(delta, context)


func _on_state_transition_requested(target_state: StringName, context: Dictionary) -> void:
	set_state(target_state, context)

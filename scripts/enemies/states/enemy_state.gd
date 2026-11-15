class_name EnemyState
extends Node

signal state_entered(state_name: StringName)
signal state_exited(state_name: StringName)
signal transition_requested(target_state: StringName, context: Dictionary)

@export var state_name: StringName = &""
var controller: Node = null
var active: bool = false


func enter(_context: Dictionary = {}) -> void:
	active = true
	state_entered.emit(state_name)


func exit(_context: Dictionary = {}) -> void:
	active = false
	state_exited.emit(state_name)


func process_state(_delta: float, _context: Dictionary = {}) -> void:
	pass


func physics_process_state(_delta: float, _context: Dictionary = {}) -> void:
	pass


func can_transition_to(_target_state: StringName, _context: Dictionary = {}) -> bool:
	return true


func request_transition(target_state: StringName, context: Dictionary = {}) -> void:
	transition_requested.emit(target_state, context)

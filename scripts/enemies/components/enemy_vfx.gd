class_name EnemyVFX
extends Node

signal vfx_requested(effect_name: StringName, context: Dictionary)

@export var vfx_root_path: NodePath
var vfx_root: Node = null


func _ready() -> void:
	if not vfx_root_path.is_empty():
		vfx_root = get_node_or_null(vfx_root_path)


func play_effect(effect_name: StringName, context: Dictionary = {}) -> void:
	vfx_requested.emit(effect_name, context)
	if vfx_root == null:
		return
	if vfx_root.has_method("play_effect"):
		vfx_root.call("play_effect", effect_name, context)
	elif vfx_root.has_method("play"):
		vfx_root.call("play")

class_name Interactable
extends Node2D
## Anything the player can walk up to and activate (NPCs, monsters, future
## gathering nodes and waypoints). Detection is distance-based and cheap; no
## physics bodies are needed for a handful of nearby actors.

var prompt: String = "Interact"
var interaction_radius: float = 96.0
var enabled: bool = true


func _ready() -> void:
	add_to_group("interactables")


func can_interact() -> bool:
	return enabled and visible


func interact() -> void:
	pass

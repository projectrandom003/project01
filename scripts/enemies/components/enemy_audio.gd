class_name EnemyAudio
extends Node

signal audio_requested(event_name: StringName)

@export var audio_root_path: NodePath
var audio_root: Node = null


func _ready() -> void:
	if not audio_root_path.is_empty():
		audio_root = get_node_or_null(audio_root_path)


func play_event(event_name: StringName) -> void:
	audio_requested.emit(event_name)
	if audio_root == null:
		return
	if audio_root.has_method("play_event"):
		audio_root.call("play_event", event_name)
	elif audio_root is AudioStreamPlayer or audio_root is AudioStreamPlayer2D:
		if audio_root.stream != null:
			audio_root.play()

class_name EnvironmentalSoundEmitter
extends Node2D

signal playback_started
signal playback_stopped

@export var stream: AudioStream
@export var autoplay: bool = false
@export var enabled: bool = true
@export_range(-80.0, 24.0, 0.1) var volume_db: float = -8.0
@export var max_distance: float = 600.0
@export var loop_hint: bool = true

@onready var player: AudioStreamPlayer2D = $AudioStreamPlayer2D


func _ready() -> void:
	_apply()
	if enabled and autoplay:
		play()


func _apply() -> void:
	if player == null:
		return
	player.stream = stream
	player.volume_db = volume_db
	player.max_distance = max_distance


func play() -> void:
	if not enabled or player == null or player.stream == null:
		return
	player.play()
	playback_started.emit()


func stop() -> void:
	if player == null:
		return
	player.stop()
	playback_stopped.emit()


func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		stop()
	elif autoplay:
		play()

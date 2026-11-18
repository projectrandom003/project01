class_name KaelCinematicPlaybackComponent
extends Node
## Owns sequence position and optional timed playback. Manual mode never advances itself.

signal advance_requested
signal shot_changed(index: int, shot: Dictionary, total: int)
signal progress_changed(progress: float)
signal sequence_completed

var shots: Array[Dictionary] = []
var shot_index := 0
var shot_elapsed := 0.0
var auto_play := false
var active := false
var _advance_pending := false

func configure(authored_shots: Array[Dictionary]) -> void:
	shots = authored_shots
	shot_index = 0
	shot_elapsed = 0.0
	_advance_pending = false
	active = not shots.is_empty()
	if active:
		shot_changed.emit(shot_index, current_shot(), shots.size())

func set_auto_play(enabled: bool) -> void:
	auto_play = enabled
	shot_elapsed = 0.0

func current_shot() -> Dictionary:
	if shot_index < 0 or shot_index >= shots.size():
		return {}
	return shots[shot_index]

func request_advance() -> void:
	if not active or _advance_pending:
		return
	_advance_pending = true
	advance_requested.emit()

func move_next() -> void:
	if not active:
		return
	shot_index += 1
	shot_elapsed = 0.0
	_advance_pending = false
	if shot_index >= shots.size():
		active = false
		sequence_completed.emit()
		return
	shot_changed.emit(shot_index, current_shot(), shots.size())

func _process(delta: float) -> void:
	if not active or not auto_play or _advance_pending:
		return
	var duration := maxf(float(current_shot().get("duration", 5.0)), 1.0)
	shot_elapsed += delta
	var progress := (float(shot_index) + clampf(shot_elapsed / duration, 0.0, 1.0)) / float(shots.size())
	progress_changed.emit(progress)
	if shot_elapsed >= duration:
		request_advance()

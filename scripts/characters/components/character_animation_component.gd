class_name CharacterAnimationComponent
extends Node
## Reusable AnimationPlayer wrapper for character presentation.
## Provides a small signal-driven API so scenes can drive animations without
## depending on a specific root implementation.

signal animation_started(animation_name: StringName)
signal animation_finished_signal(animation_name: StringName)
signal locomotion_state_changed(state: StringName)

@export var animation_player_path: NodePath = NodePath("../AnimationPlayer")
@export var locomotion_library_name: StringName = &""
@export var idle_animation: StringName = &"idle_bob"
@export var walk_animation: StringName = &"walk_bob"
@export var run_animation: StringName = &"run_bob"

var _player: AnimationPlayer
var _current_locomotion: StringName = &""


func _ready() -> void:
	_player = get_node_or_null(animation_player_path) as AnimationPlayer
	if _player != null and not _player.animation_finished.is_connected(_on_animation_finished):
		_player.animation_finished.connect(_on_animation_finished)


func get_player() -> AnimationPlayer:
	return _player


func play(animation_name: StringName, speed_scale: float = 1.0, restart: bool = false) -> bool:
	if _player == null or animation_name == StringName():
		return false
	if not _player.has_animation(animation_name):
		return false
	if restart or _player.current_animation != String(animation_name) or not _player.is_playing():
		_player.play(animation_name)
	_player.speed_scale = maxf(0.1, speed_scale)
	animation_started.emit(animation_name)
	return true


func stop(reset: bool = false) -> void:
	if _player == null:
		return
	_player.stop(reset)


func play_locomotion(state: StringName, speed_scale: float = 1.0) -> bool:
	var target := idle_animation
	match String(state):
		"walk", "WALK":
			target = walk_animation
		"run", "RUN":
			target = run_animation
		_:
			target = idle_animation
	_current_locomotion = target
	var ok := play(target, speed_scale)
	if ok:
		locomotion_state_changed.emit(target)
	return ok


func has_animation(animation_name: StringName) -> bool:
	return _player != null and _player.has_animation(animation_name)


func _on_animation_finished(anim_name: StringName) -> void:
	animation_finished_signal.emit(anim_name)

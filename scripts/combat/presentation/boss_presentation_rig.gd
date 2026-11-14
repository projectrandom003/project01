extends Control
## Node-based visual presentation layer for boss encounters.
## It receives positions and presentation cues; CombatEngine remains authoritative.

signal telegraph_spawned(position: Vector2, boss_id: String)
signal impact_spawned(position: Vector2, boss_id: String)
signal phase_change_started(boss_id: String, phase_number: int, message: String)
signal phase_change_finished
signal multi_target_sequence_finished(boss_id: String, target_count: int)

const TELEGRAPH_SCENE: PackedScene = preload("res://scenes/combat/presentation/boss_telegraph.tscn")
const IMPACT_SCENE: PackedScene = preload("res://scenes/combat/presentation/boss_impact.tscn")

@export var default_profile: Resource
@export var elder_hollow_profile: Resource
@export var fallen_matron_profile: Resource

@onready var _world_effects: Node2D = $WorldEffects
@onready var _phase_cue: Node = $PhaseCue

var _sequence_token: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phase_cue.connect("finished", _on_phase_cue_finished)


func show_target_telegraph(at: Vector2, boss_id: String, duration: float = 0.42) -> Node2D:
	var telegraph := TELEGRAPH_SCENE.instantiate() as Node2D
	telegraph.position = at
	_world_effects.add_child(telegraph)
	telegraph.call("play", _profile_for_boss(boss_id), duration)
	telegraph_spawned.emit(at, boss_id)
	return telegraph


func show_target_telegraphs(positions: Array, boss_id: String, duration: float = 0.42) -> Array[Node2D]:
	var spawned: Array[Node2D] = []
	for value in positions:
		if not (value is Vector2):
			continue
		spawned.append(show_target_telegraph(value, boss_id, duration))
	return spawned


func play_impact(at: Vector2, boss_id: String, strength: float = 1.0) -> Node2D:
	var impact := IMPACT_SCENE.instantiate() as Node2D
	impact.position = at
	_world_effects.add_child(impact)
	impact.call("play", _profile_for_boss(boss_id), strength)
	impact_spawned.emit(at, boss_id)
	return impact


func play_multi_target_strike(target_positions: Array, boss_id: String, windup_seconds: float = 0.42) -> void:
	var positions: Array[Vector2] = []
	for value in target_positions:
		if value is Vector2:
			positions.append(value)
	if positions.is_empty():
		return

	_sequence_token += 1
	var token := _sequence_token
	show_target_telegraphs(positions, boss_id, windup_seconds)
	await get_tree().create_timer(maxf(0.12, windup_seconds)).timeout
	if not is_inside_tree() or token != _sequence_token:
		return

	for index in positions.size():
		play_impact(positions[index], boss_id, 1.0 if index == 0 else 0.82)
	await get_tree().create_timer(0.36).timeout
	if is_inside_tree() and token == _sequence_token:
		multi_target_sequence_finished.emit(boss_id, positions.size())


func show_phase_transition(boss_id: String, phase_number: int, message: String = "") -> void:
	var profile := _profile_for_boss(boss_id)
	var title: String = str(profile.get("phase_title")) if profile != null else "THE ENCOUNTER CHANGES"
	var accent: Color = profile.get("phase_color") if profile != null else Color.WHITE
	var cue_message := message.strip_edges()
	if cue_message.is_empty():
		cue_message = "PHASE %d — %s" % [phase_number, title]
	phase_change_started.emit(boss_id, phase_number, cue_message)
	_phase_cue.call("play_cue", cue_message, accent, 1.35)


func clear_transients() -> void:
	_sequence_token += 1
	for child in _world_effects.get_children():
		child.queue_free()
	_phase_cue.call("cancel_cue")


func transient_count() -> int:
	return _world_effects.get_child_count()


func _profile_for_boss(boss_id: String) -> Resource:
	match boss_id:
		"elder_hollow", "corrupted_treant":
			return elder_hollow_profile if elder_hollow_profile != null else default_profile
		"fallen_matron", "fallen_matron_encounter":
			return fallen_matron_profile if fallen_matron_profile != null else default_profile
		_:
			return default_profile


func _on_phase_cue_finished() -> void:
	phase_change_finished.emit()

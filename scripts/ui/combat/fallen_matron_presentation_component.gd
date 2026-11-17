class_name FallenMatronPresentationComponent
extends Node2D
## Owns the Fallen Matron's bespoke cutout, corruption phases and boss reactions.

const PHASE_HEIGHTS := [528.0, 386.0, 400.0]
const ART_PATHS := [
	"res://assets/enemies/fallen_matron/phase_1.png",
	"res://assets/enemies/fallen_matron/phase_2.png",
	"res://assets/enemies/fallen_matron/phase_3.png"
]

var _art: Sprite2D
var _motes: CPUParticles2D
var _unit: Combatant
var _phase := 0
var _home := Vector2(0, -96)
var _hit_tween: Tween
var _attack_tween: Tween
var _phase_tween: Tween
var active := false


func _ready() -> void:
	_art = get_node_or_null("Art") as Sprite2D
	_motes = get_node_or_null("CorruptionMotes") as CPUParticles2D
	if _art == null or _motes == null:
		push_error("FallenMatronPresentation requires authored Art and CorruptionMotes children.")
		return
	_art.visible = false
	_motes.visible = false
	_motes.emitting = false


func configure(unit: Combatant, actor_visual: ActorVisual) -> bool:
	_unit = unit
	active = false
	if unit == null or unit.def_id != "fallen_matron" or _art == null or _motes == null:
		return false
	if not ResourceLoader.exists(ART_PATHS[0]):
		return false
	var texture := load(ART_PATHS[0]) as Texture2D
	if texture == null:
		return false
	_art.texture = texture
	_art.position = _home
	_art.scale = Vector2.ONE * (180.0 / PHASE_HEIGHTS[0])
	_art.visible = true
	_motes.visible = true
	_motes.emitting = true
	active = true
	if actor_visual != null:
		actor_visual.visible = false
	refresh_phase(unit.hp_ratio())
	return true


func refresh_phase(hp_ratio: float) -> void:
	if not active or _art == null:
		return
	var next_phase := 1
	if hp_ratio <= 0.33:
		next_phase = 3
	elif hp_ratio <= 0.66:
		next_phase = 2
	if next_phase == _phase:
		return
	var previous_phase := _phase
	_phase = next_phase
	var texture := load(ART_PATHS[_phase - 1]) as Texture2D
	if texture != null:
		_art.texture = texture
	_home = Vector2(0, -96)
	_art.position = _home
	if _phase_tween != null and _phase_tween.is_running():
		_phase_tween.kill()
	_phase_tween = create_tween()
	_phase_tween.tween_property(_art, "scale", Vector2.ONE * (180.0 / PHASE_HEIGHTS[_phase - 1]), 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_art.modulate = Color.WHITE if _phase == 1 else Color(1.04, 0.94, 1.12, 1.0) if _phase == 2 else Color(1.12, 0.82, 1.22, 1.0)
	if previous_phase > 0:
		_spawn_phase_burst()


func _spawn_phase_burst() -> void:
	var burst := preload("res://scenes/ui/combat/components/matron_phase_burst.tscn").instantiate() as CPUParticles2D
	burst.amount = 42 if _phase == 3 else 30
	burst.initial_velocity_max = 125.0 if _phase == 3 else 90.0
	burst.color = Color("#ed72ff") if _phase == 3 else Color("#b96cff")
	burst.position = _home + Vector2(0, -55)
	add_child(burst)
	burst.finished.connect(burst.queue_free)
	burst.emitting = true


func update_idle(pulse: float, hit_shake: float, bob: float, dead: bool) -> void:
	if not active or dead or _art == null:
		return
	_art.position = _home + Vector2(hit_shake * 6.0 + sin(pulse * 0.82) * 2.0, bob * 2.25)
	var action_running := (_attack_tween != null and _attack_tween.is_running()) or (_hit_tween != null and _hit_tween.is_running()) or (_phase_tween != null and _phase_tween.is_running())
	if not action_running:
		var base_scale: float = 180.0 / PHASE_HEIGHTS[maxi(0, _phase - 1)]
		var breath := sin(pulse * 1.35)
		_art.scale = Vector2(base_scale * (1.0 + breath * 0.024), base_scale * (1.0 - breath * 0.018))
		_art.rotation = sin(pulse * 0.62) * 0.022


func take_hit() -> void:
	if not active or _art == null:
		return
	if _hit_tween != null and _hit_tween.is_running():
		_hit_tween.kill()
	_hit_tween = create_tween()
	_hit_tween.tween_property(_art, "modulate", Color(2.0, 1.45, 2.2, 1.0), 0.055)
	_hit_tween.tween_property(_art, "modulate", Color.WHITE, 0.24)
	_hit_tween.parallel().tween_property(_art, "rotation", deg_to_rad(3.0), 0.06)
	_hit_tween.tween_property(_art, "rotation", 0.0, 0.18)


func play_attack() -> void:
	if not active or _art == null:
		return
	if _attack_tween != null and _attack_tween.is_running():
		_attack_tween.kill()
	_attack_tween = create_tween()
	var base_scale: float = 180.0 / PHASE_HEIGHTS[maxi(0, _phase - 1)]
	_attack_tween.tween_property(_art, "scale", Vector2(base_scale * 0.92, base_scale * 1.09), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_attack_tween.parallel().tween_property(_art, "rotation", deg_to_rad(5.0), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_attack_tween.tween_property(_art, "scale", Vector2(base_scale * 1.12, base_scale * 0.90), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_attack_tween.parallel().tween_property(_art, "rotation", deg_to_rad(-5.0), 0.10)
	_attack_tween.tween_property(_art, "rotation", 0.0, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_attack_tween.parallel().tween_property(_art, "scale", Vector2.ONE * base_scale, 0.26)


func play_death() -> void:
	if not active or _art == null:
		return
	var fall := create_tween()
	fall.tween_property(_art, "rotation", deg_to_rad(-12.0), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.parallel().tween_property(_art, "position:y", _art.position.y + 30.0, 0.55)
	fall.parallel().tween_property(_art, "modulate", Color(0.62, 0.38, 0.78, 0.0), 0.62)


func get_phase() -> int:
	return _phase

class_name EnemyCombat
extends Node

signal attack_started(attack_id: String)
signal attack_completed(attack_id: String)
signal skill_activated(skill_id: String)
signal cast_started(skill_id: String, cast_time: float)
signal cast_completed(skill_id: String)
signal projectile_spawn_requested(projectile_id: String, target: Variant)
signal hit_reaction_triggered(source: Variant)
signal damage_received(amount: float, source: Variant)
signal combat_state_changed(from_state: StringName, to_state: StringName)

@export var config: Resource
@export var skill_config: Resource

var combat_state: StringName = &"idle"
var attack_cooldown_remaining: float = 0.0
var is_casting: bool = false


func _process(delta: float) -> void:
	if attack_cooldown_remaining > 0.0:
		attack_cooldown_remaining = maxf(0.0, attack_cooldown_remaining - delta)


func set_combat_state(state: StringName) -> void:
	if state == combat_state:
		return
	var prev := combat_state
	combat_state = state
	combat_state_changed.emit(prev, state)


func can_attack() -> bool:
	if config != null and ("attack_enabled" in config) and not bool(config.attack_enabled):
		return false
	return attack_cooldown_remaining <= 0.0 and not is_casting


func start_attack(attack_id: String = "basic") -> bool:
	if not can_attack():
		return false
	attack_started.emit(attack_id)
	var cd := 1.0
	if config != null and ("attack_cooldown" in config):
		cd = float(config.attack_cooldown)
	attack_cooldown_remaining = cd
	set_combat_state(&"attack")
	return true


func complete_attack(attack_id: String = "basic") -> void:
	attack_completed.emit(attack_id)
	if combat_state == &"attack":
		set_combat_state(&"idle")


func activate_skill(skill_id: String) -> bool:
	skill_activated.emit(skill_id)
	return true


func start_cast(skill_id: String, cast_time: float = 0.0) -> void:
	is_casting = true
	cast_started.emit(skill_id, cast_time)
	set_combat_state(&"cast")


func complete_cast(skill_id: String) -> void:
	is_casting = false
	cast_completed.emit(skill_id)
	if combat_state == &"cast":
		set_combat_state(&"idle")


func request_projectile(projectile_id: String, target: Variant = null) -> void:
	projectile_spawn_requested.emit(projectile_id, target)


func receive_damage(amount: float, source: Variant = null) -> void:
	damage_received.emit(amount, source)
	if config == null or config.hit_reaction_enabled:
		hit_reaction_triggered.emit(source)

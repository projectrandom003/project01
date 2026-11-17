class_name EnemyHealth
extends Node

signal damaged(amount: float, current_hp: float, max_hp: float)
signal healed(amount: float, current_hp: float, max_hp: float)
signal died
signal revived
signal health_changed(current_hp: float, max_hp: float)

@export var max_hp: float = 100.0
@export var current_hp: float = 100.0
@export var invulnerable: bool = false

var is_dead: bool = false


func configure(p_max_hp: float, p_current_hp: float = -1.0) -> void:
	max_hp = maxf(1.0, p_max_hp)
	current_hp = clampf(p_current_hp if p_current_hp >= 0.0 else max_hp, 0.0, max_hp)
	is_dead = current_hp <= 0.0
	health_changed.emit(current_hp, max_hp)


func apply_damage(amount: float) -> float:
	if is_dead or invulnerable:
		return 0.0
	var dealt := maxf(0.0, amount)
	current_hp = maxf(0.0, current_hp - dealt)
	damaged.emit(dealt, current_hp, max_hp)
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0.0:
		is_dead = true
		died.emit()
	return dealt


func apply_heal(amount: float) -> float:
	if is_dead:
		return 0.0
	var before := current_hp
	current_hp = minf(max_hp, current_hp + maxf(0.0, amount))
	var healed_amount := current_hp - before
	if healed_amount > 0.0:
		healed.emit(healed_amount, current_hp, max_hp)
		health_changed.emit(current_hp, max_hp)
	return healed_amount


func revive(hp_ratio: float = 1.0) -> void:
	is_dead = false
	current_hp = clampf(max_hp * clampf(hp_ratio, 0.0, 1.0), 1.0, max_hp)
	revived.emit()
	health_changed.emit(current_hp, max_hp)

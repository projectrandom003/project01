class_name BattlefieldActorGroundFX
extends Node2D
## Authored ground shadow, elemental rune, target/turn rings and Matron sigils.

@onready var shadow_outer: Polygon2D = $ShadowOuter
@onready var shadow_inner: Polygon2D = $ShadowInner
@onready var enemy_rune: Node2D = $EnemyRune
@onready var rune_outer: Line2D = $EnemyRune/RuneOuter
@onready var rune_inner: Line2D = $EnemyRune/RuneInner
@onready var target_ring: Node2D = $TargetRing
@onready var target_outer: Line2D = $TargetRing/Outer
@onready var target_inner: Line2D = $TargetRing/Inner
@onready var active_ring: Line2D = $ActiveRing
@onready var matron_sigils: Node2D = $MatronSigils
@onready var phase_rings: Array[Line2D] = [
	$MatronSigils/PhaseRing0, $MatronSigils/PhaseRing1, $MatronSigils/PhaseRing2
]

var _is_enemy := false
var _is_boss := false
var _is_matron := false
var _element_color := Color("#c6cad6")


func configure(is_player: bool, is_boss: bool, is_matron: bool, element_color: Color) -> void:
	_is_enemy = not is_player
	_is_boss = is_boss
	_is_matron = is_matron
	_element_color = element_color
	enemy_rune.visible = _is_enemy
	rune_outer.default_color = _element_color
	rune_inner.default_color = Color(_element_color.r, _element_color.g, _element_color.b, 0.7)
	matron_sigils.visible = _is_matron


func update_state(pulse: float, targetable: bool, active: bool, dead: bool, base_scale: float, matron_phase: int) -> void:
	var shadow_radius := 16.0 * base_scale * (1.25 if _is_boss else 1.0)
	shadow_outer.position = Vector2(0, 2)
	shadow_outer.scale = Vector2(shadow_radius * 0.55, shadow_radius * 0.42)
	shadow_inner.position = Vector2(0, 2)
	shadow_inner.scale = Vector2(shadow_radius * 0.34, shadow_radius * 0.26)
	var rune_alpha := 0.12 + 0.05 * (0.5 + 0.5 * sin(pulse * 1.8))
	rune_outer.default_color = Color(_element_color.r, _element_color.g, _element_color.b, rune_alpha)
	rune_inner.default_color = Color(_element_color.r, _element_color.g, _element_color.b, rune_alpha * 0.7)
	rune_outer.scale = Vector2.ONE * shadow_radius * (1.05 if _is_boss else 0.82)
	rune_inner.scale = Vector2.ONE * shadow_radius * (1.05 if _is_boss else 0.82) * 1.18
	rune_outer.width = 2.0 if _is_boss else 1.3
	rune_inner.width = 1.0
	var target_glow := 0.5 + 0.5 * sin(pulse * 4.0)
	var target_color := Color("#ffd477")
	target_color.a = 0.35 + 0.35 * target_glow
	target_ring.visible = targetable and not dead
	target_outer.default_color = target_color
	target_inner.default_color = Color(target_color.r, target_color.g, target_color.b, target_color.a * 0.48)
	target_outer.scale = Vector2.ONE * shadow_radius * (0.75 + 0.06 * target_glow)
	target_inner.scale = Vector2.ONE * shadow_radius * (0.92 + 0.08 * target_glow)
	target_outer.width = 3.0
	target_inner.width = 1.2
	active_ring.visible = active and not dead
	active_ring.scale = Vector2.ONE * shadow_radius * 0.92
	var active_color := Color("#65e0d0")
	active_color.a = 0.75
	active_ring.default_color = active_color
	matron_sigils.visible = _is_matron and matron_phase > 0
	if matron_sigils.visible:
		var phase_pulse := 0.5 + 0.5 * sin(pulse * (2.2 + float(matron_phase) * 0.55))
		var alpha := 0.24 + float(matron_phase - 1) * 0.13 + phase_pulse * 0.12
		var radii := [48.0 + float(matron_phase - 1) * 7.0, 59.0 + float(matron_phase - 1) * 7.0, 70.0 + float(matron_phase - 1) * 7.0]
		for i in range(phase_rings.size()):
			var ring := phase_rings[i]
			ring.visible = i < matron_phase
			ring.scale = Vector2.ONE * radii[i]
			ring.rotation = pulse * [-0.35, 0.22, -0.16][i]
			ring.default_color = Color(0.68, 0.24, 0.98, alpha * (1.0 if i == 0 else 0.72 if i == 1 else 0.8))
			ring.width = 2.2 + float(matron_phase) * 0.55 if i == 0 else 1.5 if i == 1 else 2.0

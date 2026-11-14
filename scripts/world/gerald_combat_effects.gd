extends Node2D
class_name GeraldCombatEffects
## Node-authored combat overlays and particle accents. ActorVisual/CharacterAnimator remain authoritative.

@onready var slash_trail: Line2D = $SlashTrail
@onready var void_arc: Line2D = $VoidArc
@onready var slash_core: Line2D = $SlashCore
@onready var impact_ring: Line2D = $ImpactRing
@onready var cast_ring: Line2D = $CastRing
@onready var cast_inner_ring: Line2D = $CastInnerRing
@onready var eruption_left: Polygon2D = $EruptionLeft
@onready var eruption_center: Polygon2D = $EruptionCenter
@onready var eruption_right: Polygon2D = $EruptionRight
@onready var aura_halo: Line2D = $AuraHalo
@onready var void_halo: Line2D = $VoidHalo
@onready var void_motes: CPUParticles2D = $VoidMotes
@onready var slash_sparks: CPUParticles2D = $SlashSparks
@onready var impact_sparks: CPUParticles2D = $ImpactSparks
@onready var cast_embers: CPUParticles2D = $CastEmbers

var _owner_visual: ActorVisual
var attack_variant := "slash_combo"
var skill_variant := "ground_eruption"
var _last_state := -1
var _impact_fired := false
var _cast_release_fired := false

func _ready() -> void:
	_owner_visual = get_parent().get_parent() as ActorVisual
	visible = false
	_set_attack_visible(false)
	_set_cast_visible(false)
	_set_aura_visible(false)
	slash_sparks.emitting = false
	impact_sparks.emitting = false
	cast_embers.emitting = false
	void_motes.emitting = false

func set_attack_variant(value: String) -> void:
	attack_variant = value if value in ["slash_combo", "heavy_strike", "spinning_cleave"] else "slash_combo"
	if is_node_ready() and _owner_visual != null and _owner_visual.animator != null and _owner_visual.animator.state == CharacterAnimator.State.ATTACK:
		_set_attack_visible(true)

func set_skill_variant(value: String) -> void:
	skill_variant = value if value in ["blade_wave", "ground_eruption", "guardian_aura"] else "ground_eruption"
	if is_node_ready() and _owner_visual != null and _owner_visual.animator != null and _owner_visual.animator.state == CharacterAnimator.CAST_STATE:
		_set_cast_visible(skill_variant != "guardian_aura")
		_set_aura_visible(skill_variant == "guardian_aura")

func _process(_delta: float) -> void:
	if _owner_visual == null:
		_owner_visual = get_parent().get_parent() as ActorVisual
	if _owner_visual == null or _owner_visual.character_id != "gerald" or _owner_visual.animator == null:
		visible = false
		return
	var animator := _owner_visual.animator
	var state := animator.state
	var progress := clampf((float(animator.frame) + animator.elapsed * animator.fps() * animator.speed_scale) / float(maxi(1, animator.frame_count())), 0.0, 1.0)
	var particles_active := slash_sparks.emitting or impact_sparks.emitting or cast_embers.emitting or void_motes.emitting
	visible = state == CharacterAnimator.State.ATTACK or state == CharacterAnimator.CAST_STATE or state == CharacterAnimator.State.VICTORY or particles_active
	if state != _last_state:
		_last_state = state
		_impact_fired = false
		_cast_release_fired = false
		_set_attack_visible(state == CharacterAnimator.State.ATTACK)
		_set_cast_visible(state == CharacterAnimator.CAST_STATE and skill_variant != "guardian_aura")
		_set_aura_visible((state == CharacterAnimator.CAST_STATE and skill_variant == "guardian_aura") or state == CharacterAnimator.State.VICTORY)
		if state == CharacterAnimator.State.ATTACK:
			var attack_direction := _attack_direction()
			slash_sparks.direction = attack_direction
			impact_sparks.direction = attack_direction
			_restart_particles(slash_sparks)
		elif state == CharacterAnimator.CAST_STATE and skill_variant == "guardian_aura":
			_restart_particles(void_motes)
	if state == CharacterAnimator.State.ATTACK:
		_update_attack(progress)
	elif state == CharacterAnimator.CAST_STATE:
		if skill_variant == "guardian_aura":
			_update_aura(progress)
		else:
			_update_cast(progress)
	elif state == CharacterAnimator.State.VICTORY:
		_update_aura(progress)

func _restart_particles(particles: CPUParticles2D) -> void:
	particles.emitting = false
	particles.restart()
	particles.emitting = true


## Convert the animator's compass direction into a normalized local-space vector.
## Gerald's slash and forward blade wave now follow the direction he is facing.
func _attack_direction() -> Vector2:
	if _owner_visual == null or _owner_visual.animator == null:
		return Vector2.DOWN
	var direction := _owner_visual.animator.direction
	var angle := PI * 0.5 - float(direction) * PI * 0.25
	return Vector2.RIGHT.rotated(angle).normalized()


func _set_attack_visible(value: bool) -> void:
	slash_trail.visible = value
	void_arc.visible = value
	slash_core.visible = value
	impact_ring.visible = value
	slash_sparks.visible = value or slash_sparks.emitting
	impact_sparks.visible = value or impact_sparks.emitting

func _set_cast_visible(value: bool) -> void:
	cast_ring.visible = value
	cast_inner_ring.visible = value
	cast_embers.visible = value or cast_embers.emitting
	var eruption := value and skill_variant == "ground_eruption"
	var blade := value and skill_variant == "blade_wave"
	eruption_left.visible = eruption
	eruption_center.visible = eruption
	eruption_right.visible = eruption
	if blade:
		var direction := _attack_direction()
		var forward_position := Vector2(0, -38) + direction * 30.0
		eruption_center.visible = true
		eruption_center.rotation = direction.angle() + PI * 0.5
		eruption_center.position = forward_position
		cast_ring.position = forward_position
		cast_inner_ring.position = forward_position
	elif eruption:
		eruption_center.rotation = 0.0
		eruption_center.position = Vector2(0, -4)
		cast_ring.position = Vector2(0, -2)
		cast_inner_ring.position = Vector2(0, -2)

func _set_aura_visible(value: bool) -> void:
	aura_halo.visible = value
	var guardian_aura := value and _owner_visual != null and _owner_visual.animator != null and _owner_visual.animator.state == CharacterAnimator.CAST_STATE and skill_variant == "guardian_aura"
	void_halo.visible = guardian_aura
	void_motes.visible = value or void_motes.emitting

func _update_attack(progress: float) -> void:
	var sweep := smoothstep(0.08, 0.34, progress) * (1.0 - smoothstep(0.72, 0.96, progress))
	var impact := smoothstep(0.38, 0.48, progress) * (1.0 - smoothstep(0.58, 0.76, progress))
	var angle := lerpf(-0.95, 1.05, clampf((progress - 0.08) / 0.76, 0.0, 1.0))
	var direction := _attack_direction()
	var direction_angle := direction.angle()
	var attack_origin := Vector2(0, -38) + direction * 22.0
	slash_trail.position = attack_origin
	slash_core.position = attack_origin
	void_arc.position = attack_origin
	slash_sparks.position = attack_origin
	impact_ring.position = Vector2(0, -30) + direction * 30.0
	impact_sparks.position = impact_ring.position
	var ring_scale := 1.25
	match attack_variant:
		"heavy_strike":
			angle = lerpf(-0.35, 0.42, clampf((progress - 0.05) / 0.55, 0.0, 1.0))
			sweep = smoothstep(0.18, 0.48, progress) * (1.0 - smoothstep(0.62, 0.92, progress))
			impact = smoothstep(0.50, 0.58, progress) * (1.0 - smoothstep(0.68, 0.9, progress))
			ring_scale = 1.8
		"spinning_cleave":
			angle = -PI + progress * TAU
			sweep = smoothstep(0.04, 0.2, progress) * (1.0 - smoothstep(0.82, 1.0, progress))
			impact = smoothstep(0.76, 0.86, progress) * (1.0 - smoothstep(0.94, 1.0, progress))
			ring_scale = 2.15
	slash_trail.modulate.a = sweep
	void_arc.modulate.a = sweep * 0.72
	slash_core.modulate.a = sweep
	slash_trail.rotation = direction_angle + angle
	void_arc.rotation = direction_angle + angle - 0.08
	slash_core.rotation = direction_angle + angle
	impact_ring.modulate.a = impact
	impact_ring.scale = Vector2.ONE * lerpf(0.42, ring_scale, impact)
	if impact > 0.35 and not _impact_fired:
		_impact_fired = true
		_restart_particles(impact_sparks)

func _update_cast(progress: float) -> void:
	var gather := smoothstep(0.0, 0.42, progress)
	var release := smoothstep(0.52, 0.78, progress) * (1.0 - smoothstep(0.9, 1.0, progress))
	if skill_variant == "blade_wave":
		var direction := _attack_direction()
		var forward_position := Vector2(0, -38) + direction * 30.0
		cast_ring.rotation = direction.angle() + lerpf(-0.5, 0.5, progress)
		cast_inner_ring.rotation = cast_ring.rotation
		cast_ring.scale = Vector2(lerpf(0.25, 1.7, release), lerpf(0.25, 0.55, release))
		cast_inner_ring.scale = Vector2(lerpf(0.2, 1.35, release), lerpf(0.2, 0.34, release))
		cast_ring.position = forward_position
		cast_inner_ring.position = forward_position
	else:
		cast_ring.position = Vector2.ZERO
		cast_inner_ring.position = Vector2.ZERO
		cast_ring.scale = Vector2.ONE * lerpf(0.25, 1.15, gather)
		cast_inner_ring.scale = Vector2.ONE * lerpf(0.2, 0.9, gather)
	cast_ring.modulate.a = 0.18 + 0.72 * (1.0 - release)
	cast_inner_ring.modulate.a = 0.22 + 0.65 * release
	var eruption := release if skill_variant == "ground_eruption" else 0.0
	eruption_left.modulate.a = eruption
	eruption_center.modulate.a = release
	eruption_right.modulate.a = eruption
	eruption_left.scale.y = lerpf(0.2, 1.0, eruption)
	eruption_center.scale.y = lerpf(0.2, 1.25, release)
	eruption_right.scale.y = lerpf(0.2, 0.9, eruption)
	if release > 0.35 and not _cast_release_fired:
		_cast_release_fired = true
		cast_embers.direction = _attack_direction() if skill_variant == "blade_wave" else Vector2.UP
		cast_embers.spread = 24.0 if skill_variant == "blade_wave" else 128.0
		cast_embers.gravity = Vector2(0, 42) if skill_variant == "ground_eruption" else Vector2.ZERO
		_restart_particles(cast_embers)

func _update_aura(progress: float) -> void:
	var pulse := 0.55 + 0.35 * sin(progress * TAU)
	aura_halo.modulate.a = pulse
	aura_halo.scale = Vector2.ONE * (0.88 + 0.12 * pulse)
	void_halo.modulate.a = (0.28 + 0.42 * (1.0 - pulse)) if void_halo.visible else 0.0
	void_halo.scale = Vector2.ONE * (0.82 + 0.14 * (1.0 - pulse))

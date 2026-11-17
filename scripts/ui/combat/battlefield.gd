class_name Battlefield
extends Control
## The battle stage: a dark-fantasy environment with the party on the LEFT and
## the enemies on the RIGHT.
##
## PRESENTATION ONLY. The battlefield owns the actors, their positions, the
## ground shadows, the damage numbers and the attack choreography. Every
## number it shows comes from the CombatEngine's event stream, so it can never
## cause or duplicate damage.
##
## Positions are FRACTIONS of the battlefield size, so the layout follows the
## 1280x720 base viewport (and any other window size) without hardcoding.
## Party size is not hardcoded: slots are assigned by index, so any number of
## allies fits.

signal actor_clicked(actor: BattlefieldActor)
signal cinematic_impact(intensity: float, duration: float)

# Party slots (front-most first, receding up-left into the depth).
const PARTY_X := 0.315
const PARTY_DX := -0.085
const PARTY_Y := 0.855
const PARTY_DY := -0.075

# Enemy slots (front-most first, receding up-right).
const ENEMY_X := 0.735
const ENEMY_DX := -0.052
const ENEMY_Y := 0.865
const ENEMY_DY := -0.112

# The boss stands apart, further back and larger.
const BOSS_X := 0.845
const BOSS_Y := 0.905

const DAMAGE_FONT := 26
const SOFT_GLOW: Texture2D = preload("res://scenes/ui/combat/components/soft_glow.tres")

const ACTOR_SCENE: PackedScene = preload("res://scenes/ui/battlefield_actor.tscn")

var arena_id: String = ""
var _actors: Array = []
var _by_uid: Dictionary = {}
var _stage: Node2D = null
var _embers: CPUParticles2D = null
var _layout_component: BattlefieldLayoutComponent
var _effects_component: BattlefieldEffectsComponent
var _kael_attack_component: KaelAttackPresentationComponent
var _matron_attack_component: MatronAttackPresentationComponent
var _generic_attack_component: GenericAttackPresentationComponent
var _impact_component: BattlefieldImpactEffectsComponent


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	var owner_screen := get_parent() as CombatScreen
	if owner_screen != null:
		arena_id = owner_screen.group_id
	_layout_component = get_node_or_null("Layout") as BattlefieldLayoutComponent
	_effects_component = get_node_or_null("Effects") as BattlefieldEffectsComponent
	_kael_attack_component = get_node_or_null("KaelAttackPresentation") as KaelAttackPresentationComponent
	_matron_attack_component = get_node_or_null("MatronAttackPresentation") as MatronAttackPresentationComponent
	_generic_attack_component = get_node_or_null("GenericAttackPresentation") as GenericAttackPresentationComponent
	_impact_component = get_node_or_null("ImpactEffects") as BattlefieldImpactEffectsComponent
	if _layout_component == null or _effects_component == null or _kael_attack_component == null or _matron_attack_component == null or _generic_attack_component == null or _impact_component == null:
		push_error("Battlefield is missing an authored layout/effects/attack-presentation component.")
		return
	_layout_component.bind(self)
	_effects_component.bind(self)
	_kael_attack_component.bind(self)
	_matron_attack_component.bind(self)
	_generic_attack_component.bind(self)
	_impact_component.bind(self)
	_effects_component.kael_attack_component = _kael_attack_component
	_effects_component.matron_attack_component = _matron_attack_component
	_effects_component.generic_attack_component = _generic_attack_component
	_effects_component.impact_component = _impact_component
	_build_environment()
	resized.connect(_layout)

func _build_environment() -> void:
	if _layout_component != null:
		_layout_component.build_environment()

func setup(party: Array, enemies: Array) -> void:
	if _layout_component != null:
		_layout_component.setup(party, enemies)

func _add_actor(unit: Combatant, is_player: bool) -> void:
	if _layout_component != null:
		_layout_component._add_actor(unit, is_player)

func clear_actors() -> void:
	if _layout_component != null:
		_layout_component.clear_actors()

func actors() -> Array:
	return _layout_component.actors if _layout_component != null else _actors

func actor_for_uid(uid: String) -> BattlefieldActor:
	return _layout_component.actor_for_uid(uid) if _layout_component != null else null

func _layout() -> void:
	if _layout_component != null:
		_layout_component.layout()

func face_opponents() -> void:
	if _layout_component != null:
		_layout_component.face_opponents()

func refresh_actors() -> void:
	if _layout_component != null:
		_layout_component.refresh_actors()

func set_active(uid: String) -> void:
	if _layout_component != null:
		_layout_component.set_active(uid)

func set_target_team(team: int, enabled: bool) -> void:
	if _layout_component != null:
		_layout_component.set_target_team(team, enabled)

func _on_actor_clicked(actor: BattlefieldActor) -> void:
	actor_clicked.emit(actor)

func play_attack(attacker: BattlefieldActor, target: BattlefieldActor, element: String = "neutral", skill_id: String = "", ultimate: bool = false) -> void:
	if _effects_component != null:
		_effects_component.play_attack(attacker, target, element, skill_id, ultimate)


func spawn_damage_number(actor: BattlefieldActor, text: String, color: Color, delay: float = 0.0) -> void:
	if _effects_component != null:
		_effects_component.spawn_damage_number(actor, text, color, delay)


func spawn_elemental_burst(pos: Vector2, element: String) -> void:
	if _effects_component != null:
		_effects_component.spawn_elemental_burst(pos, element)


func play_matron_phase(phase_number: int) -> void:
	if _effects_component != null:
		_effects_component.play_matron_phase(phase_number)


func play_death(actor: BattlefieldActor) -> void:
	if _effects_component != null:
		_effects_component.play_death(actor)


func play_victory_animations() -> void:
	if _effects_component != null:
		_effects_component.play_victory_animations()

func presentation_report() -> Dictionary:
	var party := 0
	var enemies := 0
	var bosses := 0
	var sprites := 0
	for entry in _actors:
		var actor: BattlefieldActor = entry
		if actor.is_player:
			party += 1
		else:
			enemies += 1
			if actor.unit != null and actor.unit.is_boss:
				bosses += 1
		if actor.visual != null and not actor.visual.using_temporary_art:
			sprites += 1
	return {
		"actors": _actors.size(),
		"party": party,
		"enemies": enemies,
		"bosses": bosses,
		"painted_sprites": sprites,
		"positions": _positions(),
	}


func _positions() -> Array:
	var out: Array = []
	for entry in _actors:
		var actor: BattlefieldActor = entry
		out.append({
			"uid": actor.unit.uid if actor.unit != null else "",
			"team": "party" if actor.is_player else "enemy",
			"position": actor.position,
		})
	return out

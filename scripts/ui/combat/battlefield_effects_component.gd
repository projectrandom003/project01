class_name BattlefieldEffectsComponent
extends Control
## Facade that routes character attacks and delegates transient impact visuals.

var battlefield: Battlefield
var kael_attack_component: KaelAttackPresentationComponent
var matron_attack_component: MatronAttackPresentationComponent
var generic_attack_component: GenericAttackPresentationComponent
var impact_component: BattlefieldImpactEffectsComponent


func bind(owner: Battlefield) -> void:
	battlefield = owner
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func play_attack(attacker: BattlefieldActor, target: BattlefieldActor,
		element: String = "neutral", skill_id: String = "", ultimate: bool = false) -> void:
	if attacker == null or not is_instance_valid(attacker):
		return
	if attacker.unit != null and attacker.unit.def_id == "fallen_matron":
		if matron_attack_component != null:
			matron_attack_component.play_attack(attacker, target, skill_id, ultimate)
		return
	if attacker.unit != null and attacker.unit.def_id == "kael":
		kael_attack_component.play_attack(attacker, target, skill_id, ultimate)
		return
	if generic_attack_component != null:
		generic_attack_component.play_attack(attacker, target, element)


## Impact numbers and elemental particles are owned by their authored component.
func spawn_damage_number(actor: BattlefieldActor, text: String, color: Color,
		delay: float = 0.0) -> void:
	if impact_component != null:
		impact_component.spawn_damage_number(actor, text, color, delay)


func spawn_elemental_burst(pos: Vector2, element: String) -> void:
	if impact_component != null:
		impact_component.spawn_elemental_burst(pos, element)


func play_matron_phase(phase_number: int) -> void:
	if matron_attack_component != null:
		matron_attack_component.play_matron_phase(phase_number)


func play_death(actor: BattlefieldActor) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	actor.play_death()


func play_victory_animations() -> void:
	for entry in battlefield._actors:
		var actor: BattlefieldActor = entry
		if actor.is_player and not actor.dead:
			actor.play_victory()


# ------------------------------------------------------------------ report

## Machine-readable snapshot of the battlefield, for tests and tooling.

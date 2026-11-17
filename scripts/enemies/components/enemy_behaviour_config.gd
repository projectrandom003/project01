class_name EnemyBehaviourConfig
extends Resource

@export var initial_state: StringName = &"idle"
@export var can_investigate: bool = false
@export var can_retreat: bool = false
@export var can_chase: bool = false
@export var can_cast: bool = false
@export var return_to_origin_after_combat: bool = true
@export var despawn_on_death: bool = false
@export var respawn_seconds: float = 75.0
@export var metadata: Dictionary = {}

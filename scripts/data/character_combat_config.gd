class_name CharacterCombatConfig
extends Resource
## Reusable per-character combat presentation/configuration data.
## Numerical combat rules remain in gameplay systems; this resource describes
## presentation hooks, attachment preferences, and configurable combat visuals.

@export var character_id: StringName = &""
@export var combat_attachment_scene: PackedScene
@export var vfx_attachment_scene: PackedScene
@export var default_attack_animation: StringName = &"attack"
@export var default_skill_animation: StringName = &"cast"
@export var default_hit_animation: StringName = &"damage"
@export var default_death_animation: StringName = &"defeat"
@export var default_victory_animation: StringName = &"victory"
@export var projectile_origin: Vector2 = Vector2.ZERO
@export var hit_origin: Vector2 = Vector2(0, -24)
@export var notes: String = ""

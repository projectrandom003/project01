class_name CharacterAnimationConfig
extends Resource
## Reusable per-character animation presentation configuration.
## Keeps animation library/state references as data without owning gameplay logic.

@export var character_id: StringName = &""
@export var locomotion_library: AnimationLibrary
@export var action_library: AnimationLibrary
@export var default_idle_animation: StringName = &"idle_bob"
@export var default_walk_animation: StringName = &"walk_bob"
@export var default_run_animation: StringName = &"run_bob"
@export var supports_directions: bool = true
@export var supports_one_shots: bool = true
@export var notes: String = ""

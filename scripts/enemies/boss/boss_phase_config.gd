class_name BossPhaseConfig
extends Resource

@export var phase_id: StringName = &"phase_1"
@export var display_name: String = "Phase 1"
@export var hp_threshold_ratio: float = 1.0
@export var attack_pattern_ids: Array[String] = []
@export var skill_ids: Array[String] = []
@export var movement_profile: String = "default"
@export var transition_message: String = ""
@export var presentation_profile: Resource
@export var metadata: Dictionary = {}

class_name BossConfig
extends Resource

@export var boss_id: String = ""
@export var display_name: String = ""
@export var phases: Array[BossPhaseConfig] = []
@export var presentation_profile: Resource
@export var health_display_enabled: bool = true
@export var transition_effects_enabled: bool = true
@export var metadata: Dictionary = {}
